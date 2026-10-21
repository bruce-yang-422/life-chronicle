import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/media_probe.dart';

import '../../support/mpeg_samples.dart';

Future<MediaProbe> probe(List<int> bytes) async {
  final result = MediaProbe(
    bytes.length,
    (offset, count) async => bytes.sublist(offset, offset + count),
  );
  await result.inspect();
  return result;
}

void main() {
  test('測資 CRC 使用 MPEG-2 已知測試向量', () {
    expect(mpegCrc(ascii.encode('123456789')), 0x0376e6e7);
  });

  test('MPEG-1／2 PS 純音訊允許，後續影片 PES 不漏判', () async {
    for (final pack in [psPack, psPack1]) {
      final audio = await probe([
        ...pack,
        ...pes(0xc0, [0, 0, 1, 0xe0]),
        0,
        0,
        1,
        0xb9,
      ]);
      expect(audio.containsVideo, isFalse);
      expect(await audio.inspect(), 'video/mpeg');
      expect(
        (await probe([
          ...pack,
          ...pes(0xc0, [1]),
          ...pes(0xe0, [2]),
        ])).containsVideo,
        isTrue,
      );
    }
  });

  test('PSM 內的影片即使沒有影片 PES 仍辨識，CRC 錯誤不可放行', () async {
    expect(
      (await probe([
        ...psPack,
        ...psm([(0x0f, 0xc0)]),
      ])).containsVideo,
      isFalse,
    );
    expect(
      (await probe([
        ...psPack,
        ...psm([(0x0f, 0xc0), (0x1b, 0xe0)]),
      ])).containsVideo,
      isTrue,
    );
    final corrupt = [
      ...psPack,
      ...psm([(0x0f, 0xc0)]),
    ];
    corrupt[corrupt.length - 1] ^= 1;
    await expectLater(probe(corrupt), throwsFormatException);
    await expectLater(
      probe([
        ...psPack,
        ...pes(0xbd, [1]),
      ]),
      throwsFormatException,
    );
  });

  test('188／192／204 byte TS 依軌道區分純音訊與影片，MIME 不代替影片旗標', () async {
    for (final stride in [188, 192, 204]) {
      final audio = await probe(
        transport([track(0x0f, 0x101)], stride: stride),
      );
      expect(await audio.inspect(), 'video/mp2t');
      expect(audio.containsVideo, isFalse);
      final video = await probe(
        transport([track(0x0f, 0x101), track(0x1b, 0x102)], stride: stride),
      );
      expect(video.containsVideo, isTrue);
    }
  });

  test('TS 不採信第一個節目，PMT 出現在 PAT 之前也能判讀', () async {
    final bytes = ts([
      ...sectionPackets(0x100, pmt([track(0x0f, 0x101)])),
      ...sectionPackets(0, programTable({1: 0x100, 2: 0x200})),
      ...sectionPackets(0x200, pmt([track(0x24, 0x201)], program: 2)),
    ]);
    expect((await probe(bytes)).containsVideo, isTrue);
  });

  test('跨封包 PMT、pointer 完成前一 section、重複封包與多 section PAT', () async {
    final firstPat = programTable({1: 0x100}, section: 0, last: 1);
    final secondPat = programTable({2: 0x200}, section: 1, last: 1);
    final header = tsPacket(0, [0, ...firstPat.sublist(0, 7)], cc: 0);
    final rest = firstPat.sublist(7);
    final next = tsPacket(0, [rest.length, ...rest, ...secondPat], cc: 1);
    final longPmt = pmt([
      track(6, 0x101, [
        5,
        4,
        ...ascii.encode('Opus'),
        0x0a,
        180,
        ...List.filled(180, 0),
      ]),
    ]);
    final pmts = sectionPackets(0x100, longPmt, firstCapacity: 10);
    final bytes = ts([
      header,
      next,
      next,
      ...pmts,
      ...sectionPackets(0x200, pmt([track(3, 0x201)], program: 2)),
    ]);
    expect((await probe(bytes)).containsVideo, isFalse);
  });

  test('檢查整份串流後續 PMT 版本，不能只看開頭的純音訊表格', () async {
    final bytes = ts([
      ...sectionPackets(0, programTable({1: 0x100})),
      ...sectionPackets(0x100, pmt([track(3, 0x101)])),
      ...sectionPackets(
        0x100,
        pmt([track(3, 0x101), track(0x33, 0x102)], version: 1),
        cc: 1,
      ),
    ]);
    expect((await probe(bytes)).containsVideo, isTrue);
  });

  test('兩個 TS 封包即可識別表格，adaptation-only discontinuity 可重設連續號', () async {
    final tables = [
      ...sectionPackets(0, programTable({1: 0x100})),
      ...sectionPackets(0x100, pmt([track(3, 0x101)])),
    ];
    expect((await probe(ts(tables))).containsVideo, isFalse);
    expect(
      (await probe(
        ts([
          ...tables,
          [0x47, 1, 0, 0x20, 183, 0x80, ...List.filled(182, 255)],
          ...sectionPackets(0x100, pmt([track(3, 0x101)]), cc: 7),
        ]),
      )).containsVideo,
      isFalse,
    );
  });

  test('私有描述器分辨音訊與影片；未知私有軌不可猜成音訊', () async {
    expect(
      (await probe(
        transport([
          track(6, 0x101, [5, 4, ...ascii.encode('AC-3')]),
        ]),
      )).containsVideo,
      isFalse,
    );
    expect(
      (await probe(
        transport([
          track(6, 0x101, [5, 4, ...ascii.encode('AV01')]),
        ]),
      )).containsVideo,
      isTrue,
    );
    await expectLater(
      probe(transport([track(3, 0x101), track(6, 0x102)])),
      throwsFormatException,
    );
  });

  test('CRC 損毀、缺少節目 PMT、截斷、加密、封包錯誤均不放行純音訊', () async {
    final valid = transport([track(3, 0x101)]);
    final badCrc = List.of(valid)..[187] ^= 1;
    final encrypted = List.of(valid)..[3] |= 0x80;
    final transportError = List.of(valid)..[1] |= 0x80;
    final missing = ts([
      ...sectionPackets(0, programTable({1: 0x100, 2: 0x200})),
      ...sectionPackets(0x100, pmt([track(3, 0x101)])),
      tsPacket(8191, List.filled(184, 255)),
    ]);
    for (final bytes in [
      badCrc,
      encrypted,
      transportError,
      missing,
      valid.sublist(0, valid.length - 1),
    ]) {
      await expectLater(probe(bytes), throwsFormatException);
    }
  });

  test('PMT 斷續封包或 pointer 越界，不接受不完整表格', () async {
    final section = pmt([track(3, 0x101)]);
    final fragments = sectionPackets(0x100, section, firstCapacity: 10);
    final badCounter = List.of(fragments.last)
      ..[3] = (fragments.last[3] & 0xf0) | 4;
    for (final packets in [
      [fragments.first, badCounter],
      [
        tsPacket(0x100, [255, 1]),
      ],
    ]) {
      await expectLater(
        probe(
          ts([
            ...sectionPackets(0, programTable({1: 0x100})),
            ...packets,
            tsPacket(8191, List.filled(184, 255)),
          ]),
        ),
        throwsFormatException,
      );
    }
  });
}
