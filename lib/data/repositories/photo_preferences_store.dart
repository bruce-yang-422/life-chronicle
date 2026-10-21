import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/attachments/photo_compression.dart';
import '../../core/attachments/photo_preferences.dart';

abstract interface class PhotoPreferencesStore {
  Future<PhotoPreferences> load();
  Future<void> save(PhotoPreferences preferences);
}

/// 照片偏好與生命紀錄分開；寫入失敗不取代已保存的設定。
class FilePhotoPreferencesStore implements PhotoPreferencesStore {
  FilePhotoPreferencesStore(this.file);
  final File file;
  Future<void> _writes = Future.value();
  static Future<FilePhotoPreferencesStore> open() async =>
      FilePhotoPreferencesStore(
        File(
          p.join(
            (await getApplicationSupportDirectory()).path,
            'photo_preferences.json',
          ),
        ),
      );
  @override
  Future<PhotoPreferences> load() async {
    if (!await file.exists()) return const PhotoPreferences();
    final value = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (value['version'] != 1 ||
        value['alwaysCompress'] is! bool ||
        value['keepGps'] is! bool ||
        !PhotoPreset.values.any((preset) => preset.name == value['preset'])) {
      throw const FormatException('照片保存設定格式錯誤');
    }
    return PhotoPreferences(
      alwaysCompress: value['alwaysCompress'] as bool,
      keepGps: value['keepGps'] as bool,
      preset: PhotoPreset.values.byName(value['preset'] as String),
    );
  }

  @override
  Future<void> save(PhotoPreferences preferences) {
    final operation = _writes.then((_) async {
      await file.parent.create(recursive: true);
      final temporary = File('${file.path}.partial');
      await temporary.writeAsString(
        jsonEncode({
          'version': 1,
          'alwaysCompress': preferences.alwaysCompress,
          'keepGps': preferences.keepGps,
          'preset': preferences.preset.name,
        }),
        flush: true,
      );
      await temporary.rename(file.path);
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }
}
