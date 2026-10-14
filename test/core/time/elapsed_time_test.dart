import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/time/calendar_date.dart';
import 'package:life_chronicle/core/time/elapsed_time.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/l10n/app_localizations_zh.dart';
import 'package:life_chronicle/l10n/app_localizations_en.dart';
import 'package:life_chronicle/l10n/l10n_elapsed_time.dart';

void main() {
  final today = CalendarDate(2026, 10, 14);
  final zh = AppLocalizationsZh();
  String label(TimeValue time) =>
      elapsedTimeLabel(ElapsedTime.calculate(time, today), zh);
  test('精確日期以完整日、月、年顯示；今天與未來不出現負數', () {
    expect(label(DayTime(2026, 10, 14)), '今天');
    expect(label(DayTime(2026, 10, 11)), '3 天前');
    expect(label(DayTime(2026, 9, 15)), '29 天前');
    expect(label(DayTime(2026, 9, 14)), '1 個月前');
    expect(label(DayTime(2025, 10, 15)), '11 個月前');
    expect(label(DayTime(2025, 10, 14)), '1 年前');
    expect(label(DayTime(2026, 10, 16)), '2 天後');
  });
  test('模糊時間明確標示約，不假造月日；區間顯示可能範圍', () {
    expect(label(YearTime(2025)), '約1 年前');
    expect(label(ApproxYearTime(2003)), '約23 年前');
    expect(label(MonthTime(2026, 9)), '約1 個月前');
    expect(label(QuarterTime(2026, 3)), '約14～105 天前');
    expect(label(HalfYearTime(2024, 2)), '約1～2 年前');
    expect(label(YearTime(2026)), '今年');
    expect(label(MonthTime(2026, 10)), '本月');
    expect(label(QuarterTime(2026, 4)), '期間包含今天');
    expect(
      label(RangeTime(DayTime(2026, 10, 10), DayTime(2026, 10, 12))),
      '約2～4 天前',
    );
    expect(
      label(RangeTime(DayTime(2026, 10, 16), DayTime(2026, 10, 18))),
      '約2～4 天後',
    );
    expect(label(const UnknownTime()), '距今時間未定');
    expect(label(AgeEstimateTime(20)), '距今時間未定');
  });
  test('閏日與月末使用曆法計算，不受一天長度或夏令時間影響', () {
    final month = ElapsedTime.calculate(
      DayTime(2026, 1, 31),
      CalendarDate(2026, 2, 28),
    );
    expect(month.unit, ElapsedUnit.months);
    expect(month.count, 1);
    final year = ElapsedTime.calculate(
      DayTime(2024, 2, 29),
      CalendarDate(2025, 2, 28),
    );
    expect(year.unit, ElapsedUnit.years);
    expect(year.count, 1);
    expect(
      elapsedTimeLabel(
        ElapsedTime.calculate(DayTime(2026, 10, 11), today),
        AppLocalizationsEn(),
      ),
      '3 days ago',
    );
    expect(
      elapsedTimeLabel(
        ElapsedTime.calculate(DayTime(2026, 9, 14), today),
        AppLocalizationsEn(),
      ),
      '1 month ago',
    );
    expect(
      elapsedTimeLabel(
        ElapsedTime.calculate(DayTime(2026, 10, 15), today),
        AppLocalizationsEn(),
      ),
      'In 1 day',
    );
  });
}
