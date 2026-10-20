import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/policy/layer_policy.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/search_repository.dart';
import 'package:life_chronicle/data/repositories/story_repository.dart';

import 'harness.dart';

void main() {
  late Harness h;
  late StoryRepository stories;
  setUp(() async {
    h = await Harness.create();
    stories = StoryRepository(h.context());
  });
  tearDown(() => h.close());
  Future<String> event(String title, {String privacy = 'normal'}) => h
      .events()
      .create(EventInput(title: title, time: YearTime(2003), privacy: privacy));

  test('篇章共用事件、改名排序與刪除均不修改事件或原有層級作者', () async {
    final a = await event('甲');
    final b = await event('乙');
    final before = await h.db.select(h.db.events).get();
    final one = await stories.save(title: ' 大學四年 ', eventIds: [a, b]);
    final two = await stories.save(title: '我們', eventIds: [a]);
    final initial = (await stories.load(one))!.summary.story;
    await stories.save(id: one, title: '大學生活', eventIds: [b, a]);
    final updated = (await stories.load(one))!;
    expect(updated.entries.map((e) => e.eventId), [b, a]);
    expect(updated.summary.story.title, '大學生活');
    expect(updated.summary.story.layer, initial.layer);
    expect(updated.summary.story.createdAt, initial.createdAt);
    expect(updated.summary.story.authorId, initial.authorId);
    await stories.delete(one);
    expect(await stories.load(one), isNull);
    expect((await stories.load(two))!.entries.single.eventId, a);
    expect(await h.db.select(h.db.events).get(), before);
  });

  test('名稱、重複引用及遺失事件驗證失敗均完整回滾', () async {
    final a = await event('原事件');
    final id = await stories.save(title: '原名稱', eventIds: [a]);
    for (final ids in [
      [a, a],
      ['missing'],
    ]) {
      await expectLater(
        stories.save(id: id, title: '不可寫入', eventIds: ids),
        throwsA(isA<Object>()),
      );
      expect((await stories.load(id))!.summary.story.title, '原名稱');
      expect((await stories.load(id))!.entries.single.eventId, a);
    }
    await expectLater(
      stories.save(title: '  ', eventIds: []),
      throwsArgumentError,
    );
    await expectLater(
      stories.save(id: 'missing', title: '名稱', eventIds: []),
      throwsA(isA<EventStateException>()),
    );
    expect((await h.db.select(h.db.stories).get()).length, 1);
  });

  test('私密事件未授權不提供內容，也不能新加入；已存在引用可保留', () async {
    final a = await event('私密名稱不可洩露', privacy: 'private');
    final id = await stories.save(title: '既有篇章', eventIds: [a]);
    final locked = StoryRepository(
      RepositoryContext(
        h.db,
        subjectId: h.profile.subjectId,
        actingAuthorId: h.profile.selfAuthorId,
        canReadPrivate: false,
      ),
    );
    expect((await locked.load(id))!.entries.single.event, isNull);
    await expectLater(
      locked.save(title: '不可新增', eventIds: [a]),
      throwsA(isA<PermissionDeniedException>()),
    );
    await locked.save(id: id, title: '改名並保留引用', eventIds: [a]);
    expect((await stories.load(id))!.entries.single.event!.title, '私密名稱不可洩露');
  });

  test('典藏中原始篇章不可修改刪除，新篇章由家人建立追憶層', () async {
    final a = await event('原事件');
    final id = await stories.save(title: '原始篇章', eventIds: [a]);
    await h.activateArchive();
    expect((await stories.load(id))!.summary.canModify, isFalse);
    await expectLater(
      stories.save(id: id, title: '不可修改', eventIds: []),
      throwsA(isA<PermissionDeniedException>()),
    );
    await expectLater(
      stories.delete(id),
      throwsA(isA<PermissionDeniedException>()),
    );
    await expectLater(
      stories.save(title: '本人不可追憶', eventIds: []),
      throwsA(isA<PermissionDeniedException>()),
    );
    final family = StoryRepository(h.context(actingAuthorId: h.familyAuthorId));
    final memory = await family.save(title: '家人篇章', eventIds: [a]);
    final original = (await family.load(memory))!.summary.story;
    expect(original.layer, 'remembrance');
    expect(original.authorId, h.familyAuthorId);
    expect(original.archiveSessionId, isNotNull);
    await h.deactivateArchive();
    await family.save(id: memory, title: '繼續追憶', eventIds: [a]);
    expect((await family.load(memory))!.summary.story.layer, 'remembrance');
    await family.delete(memory);
  });

  test('最近刪除引用保留，不能新選；永久刪除同步移除引用', () async {
    final a = await event('將刪除');
    final id = await stories.save(title: '篇章', eventIds: [a]);
    await h.events().softDelete(a);
    expect(
      (await stories.load(id))!.entries.single.event!.deletedAt,
      isNotNull,
    );
    await stories.save(id: id, title: '保留刪除引用', eventIds: [a]);
    await expectLater(
      stories.save(title: '新篇章', eventIds: [a]),
      throwsA(isA<EventStateException>()),
    );
    await h.events().purge(a);
    expect((await stories.load(id))!.entries, isEmpty);
  });

  test('篇章事件與標題異動會更新閱讀串流及全文搜尋', () async {
    final a = await event('畢業');
    final id = await stories.save(title: '大學生活', eventIds: [a]);
    expect(
      (await SearchRepository(h.context()).watch('大學生活').first).single.id,
      a,
    );
    final change = stories
        .watchContent(id)
        .firstWhere((c) => c?.summary.story.title == '新的篇章');
    await stories.save(id: id, title: '新的篇章', eventIds: []);
    expect((await change)!.entries, isEmpty);
    expect(await SearchRepository(h.context()).watch('大學生活').first, isEmpty);
    expect((await stories.watch().first).single.eventCount, 0);
  });
}
