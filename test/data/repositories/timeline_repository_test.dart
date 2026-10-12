import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/core/time/timeline_sort.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/data/repositories/timeline_repository.dart';

import 'harness.dart';

void main() {
  late Harness h;
  late TimelineRepository timeline;
  setUp(() async {
    h = await Harness.create();
    timeline = TimelineRepository(h.context());
  });
  tearDown(() => h.close());

  test('年份索引完整計數，跨年依起點分組，已刪除不計入', () async {
    for (var i = 0; i < 20; i++) {
      await h.events().create(
        EventInput(title: 'event $i', time: YearTime(2003)),
      );
    }
    await h.events().create(
      EventInput(
        title: 'range',
        time: RangeTime(YearTime(2002), YearTime(2004)),
      ),
    );
    await h.events().create(
      const EventInput(title: 'unknown', time: UnknownTime()),
    );
    final deleted = await h.events().create(
      EventInput(title: 'deleted', time: YearTime(2026)),
    );
    await h.events().softDelete(deleted);
    final years = await timeline.watchYears().first;
    expect(
      {for (final year in years) year.year: year.count},
      {2002: 1, 2003: 20, null: 1},
    );
    expect((await timeline.watchYear(2003).first).items, hasLength(20));
    expect(
      (await timeline.watchYear(null).first).items.single.data.title,
      'unknown',
    );
  });

  test('年份分段查詢與既有全量查詢的雙向排序一致，保留年外參照鏈', () async {
    final root = await h.events().create(
      EventInput(
        title: 'root',
        time: RangeTime(YearTime(2002), YearTime(2004)),
      ),
    );
    final ref = await h.events().create(
      EventInput(
        title: 'relative',
        time: RelativeTime(root, RelativeRelation.after),
      ),
    );
    await h.events().create(
      EventInput(
        title: 'nested',
        time: RelativeTime(ref, RelativeRelation.after),
      ),
    );
    await h.events().create(
      EventInput(title: 'half', time: HalfYearTime(2003, 2)),
    );
    await h.events().create(
      EventInput(title: 'approx', time: ApproxYearTime(2003)),
    );
    final all = await h.events().watchTimeline().first;
    for (final direction in SortDirection.values) {
      for (final group in TimelineSort.group(all, direction)) {
        final page = await timeline.watchYear(group.year).first;
        expect(
          TimelineSort.sort(page.items, direction).map((item) => item.id),
          group.items.map((item) => item.id),
        );
      }
    }
    expect(
      (await timeline.watchYear(2002).first).referenceTitles[root],
      'root',
    );
  });

  test('年外相對參照被刪除時保留排序並移除可顯示的標題', () async {
    final root = await h.events().create(
      EventInput(title: 'root', time: YearTime(2003)),
    );
    await h.events().create(
      EventInput(
        title: 'relative',
        time: RelativeTime(root, RelativeRelation.after),
      ),
    );
    await h.events().softDelete(root);
    final data = await timeline.watchYear(2003).first;
    expect(data.items.single.groupYear, 2003);
    expect(data.referenceTitles, isNot(contains(root)));
  });

  test('索引監聽新增、改年、刪除與復原', () async {
    final snapshots = <Map<int?, int>>[];
    final subscription = timeline.watchYears().listen((years) {
      snapshots.add({for (final year in years) year.year: year.count});
    });
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    await settle();
    final id = await h.events().create(
      EventInput(title: 'live', time: YearTime(2003)),
    );
    await settle();
    expect(snapshots.last, {2003: 1});
    await h.events().update(id, EventChanges(time: Value(YearTime(1990))));
    await settle();
    expect(snapshots.last, {1990: 1});
    await h.events().softDelete(id);
    await settle();
    expect(snapshots.last, isEmpty);
    await h.events().restore(id);
    await settle();
    expect(snapshots.last, {1990: 1});
    await subscription.cancel();
  });

  test('類別與人物篩選、索引與年份查詢使用相同條件', () async {
    final id = await h.events().create(
      EventInput(title: 'career', time: YearTime(2003), category: '職涯'),
    );
    await h.events().create(
      EventInput(title: 'other', time: YearTime(1990), category: '生活'),
    );
    final person = await h.people.findOrCreate('小美');
    await h.relations().addPerson(id, person);
    final filter = TimelineFilter(category: '職涯', personId: person);
    expect((await timeline.watchYears(filter: filter).first).single.year, 2003);
    expect(
      (await timeline.watchYear(2003, filter: filter).first).items.single.id,
      id,
    );
    expect(
      await timeline
          .watchYears(filter: const TimelineFilter(category: "' OR 1=1 --"))
          .first,
      isEmpty,
    );
    expect(
      (await timeline.filterOptions()).categories.map((option) => option.label),
      containsAll(['職涯', '生活']),
    );
  });

  test('人生階段只看明確關聯，不以時間重疊自行歸入', () async {
    final linked = await h.events().create(
      EventInput(title: 'linked', time: YearTime(1990)),
    );
    await h.events().create(
      EventInput(title: 'overlaps', time: YearTime(2003)),
    );
    await h.db
        .into(h.db.lifePeriods)
        .insert(
          LifePeriodsCompanion.insert(
            id: 'period',
            subjectId: h.profile.subjectId,
            type: 'education',
            startTime: encodeTime(YearTime(2000)),
            endTime: Value(encodeTime(YearTime(2005))),
            organization: const Value('大學'),
            layer: 'original',
            authorId: h.profile.selfAuthorId,
            createdAt: h.now,
          ),
        );
    await h.relations().addLifePeriod(linked, 'period');
    await h.relations().addLifePeriod(linked, 'period');
    expect(await h.relations().lifePeriodsOf(linked), hasLength(1));
    const filter = TimelineFilter(lifePeriodId: 'period');
    expect((await timeline.watchYears(filter: filter).first).single.year, 1990);
    expect(
      (await timeline.watchYear(1990, filter: filter).first).items.single.id,
      linked,
    );
    await h.relations().removeLifePeriod(linked, 'period');
    expect(await timeline.watchYears(filter: filter).first, isEmpty);
  });

  test('人生階段關聯也遵守生命典藏權限及永久刪除規則', () async {
    final id = await h.events().create(
      EventInput(title: 'event', time: YearTime(2003)),
    );
    await h.db
        .into(h.db.lifePeriods)
        .insert(
          LifePeriodsCompanion.insert(
            id: 'period',
            subjectId: h.profile.subjectId,
            type: 'education',
            startTime: encodeTime(YearTime(2000)),
            layer: 'original',
            authorId: h.profile.selfAuthorId,
            createdAt: h.now,
          ),
        );
    await h.relations().addLifePeriod(id, 'period');
    await h.activateArchive();
    await expectLater(
      h.relations(as: h.familyAuthorId).removeLifePeriod(id, 'period'),
      throwsException,
    );
    await h.deactivateArchive();
    await h.relations().removeLifePeriod(id, 'period');
    await h.activateArchive();
    await expectLater(
      h.relations().addLifePeriod(id, 'period'),
      throwsException,
    );
    await h.relations(as: h.familyAuthorId).addLifePeriod(id, 'period');
    await h.deactivateArchive();
    await h.events().softDelete(id);
    expect(await h.events().purge(id), isTrue);
    expect(await h.relations().lifePeriodsOf(id), hasLength(1));
  });
}
