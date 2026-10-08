import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/policy/layer_policy.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/core/time/timeline_sort.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/db/tables.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';

import 'harness.dart';

Matcher deniedWith(PermissionDeniedReason reason) => throwsA(
  isA<PermissionDeniedException>().having((e) => e.reason, 'reason', reason),
);

void main() {
  late Harness h;

  setUp(() async => h = await Harness.create());
  tearDown(() => h.close());

  Future<String> create(String title, TimeValue time, {String? as}) =>
      h.events(as: as).create(EventInput(title: title, time: time));

  group('新增：層級由資料存取層決定', () {
    test('一般模式新增為 original，不帶典藏期間', () async {
      final id = await create('進入大學', YearTime(2003));
      final row = (await h.events().find(id))!;
      expect(row.layer, Layer.original);
      expect(row.archiveSessionId, isNull);
      expect(row.authorId, h.profile.selfAuthorId);
    });

    test('生命典藏期間新增為 remembrance，指向典藏期間', () async {
      await h.activateArchive();
      final id = await create(
        '父親 1990 年的照片',
        YearTime(1990),
        as: h.familyAuthorId,
      );
      final row = (await h.events().find(id))!;
      expect(row.layer, Layer.remembrance);
      expect(row.archiveSessionId, isNotNull);
    });

    test('生命典藏期間以本人身分新增：拒絕', () async {
      await h.activateArchive();
      expect(
        () => create('x', YearTime(2045)),
        deniedWith(PermissionDeniedReason.subjectCannotAuthorRemembrance),
      );
    });

    test('層級判定不參考事件時間：2045 年加入 1990 年的事件仍為 remembrance', () async {
      await h.activateArchive();
      h.now = DateTime.utc(2045, 3, 2);
      final id = await create(
        '1990 海邊',
        DayTime(1990, 7, 1),
        as: h.familyAuthorId,
      );
      final row = (await h.events().find(id))!;
      expect(row.layer, Layer.remembrance);
      expect(row.sortStart, '1990-07-01');
      expect(row.createdAt, DateTime.utc(2045, 3, 2));
    });
  });

  group('修改權限（企劃書 9.3）', () {
    test('一般模式可修改 original', () async {
      final id = await create('進入大學', YearTime(2003));
      await h.events().update(id, const EventChanges(title: Value('進入台大')));
      expect((await h.events().find(id))!.title, '進入台大');
    });

    test('生命典藏期間不可修改或刪除 original', () async {
      final id = await create('進入大學', YearTime(2003));
      await h.activateArchive();
      final repo = h.events(as: h.familyAuthorId);
      expect(
        () => repo.update(id, const EventChanges(title: Value('改'))),
        deniedWith(PermissionDeniedReason.originalIsReadOnly),
      );
      expect(
        () => repo.softDelete(id),
        deniedWith(PermissionDeniedReason.originalIsReadOnly),
      );
    });

    test('remembrance 在兩種模式都可修改，修改後仍為 remembrance', () async {
      await h.activateArchive();
      final id = await create('追憶', YearTime(1990), as: h.familyAuthorId);
      await h
          .events(as: h.familyAuthorId)
          .update(id, const EventChanges(title: Value('追憶二')));
      await h.deactivateArchive();
      await h
          .events(as: h.familyAuthorId)
          .update(id, const EventChanges(title: Value('追憶三')));
      final row = (await h.events().find(id))!;
      expect(row.title, '追憶三');
      expect(row.layer, Layer.remembrance);
    });

    test('解除生命典藏後 original 恢復可編輯，新增內容回到 original', () async {
      final id = await create('進入大學', YearTime(2003));
      await h.activateArchive();
      await h.deactivateArchive();
      await h.events().update(id, const EventChanges(title: Value('進入台大')));
      final newId = await create('解除後新增', YearTime(2050));
      expect((await h.events().find(newId))!.layer, Layer.original);
    });
  });

  group('時間與排序區間', () {
    test('儲存時寫入排序區間；時間未定為 null', () async {
      final a = await create('季度', QuarterTime(2003, 3));
      final b = await create('未定', const UnknownTime());
      final rowA = (await h.events().find(a))!;
      final rowB = (await h.events().find(b))!;
      expect([rowA.sortStart, rowA.sortEnd], ['2003-07-01', '2003-09-30']);
      expect([rowB.sortStart, rowB.sortEnd], [null, null]);
    });

    test('追記時保留發生時間與記錄時間（驗收 #2）', () async {
      h.now = DateTime.utc(2026, 5, 1);
      final id = await create('大學入學', DayTime(2003, 9, 15));
      final row = (await h.events().find(id))!;
      expect(decodeTime(row.timePayload), DayTime(2003, 9, 15));
      expect(row.createdAt, DateTime.utc(2026, 5, 1));
    });

    test('修改「大學畢業」日期後，「大學畢業後」的事件自動移動（驗收 #17）', () async {
      final grad = await create('大學畢業', MonthTime(2007, 6));
      final trip = await create(
        '畢業旅行',
        RelativeTime(grad, RelativeRelation.after),
      );
      final next = await create(
        '旅行後找工作',
        RelativeTime(trip, RelativeRelation.after),
      );
      expect((await h.events().find(trip))!.sortStart, '2007-06-01');

      await h.events().update(
        grad,
        EventChanges(time: Value(MonthTime(2008, 1))),
      );

      expect((await h.events().find(trip))!.sortStart, '2008-01-01');
      expect((await h.events().find(next))!.sortStart, '2008-01-01');
    });

    test('形成循環參照時拒絕儲存', () async {
      final a = await create('A', YearTime(2000));
      final b = await create('B', RelativeTime(a, RelativeRelation.after));
      expect(
        () => h.events().update(
          a,
          EventChanges(time: Value(RelativeTime(b, RelativeRelation.after))),
        ),
        throwsA(isA<CircularTimeReferenceException>()),
      );
      expect(
        decodeTime((await h.events().find(a))!.timePayload),
        YearTime(2000),
      );
    });
  });

  group('時間軸監聽', () {
    test('排除已刪除事件，可直接交給 TimelineSort 排序', () async {
      await create('2003 年', YearTime(2003));
      await create('2003-09-15', DayTime(2003, 9, 15));
      final deleted = await create('刪掉的', YearTime(2003));
      await h.events().softDelete(deleted);

      final items = await h.events().watchTimeline().first;
      final sorted = TimelineSort.sort(items, SortDirection.oldestFirst);
      expect(sorted.map((i) => i.data.title), ['2003 年', '2003-09-15']);
    });

    test('參照已刪除事件的相對事件仍沿用其時間排序', () async {
      final grad = await create('大學畢業', MonthTime(2007, 6));
      final trip = await create(
        '畢業旅行',
        RelativeTime(grad, RelativeRelation.after),
      );
      await h.events().softDelete(grad);
      final items = await h.events().watchTimeline().first;
      final item = items.singleWhere((i) => i.id == trip);
      expect(item.effective!.range.start.toIso(), '2007-06-01');
    });
  });

  group('軟刪除與最近刪除（驗收 #35 資料層）', () {
    Future<String> attachRemembranceReflection(String eventId) async {
      await h.activateArchive();
      await h.db
          .into(h.db.reflections)
          .insert(
            ReflectionsCompanion.insert(
              id: 'r1',
              eventId: eventId,
              recordedAt: h.now,
              contentMd: '女兒的追憶',
              layer: Layer.remembrance,
              authorId: h.familyAuthorId,
              createdAt: h.now,
              archiveSessionId: Value(
                (await h.db.select(h.db.archiveSessions).getSingle()).id,
              ),
            ),
          );
      await h.deactivateArchive();
      return 'r1';
    }

    test('刪除後進入最近刪除，可復原', () async {
      final id = await create('進入大學', YearTime(2003));
      await h.events().softDelete(id);
      expect((await h.events().listRecentlyDeleted()).map((e) => e.id), [id]);

      await h.events().restore(id);
      expect(await h.events().listRecentlyDeleted(), isEmpty);
      expect((await h.events().find(id))!.deletedAt, isNull);
    });

    test('有後續追憶附掛：刪除後追憶仍在，復原後完整恢復', () async {
      final id = await create('1990 海邊', YearTime(1990));
      await attachRemembranceReflection(id);
      await h.events().softDelete(id);
      expect(await h.db.select(h.db.reflections).get(), hasLength(1));
      await h.events().restore(id);
      expect((await h.events().find(id))!.deletedAt, isNull);
    });

    test('永久刪除：有追憶附掛時保留標題，追憶仍可查看', () async {
      final id = await create('1990 海邊', YearTime(1990));
      await h.db
          .into(h.db.eventSections)
          .insert(
            EventSectionsCompanion.insert(
              id: 's1',
              eventId: id,
              position: 0,
              contentMd: '原始記述',
              layer: Layer.original,
              authorId: h.profile.selfAuthorId,
              createdAt: h.now,
            ),
          );
      await attachRemembranceReflection(id);
      await h.events().softDelete(id);

      final keptTitle = await h.events().purge(id);

      expect(keptTitle, isTrue);
      final row = (await h.events().find(id))!;
      expect(row.title, '1990 海邊');
      expect(row.purgedAt, isNotNull);
      expect(await h.db.select(h.db.eventSections).get(), isEmpty);
      expect(await h.db.select(h.db.reflections).get(), hasLength(1));
      expect(await h.events().listRecentlyDeleted(), isEmpty);
      expect(() => h.events().restore(id), throwsA(isA<EventStateException>()));
    });

    test('永久刪除：沒有追憶附掛時完整移除', () async {
      final id = await create('刪掉', YearTime(2003));
      await h.events().softDelete(id);
      expect(await h.events().purge(id), isFalse);
      expect(await h.events().find(id), isNull);
    });

    test('只能永久刪除已移入最近刪除的事件', () async {
      final id = await create('進入大學', YearTime(2003));
      expect(() => h.events().purge(id), throwsA(isA<EventStateException>()));
    });

    test('每次操作都記錄修訂來源', () async {
      final id = await create('進入大學', YearTime(2003));
      await h.events().softDelete(id);
      await h.events().restore(id);
      final ops = (await h.db.select(h.db.changeHistory).get())
          .where((c) => c.entityId == id)
          .map((c) => c.operation);
      expect(ops, ['create', 'delete', 'restore']);
    });
  });
}
