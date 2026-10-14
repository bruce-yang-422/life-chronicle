import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';

import 'harness.dart';

void main() {
  late Harness h;
  late EventContentRepository repository;
  setUp(() async {
    h = await Harness.create();
    repository = EventContentRepository(h.context());
  });
  tearDown(() => h.close());
  test('保存後草稿清理中斷再試，不重複建立事件與段落', () async {
    final draft = EventDraft(
      title: '重試',
      creationId: repository.reserveCreationId(),
      sections: [DraftSection(content: '原文')],
    );
    final first = await repository.save(draft);
    final second = await repository.save(draft);
    expect(second, first);
    expect(await h.db.select(h.db.events).get(), hasLength(1));
    expect(await h.db.select(h.db.eventSections).get(), hasLength(1));
  });
  test('最小事件與未命名記述，保留年份及半年精確度', () async {
    final id = await repository.save(
      EventDraft(
        title: '大學',
        time: YearTime(2003),
        sections: [DraftSection(content: '難忘的生活')],
      ),
    );
    final data = (await repository.load(id))!;
    expect(data.sections.single.title, isNull);
    expect(decodeTime(data.event.timePayload), YearTime(2003));
    final unknown = await repository.save(EventDraft(title: '未定'));
    expect(
      decodeTime((await repository.load(unknown))!.event.timePayload),
      const UnknownTime(),
    );
    final half = await repository.save(
      EventDraft(title: '半年', time: HalfYearTime(2003, 2)),
    );
    expect(
      decodeTime((await repository.load(half))!.event.timePayload),
      HalfYearTime(2003, 2),
    );
  });
  test('段落改名排序刪除保留建立時間與層級', () async {
    final id = await repository.save(
      EventDraft(
        title: '故事',
        sections: [
          DraftSection(content: '第一段'),
          DraftSection(title: '想對你說的話', content: '第二段'),
          DraftSection(title: '空白'),
        ],
      ),
    );
    final before = (await repository.load(id))!;
    final draft = before.toDraft();
    final moved = draft.sections.removeAt(1);
    draft.sections.insert(0, moved);
    draft.sections[0].title = '新的標題';
    draft.sections.removeLast();
    h.now = DateTime.utc(2026, 10, 14);
    await repository.save(draft);
    final after = (await repository.load(id))!;
    expect(after.sections.map((s) => s.contentMd), ['第二段', '第一段']);
    expect(after.sections.first.title, '新的標題');
    expect(after.sections.first.createdAt, before.sections[1].createdAt);
    expect(after.sections.first.layer, 'original');
  });
  test('地點正規化、人物標籤與三個双向關聯及移除', () async {
    final related = <String>[];
    for (var i = 0; i < 3; i++) {
      related.add(await repository.save(EventDraft(title: '朋友 $i')));
    }
    final id = await repository.save(
      EventDraft(
        title: '相聚',
        place: '臺北市',
        people: ['媽媽'],
        tags: ['家庭'],
        relatedIds: related,
      ),
    );
    final other = await repository.save(EventDraft(title: '旅行', place: '台北市'));
    final data = (await repository.load(id))!;
    expect(data.event.placeId, (await repository.load(other))!.event.placeId);
    expect(data.people.single.displayName, '媽媽');
    expect(data.tags.single.label, '家庭');
    expect(data.related.map((e) => e.id), containsAll(related));
    for (final id2 in related) {
      expect((await repository.load(id2))!.related.single.id, id);
    }
    final draft = data.toDraft()
      ..relatedIds = []
      ..people = []
      ..tags = [];
    await repository.save(draft);
    final cleared = (await repository.load(id))!;
    expect(cleared.related, isEmpty);
    expect(cleared.people, isEmpty);
    expect(cleared.tags, isEmpty);
  });
  test('追加回顧保留舊內容、作者及發生與追記時間', () async {
    final id = await repository.save(
      EventDraft(title: '大學', time: YearTime(2003)),
    );
    final first = await repository.appendReflection(id, '第一則回顧');
    h.now = DateTime.utc(2027, 1, 1);
    await repository.appendReflection(id, '第二則回顧');
    final data = (await repository.load(id))!;
    expect(data.reflections.map((r) => r.contentMd), ['第一則回顧', '第二則回顧']);
    expect(data.reflections.first.id, first);
    expect(data.reflections.first.authorId, h.profile.selfAuthorId);
    expect(data.reflections.first.recordedAt.year, 2026);
    expect(data.reflections.last.recordedAt.year, 2027);
    expect(decodeTime(data.event.timePayload), YearTime(2003));
  });
  test('無效關聯回復整筆交易，不留下半筆事件或段落', () async {
    await expectLater(
      repository.save(
        EventDraft(
          title: '失敗',
          place: '臺北市',
          sections: [DraftSection(content: '不應保存')],
          relatedIds: ['missing'],
        ),
      ),
      throwsA(isA<EventStateException>()),
    );
    expect(await h.db.select(h.db.events).get(), isEmpty);
    expect(await h.db.select(h.db.eventSections).get(), isEmpty);
    expect(await h.db.select(h.db.places).get(), isEmpty);
  });
  test('典藏禁止改原始內容，家屬追加不改事件修改時間', () async {
    final id = await repository.save(
      EventDraft(
        title: '原事件',
        sections: [DraftSection(content: '原文')],
      ),
    );
    final before = (await repository.load(id))!;
    await h.activateArchive();
    h.now = DateTime.utc(2045, 1, 1);
    final family = EventContentRepository(
      h.context(actingAuthorId: h.familyAuthorId),
    );
    await expectLater(
      family.save(before.toDraft()..title = '修改'),
      throwsA(isA<Exception>()),
    );
    await family.appendReflection(id, '後續追憶');
    final appended = before.toDraft()
      ..sections.add(DraftSection(content: '新增追憶段落'));
    await family.save(appended);
    final after = (await repository.load(id))!;
    expect(after.event.updatedAt, before.event.updatedAt);
    expect(after.event.layer, 'original');
    expect(after.reflections.single.layer, 'remembrance');
    expect(after.sections.first.contentMd, '原文');
    expect(after.sections.last.layer, 'remembrance');
    await expectLater(
      family.save(after.toDraft()..sections.first.content = '竄改原文'),
      throwsA(isA<Exception>()),
    );
    expect((await repository.load(id))!.sections.first.contentMd, '原文');
  });
  test('拒絕拿另一事件的段落 ID 竄改', () async {
    final a = await repository.save(
      EventDraft(
        title: 'A',
        sections: [DraftSection(content: '原文')],
      ),
    );
    final b = await repository.save(EventDraft(title: 'B'));
    final section = (await repository.load(a))!.sections.single;
    await expectLater(
      repository.save(
        EventDraft(
          eventId: b,
          title: 'B',
          sections: [DraftSection(id: section.id, content: '竄改')],
        ),
      ),
      throwsA(isA<EventStateException>()),
    );
    expect((await repository.load(a))!.sections.single.contentMd, '原文');
  });
}
