import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'package:life_chronicle/core/attachments/media_probe.dart';

/// 比對 Android MediaExtractor 與 APP 共用解析器，不開啟或寫入 APP 資料庫。
Future<void> main(List<String> args) async {
  final directory = Directory(args.single);
  final native = jsonDecode(
    await File('${directory.path}/samples.json').readAsString(),
  ) as Map<String, dynamic>;
  final reports = <Map<String, Object?>>[];
  final mpegFile = File('${directory.path}/mpeg_native.json');
  final mpegNative = await mpegFile.exists()
      ? jsonDecode(await mpegFile.readAsString()) as Map<String, dynamic>
      : <String, dynamic>{};
  for (final item in [
    ...native['samples'] as List,
    ...mpegNative['samples'] as List? ?? [],
  ]) {
    final entry = item as Map<String, dynamic>;
    final name = entry['name'] as String;
    if (name.contains('/') || name.contains('\\') || name.contains('..')) {
      throw FormatException(name);
    }
    final file = File('${directory.path}/$name');
    final handle = await file.open();
    try {
      final probe = MediaProbe(await handle.length(), (offset, count) async {
        await handle.setPosition(offset);
        return handle.read(count);
      });
      final type = await probe.inspect();
      final tracks = (entry['tracks'] as List).cast<String>();
      final expectedVideo = tracks.any((track) => track.startsWith('video/'));
      if (probe.containsVideo != expectedVideo) {
        throw StateError('$name: $type / $tracks');
      }
      reports.add({
        'name': name,
        'bytes': await file.length(),
        'sha256': (await sha256.bind(file.openRead()).first).toString(),
        'media_type': type,
        'contains_video': probe.containsVideo,
        'native_tracks': tracks,
        'matches_native': true,
      });
    } finally {
      await handle.close();
    }
  }
  final image = File('${directory.path}/still.jpg');
  final bytes = await image.readAsBytes();
  final jpeg = MediaProbe(
    bytes.length,
    (offset, count) async => bytes.sublist(offset, offset + count),
  );
  if (await jpeg.inspect() != 'image/jpeg' || jpeg.containsVideo) {
    throw StateError('JPEG');
  }
  final video = await File('${directory.path}/video.mp4').readAsBytes();
  final motion = File('${directory.path}/motion.jpg');
  await motion.writeAsBytes([...bytes, ...video]);
  final data = await motion.readAsBytes();
  final dynamicPhoto = MediaProbe(
    data.length,
    (offset, count) async => data.sublist(offset, offset + count),
  );
  if (await dynamicPhoto.inspect() != 'image/jpeg' ||
      dynamicPhoto.staticImageBytes != bytes.length) {
    throw StateError('Motion JPEG');
  }
  final result = {
    'samples': reports,
    'native_matches': reports.length,
    'jpeg_passed': true,
    'motion_static_bytes': dynamicPhoto.staticImageBytes,
    'native_unsupported': mpegNative['unsupported'] ?? [],
  };
  final systems = <Map<String, Object?>>[];
  for (final name in [
    'audio.ts',
    'video.ts',
    'audio.ps',
    'video.ps',
    'video.h264',
  ]) {
    final sample = File('${directory.path}/$name');
    if (!await sample.exists()) continue;
    final handle = await sample.open();
    try {
      final probe = MediaProbe(await handle.length(), (offset, count) async {
        await handle.setPosition(offset);
        return handle.read(count);
      });
      final mime = await probe.inspect();
      if (probe.containsVideo != name.startsWith('video')) {
        throw StateError('MPEG: $name');
      }
      systems.add({
        'name': name,
        'media_type': mime,
        'contains_video': probe.containsVideo,
        'sha256': (await sha256.bind(sample.openRead()).first).toString(),
      });
    } finally {
      await handle.close();
    }
  }
  result['mpeg_classification'] = systems;
  await File('${directory.path}/probe_report.json')
      .writeAsString(const JsonEncoder.withIndent('  ').convert(result));
  stdout.writeln(jsonEncode(result));
}
