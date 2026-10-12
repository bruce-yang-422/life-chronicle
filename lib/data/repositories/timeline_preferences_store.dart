import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/time/timeline_sort.dart';

class TimelinePreferences {
  const TimelinePreferences({
    this.direction = SortDirection.newestFirst,
    this.cards = false,
  });
  final SortDirection direction;
  final bool cards;
}

abstract class TimelinePreferencesStore {
  Future<TimelinePreferences> load();
  Future<void> save(TimelinePreferences preferences);
}

/// 只有介面偏好；與生命紀錄分開，存於跨平台持久性目錄。
class FileTimelinePreferencesStore implements TimelinePreferencesStore {
  FileTimelinePreferencesStore(this.file);
  final File file;
  Future<void> _writes = Future.value();

  static Future<FileTimelinePreferencesStore> open() async {
    final directory = await getApplicationSupportDirectory();
    return FileTimelinePreferencesStore(
      File(p.join(directory.path, 'timeline_preferences.json')),
    );
  }

  @override
  Future<TimelinePreferences> load() async {
    if (!await file.exists()) return const TimelinePreferences();
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return TimelinePreferences(
      direction: json['direction'] == SortDirection.oldestFirst.name
          ? SortDirection.oldestFirst
          : SortDirection.newestFirst,
      cards: json['cards'] == true,
    );
  }

  @override
  Future<void> save(TimelinePreferences preferences) {
    final result = _writes.then((_) async {
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.partial');
      await temporary.writeAsString(
        jsonEncode({
          'direction': preferences.direction.name,
          'cards': preferences.cards,
        }),
        flush: true,
      );
      await temporary.rename(file.path);
    });
    _writes = result.catchError((Object error) {});
    return result;
  }
}

/// 測試或預覽使用，不存取裝置檔案。
class MemoryTimelinePreferencesStore implements TimelinePreferencesStore {
  TimelinePreferences _value = const TimelinePreferences();
  @override
  Future<TimelinePreferences> load() async => _value;
  @override
  Future<void> save(TimelinePreferences preferences) async =>
      _value = preferences;
}
