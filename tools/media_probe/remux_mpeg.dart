import 'dart:io';

import '../../test/support/mpeg_samples.dart';
import '../../test/support/media_samples.dart';

/// 將 Android 編碼器產生的 AAC／AVC 封裝成測試用 MPEG 系統串流。
/// 不呼叫 APP repository；產物只寫入指定的獨立驗收目錄。
Future<void> main(List<String> args) async {
  final root = args.single;
  for (final video in [false, true]) {
    final bytes = await File('$root/${video ? 'video.h264' : 'audio.aac'}')
        .readAsBytes();
    if (bytes.length > 60000) throw StateError('Sample too large');
    final id = video ? 0xe0 : 0xc0;
    final type = video ? 0x1b : 0x0f;
    final frames = <List<int>>[];
    if (!video) {
      for (var at = 0; at < bytes.length;) {
        final size =
            ((bytes[at + 3] & 3) << 11) |
            (bytes[at + 4] << 3) |
            (bytes[at + 5] >> 5);
        if (size < 7 || at + size > bytes.length) throw const FormatException();
        frames.add(bytes.sublist(at, at + size));
        at += size;
      }
    } else {
      final starts = <int>[];
      for (var at = 0; at + 4 < bytes.length; at++) {
        if (bytes[at] == 0 &&
            bytes[at + 1] == 0 &&
            bytes[at + 2] == 0 &&
            bytes[at + 3] == 1) {
          starts.add(at);
        }
      }
      final config = <int>[];
      for (var i = 0; i < starts.length; i++) {
        final at = starts[i],
            end = i + 1 < starts.length ? starts[i + 1] : bytes.length;
        final nal = bytes[at + 4] & 31;
        if (nal == 7 || nal == 8) {
          config.addAll(bytes.sublist(at, end));
        } else {
          frames.add([
            0,
            0,
            0,
            1,
            9,
            0xf0,
            if (frames.isEmpty) ...config,
            ...bytes.sublist(at, end),
          ]);
        }
      }
    }
    // 每個實際壓縮影格各自具備 PES 邊界與 PTS，供獨立 extractor 取樣。
    final pesPackets = <List<int>>[];
    for (var i = 0; i < frames.length; i++) {
      final pts = i * (video ? 9000 : 5760);
      pesPackets.add([
        0,
        0,
        1,
        id,
        ...number(frames[i].length + 8, 2),
        0x80,
        0x80,
        5,
        0x21 | (((pts >> 30) & 7) << 1),
        (pts >> 22) & 255,
        1 | (((pts >> 15) & 127) << 1),
        (pts >> 7) & 255,
        1 | ((pts & 127) << 1),
        ...frames[i],
      ]);
    }
    final packets = <List<int>>[
      ...sectionPackets(0, programTable({1: 0x100})),
      ...sectionPackets(0x100, pmt([track(type, 0x101)])),
    ];
    var cc = 0;
    for (final packet in pesPackets) {
      var at = 0;
      while (at < packet.length) {
        final end = (at + 184).clamp(0, packet.length);
        packets.add(
          tsPacket(0x101, packet.sublist(at, end), start: at == 0, cc: cc),
        );
        cc = (cc + 1) % 16;
        at = end;
      }
    }
    while (packets.length < 8) {
      packets.add(tsPacket(8191, List.filled(184, 255)));
    }
    final name = video ? 'video' : 'audio';
    await File('$root/$name.ts').writeAsBytes(ts(packets));
    await File('$root/$name.ps').writeAsBytes([
      ...psPack,
      ...psm([(type, id)]),
      for (final packet in pesPackets) ...packet,
      0,
      0,
      1,
      0xb9,
    ]);
  }
}
