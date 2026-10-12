import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/time/timeline_sort.dart';
import 'package:life_chronicle/data/repositories/timeline_preferences_store.dart';

void main() {
  test('首次開啟預設新到舊與精簡清單，重開沿用排序與密度', () async {
    final directory = await Directory.systemTemp.createTemp(
      'chronicle_preferences_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/preferences.json');
    final store = FileTimelinePreferencesStore(file);
    final initial = await store.load();
    expect(initial.direction, SortDirection.newestFirst);
    expect(initial.cards, isFalse);
    await store.save(
      const TimelinePreferences(
        direction: SortDirection.oldestFirst,
        cards: true,
      ),
    );
    final restored = await FileTimelinePreferencesStore(file).load();
    expect(restored.direction, SortDirection.oldestFirst);
    expect(restored.cards, isTrue);
    expect(await File('${file.path}.partial').exists(), isFalse);
  });

  test('快速連續切換以最後一次偏好為準，不留下不完整 JSON', () async {
    final directory = await Directory.systemTemp.createTemp(
      'chronicle_preferences_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final store = FileTimelinePreferencesStore(
      File('${directory.path}/preferences.json'),
    );
    await Future.wait([
      store.save(const TimelinePreferences(cards: true)),
      store.save(
        const TimelinePreferences(direction: SortDirection.oldestFirst),
      ),
      store.save(
        const TimelinePreferences(
          direction: SortDirection.newestFirst,
          cards: true,
        ),
      ),
    ]);
    final restored = await store.load();
    expect(restored.direction, SortDirection.newestFirst);
    expect(restored.cards, isTrue);
  });
}
