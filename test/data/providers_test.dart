import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';

void main() {
  test('時間軸 provider 在新增事件後自動更新', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final updates = <int>[];
    final done = Completer<void>();
    container.listen(timelineItemsProvider, (_, next) {
      final items = next.value;
      if (items == null) return;
      updates.add(items.length);
      if (items.length == 1 && !done.isCompleted) done.complete();
    }, fireImmediately: true);

    final repository = await container.read(eventRepositoryProvider.future);
    await repository.create(EventInput(title: '進入大學', time: YearTime(2003)));
    await done.future.timeout(const Duration(seconds: 5));

    expect(updates.last, 1);
  });

  test('首次開啟自動建立主角與本人作者，重複呼叫不重複建立', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });
    final first = await container.read(profileProvider.future);
    container.invalidate(profileProvider);
    final second = await container.read(profileProvider.future);
    expect(second.subjectId, first.subjectId);
    expect(await db.select(db.subjects).get(), hasLength(1));
  });
}
