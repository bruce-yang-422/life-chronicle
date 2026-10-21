/// MPEG 系統串流的結構判讀，不解碼或執行內容。
/// 參考 ITU-T H.222.0 與 https://www.w3.org/TR/mse-byte-stream-format-mp2t/
class MpegProbe {
  MpegProbe(this.length, this.read);
  final int length;
  final Future<List<int>> Function(int offset, int count) read;

  static int _u(List<int> bytes) => bytes.fold(0, (v, b) => v * 256 + b);
  static bool _prefix(List<int> b) =>
      b.length >= 4 && b[0] == 0 && b[1] == 0 && b[2] == 1;

  Future<List<int>> _get(int at, int count) async {
    if (at < 0 || count < 0 || at + count > length) {
      throw const FormatException();
    }
    final bytes = await read(at, count);
    if (bytes.length != count) throw const FormatException();
    return bytes;
  }

  /// Program Stream：依 pack／PES 邊界走訪，絕不在壓縮 payload 中搜尋假 start code。
  Future<String> programStream() async {
    var at = 0;
    var audio = false;
    var unknown = false;
    final mapped = <int, _Kind>{};
    while (at < length) {
      final h = await _get(at, 4);
      if (!_prefix(h)) throw const FormatException();
      final id = h[3];
      if (id == 0xb9) {
        if (at + 4 != length) throw const FormatException();
        at += 4;
        continue;
      }
      if (id == 0xba) {
        final first = (await _get(at + 4, 1)).single;
        if (first & 0xc0 == 0x40) {
          final pack = await _get(at, 14);
          if (pack[4] & 4 == 0 ||
              pack[6] & 4 == 0 ||
              pack[8] & 4 == 0 ||
              pack[9] & 1 == 0 ||
              pack[12] & 3 != 3) {
            throw const FormatException();
          }
          final stuff = await _get(at + 14, pack[13] & 7);
          if (stuff.any((b) => b != 255)) throw const FormatException();
          at += 14 + stuff.length;
        } else if (first & 0xf0 == 0x20) {
          final pack = await _get(at, 12);
          if (pack[4] & 1 == 0 ||
              pack[6] & 1 == 0 ||
              pack[8] & 1 == 0 ||
              pack[9] & 0x80 == 0 ||
              pack[11] & 1 == 0) {
            throw const FormatException();
          }
          at += 12;
        } else {
          throw const FormatException();
        }
        continue;
      }
      final size = _u(await _get(at + 4, 2));
      if (id >= 0xe0 && id <= 0xef) return 'video/mpeg';
      if (size == 0 || at + 6 + size > length) throw const FormatException();
      if (id == 0xbc) {
        final body = await _get(at + 6, size);
        if (size < 10 ||
            _crc(await _get(at, size + 6)) != 0 ||
            body[1] & 1 == 0) {
          throw const FormatException();
        }
        if (body[0] & 0x80 != 0) {
          final info = _u(body.sublist(2, 4));
          if (4 + info + 2 > body.length - 4) throw const FormatException();
          var pos = 6 + info;
          final end = pos + _u(body.sublist(4 + info, 6 + info));
          if (end != body.length - 4) throw const FormatException();
          while (pos < end) {
            if (pos + 4 > end) throw const FormatException();
            final extra = _u(body.sublist(pos + 2, pos + 4));
            if (pos + 4 + extra > end) throw const FormatException();
            final kind = _kind(
              body[pos],
              body.sublist(pos + 4, pos + 4 + extra),
            );
            if (kind == _Kind.video) return 'video/mpeg';
            audio |= kind == _Kind.audio;
            unknown |= kind == _Kind.unknown;
            mapped[body[pos + 1]] = kind;
            pos += 4 + extra;
          }
        }
      } else if (id >= 0xc0 && id <= 0xdf) {
        audio = true;
      } else if (id == 0xbd || id == 0xfd) {
        final kind = mapped[id] ?? _Kind.unknown;
        if (kind == _Kind.video) return 'video/mpeg';
        audio |= kind == _Kind.audio;
        unknown |= kind == _Kind.unknown;
      } else if (!{
        0xbb,
        0xbe,
        0xbf,
        0xf0,
        0xf1,
        0xf2,
        0xf8,
        0xff,
      }.contains(id)) {
        throw const FormatException();
      }
      at += 6 + size;
    }
    if (audio && !unknown) return 'audio/mpeg-ps';
    throw const FormatException();
  }

  /// 先收集整份 PAT，再讀所有節目的 PMT，涵蓋表格順序及版本變動。
  Future<String> transportStream(int stride) async {
    if (length % stride != 0) throw const FormatException();
    final programs = <(int, int)>{}; // (PMT PID, program_number)
    final found = <(int, int)>{};
    var audio = false;
    var video = false;
    var unknown = false;
    final tables = <(int, int, int), _TableSections>{};

    void section(int pid, List<int> b, bool pat) {
      if (b.length < (pat ? 12 : 16) ||
          b[0] != (pat ? 0 : 2) ||
          b[1] & 0xf0 != 0xb0 ||
          _crc(b) != 0) {
        throw const FormatException();
      }
      if (b[5] & 1 == 0) return;
      final program = _u(b.sublist(3, 5));
      final key = (pid, program, (b[5] >> 1) & 31);
      (tables[key] ??= _TableSections()).add(b);
      final end = b.length - 4;
      if (pat) {
        if ((end - 8) % 4 != 0) throw const FormatException();
        for (var pos = 8; pos < end; pos += 4) {
          final number = _u(b.sublist(pos, pos + 2));
          final pmt = ((b[pos + 2] & 31) << 8) | b[pos + 3];
          if (number != 0) {
            if (pmt == 0 || pmt == 8191) throw const FormatException();
            programs.add((pmt, number));
          }
        }
      } else {
        if (!programs.contains((pid, program)) || b[6] != 0 || b[7] != 0) {
          throw const FormatException();
        }
        found.add((pid, program));
        var pos = 12 + (((b[10] & 15) << 8) | b[11]);
        if (pos > end) throw const FormatException();
        while (pos < end) {
          if (pos + 5 > end) throw const FormatException();
          final size = ((b[pos + 3] & 15) << 8) | b[pos + 4];
          if (pos + 5 + size > end) throw const FormatException();
          final kind = _kind(b[pos], b.sublist(pos + 5, pos + 5 + size));
          video |= kind == _Kind.video;
          audio |= kind == _Kind.audio;
          unknown |= kind == _Kind.unknown;
          pos += 5 + size;
        }
      }
    }

    Future<void> pass(bool pat) async {
      final assemblers = <int, _Psi>{};
      final resets = <int>{};
      final pids = programs.map((p) => p.$1).toSet();
      for (var at = 0; at < length; at += stride) {
        final packet = await _get(at + (stride == 192 ? 4 : 0), 188);
        if (packet[0] != 0x47 || packet[1] & 0x80 != 0) {
          throw const FormatException();
        }
        final pid = ((packet[1] & 31) << 8) | packet[2];
        if (pid == 8191) continue;
        if (packet[3] & 0xc0 != 0) throw const FormatException();
        final control = (packet[3] >> 4) & 3;
        if (control == 0) throw const FormatException();
        var pos = 4;
        var discontinuity = false;
        if (control & 2 != 0) {
          final size = packet[pos++];
          if (pos + size > 188) throw const FormatException();
          if (size > 0) discontinuity = packet[pos] & 0x80 != 0;
          pos += size;
        }
        if (discontinuity) resets.add(pid);
        if (control & 1 == 0) {
          if (pos != 188) throw const FormatException();
          continue;
        }
        if (pos >= 188) throw const FormatException();
        final start = packet[1] & 0x40 != 0;
        final payload = packet.sublist(pos);
        if (start &&
            _prefix(payload) &&
            payload[3] >= 0xe0 &&
            payload[3] <= 0xef) {
          video = true;
          return;
        }
        if ((pat && pid == 0) || (!pat && pids.contains(pid))) {
          (assemblers[pid] ??= _Psi(
            (b) => section(pid, b, pat),
          )).packet(payload, start, packet[3] & 15, resets.remove(pid));
          if (video) return;
        }
      }
      if (assemblers.values.any((a) => a.incomplete)) {
        throw const FormatException();
      }
    }

    await pass(true);
    if (video) return 'video/mp2t';
    if (programs.isEmpty) throw const FormatException();
    await pass(false);
    if (video) return 'video/mp2t';
    if (programs.any((p) => !found.contains(p)) ||
        tables.values.any((t) => !t.complete) ||
        !audio ||
        unknown) {
      throw const FormatException();
    }
    return 'audio/mp2t';
  }
}

enum _Kind { audio, video, data, unknown }

_Kind _kind(int type, List<int> descriptors) {
  // 標準 stream_type；私有串流必須另有明確的 codec 描述，不能猜成錄音。
  if ({
    1,
    2,
    0x10,
    0x1b,
    0x1e,
    0x1f,
    0x20,
    0x21,
    0x22,
    0x23,
    0x24,
    0x25,
    0x2d,
    0x32,
    0x33,
    0x42,
    0xd1,
    0xea,
    0xdb,
  }.contains(type)) {
    return _Kind.video;
  }
  if ({3, 4, 0x0f, 0x11, 0x1c, 0x81, 0x84, 0xcf}.contains(type)) {
    return _Kind.audio;
  }
  if ({5, 0x0b, 0x0d, 0x15}.contains(type)) return _Kind.data;
  var kind = _Kind.unknown;
  for (var at = 0; at < descriptors.length;) {
    if (at + 2 > descriptors.length) throw const FormatException();
    final tag = descriptors[at];
    final end = at + 2 + descriptors[at + 1];
    if (end > descriptors.length) throw const FormatException();
    if (tag == 5 && end - at >= 6) {
      final registration = String.fromCharCodes(
        descriptors.sublist(at + 2, at + 6),
      );
      if ({'HEVC', 'AV01', 'VC-1', 'drac', 'VVC '}.contains(registration)) {
        return _Kind.video;
      }
      if ({
        'AC-3',
        'EAC3',
        'DTS1',
        'DTS2',
        'DTS3',
        'Opus',
        'BSSD',
      }.contains(registration)) {
        kind = _Kind.audio;
      }
    } else if ({0x6a, 0x7a, 0x7b, 0x7c}.contains(tag)) {
      kind = _Kind.audio;
    } else if ({0x56, 0x59}.contains(tag) && kind == _Kind.unknown) {
      kind = _Kind.data;
    }
    at = end;
  }
  return kind;
}

int _crc(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte << 24;
    for (var bit = 0; bit < 8; bit++) {
      crc =
          ((crc << 1) ^ (crc & 0x80000000 != 0 ? 0x04c11db7 : 0)) & 0xffffffff;
    }
  }
  return crc;
}

class _TableSections {
  int? last;
  final sections = <int, List<int>>{};
  void add(List<int> b) {
    if (b[6] > b[7] || (last != null && last != b[7])) {
      throw const FormatException();
    }
    last = b[7];
    final prior = sections[b[6]];
    if (prior != null &&
        (prior.length != b.length ||
            List.generate(b.length, (i) => b[i] != prior[i]).any((v) => v))) {
      throw const FormatException();
    }
    sections[b[6]] = b;
  }

  bool get complete => last != null && sections.length == last! + 1;
}

class _Psi {
  _Psi(this.onSection);
  final void Function(List<int>) onSection;
  final buffer = <int>[];
  int? counter;
  List<int>? lastPayload;
  bool? lastStart;
  bool get incomplete => buffer.isNotEmpty;

  void packet(List<int> bytes, bool start, int cc, bool discontinuity) {
    if (discontinuity) {
      if (incomplete) throw const FormatException();
      counter = null;
    }
    if (counter == cc) {
      if (lastStart != start ||
          lastPayload!.length != bytes.length ||
          List.generate(
            bytes.length,
            (i) => bytes[i] != lastPayload![i],
          ).any((v) => v)) {
        throw const FormatException();
      }
      return;
    }
    if (counter != null && cc != (counter! + 1) % 16) {
      throw const FormatException();
    }
    counter = cc;
    lastPayload = bytes;
    lastStart = start;
    if (start) {
      if (bytes.isEmpty || bytes[0] + 1 > bytes.length) {
        throw const FormatException();
      }
      final next = bytes[0] + 1;
      if (incomplete) {
        _feed(bytes.sublist(1, next), allowNew: false);
        if (incomplete) throw const FormatException();
      }
      _feed(bytes.sublist(next));
    } else if (incomplete) {
      _feed(bytes);
    }
  }

  void _feed(List<int> bytes, {bool allowNew = true}) {
    var at = 0;
    while (at < bytes.length) {
      if (buffer.isEmpty && bytes[at] == 255) {
        if (bytes.skip(at).any((b) => b != 255)) throw const FormatException();
        return;
      }
      final target = buffer.length < 3
          ? 3
          : 3 + (((buffer[1] & 15) << 8) | buffer[2]);
      if (target < 12 || target > 1024) {
        if (buffer.length >= 3) throw const FormatException();
      }
      final count = (target - buffer.length).clamp(0, bytes.length - at);
      buffer.addAll(bytes.sublist(at, at + count));
      at += count;
      if (buffer.length >= 3 &&
          buffer.length == 3 + (((buffer[1] & 15) << 8) | buffer[2])) {
        onSection(List.of(buffer));
        buffer.clear();
        if (!allowNew) {
          if (bytes.skip(at).any((b) => b != 255)) {
            throw const FormatException();
          }
          return;
        }
      }
    }
  }
}
