import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/photo_compression.dart';
import 'package:life_chronicle/core/attachments/photo_preferences.dart';
import 'package:life_chronicle/data/repositories/photo_preferences_store.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('photo-settings-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  test('初始偏好保留原始檔、標準與 GPS，重開後保存全部選項', () async {
    final file = File('${root.path}/preferences.json');
    final store = FilePhotoPreferencesStore(file);
    final initial = await store.load();
    expect(initial.alwaysCompress, isFalse);
    expect(initial.preset, PhotoPreset.standard);
    expect(initial.keepGps, isTrue);
    await store.save(
      const PhotoPreferences(
        alwaysCompress: true,
        preset: PhotoPreset.compact,
        keepGps: false,
      ),
    );
    final restored = await FilePhotoPreferencesStore(file).load();
    expect(restored.alwaysCompress, isTrue);
    expect(restored.preset, PhotoPreset.compact);
    expect(restored.keepGps, isFalse);
  });
  test('連續設定依序保存，未完成暫存不覆蓋既有偏好，損毀不靜默重設', () async {
    final file = File('${root.path}/preferences.json');
    final store = FilePhotoPreferencesStore(file);
    await Future.wait([
      store.save(const PhotoPreferences(preset: PhotoPreset.high)),
      store.save(const PhotoPreferences(preset: PhotoPreset.compact)),
    ]);
    await File('${file.path}.partial').writeAsString('broken');
    expect((await store.load()).preset, PhotoPreset.compact);
    await file.writeAsString('{"version":999}');
    await expectLater(store.load(), throwsFormatException);
    expect(await file.readAsString(), '{"version":999}');
  });
}
