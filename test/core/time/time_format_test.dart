import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/time/time_format.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';
import 'package:life_chronicle/l10n/l10n_time_texts.dart';

final zh = L10nTimeTexts(lookupAppLocalizations(const Locale('zh')));
final en = L10nTimeTexts(lookupAppLocalizations(const Locale('en')));

/// 每種時間類型的代表樣本。
final samples = <TimeValue>[
  DayTime(2003, 9, 15),
  MonthTime(2003, 9),
  QuarterTime(2003, 3),
  HalfYearTime(2003, 1),
  HalfYearTime(2003, 2),
  YearTime(2003),
  ApproxYearTime(2003),
  RangeTime(YearTime(2002), YearTime(2004)),
  RangeTime(MonthTime(2002, 9), YearTime(2004)),
  RelativeTime('id', RelativeRelation.after),
  AgeEstimateTime(20),
  const UnknownTime(),
];

void main() {
  group('繁體中文：完整格式（詳情頁）', () {
    test('與企劃書範例一致', () {
      expect(TimeFormat.full(DayTime(2003, 9, 15), zh), '2003-09-15');
      expect(TimeFormat.full(MonthTime(2003, 9), zh), '2003-09');
      expect(TimeFormat.full(QuarterTime(2003, 3), zh), '2003 年第 3 季');
      expect(TimeFormat.full(HalfYearTime(2003, 1), zh), '2003 年上半年');
      expect(TimeFormat.full(HalfYearTime(2003, 2), zh), '2003 年下半年');
      expect(TimeFormat.full(YearTime(2003), zh), '2003 年');
      expect(TimeFormat.full(ApproxYearTime(2003), zh), '約 2003 年');
      expect(
        TimeFormat.full(RangeTime(YearTime(2002), YearTime(2004)), zh),
        '2002～2004 年',
      );
      expect(
        TimeFormat.full(RangeTime(MonthTime(2002, 9), YearTime(2004)), zh),
        '2002-09～2004 年',
      );
      expect(
        TimeFormat.full(
          RelativeTime('id', RelativeRelation.after),
          zh,
          relatedEventTitle: '大學畢業',
        ),
        '大學畢業後',
      );
      expect(TimeFormat.full(AgeEstimateTime(20), zh), '約 20 歲');
      expect(TimeFormat.full(const UnknownTime(), zh), '時間未定');
    });

    test('相對事件的三種關係與參照已刪除', () {
      final before = RelativeTime('id', RelativeRelation.before);
      final during = RelativeTime('id', RelativeRelation.during);
      expect(TimeFormat.full(before, zh, relatedEventTitle: '入伍'), '入伍前');
      expect(TimeFormat.full(during, zh, relatedEventTitle: '留學'), '留學期間');
      expect(TimeFormat.full(before, zh), '（參照事件已刪除）前');
    });

    test('年份不加千分位', () {
      expect(TimeFormat.full(YearTime(2003), zh), isNot(contains(',')));
    });
  });

  group('繁體中文：列表格式（時間軸首頁）', () {
    test('與企劃書 4.6 範例一致', () {
      expect(TimeFormat.list(DayTime(2026, 12, 28), zh), '12/28');
      expect(TimeFormat.list(DayTime(2026, 9, 5), zh), '09/05');
      expect(TimeFormat.list(MonthTime(2026, 12), zh), '12 月');
      expect(TimeFormat.list(QuarterTime(2026, 4), zh), '第 4 季');
      expect(TimeFormat.list(HalfYearTime(2003, 2), zh), '下半年');
      expect(TimeFormat.list(YearTime(2003), zh), '月份未定');
      expect(TimeFormat.list(ApproxYearTime(2003), zh), '約 2003 年');
      expect(
        TimeFormat.list(RangeTime(YearTime(2002), YearTime(2004)), zh),
        '2002～2004',
      );
      expect(TimeFormat.list(const UnknownTime(), zh), '時間未定');
    });
  });

  group('英文（驗收 #31 的時間格式部分）', () {
    test('完整格式', () {
      expect(TimeFormat.full(DayTime(2003, 9, 15), en), '2003-09-15');
      expect(TimeFormat.full(QuarterTime(2003, 3), en), 'Q3 2003');
      expect(TimeFormat.full(HalfYearTime(2003, 1), en), 'H1 2003');
      expect(TimeFormat.full(HalfYearTime(2003, 2), en), 'H2 2003');
      expect(TimeFormat.full(YearTime(2003), en), '2003');
      expect(TimeFormat.full(ApproxYearTime(2003), en), 'c. 2003');
      expect(
        TimeFormat.full(RangeTime(YearTime(2002), YearTime(2004)), en),
        '2002–2004',
      );
      expect(
        TimeFormat.full(RangeTime(MonthTime(2002, 9), YearTime(2004)), en),
        '2002-09 – 2004',
      );
      expect(
        TimeFormat.full(
          RelativeTime('id', RelativeRelation.after),
          en,
          relatedEventTitle: '大學畢業',
        ),
        'After 大學畢業',
      );
      expect(TimeFormat.full(AgeEstimateTime(20), en), 'About age 20');
      expect(TimeFormat.full(const UnknownTime(), en), 'Date unknown');
    });

    test('列表格式', () {
      expect(TimeFormat.list(DayTime(2026, 12, 28), en), '12/28');
      expect(TimeFormat.list(MonthTime(2026, 1), en), 'Jan');
      expect(TimeFormat.list(MonthTime(2026, 12), en), 'Dec');
      expect(TimeFormat.list(QuarterTime(2026, 4), en), 'Q4');
      expect(TimeFormat.list(HalfYearTime(2003, 2), en), 'H2');
      expect(TimeFormat.list(YearTime(2003), en), 'Month unknown');
    });

    test('十二個月份名稱皆有對應', () {
      const names = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      for (var m = 1; m <= 12; m++) {
        expect(TimeFormat.list(MonthTime(2026, m), en), names[m - 1]);
      }
    });

    test('使用者輸入的標題不翻譯', () {
      expect(
        TimeFormat.full(
          RelativeTime('id', RelativeRelation.during),
          en,
          relatedEventTitle: '留學',
        ),
        'During 留學',
      );
    });
  });

  group('不得顯示未輸入的月日（驗收 #1、#14）', () {
    test('只輸入「2003 年」：只顯示年份', () {
      expect(TimeFormat.full(YearTime(2003), zh), '2003 年');
      expect(TimeFormat.list(YearTime(2003), zh), '月份未定');
    });

    test('「2003 年下半年」：不顯示月日', () {
      expect(TimeFormat.full(HalfYearTime(2003, 2), zh), '2003 年下半年');
      expect(TimeFormat.list(HalfYearTime(2003, 2), zh), '下半年');
    });

    test('兩種語言下，非精確日期的任何格式都不含月日', () {
      final monthDay = RegExp(r'\d{1,2}/\d{1,2}|\d{4}-\d{2}-\d{2}');
      for (final texts in [zh, en]) {
        for (final value in samples.where((v) => v is! DayTime)) {
          for (final text in [
            TimeFormat.full(value, texts),
            TimeFormat.list(value, texts),
          ]) {
            expect(
              text,
              isNot(matches(monthDay)),
              reason: '${value.type}: $text',
            );
          }
        }
      }
    });
  });
}
