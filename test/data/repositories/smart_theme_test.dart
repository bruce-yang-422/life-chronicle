import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/stories/theme_rule.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/search_repository.dart';
import 'package:life_chronicle/data/repositories/story_repository.dart';

import 'harness.dart';

void main() {
  late Harness h;
  setUp(() async => h = await Harness.create());
  tearDown(() => h.close());
  Future<String> event(
    String title,
    List<String> tags, {
    int year = 2003,
    String privacy = 'normal',
  }) => EventContentRepository(h.context()).save(
    EventDraft(
      title: title,
      time: YearTime(year),
      tags: tags,
      privacy: privacy,
    ),
  );
  Future<Map<String, String>> tags() async => {
    for (final t in await h.db.select(h.db.tags).get()) t.label: t.id,
  };
  test('智慧主題依標籤動態更新、排除私密與刪除事件並共用時間排序', () async {
    final a = await event('家庭旅遊', ['family', 'travel'], year: 2004);
    final b = await event('旅遊', ['travel'], year: 2003);
    await event('出差', ['travel', 'work']);
    await event('私密', ['family', 'travel'], privacy: 'private');
    final ids = await tags();
    final repo = StoryRepository(h.context());
    final id = await repo.save(
      title: '旅遊主題',
      rule: ThemeRule(
        mode: TagMatchMode.any,
        include: [ids['travel']!],
        exclude: [ids['work']!],
      ),
    );
    expect((await repo.load(id))!.entries.map((e) => e.eventId), [a, b]);
    expect(await h.db.select(h.db.storyEvents).get(), isEmpty);
    final update = repo
        .watchContent(id)
        .firstWhere((c) => c!.entries.length == 3);
    final c = await event('新旅遊', ['travel'], year: 2005);
    expect((await update)!.entries.first.eventId, c);
    await h.events().softDelete(b);
    expect((await repo.load(id))!.entries.map((e) => e.eventId), [c, a]);
    final draft = (await EventContentRepository(h.context()).load(a))!.toDraft()
      ..tags = ['work'];
    await EventContentRepository(h.context()).save(draft);
    expect((await repo.load(id))!.entries.single.eventId, c);
    await h.events().restore(b);
    expect((await repo.load(id))!.entries.map((e) => e.eventId), [c, b]);
  });
  test('舊版篇章可明確轉換、搜尋使用主題規則並保留事件與層級', () async {
    final a = await event('旅行事件', ['travel']);
    final b = await event('工作事件', ['work']);
    final ids = await tags();
    final repo = StoryRepository(h.context());
    final id = await repo.save(title: '舊版', eventIds: [b]);
    final before = await h.db.select(h.db.events).get();
    await repo.save(
      id: id,
      title: '旅行主題',
      rule: ThemeRule(mode: TagMatchMode.all, include: [ids['travel']!]),
    );
    expect(await h.db.select(h.db.storyEvents).get(), isEmpty);
    expect((await repo.load(id))!.entries.single.eventId, a);
    expect(
      (await SearchRepository(h.context()).watch('旅行主題').first).single.id,
      a,
    );
    expect(await h.db.select(h.db.events).get(), before);
    expect((await repo.load(id))!.summary.story.layer, 'original');
  });
  test('無效標籤拒絕寫入，原始主題於典藏期間不可修改', () async {
    await event('旅行', ['travel']);
    final ids = await tags();
    final repo = StoryRepository(h.context());
    final id = await repo.save(
      title: '主題',
      rule: ThemeRule(mode: TagMatchMode.all, include: ids.values),
    );
    await expectLater(
      repo.save(
        id: id,
        title: '錯誤',
        rule: ThemeRule(mode: TagMatchMode.all, include: ['missing']),
      ),
      throwsArgumentError,
    );
    expect((await repo.load(id))!.summary.story.title, '主題');
    await h.activateArchive();
    await expectLater(
      repo.save(
        id: id,
        title: '不可改',
        rule: ThemeRule(mode: TagMatchMode.all, include: ids.values),
      ),
      throwsA(isA<Exception>()),
    );
    expect((await repo.load(id))!.entries, hasLength(1));
  });
}
