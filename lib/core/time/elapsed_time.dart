import 'calendar_date.dart';
import 'time_value.dart';

enum ElapsedUnit { days, months, years }

enum ElapsedSpecial { today, thisMonth, thisYear, includesToday, unknown }

/// 距今顯示只衍生自事件日期；不將模糊時間當成精確日期保存。
class ElapsedTime {
  const ElapsedTime({
    this.unit,
    this.count = 0,
    this.maximum,
    this.future = false,
    this.approximate = false,
    this.special,
  });
  final ElapsedUnit? unit;
  final int count;
  final int? maximum;
  final bool future, approximate;
  final ElapsedSpecial? special;

  static ElapsedTime calculate(TimeValue time, CalendarDate today) {
    if (time is DayTime) return _point(time.date, today);
    if (time is YearTime || time is ApproxYearTime) {
      final year = time is YearTime ? time.year : (time as ApproxYearTime).year;
      final difference = today.year - year;
      if (difference == 0) {
        return const ElapsedTime(special: ElapsedSpecial.thisYear);
      }
      return ElapsedTime(
        unit: ElapsedUnit.years,
        count: difference.abs(),
        future: difference < 0,
        approximate: true,
      );
    }
    if (time is MonthTime) {
      final difference =
          (today.year - time.year) * 12 + today.month - time.month;
      if (difference == 0) {
        return const ElapsedTime(special: ElapsedSpecial.thisMonth);
      }
      return ElapsedTime(
        unit: difference.abs() >= 12 ? ElapsedUnit.years : ElapsedUnit.months,
        count: difference.abs() >= 12
            ? difference.abs() ~/ 12
            : difference.abs(),
        future: difference < 0,
        approximate: true,
      );
    }
    final CalendarDate start, end;
    if (time is RangeTime) {
      start = time.start.startDate;
      end = time.end.endDate;
    } else if (time is CalendarTime) {
      start = time.startDate;
      end = time.endDate;
    } else {
      // 相對事件／年齡推估未提供確切日期，不能拿排序用途的區間當成事實。
      return const ElapsedTime(special: ElapsedSpecial.unknown);
    }
    if (!today.isBefore(start) && !today.isAfter(end)) {
      return const ElapsedTime(special: ElapsedSpecial.includesToday);
    }
    final future = start.isAfter(today);
    final nearest = future ? start : end;
    final farthest = future ? end : start;
    final nearestMonths = future
        ? _months(today, nearest)
        : _months(nearest, today);
    final farthestMonths = future
        ? _months(today, farthest)
        : _months(farthest, today);
    final unit = nearestMonths >= 12
        ? ElapsedUnit.years
        : nearestMonths >= 1
        ? ElapsedUnit.months
        : ElapsedUnit.days;
    final low = unit == ElapsedUnit.years
        ? nearestMonths ~/ 12
        : unit == ElapsedUnit.months
        ? nearestMonths
        : _days(nearest, today);
    final high = unit == ElapsedUnit.years
        ? farthestMonths ~/ 12
        : unit == ElapsedUnit.months
        ? farthestMonths
        : _days(farthest, today);
    return ElapsedTime(
      unit: unit,
      count: low,
      maximum: low == high ? null : high,
      future: future,
      approximate: true,
    );
  }

  static int _days(CalendarDate a, CalendarDate b) => DateTime.utc(
    a.year,
    a.month,
    a.day,
  ).difference(DateTime.utc(b.year, b.month, b.day)).inDays.abs();
  static int _months(CalendarDate earlier, CalendarDate later) {
    final anniversaryDay = earlier.day.clamp(
      1,
      CalendarDate.daysInMonth(later.year, later.month),
    );
    return (later.year - earlier.year) * 12 +
        later.month -
        earlier.month -
        (later.day < anniversaryDay ? 1 : 0);
  }

  static ElapsedTime _point(CalendarDate date, CalendarDate today) {
    if (date == today) return const ElapsedTime(special: ElapsedSpecial.today);
    final future = date.isAfter(today);
    final months = future ? _months(today, date) : _months(date, today);
    return ElapsedTime(
      unit: months >= 12
          ? ElapsedUnit.years
          : months >= 1
          ? ElapsedUnit.months
          : ElapsedUnit.days,
      count: months >= 12
          ? months ~/ 12
          : months >= 1
          ? months
          : _days(date, today),
      future: future,
    );
  }
}
