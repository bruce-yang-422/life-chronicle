import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/time/calendar_date.dart';
import 'package:life_chronicle/core/time/time_value.dart';

/// 每種時間類型的代表樣本。
final _samples = <TimeValue>[
  DayTime(2003, 9, 15),
  MonthTime(2003, 9),
  QuarterTime(2003, 3),
  HalfYearTime(2003, 1),
  YearTime(2003),
  ApproxYearTime(2003),
  RangeTime(YearTime(2002), YearTime(2004)),
  RangeTime(MonthTime(2002, 9), YearTime(2004)),
  RelativeTime('01J9Z3K8QXR4T6V8W0Y2A4C6E8', RelativeRelation.after),
  AgeEstimateTime(20),
  const UnknownTime(),
];

void main() {
  group('CalendarDate', () {
    test('驗證月份與日期，含閏年 2 月', () {
      expect(CalendarDate(2024, 2, 29).day, 29);
      expect(() => CalendarDate(2023, 2, 29), throwsArgumentError);
      expect(() => CalendarDate(2003, 13, 1), throwsArgumentError);
      expect(() => CalendarDate(2003, 4, 31), throwsArgumentError);
      expect(() => CalendarDate(0, 1, 1), throwsArgumentError);
      expect(CalendarDate.isLeapYear(2000), isTrue);
      expect(CalendarDate.isLeapYear(1900), isFalse);
    });

    test('ISO 字串來回轉換，且字串順序等於日期順序', () {
      final d = CalendarDate(987, 3, 4);
      expect(d.toIso(), '0987-03-04');
      expect(CalendarDate.parse('0987-03-04'), d);
      expect(() => CalendarDate.parse('2003-9-15'), throwsFormatException);
      final a = CalendarDate(2003, 9, 15), b = CalendarDate(2003, 10, 1);
      expect(a.compareTo(b) < 0, a.toIso().compareTo(b.toIso()) < 0);
    });

    test('加減天數與年數', () {
      expect(CalendarDate(2003, 12, 31).addDays(1), CalendarDate(2004, 1, 1));
      expect(CalendarDate(2004, 3, 1).addDays(-1), CalendarDate(2004, 2, 29));
      expect(CalendarDate(2000, 2, 29).addYears(1), CalendarDate(2001, 3, 1));
      expect(CalendarDate(2000, 2, 29).addYears(4), CalendarDate(2004, 2, 29));
    });
  });

  group('建立與驗證', () {
    test('月份須為 1–12、季度 1–4、半年 1–2', () {
      expect(() => MonthTime(2003, 0), throwsArgumentError);
      expect(() => MonthTime(2003, 13), throwsArgumentError);
      expect(() => QuarterTime(2003, 0), throwsArgumentError);
      expect(() => QuarterTime(2003, 5), throwsArgumentError);
      expect(() => HalfYearTime(2003, 3), throwsArgumentError);
      expect(() => DayTime(2003, 2, 30), throwsArgumentError);
    });

    test('年份須在有效範圍', () {
      expect(() => YearTime(0), throwsArgumentError);
      expect(() => ApproxYearTime(10000), throwsArgumentError);
    });

    test('年齡須為 0–150', () {
      expect(() => AgeEstimateTime(-1), throwsArgumentError);
      expect(() => AgeEstimateTime(151), throwsArgumentError);
      expect(AgeEstimateTime(0).age, 0);
    });

    test('時間範圍起點不可晚於終點，也不可相同', () {
      expect(
        () => RangeTime(YearTime(2004), YearTime(2002)),
        throwsArgumentError,
      );
      expect(
        () => RangeTime(YearTime(2003), YearTime(2003)),
        throwsArgumentError,
      );
      expect(
        () => RangeTime(MonthTime(2003, 9), DayTime(2003, 1, 1)),
        throwsArgumentError,
      );
      // 起訖精確度不同但順序正確
      expect(RangeTime(MonthTime(2002, 9), YearTime(2004)).type, 'range');
    });

    test('相對事件必須指定參照事件', () {
      expect(
        () => RelativeTime('', RelativeRelation.after),
        throwsArgumentError,
      );
    });

    test('季度與半年的曆法期間', () {
      final q3 = QuarterTime(2003, 3);
      expect(q3.startDate, CalendarDate(2003, 7, 1));
      expect(q3.endDate, CalendarDate(2003, 9, 30));
      final h1 = HalfYearTime(2003, 1);
      expect(h1.startDate, CalendarDate(2003, 1, 1));
      expect(h1.endDate, CalendarDate(2003, 6, 30));
      expect(MonthTime(2024, 2).endDate, CalendarDate(2024, 2, 29));
    });
  });

  group('JSON（time_payload）', () {
    test('每種類型皆可來回轉換且完全相等', () {
      for (final value in _samples) {
        final restored = TimeValue.fromJson(value.toJson());
        expect(restored, value, reason: value.type);
        expect(restored.hashCode, value.hashCode, reason: value.type);
      }
    });

    test('type 代號與企劃書一致', () {
      expect(_samples.map((v) => v.type).toSet(), {
        'day',
        'month',
        'quarter',
        'half_year',
        'year',
        'approx_year',
        'range',
        'relative',
        'age_estimate',
        'unknown',
      });
    });

    test('格式錯誤時拋出 FormatException', () {
      expect(() => TimeValue.fromJson({'type': 'week'}), throwsFormatException);
      expect(
        () => TimeValue.fromJson({'type': 'year', 'year': '2003'}),
        throwsFormatException,
      );
      expect(
        () => TimeValue.fromJson({
          'type': 'range',
          'start': {'type': 'unknown'},
          'end': {'type': 'year', 'year': 2004},
        }),
        throwsFormatException,
      );
      expect(
        () => TimeValue.fromJson({
          'type': 'relative',
          'event_id': 'x',
          'relation': 'around',
        }),
        throwsFormatException,
      );
    });
  });
}
