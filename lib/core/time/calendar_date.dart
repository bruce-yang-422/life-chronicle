/// 不含時區的曆法日期（企劃書 5.1：日期僅以當地曆法日期保存，不做時區換算）。
///
/// 不使用 [DateTime] 直接保存，避免出國或換時區後日期偏移。
class CalendarDate implements Comparable<CalendarDate> {
  CalendarDate(this.year, this.month, this.day) {
    if (year < minYear || year > maxYear) {
      throw ArgumentError.value(year, 'year', '年份須介於 $minYear 與 $maxYear');
    }
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', '月份須介於 1 與 12');
    }
    final last = daysInMonth(year, month);
    if (day < 1 || day > last) {
      throw ArgumentError.value(day, 'day', '$year 年 $month 月只有 $last 天');
    }
  }

  /// 一年的第一天。
  factory CalendarDate.firstOfYear(int year) => CalendarDate(year, 1, 1);

  /// 一年的最後一天。
  factory CalendarDate.lastOfYear(int year) => CalendarDate(year, 12, 31);

  /// 某月的最後一天。
  factory CalendarDate.lastOfMonth(int year, int month) =>
      CalendarDate(year, month, daysInMonth(year, month));

  /// 解析 `YYYY-MM-DD` 格式。
  factory CalendarDate.parse(String value) {
    final match = _isoPattern.firstMatch(value);
    if (match == null) {
      throw FormatException('日期格式須為 YYYY-MM-DD', value);
    }
    return CalendarDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  static const int minYear = 1;
  static const int maxYear = 9999;
  static final RegExp _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;
  final int month;
  final int day;

  static bool isLeapYear(int year) =>
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;

  static int daysInMonth(int year, int month) => switch (month) {
    2 => isLeapYear(year) ? 29 : 28,
    4 || 6 || 9 || 11 => 30,
    _ => 31,
  };

  /// 加減天數（可為負數）。
  CalendarDate addDays(int days) {
    final d = DateTime.utc(year, month, day).add(Duration(days: days));
    return CalendarDate(d.year, d.month, d.day);
  }

  /// 加減年數。原日期為 2 月 29 日而目標年份非閏年時，順延為 3 月 1 日。
  CalendarDate addYears(int years) {
    final target = year + years;
    if (month == 2 && day == 29 && !isLeapYear(target)) {
      return CalendarDate(target, 3, 1);
    }
    return CalendarDate(target, month, day);
  }

  /// `YYYY-MM-DD` 格式，可直接以字串比較大小。
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  bool isBefore(CalendarDate other) => compareTo(other) < 0;

  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  @override
  int compareTo(CalendarDate other) {
    if (year != other.year) return year.compareTo(other.year);
    if (month != other.month) return month.compareTo(other.month);
    return day.compareTo(other.day);
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}
