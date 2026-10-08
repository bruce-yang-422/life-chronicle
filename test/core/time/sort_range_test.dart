import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/time/calendar_date.dart';
import 'package:life_chronicle/core/time/sort_range.dart';
import 'package:life_chronicle/core/time/time_value.dart';

class FakeSortContext implements SortContext {
  FakeSortContext({this.events = const {}, this.birth});

  final Map<String, TimeValue> events;
  final CalendarTime? birth;

  @override
  TimeValue? timeOfEvent(String eventId) => events[eventId];

  @override
  CalendarTime? subjectBirth() => birth;
}

CalendarDate d(String iso) => CalendarDate.parse(iso);

SortResolution resolve(
  TimeValue value, {
  FakeSortContext? context,
  String? selfId,
  SortResolved? previous,
}) => SortRangeResolver.resolve(
  value,
  context ?? FakeSortContext(),
  selfId: selfId,
  previous: previous,
);

SortResolved exact(String start, String end) =>
    SortResolved(SortRange(d(start), d(end)), TimeCertainty.exact);

SortResolved approx(String start, String end) =>
    SortResolved(SortRange(d(start), d(end)), TimeCertainty.approximate);

void main() {
  group('企劃書 5.1 步驟一：各類型換算', () {
    test('day：當日～當日', () {
      expect(resolve(DayTime(2003, 9, 15)), exact('2003-09-15', '2003-09-15'));
    });

    test('month：該月 1 日～最後一日（2003-09 → 09-01～09-30）', () {
      expect(resolve(MonthTime(2003, 9)), exact('2003-09-01', '2003-09-30'));
    });

    test('month：閏年與平年的 2 月', () {
      expect(resolve(MonthTime(2024, 2)), exact('2024-02-01', '2024-02-29'));
      expect(resolve(MonthTime(2023, 2)), exact('2023-02-01', '2023-02-28'));
      expect(resolve(MonthTime(1900, 2)), exact('1900-02-01', '1900-02-28'));
    });

    test('quarter：Q1～Q4', () {
      expect(resolve(QuarterTime(2003, 1)), exact('2003-01-01', '2003-03-31'));
      expect(resolve(QuarterTime(2003, 2)), exact('2003-04-01', '2003-06-30'));
      expect(resolve(QuarterTime(2003, 3)), exact('2003-07-01', '2003-09-30'));
      expect(resolve(QuarterTime(2003, 4)), exact('2003-10-01', '2003-12-31'));
    });

    test('half_year：上半年 1–6 月、下半年 7–12 月', () {
      expect(resolve(HalfYearTime(2003, 1)), exact('2003-01-01', '2003-06-30'));
      expect(resolve(HalfYearTime(2003, 2)), exact('2003-07-01', '2003-12-31'));
    });

    test('year：1 月 1 日～12 月 31 日', () {
      expect(resolve(YearTime(2003)), exact('2003-01-01', '2003-12-31'));
    });

    test('approx_year：同 year，另標記為推估', () {
      expect(resolve(ApproxYearTime(2003)), approx('2003-01-01', '2003-12-31'));
    });

    test('range：起點最早日期～終點最晚日期（跨年、不同精確度）', () {
      expect(
        resolve(RangeTime(YearTime(2002), YearTime(2004))),
        exact('2002-01-01', '2004-12-31'),
      );
      expect(
        resolve(RangeTime(MonthTime(2002, 9), YearTime(2004))),
        exact('2002-09-01', '2004-12-31'),
      );
      expect(
        resolve(RangeTime(DayTime(2003, 12, 31), MonthTime(2004, 2))),
        exact('2003-12-31', '2004-02-29'),
      );
    });

    test('unknown：不參與排序', () {
      expect(
        resolve(const UnknownTime()),
        const SortUnsortable(UnsortableReason.unknownTime),
      );
    });
  });

  group('relative：繼承參照事件的區間', () {
    final graduation = MonthTime(2007, 6);
    final ctx = FakeSortContext(events: {'grad': graduation});

    test('之後、之前、期間皆繼承參照事件區間', () {
      for (final relation in RelativeRelation.values) {
        expect(
          resolve(RelativeTime('grad', relation), context: ctx),
          exact('2007-06-01', '2007-06-30'),
          reason: relation.name,
        );
      }
    });

    test('可連續參照（A 參照 B，B 參照 C）', () {
      final chain = FakeSortContext(
        events: {
          'b': RelativeTime('c', RelativeRelation.after),
          'c': ApproxYearTime(1995),
        },
      );
      expect(
        resolve(
          RelativeTime('b', RelativeRelation.after),
          context: chain,
          selfId: 'a',
        ),
        approx('1995-01-01', '1995-12-31'),
      );
    });

    test('參照時間未定的事件時，自己也無法排序', () {
      final c = FakeSortContext(events: {'x': const UnknownTime()});
      expect(
        resolve(RelativeTime('x', RelativeRelation.after), context: c),
        const SortUnsortable(UnsortableReason.unknownTime),
      );
    });

    test('參照事件不存在：保留上一次換算的區間', () {
      final last = exact('2007-06-01', '2007-06-30');
      expect(
        resolve(RelativeTime('gone', RelativeRelation.after), previous: last),
        SortReferenceMissing('gone', last),
      );
      expect(
        resolve(RelativeTime('gone', RelativeRelation.after)),
        const SortReferenceMissing('gone', null),
      );
    });

    test('偵測循環參照：A → B → A', () {
      final c = FakeSortContext(
        events: {'b': RelativeTime('a', RelativeRelation.after)},
      );
      final result = resolve(
        RelativeTime('b', RelativeRelation.after),
        context: c,
        selfId: 'a',
      );
      expect(result, const SortCircularReference(['a', 'b', 'a']));
    });

    test('偵測自我參照', () {
      final result = resolve(
        RelativeTime('a', RelativeRelation.before),
        selfId: 'a',
      );
      expect(result, isA<SortCircularReference>());
    });

    test('偵測不含自身的循環：A → B → C → B', () {
      final c = FakeSortContext(
        events: {
          'b': RelativeTime('c', RelativeRelation.after),
          'c': RelativeTime('b', RelativeRelation.after),
        },
      );
      final result = resolve(
        RelativeTime('b', RelativeRelation.after),
        context: c,
        selfId: 'a',
      );
      expect(result, const SortCircularReference(['a', 'b', 'c', 'b']));
    });
  });

  group('age_estimate：依主角生日換算', () {
    test('生日精確到日：生日＋N 歲～生日＋(N+1) 歲前一日', () {
      final c = FakeSortContext(birth: DayTime(1983, 5, 20));
      expect(
        resolve(AgeEstimateTime(20), context: c),
        approx('2003-05-20', '2004-05-19'),
      );
    });

    test('生日只知年月：區間放寬', () {
      final c = FakeSortContext(birth: MonthTime(1983, 5));
      expect(
        resolve(AgeEstimateTime(20), context: c),
        approx('2003-05-01', '2004-05-30'),
      );
    });

    test('生日只知年份：區間放寬為兩個曆年', () {
      final c = FakeSortContext(birth: YearTime(1980));
      expect(
        resolve(AgeEstimateTime(20), context: c),
        approx('2000-01-01', '2001-12-30'),
      );
    });

    test('2 月 29 日生日在平年以 3 月 1 日起算', () {
      final c = FakeSortContext(birth: DayTime(2000, 2, 29));
      expect(
        resolve(AgeEstimateTime(1), context: c),
        approx('2001-03-01', '2002-02-28'),
      );
    });

    test('0 歲', () {
      final c = FakeSortContext(birth: DayTime(2020, 1, 15));
      expect(
        resolve(AgeEstimateTime(0), context: c),
        approx('2020-01-15', '2021-01-14'),
      );
    });

    test('沒有生日資料：視同時間未定', () {
      expect(
        resolve(AgeEstimateTime(20)),
        const SortUnsortable(UnsortableReason.missingBirthDate),
      );
    });
  });

  test('SortRange 起點不可晚於終點', () {
    expect(
      () => SortRange(d('2004-01-01'), d('2003-01-01')),
      throwsArgumentError,
    );
  });
}
