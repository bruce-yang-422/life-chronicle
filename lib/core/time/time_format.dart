import 'time_value.dart';

/// 時間的顯示格式（企劃書第 5 節、4.6）。
///
/// 一律依使用者輸入的精確度顯示，**不得補出未輸入的月日**。
abstract final class TimeFormat {
  /// 完整格式，用於紀事本末詳情頁。
  ///
  /// 例：「2003-09-15」「2003 年第 3 季」「2003 年上半年」「約 2003 年」
  /// 「2002～2004 年」「大學畢業後」「約 20 歲」「時間未定」。
  ///
  /// [relatedEventTitle] 為相對事件所參照事件的標題；參照事件已不存在時傳入 null。
  static String full(TimeValue value, {String? relatedEventTitle}) =>
      switch (value) {
        CalendarTime c => _calendarFull(c),
        ApproxYearTime(:final year) => '約 $year 年',
        RangeTime(:final start, :final end) => _rangeFull(start, end),
        RelativeTime(:final relation) => _relative(relation, relatedEventTitle),
        AgeEstimateTime(:final age) => '約 $age 歲',
        UnknownTime() => '時間未定',
      };

  /// 列表格式，用於時間軸首頁（已依年份分組，因此省略年份）。
  ///
  /// 例：「12/28」「12 月」「第 4 季」「下半年」「月份未定」「約 2003 年」「2002～2004」。
  static String list(TimeValue value, {String? relatedEventTitle}) =>
      switch (value) {
        DayTime(:final month, :final day) => '${_two(month)}/${_two(day)}',
        MonthTime(:final month) => '$month 月',
        QuarterTime(:final quarter) => '第 $quarter 季',
        HalfYearTime(:final isFirstHalf) => isFirstHalf ? '上半年' : '下半年',
        YearTime() => '月份未定',
        ApproxYearTime(:final year) => '約 $year 年',
        RangeTime(:final start, :final end) => _rangeList(start, end),
        RelativeTime(:final relation) => _relative(relation, relatedEventTitle),
        AgeEstimateTime(:final age) => '約 $age 歲',
        UnknownTime() => '時間未定',
      };

  static String _calendarFull(CalendarTime value) => switch (value) {
    DayTime(:final year, :final month, :final day) =>
      '${_four(year)}-${_two(month)}-${_two(day)}',
    MonthTime(:final year, :final month) => '${_four(year)}-${_two(month)}',
    QuarterTime(:final year, :final quarter) => '$year 年第 $quarter 季',
    HalfYearTime(:final year, :final isFirstHalf) =>
      '$year 年${isFirstHalf ? '上' : '下'}半年',
    YearTime(:final year) => '$year 年',
  };

  /// 起訖皆為年份時合併為「2002～2004 年」，其餘為「起點～終點」。
  static String _rangeFull(CalendarTime start, CalendarTime end) {
    if (start is YearTime && end is YearTime) {
      return '${start.year}～${end.year} 年';
    }
    return '${_calendarFull(start)}～${_calendarFull(end)}';
  }

  /// 列表格式去掉結尾的「 年」，例如「2002～2004」「2002-09～2004」。
  static String _rangeList(CalendarTime start, CalendarTime end) {
    final full = _rangeFull(start, end);
    return full.endsWith(' 年') ? full.substring(0, full.length - 2) : full;
  }

  static String _relative(RelativeRelation relation, String? title) {
    final subject = title ?? '（參照事件已刪除）';
    return switch (relation) {
      RelativeRelation.after => '$subject後',
      RelativeRelation.before => '$subject前',
      RelativeRelation.during => '$subject期間',
    };
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _four(int n) => n.toString().padLeft(4, '0');
}
