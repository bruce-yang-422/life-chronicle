import 'dart:math' as math;

import 'mpeg_probe.dart';

typedef MediaRead = Future<List<int>> Function(int offset, int count);

/// 不讀副檔名或平台 MIME；只依內容判斷。呼叫端提供可定位的讀取介面。
/// 容器結構依 W3C ISO BMFF 與 Matroska element 規格：
/// https://www.w3.org/TR/mse-byte-stream-format-isobmff/
/// https://www.matroska.org/technical/elements.html
class MediaProbe {
  MediaProbe(this.length, this.read);
  final int length;
  final MediaRead read;
  int? staticImageBytes;
  bool containsVideo = false;
  int _elements = 0;
  int _cacheOffset = -1;
  List<int> _cache = const [];

  void _step() {
    if (++_elements > 100000) throw const FormatException();
  }

  Future<List<int>> _bytes(int offset, int count) async {
    if (offset < 0 || count < 0 || offset + count > length) {
      throw const FormatException();
    }
    if (count == 0) return const [];
    if (offset < _cacheOffset ||
        offset + count > _cacheOffset + _cache.length) {
      final size = math.min(length - offset, math.max(count, 65536));
      _cache = await read(offset, size);
      _cacheOffset = offset;
      if (_cache.length != size) throw const FormatException();
    }
    return _cache.sublist(offset - _cacheOffset, offset - _cacheOffset + count);
  }

  static int _uint(List<int> bytes, {bool little = false}) {
    var result = 0;
    for (final byte in little ? bytes.reversed : bytes) {
      result = result * 256 + byte;
    }
    return result;
  }

  static String _text(List<int> bytes) => String.fromCharCodes(bytes);

  Future<String> inspect() async {
    final type = await _inspect();
    containsVideo = type.startsWith('video/');
    // MPEG 容器的標準 MIME 以 video/ 開頭，即使內容只有錄音。
    return switch (type) {
      'audio/mp2t' => 'video/mp2t',
      'audio/mpeg-ps' => 'video/mpeg',
      _ => type,
    };
  }

  Future<String> _inspect() async {
    final head = await _bytes(0, math.min(length, 32));
    bool starts(List<int> signature) =>
        head.length >= signature.length &&
        List.generate(
          signature.length,
          (i) => head[i] == signature[i],
        ).every((v) => v);
    if (head.length >= 8 &&
        const {
          'ftyp',
          'moov',
          'mdat',
          'free',
          'wide',
          'skip',
          'styp',
        }.contains(_text(head.sublist(4, 8)))) {
      return _bmff();
    }
    if (await _hasBmffMarker()) return _bmff();
    if (starts([0x1a, 0x45, 0xdf, 0xa3])) return _matroska();
    if (starts([0x52, 0x49, 0x46, 0x46]) && head.length >= 12) {
      final form = _text(head.sublist(8, 12));
      if (form == 'AVI ') return _avi();
      if (form == 'WAVE') return 'audio/wav';
      if (form == 'WEBP') return 'image/webp';
    }
    if (starts([0x46, 0x4c, 0x56]) && head.length >= 9) {
      return _flv();
    }
    if (starts([
      0x30,
      0x26,
      0xb2,
      0x75,
      0x8e,
      0x66,
      0xcf,
      0x11,
      0xa6,
      0xd9,
      0,
      0xaa,
      0,
      0x62,
      0xce,
      0x6c,
    ])) {
      return _asf();
    }
    if (starts([0x4f, 0x67, 0x67, 0x53])) return _ogg();
    if (starts([0, 0, 1, 0xb3])) return 'video/mpeg';
    if (starts([0, 0, 1, 0xb0])) return 'video/mp4v-es';
    if (starts([0, 0, 1, 0xba])) {
      return MpegProbe(length, _bytes).programStream();
    }
    final nalAt = starts([0, 0, 0, 1])
        ? 4
        : starts([0, 0, 1])
        ? 3
        : -1;
    if (nalAt >= 0 && head.length > nalAt + 1 && head[nalAt] & 0x80 == 0) {
      if ({32, 33, 34, 35, 39, 40}.contains((head[nalAt] >> 1) & 63)) {
        return 'video/h265';
      }
      if ({1, 5, 6, 7, 8, 9}.contains(head[nalAt] & 31)) return 'video/h264';
    }
    // 至少確認兩個封包，另檢查可用的第三個同步位元組。
    for (final stride in [188, 192, 204]) {
      final start = stride == 192 ? 4 : 0;
      if (length >= stride * 2 &&
          (await _bytes(start, 1)).single == 0x47 &&
          (await _bytes(start + stride, 1)).single == 0x47 &&
          (length < stride * 3 ||
              (await _bytes(start + stride * 2, 1)).single == 0x47)) {
        return MpegProbe(length, _bytes).transportStream(stride);
      }
    }
    if (starts([255, 216, 255])) return _jpeg();
    if (starts([137, 80, 78, 71, 13, 10, 26, 10])) return 'image/png';
    if (starts([71, 73, 70, 56, 55, 97]) || starts([71, 73, 70, 56, 57, 97])) {
      return 'image/gif';
    }
    if (starts([37, 80, 68, 70, 45])) return 'application/pdf';
    if (starts([0x50, 0x4b, 3, 4]) || starts([0x50, 0x4b, 5, 6])) {
      return _zipType();
    }
    if (starts([0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1])) {
      return 'application/x-ole-storage';
    }
    if (starts([0x66, 0x4c, 0x61, 0x43])) return 'audio/flac';
    if (starts([0x49, 0x44, 0x33])) return 'audio/mpeg';
    if (head.length >= 2 && head[0] == 255 && head[1] & 0xe0 == 0xe0) {
      return head[1] & 0xf6 == 0xf0 ? 'audio/aac' : 'audio/mpeg';
    }
    return 'application/octet-stream';
  }

  /// BMFF 允許未知頂層 box，前置 uuid／自訂 box 仍須找到後面的軌道。
  Future<bool> _hasBmffMarker() async {
    var at = 0;
    while (at + 8 <= length) {
      final h = await _bytes(at, 8);
      if (h.skip(4).any((byte) => byte < 32 || byte > 126)) return false;
      final type = _text(h.sublist(4));
      if (type == 'ftyp' || type == 'moov' || type == 'mdat') return true;
      var size = _uint(h.sublist(0, 4));
      var header = 8;
      if (size == 1) {
        if (at + 16 > length) return false;
        size = _uint(await _bytes(at + 8, 8));
        header = 16;
      }
      if (size < header || size > length - at) return false;
      _step();
      at += size;
    }
    return false;
  }

  /// 略過 EXIF 縮圖與 FF00 熵資料，不把內嵌的 EOI 誤認為照片結尾。
  Future<String> _jpeg() async {
    var at = 2;
    var motionDeclared = false;
    while (at < length) {
      _step();
      if ((await _bytes(at++, 1)).single != 255) throw const FormatException();
      var marker = (await _bytes(at++, 1)).single;
      while (marker == 255) {
        marker = (await _bytes(at++, 1)).single;
      }
      if (marker == 0xd9) {
        if (length > at &&
            (motionDeclared ||
                length - at >= 16 &&
                    _text(await _bytes(at, 16)) == 'MotionPhoto_Data')) {
          staticImageBytes = at;
          return 'image/jpeg';
        }
        if (length - at >= 8 && _text(await _bytes(at + 4, 4)) == 'ftyp') {
          final end = at;
          final tail = await MediaProbe(
            length - end,
            (offset, count) => read(offset + end, count),
          ).inspect();
          if (tail.startsWith('video/')) staticImageBytes = end;
        }
        return 'image/jpeg';
      }
      if (marker == 0 ||
          marker == 0xd8 ||
          marker == 0x01 ||
          marker >= 0xd0 && marker <= 0xd7) {
        throw const FormatException();
      }
      final size = _uint(await _bytes(at, 2));
      if (size < 2 || size > length - at) throw const FormatException();
      if (marker == 0xe1) {
        final xmp = _text(await _bytes(at + 2, size - 2));
        if (xmp.startsWith('http://ns.adobe.com/xap/1.0/\u0000')) {
          motionDeclared |= RegExp(
            r'''(?:\w+:)?(?:MotionPhoto|MicroVideo)\s*=\s*["']1["']''',
          ).hasMatch(xmp);
        }
      }
      at += size;
      if (marker == 0xda) {
        while (at < length) {
          final bytes = await _bytes(at, math.min(65536, length - at));
          final next = bytes.indexOf(255);
          if (next < 0) {
            at += bytes.length;
            continue;
          }
          at += next;
          final code = (await _bytes(at + 1, 1)).single;
          if (code == 0 || code >= 0xd0 && code <= 0xd7) {
            at += 2;
          } else {
            break;
          }
        }
      }
    }
    throw const FormatException();
  }

  /// 只讀 ZIP 目錄辨識 OOXML；不解壓或執行附件，其他 ZIP 原樣保存。
  Future<String> _zipType() async {
    final start = math.max(0, length - 65557);
    final tail = await _bytes(start, length - start);
    for (var i = tail.length - 22; i >= 0; i--) {
      if (tail[i] != 0x50 ||
          tail[i + 1] != 0x4b ||
          tail[i + 2] != 5 ||
          tail[i + 3] != 6) {
        continue;
      }
      if (i + 22 + _uint(tail.sublist(i + 20, i + 22), little: true) !=
          tail.length) {
        continue;
      }
      final count = _uint(tail.sublist(i + 10, i + 12), little: true);
      final size = _uint(tail.sublist(i + 12, i + 16), little: true);
      var at = _uint(tail.sublist(i + 16, i + 20), little: true);
      if (at + size > start + i || count == 65535 || at == 0xffffffff) break;
      final end = at + size;
      var contentTypes = false;
      var word = false;
      var excel = false;
      var slides = false;
      for (var entry = 0; entry < count; entry++) {
        if (at + 46 > end) return 'application/zip';
        final header = await _bytes(at, 46);
        if (_uint(header.sublist(0, 4), little: true) != 0x02014b50) {
          return 'application/zip';
        }
        final nameLength = _uint(header.sublist(28, 30), little: true);
        final extraLength = _uint(header.sublist(30, 32), little: true);
        final commentLength = _uint(header.sublist(32, 34), little: true);
        final next = at + 46 + nameLength + extraLength + commentLength;
        if (next > end) return 'application/zip';
        final name = _text(await _bytes(at + 46, nameLength));
        contentTypes |= name == '[Content_Types].xml';
        word |= name == 'word/document.xml';
        excel |= name == 'xl/workbook.xml';
        slides |= name == 'ppt/presentation.xml';
        at = next;
      }
      if (!contentTypes) break;
      if (word) {
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      }
      if (excel) {
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      }
      if (slides) {
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      }
      break;
    }
    return 'application/zip';
  }

  Future<String> _bmff() async {
    final handlers = <String>{};
    final brands = <String>{};
    Future<void> boxes(int start, int end, String parent) async {
      var at = start;
      while (at < end) {
        _step();
        if (end - at < 8) throw const FormatException();
        final h = await _bytes(at, 8);
        var size = _uint(h.sublist(0, 4));
        final type = _text(h.sublist(4));
        var header = 8;
        if (size == 1) {
          if (end - at < 16) throw const FormatException();
          size = _uint(await _bytes(at + 8, 8));
          header = 16;
        } else if (size == 0) {
          size = end - at;
        }
        if (size < header || size > end - at) throw const FormatException();
        final body = at + header;
        if (type == 'ftyp' && parent.isEmpty) {
          if (size - header < 8 || (size - header) % 4 != 0) {
            throw const FormatException();
          }
          brands.add(_text(await _bytes(body, 4)));
          for (var i = body + 8; i < at + size; i += 4) {
            _step();
            brands.add(_text(await _bytes(i, 4)));
          }
        } else if ((type == 'moov' && parent.isEmpty) ||
            (type == 'trak' && parent == 'moov') ||
            (type == 'mdia' && parent == 'trak')) {
          await boxes(body, at + size, type);
        } else if (type == 'hdlr' && parent == 'mdia') {
          if (size - header < 12) throw const FormatException();
          handlers.add(_text(await _bytes(body + 8, 4)));
        }
        at += size;
      }
    }

    await boxes(0, length, '');
    if (handlers.contains('vide')) return 'video/mp4';
    if (brands.any({'heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'}.contains)) {
      return 'image/heif';
    }
    if (brands.any({'avif', 'avis'}.contains)) return 'image/avif';
    if (handlers.contains('soun')) return 'audio/mp4';
    if (handlers.isNotEmpty) return 'application/mp4';
    throw const FormatException();
  }

  Future<({int value, int width, bool unknown})> _vint(
    int at,
    int end, {
    bool id = false,
  }) async {
    if (at >= end) throw const FormatException();
    final first = (await _bytes(at, 1)).single;
    var mask = 0x80;
    var width = 1;
    while (mask > 0 && first & mask == 0) {
      mask >>= 1;
      width++;
    }
    if (mask == 0 || width > (id ? 4 : 8) || at + width > end) {
      throw const FormatException();
    }
    final bytes = await _bytes(at, width);
    var value = id ? first : first & (mask - 1);
    var unknown = !id && value == mask - 1;
    for (final byte in bytes.skip(1)) {
      value = value * 256 + byte;
      unknown = unknown && byte == 255;
    }
    return (value: value, width: width, unknown: unknown);
  }

  Future<String> _matroska() async {
    final tracks = <int>{};
    var webm = false;
    Future<void> elements(int start, int end, int parent) async {
      var at = start;
      while (at < end) {
        _step();
        final id = await _vint(at, end, id: true);
        final size = await _vint(at + id.width, end);
        final body = at + id.width + size.width;
        if (size.unknown && id.value != 0x18538067) {
          throw const FormatException();
        }
        final next = size.unknown ? end : body + size.value;
        if (next > end) throw const FormatException();
        if ((parent == 0 && {0x1a45dfa3, 0x18538067}.contains(id.value)) ||
            (parent == 0x18538067 && id.value == 0x1654ae6b) ||
            (parent == 0x1654ae6b && id.value == 0xae)) {
          await elements(body, next, id.value);
        } else if (parent == 0x1a45dfa3 &&
            id.value == 0x4282 &&
            next - body <= 32) {
          webm = _text(await _bytes(body, next - body)) == 'webm';
        } else if (parent == 0xae && id.value == 0x83) {
          if (next - body < 1 || next - body > 8) throw const FormatException();
          tracks.add(_uint(await _bytes(body, next - body)));
        }
        at = next;
      }
    }

    await elements(0, length, 0);
    if (tracks.contains(1)) return webm ? 'video/webm' : 'video/x-matroska';
    if (tracks.contains(2)) return webm ? 'audio/webm' : 'audio/x-matroska';
    if (tracks.isNotEmpty) return 'application/x-matroska';
    throw const FormatException();
  }

  Future<String> _avi() async {
    var video = false;
    var audio = false;
    Future<void> chunks(int start, int end, int depth) async {
      if (depth > 16) throw const FormatException();
      var at = start;
      while (at < end) {
        _step();
        if (end - at < 8) throw const FormatException();
        final h = await _bytes(at, 8);
        final type = _text(h.sublist(0, 4));
        final size = _uint(h.sublist(4), little: true);
        final body = at + 8;
        if (size > end - body) throw const FormatException();
        if (type == 'LIST' && size >= 4) {
          final kind = _text(await _bytes(body, 4));
          if (kind == 'hdrl' || kind == 'strl') {
            await chunks(body + 4, body + size, depth + 1);
          }
        } else if (type == 'strh' && size >= 4) {
          final kind = _text(await _bytes(body, 4));
          video |= kind == 'vids';
          audio |= kind == 'auds';
        }
        at = body + size + (size % 2);
      }
    }

    final size = _uint(await _bytes(4, 4), little: true);
    if (size < 4 || size + 8 > length) throw const FormatException();
    await chunks(12, size + 8, 0);
    if (video) return 'video/x-msvideo';
    if (audio) return 'audio/x-msvideo';
    throw const FormatException();
  }

  Future<String> _asf() async {
    if (length < 30) throw const FormatException();
    final end = _uint(await _bytes(16, 8), little: true);
    if (end < 30 || end > length) throw const FormatException();
    var at = 30;
    var audio = false;
    while (at < end) {
      _step();
      if (end - at < 24) throw const FormatException();
      final h = await _bytes(at, 24);
      final size = _uint(h.sublist(16), little: true);
      if (size < 24 || size > end - at) throw const FormatException();
      if (_text(h.sublist(0, 16)) ==
          String.fromCharCodes([
            0x91,
            7,
            0xdc,
            0xb7,
            0xb7,
            0xa9,
            0xcf,
            0x11,
            0x8e,
            0xe6,
            0,
            0xc0,
            0x0c,
            0x20,
            0x53,
            0x65,
          ])) {
        if (size < 40) throw const FormatException();
        final stream = await _bytes(at + 24, 16);
        if (_text(stream) ==
            String.fromCharCodes([
              0xc0,
              0xef,
              0x19,
              0xbc,
              0x4d,
              0x5b,
              0xcf,
              0x11,
              0xa8,
              0xfd,
              0,
              0x80,
              0x5f,
              0x5c,
              0x44,
              0x2b,
            ])) {
          return 'video/x-ms-wmv';
        }
        audio |=
            _text(stream) ==
            String.fromCharCodes([
              0x40,
              0x9e,
              0x69,
              0xf8,
              0x4d,
              0x5b,
              0xcf,
              0x11,
              0xa8,
              0xfd,
              0,
              0x80,
              0x5f,
              0x5c,
              0x44,
              0x2b,
            ]);
      }
      at += size;
    }
    if (audio) return 'audio/x-ms-wma';
    throw const FormatException();
  }

  Future<String> _flv() async {
    final h = await _bytes(0, 9);
    if (h[3] != 1) throw const FormatException();
    var at = _uint(h.sublist(5));
    if (at < 9) throw const FormatException();
    var audio = false;
    while (at < length) {
      _step();
      if (at + 4 == length) break;
      final tag = await _bytes(at + 4, 11);
      final size = _uint(tag.sublist(1, 4));
      if (at + 15 + size > length) throw const FormatException();
      if (tag[0] & 31 == 9) return 'video/x-flv';
      audio |= tag[0] & 31 == 8;
      at += 15 + size;
    }
    if (audio) return 'audio/x-flv';
    throw const FormatException();
  }

  Future<String> _ogg() async {
    var at = 0;
    var audio = false;
    while (at < length) {
      _step();
      final h = await _bytes(at, 27);
      if (_text(h.sublist(0, 4)) != 'OggS' || h[4] != 0) {
        throw const FormatException();
      }
      final lace = await _bytes(at + 27, h[26]);
      final size = lace.fold(0, (a, b) => a + b);
      final body = at + 27 + lace.length;
      if (body + size > length) throw const FormatException();
      if (h[5] & 2 != 0) {
        final first = _text(await _bytes(body, math.min(size, 16)));
        if (first.startsWith('\u0080theora') ||
            first.startsWith('BBCD') ||
            first.startsWith('\u0001video')) {
          return 'video/ogg';
        }
        final isAudio =
            first.startsWith('OpusHead') ||
            first.startsWith('\u0001vorbis') ||
            first.startsWith('Speex   ') ||
            first.startsWith('\u007fFLAC');
        if (!isAudio && !first.startsWith('fishead')) {
          throw const FormatException();
        }
        audio |= isAudio;
      }
      at = body + size;
    }
    if (audio) return 'audio/ogg';
    throw const FormatException();
  }
}
