import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/repositories/profile_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/story_repository.dart';

void main() {
  test('v1 升級 v2 保留舊版篇章、作者、層級及層級觸發器', () async {
    final directory = await Directory.systemTemp.createTemp('theme-migration-');
    final file = File('${directory.path}/old.sqlite');
    final old = AppDatabase(NativeDatabase(file));
    final profile = await ProfileRepository(old).ensureDefaultProfile();
    final ctx = RepositoryContext(
      old,
      subjectId: profile.subjectId,
      actingAuthorId: profile.selfAuthorId,
    );
    final id = await StoryRepository(ctx).save(title: '舊版篇章', eventIds: []);
    final before = (await old.select(old.stories).get()).single;
    await old.customStatement('ALTER TABLE stories DROP COLUMN rules_json');
    await old.customStatement('PRAGMA user_version = 1');
    await old.close();
    final upgraded = AppDatabase(NativeDatabase(file));
    try {
      final story = (await upgraded.select(upgraded.stories).get()).single;
      expect(story.id, id);
      expect(story.title, before.title);
      expect(story.layer, before.layer);
      expect(story.authorId, before.authorId);
      expect(story.createdAt, before.createdAt);
      expect(story.rulesJson, isNull);
      expect(
        (await upgraded.customSelect('PRAGMA user_version').getSingle())
            .data['user_version'],
        2,
      );
      await expectLater(
        upgraded.customStatement("UPDATE stories SET layer = 'remembrance'"),
        throwsA(isA<SqliteException>()),
      );
      expect(
        await upgraded.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    } finally {
      await upgraded.close();
      await directory.delete(recursive: true);
    }
  });
}
