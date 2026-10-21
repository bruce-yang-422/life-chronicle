import 'dart:convert';

import 'package:archive/archive.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/media_probe.dart';

import '../../support/media_samples.dart';

Future<String> inspect(List<int> bytes) => MediaProbe(
  bytes.length,
  (offset, count) async => bytes.sublist(offset, offset + count),
).inspect();

void main() {
  test('BMFF 只讀軌道 handler，純音訊允許，最後一條影片仍拒絕', () async {
    expect(await inspect(bmff(['soun'])), 'audio/mp4');
    expect(
      await inspect([
        ...box('uuid', List.filled(16, 0)),
        ...box('abcd', [1, 2]),
        ...bmff(['vide']),
      ]),
      'video/mp4',
    );
    expect(await inspect(bmff(['soun', 'vide'])), 'video/mp4');
    expect(await inspect(bmff(['vide'], brand: 'heic')), 'video/mp4');
    expect(await inspect(bmff(['soun'], extended: true)), 'audio/mp4');
    expect(
      await inspect([
        ...box('free', [1, 2]),
        ...bmff(['vide']),
      ]),
      'video/mp4',
    );
    expect(
      await inspect(
        box(
          'moov',
          box(
            'trak',
            box(
              'mdia',
              box('hdlr', [...List.filled(8, 0), ...ascii.encode('soun')]),
            ),
          ),
          toEnd: true,
        ),
      ),
      'audio/mp4',
    );
  });

  test('HEIF／AVIF 依品牌判定，沒有音訊或影片軌也不誤拒絕靜態圖', () async {
    expect(
      await inspect(
        box('ftyp', [...ascii.encode('heic'), ...List.filled(4, 0)]),
      ),
      'image/heif',
    );
    expect(
      await inspect(
        box('ftyp', [...ascii.encode('avif'), ...List.filled(4, 0)]),
      ),
      'image/avif',
    );
  });

  test('Matroska／WebM 解析 TrackType，不採用名稱或 payload 字串', () async {
    expect(await inspect(matroska([2])), 'audio/webm');
    expect(await inspect(matroska([2, 1])), 'video/webm');
    expect(await inspect(matroska([2], webm: false)), 'audio/x-matroska');
    expect(await inspect(matroska([1], unknown: true)), 'video/webm');
    expect(await inspect(matroska([2], unknown: true)), 'audio/webm');
  });

  test('AVI／FLV／Ogg 的音訊與影片分開判斷', () async {
    expect(await inspect(avi(['auds'])), 'audio/x-msvideo');
    expect(await inspect(avi(['auds', 'vids'])), 'video/x-msvideo');
    expect(await inspect(flv([8])), 'audio/x-flv');
    expect(await inspect(flv([8, 9])), 'video/x-flv');
    expect(await inspect(ogg('OpusHead')), 'audio/ogg');
    expect(
      await inspect([...ogg('OpusHead'), ...ogg('\u0080theora')]),
      'video/ogg',
    );
    expect(await inspect(asf(false)), 'audio/x-ms-wma');
    expect(await inspect(asf(true)), 'video/x-ms-wmv');
    await expectLater(
      inspect([...ogg('OpusHead'), ...ogg('unknown codec')]),
      throwsFormatException,
    );
  });

  test('已知媒體容器截斷、越界與無法判讀軌道均不當作一般檔案放行', () async {
    for (final bytes in [
      [0, 0, 0, 255, ...ascii.encode('ftyp')],
      [0, 0, 0, 1, ...ascii.encode('moov'), ...List.filled(8, 255)],
      box('ftyp', [...ascii.encode('isom'), ...List.filled(4, 0)]),
      matroska([2]).sublist(0, 11),
      [0x1a, 0x45, 0xdf, 0xa3, 0],
      avi(['auds']).sublist(0, 14),
      ogg('OpusHead').sublist(0, 10),
    ]) {
      await expectLater(inspect(bytes), throwsFormatException);
    }
  });

  test('JPEG 密集 stuffed bytes／restart 仍按區塊讀取，保留跨界 EOI', () async {
    for (final ending in [0, 1, 2]) {
      final entropy = <int>[
        for (var i = 0; i < 100000; i++) ...[17, 255, i.isEven ? 0 : 0xd0],
        ...List.filled(ending, 17),
      ];
      final bytes = <int>[255, 216, 255, 218, 0, 2, ...entropy, 255, 217];
      var readBytes = 0;
      final probe = MediaProbe(bytes.length, (offset, count) async {
        readBytes += count;
        return bytes.sublist(offset, offset + count);
      });
      expect(await probe.inspect(), 'image/jpeg');
      expect(readBytes, lessThan(bytes.length * 4));
      expect(probe.staticImageBytes, isNull);
    }
    // 第一塊末尾的 FF 與下一塊的 00 仍是熵資料，不能誤截照片。
    final bytes = <int>[
      255,
      216,
      255,
      218,
      0,
      2,
      ...List.filled(65535, 17),
      255,
      0,
      17,
      255,
      217,
    ];
    expect(await inspect(bytes), 'image/jpeg');
    await expectLater(
      inspect(bytes.sublist(0, bytes.length - 1)),
      throwsFormatException,
    );
  });

  test('動態 JPEG 只取外層 EOI 之前的靜態圖，不截在 EXIF 縮圖', () async {
    final bytes = [
      ...stillJpeg,
      ...bmff(['vide']),
    ];
    final probe = MediaProbe(
      bytes.length,
      (offset, count) async => bytes.sublist(offset, offset + count),
    );
    expect(await probe.inspect(), 'image/jpeg');
    expect(probe.staticImageBytes, stillJpeg.length);
    expect(await inspect(stillJpeg), 'image/jpeg');
  });

  test('XMP 宣告的動態照片即使有尾段前綴，也只保存靜態 JPEG', () async {
    final xmp = ascii.encode(
      'http://ns.adobe.com/xap/1.0/\u0000<x GCamera:MotionPhoto="1"/>',
    );
    final image = [
      255,
      216,
      255,
      225,
      ...number(xmp.length + 2, 2),
      ...xmp,
      ...stillJpeg.skip(2),
    ];
    final bytes = [
      ...image,
      ...ascii.encode('MotionPhoto_Data'),
      ...bmff(['vide']),
    ];
    final probe = MediaProbe(
      bytes.length,
      (offset, count) async => bytes.sublist(offset, offset + count),
    );
    expect(await probe.inspect(), 'image/jpeg');
    expect(probe.staticImageBytes, image.length);
  });

  test('PDF、PNG、GIF 與未知一般檔案不信任外部副檔名', () async {
    expect(await inspect(ascii.encode('%PDF-1.7')), 'application/pdf');
    expect(await inspect([137, 80, 78, 71, 13, 10, 26, 10]), 'image/png');
    expect(await inspect(ascii.encode('GIF89a')), 'image/gif');
    expect(await inspect([1, 2, 3]), 'application/octet-stream');
  });

  test('OOXML 依 ZIP 結構保留 Office MIME，一般 ZIP 不誤判', () async {
    for (final (entry, suffix) in [
      ('word/document.xml', 'wordprocessingml.document'),
      ('xl/workbook.xml', 'spreadsheetml.sheet'),
      ('ppt/presentation.xml', 'presentationml.presentation'),
    ]) {
      final archive = Archive()
        ..addFile(ArchiveFile.string('[Content_Types].xml', '<Types/>'))
        ..addFile(ArchiveFile.string(entry, '<document/>'));
      expect(
        await inspect(ZipEncoder().encode(archive)),
        'application/vnd.openxmlformats-officedocument.$suffix',
      );
    }
    expect(
      await inspect(
        ZipEncoder().encode(
          Archive()..addFile(ArchiveFile.string('notes.txt', 'notes')),
        ),
      ),
      'application/zip',
    );
  });

  test('大 mdat 直接定位略過，不載入整份影音或逐 byte 搜尋 vide', () async {
    const payload = 1024 * 1024 * 1024;
    final prefix = [
      ...box('ftyp', [...ascii.encode('isom'), ...List.filled(4, 0)]),
      ...number(payload + 8, 4),
      ...ascii.encode('mdat'),
    ];
    final suffix = box(
      'moov',
      box(
        'trak',
        box(
          'mdia',
          box('hdlr', [...List.filled(8, 0), ...ascii.encode('vide')]),
        ),
      ),
    );
    final tailAt = prefix.length + payload;
    var totalRead = 0;
    final result = await MediaProbe(tailAt + suffix.length, (
      offset,
      count,
    ) async {
      expect(count, lessThanOrEqualTo(65536));
      totalRead += count;
      return List.generate(count, (i) {
        final at = offset + i;
        if (at < prefix.length) return prefix[at];
        if (at >= tailAt) return suffix[at - tailAt];
        return 0;
      });
    }).inspect();
    expect(result, 'video/mp4');
    expect(totalRead, lessThan(140000));
  });

  test('短讀取回報失敗，避免檔案變動造成越界或誤判', () async {
    await expectLater(
      MediaProbe(100, (_, count) async => [0]).inspect(),
      throwsFormatException,
    );
  });
}
