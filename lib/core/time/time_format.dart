import 'time_texts.dart';
import 'time_value.dart';

/// 時間的顯示格式（企劃書第 5 節、4.6、4.7）。
///
/// 一律依使用者輸入的精確度顯示，**不得補出未輸入的月日**。
/// 文字由 [TimeTexts] 依語系提供。
abstract final class TimeFormat {
  /// 完整格式，用於紀事本末詳情頁。
  ///
  /// [relatedEventTitle] 為相對事件所參照事件的標題；參照事件已不存在時傳入 null。
  static String full(
    TimeValue value,
    TimeTexts texts, {
    String? relatedEventTitle,
  }) => switch (value) {
    CalendarTime c => _calendarFull(c, texts),
    ApproxYearTime(:final year) => texts.approxYear(year),
    RangeTime(:final start, :final end) =>
      start is YearTime && end is YearTime
          ? texts.rangeYearsFull(start.year, end.year)
          : texts.range(_calendarFull(start, texts), _calendarFull(end, texts)),
    RelativeTime(:final relation) => _relative(
      relation,
      relatedEventTitle,
      texts,
    ),
    AgeEstimateTime(:final age) => texts.ageEstimate(age),
    UnknownTime() => texts.unknown(),
  };

  /// 列表格式，用於時間軸首頁（已依年份分組，因此精確到月日的時間省略年份）。
  static String list(
    TimeValue value,
    TimeTexts texts, {
    String? relatedEventTitle,
  }) => switch (value) {
    DayTime(:final month, :final day) => texts.listDay(month, day),
    MonthTime(:final month) => texts.listMonth(month),
    QuarterTime(:final quarter) => texts.listQuarter(quarter),
    HalfYearTime(:final isFirstHalf) => texts.listHalfYear(
      firstHalf: isFirstHalf,
    ),
    YearTime() => texts.listYearOnly(),
    ApproxYearTime(:final year) => texts.approxYear(year),
    RangeTime(:final start, :final end) =>
      start is YearTime && end is YearTime
          ? texts.rangeYearsList(start.year, end.year)
          : texts.range(_calendarFull(start, texts), _calendarFull(end, texts)),
    RelativeTime(:final relation) => _relative(
      relation,
      relatedEventTitle,
      texts,
    ),
    AgeEstimateTime(:final age) => texts.ageEstimate(age),
    UnknownTime() => texts.unknown(),
  };

  static String _calendarFull(CalendarTime value, TimeTexts texts) =>
      switch (value) {
        DayTime(:final year, :final month, :final day) =>
          '${_four(year)}-${_two(month)}-${_two(day)}',
        MonthTime(:final year, :final month) => '${_four(year)}-${_two(month)}',
        QuarterTime(:final year, :final quarter) => texts.quarterFull(
          year,
          quarter,
        ),
        HalfYearTime(:final year, :final isFirstHalf) => texts.halfYearFull(
          year,
          firstHalf: isFirstHalf,
        ),
        YearTime(:final year) => texts.yearFull(year),
      };

  static String _relative(
    RelativeRelation relation,
    String? title,
    TimeTexts texts,
  ) {
    final subject = title ?? texts.deletedReference();
    return switch (relation) {
      RelativeRelation.after => texts.relativeAfter(subject),
      RelativeRelation.before => texts.relativeBefore(subject),
      RelativeRelation.during => texts.relativeDuring(subject),
    };
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _four(int n) => n.toString().padLeft(4, '0');
}
