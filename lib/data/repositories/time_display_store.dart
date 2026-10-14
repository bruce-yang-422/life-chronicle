import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/time/timestamp_display.dart';

abstract class TimeDisplayStore {
  Future<String> load();
  Future<void> save(String zone);
}

class FileTimeDisplayStore implements TimeDisplayStore {
  FileTimeDisplayStore(this.file);
  final File file;
  static Future<FileTimeDisplayStore> open() async => FileTimeDisplayStore(
    File(
      p.join(
        (await getApplicationSupportDirectory()).path,
        'time_display.json',
      ),
    ),
  );
  @override
  Future<String> load() async {
    if (!await file.exists()) return 'system';
    final zone = (jsonDecode(await file.readAsString()) as Map)['zone'];
    return TimestampDisplay.zones.contains(zone) ? zone as String : 'system';
  }

  @override
  Future<void> save(String zone) async {
    if (!TimestampDisplay.zones.contains(zone)) throw ArgumentError.value(zone);
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.partial');
    await temporary.writeAsString(jsonEncode({'zone': zone}), flush: true);
    await temporary.rename(file.path);
  }
}

class MemoryTimeDisplayStore implements TimeDisplayStore {
  String zone = 'system';
  @override
  Future<String> load() async => zone;
  @override
  Future<void> save(String value) async => zone = value;
}
