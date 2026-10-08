import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/time/sort_range.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/core/time/timeline_sort.dart';

class FakeSortContext implements SortContext {
  FakeSortContext(this.times);

  final Map<String, TimeValue> times;

  @override
  TimeValue? timeOfEvent(String eventId) => times[eventId];

  @override
  CalendarTime? subjectBirth() => null;
}

final _recorded = DateTime.utc(2026, 1, 1);

/// 依時間值建立項目；label 同時作為 ID 與預期結果中的名稱。
List<TimelineItem<String>> buildItems(
  Map<String, TimeValue> times, {
  Map<String, int> manualOrder = const {},
  Map<String, DateTime> recordedAt = const {},
}) {
  final context = FakeSortContext(times);
  return [
    for (final MapEntry(key: id, value: time) in times.entries)
      TimelineItem(
        id: id,
        time: time,
        resolution: SortRangeResolver.resolve(time, context, selfId: id),
        manualOrder: manualOrder[id] ?? 0,
        recordedAt: recordedAt[id] ?? _recorded,
        data: id,
      ),
  ];
}

List<String> ids(Iterable<TimelineItem<String>> items) =>
    items.map((i) => i.id).toList();

/// 企劃書 5.1 排序範例（2003 年）的九筆事件與一筆時間未定。
final exampleTimes = <String, TimeValue>{
  '2003 年': YearTime(2003),
  '約 2003 年': ApproxYearTime(2003),
  '2003 年上半年': HalfYearTime(2003, 1),
  '2003 年第 1 季': QuarterTime(2003, 1),
  '2003-02': MonthTime(2003, 2),
  '2003-02-14': DayTime(2003, 2, 14),
  '2003 年下半年': HalfYearTime(2003, 2),
  '2003 年第 3 季': QuarterTime(2003, 3),
  '2003-09-15': DayTime(2003, 9, 15),
  '時間未定': const UnknownTime(),
};

/// 企劃書 5.1「排序範例（2003 年）」表格順序（舊到新）。
const expectedOldestFirst = [
  '2003 年',
  '約 2003 年',
  '2003 年上半年',
  '2003 年第 1 季',
  '2003-02',
  '2003-02-14',
  '2003 年下半年',
  '2003 年第 3 季',
  '2003-09-15',
  '時間未定',
];

/// 企劃書 5.1「新到舊範例（2003 年）」表格順序。
const expectedNewestFirst = [
  '2003 年',
  '約 2003 年',
  '2003 年下半年',
  '2003 年第 3 季',
  '2003-09-15',
  '2003 年上半年',
  '2003 年第 1 季',
  '2003-02',
  '2003-02-14',
  '時間未定',
];

void main() {
  group('企劃書 5.1 範例表（驗收 #16、#29 排序部分）', () {
    final items = buildItems(exampleTimes);
    final random = Random(20261008);

    test('舊到新：任意打亂 100 次，結果皆與範例表一致', () {
      for (var i = 0; i < 100; i++) {
        final shuffled = [...items]..shuffle(random);
        expect(
          ids(TimelineSort.sort(shuffled, SortDirection.oldestFirst)),
          expectedOldestFirst,
        );
      }
    });

    test('新到舊：任意打亂 100 次，結果皆與範例表一致', () {
      for (var i = 0; i < 100; i++) {
        final shuffled = [...items]..shuffle(random);
        expect(
          ids(TimelineSort.sort(shuffled, SortDirection.newestFirst)),
          expectedNewestFirst,
        );
      }
    });

    test('新到舊不是舊到新的直接倒轉', () {
      final oldest = TimelineSort.sort(items, SortDirection.oldestFirst);
      final newest = TimelineSort.sort(items, SortDirection.newestFirst);
      expect(ids(newest), isNot(ids(oldest).reversed.toList()));
      // 模糊的「2003 年」在兩個方向都排在該年最前面
      expect(ids(oldest).first, '2003 年');
      expect(ids(newest).first, '2003 年');
    });
  });

  test('「2003 年下半年」排在「2003 年上半年」之後（驗收 #14）', () {
    final items = buildItems({
      '下半年': HalfYearTime(2003, 2),
      '上半年': HalfYearTime(2003, 1),
    });
    expect(ids(TimelineSort.sort(items, SortDirection.oldestFirst)), [
      '上半年',
      '下半年',
    ]);
  });

  group('規則 4、5：手動順序與穩定排序', () {
    test('同一天的事件依 manual_order 排列，新到舊時反向', () {
      final items = buildItems(
        {'早餐': DayTime(2003, 9, 15), '開學典禮': DayTime(2003, 9, 15)},
        manualOrder: {'早餐': 1, '開學典禮': 2},
      );
      expect(ids(TimelineSort.sort(items, SortDirection.oldestFirst)), [
        '早餐',
        '開學典禮',
      ]);
      expect(ids(TimelineSort.sort(items, SortDirection.newestFirst)), [
        '開學典禮',
        '早餐',
      ]);
    });

    test('完全相同時依建立時間，再依 ID', () {
      final items = buildItems(
        {'b': YearTime(2003), 'a': YearTime(2003), 'c': YearTime(2003)},
        recordedAt: {'c': DateTime.utc(2020)},
      );
      expect(ids(TimelineSort.sort(items, SortDirection.oldestFirst)), [
        'c',
        'a',
        'b',
      ]);
      expect(ids(TimelineSort.sort(items, SortDirection.newestFirst)), [
        'b',
        'a',
        'c',
      ]);
    });
  });

  group('相對事件緊鄰參照事件', () {
    final times = <String, TimeValue>{
      '入學': DayTime(2003, 9, 15),
      '大學畢業': MonthTime(2007, 6),
      '畢業後旅行': RelativeTime('大學畢業', RelativeRelation.after),
      '畢業前論文': RelativeTime('大學畢業', RelativeRelation.before),
      '2007-06-20': DayTime(2007, 6, 20),
      '2008 年': YearTime(2008),
    };

    test('舊到新：「之前」在上方、「之後」緊接在下方', () {
      final sorted = ids(
        TimelineSort.sort(buildItems(times), SortDirection.oldestFirst),
      );
      final i = sorted.indexOf('大學畢業');
      expect(sorted[i - 1], '畢業前論文');
      expect(sorted[i + 1], '畢業後旅行');
    });

    test('新到舊：「之後」顯示在參照事件上方', () {
      final sorted = ids(
        TimelineSort.sort(buildItems(times), SortDirection.newestFirst),
      );
      final i = sorted.indexOf('大學畢業');
      expect(sorted[i - 1], '畢業後旅行');
      expect(sorted[i + 1], '畢業前論文');
    });

    test('連續參照：A 在 B 之後，B 在 C 之後', () {
      final sorted = ids(
        TimelineSort.sort(
          buildItems({
            'C': YearTime(2000),
            'B': RelativeTime('C', RelativeRelation.after),
            'A': RelativeTime('B', RelativeRelation.after),
            'D': YearTime(2001),
          }),
          SortDirection.oldestFirst,
        ),
      );
      expect(sorted, ['C', 'B', 'A', 'D']);
    });

    test('參照事件不在清單中（如被篩選）時依繼承區間一般排序', () {
      final all = buildItems(times);
      final filtered = all.where((i) => i.id != '大學畢業');
      final sorted = ids(
        TimelineSort.sort(filtered, SortDirection.oldestFirst),
      );
      expect(sorted, contains('畢業後旅行'));
      expect(sorted.indexOf('畢業後旅行'), lessThan(sorted.indexOf('2008 年')));
    });

    test('「期間」視同參照事件區間，一般排序', () {
      final sorted = ids(
        TimelineSort.sort(
          buildItems({
            '留學': YearTime(2010),
            '留學期間打工': RelativeTime('留學', RelativeRelation.during),
          }),
          SortDirection.oldestFirst,
        ),
      );
      expect(sorted, hasLength(2));
    });

    test('循環參照的事件歸入時間未定，不會無限遞迴', () {
      final sorted = TimelineSort.group(
        buildItems({
          'A': RelativeTime('B', RelativeRelation.after),
          'B': RelativeTime('A', RelativeRelation.after),
          'C': YearTime(2003),
        }),
        SortDirection.oldestFirst,
      );
      expect(sorted.last.year, isNull);
      expect(ids(sorted.last.items)..sort(), ['A', 'B']);
    });
  });

  group('年份分組', () {
    final items = buildItems({
      '2002～2004': RangeTime(YearTime(2002), YearTime(2004)),
      '2002-05': MonthTime(2002, 5),
      '2003 年': YearTime(2003),
      '2004-12-01': DayTime(2004, 12, 1),
      '時間未定': const UnknownTime(),
    });

    test('跨年範圍歸入起始年份；時間未定區固定在最後', () {
      final groups = TimelineSort.group(items, SortDirection.oldestFirst);
      expect(groups.map((g) => g.year), [2002, 2003, 2004, null]);
      expect(ids(groups.first.items), ['2002～2004', '2002-05']);
    });

    test('新到舊：年份由新到舊，時間未定仍在最後', () {
      final groups = TimelineSort.group(items, SortDirection.newestFirst);
      expect(groups.map((g) => g.year), [2004, 2003, 2002, null]);
    });

    test('切換方向時事件不換組', () {
      Map<String, int?> membership(List<TimelineGroup<String>> groups) => {
        for (final g in groups)
          for (final item in g.items) item.id: g.year,
      };
      expect(
        membership(TimelineSort.group(items, SortDirection.newestFirst)),
        membership(TimelineSort.group(items, SortDirection.oldestFirst)),
      );
    });

    test('參照事件已刪除時沿用最後一次換算的區間分組', () {
      final missing = TimelineItem(
        id: 'orphan',
        time: RelativeTime('gone', RelativeRelation.after),
        resolution: SortReferenceMissing(
          'gone',
          SortResolved(
            SortRange(
              DayTime(2003, 1, 1).startDate,
              DayTime(2003, 1, 1).endDate,
            ),
            TimeCertainty.exact,
          ),
        ),
        recordedAt: _recorded,
        data: 'orphan',
      );
      final groups = TimelineSort.group([
        missing,
        ...items,
      ], SortDirection.oldestFirst);
      final group2003 = groups.firstWhere((g) => g.year == 2003);
      expect(ids(group2003.items), contains('orphan'));
    });
  });
}
