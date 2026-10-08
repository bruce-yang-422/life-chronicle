import 'calendar_date.dart';

/// 事件的時間資訊（企劃書第 5 節）。
///
/// 時間精確度必須明確保存，不可把不確定時間補成某月某日。
/// 以 [toJson] 序列化為資料庫的 `time_payload` 欄位，並可用 [TimeValue.fromJson] 完整還原。
sealed class TimeValue {
  const TimeValue();

  /// 資料表示代號（企劃書 5 節表格），同時作為 JSON 的 `type`。
  String get type;

  Map<String, Object?> toJson();

  factory TimeValue.fromJson(Map<String, Object?> json) {
    final type = json['type'];
    return switch (type) {
      'day' => DayTime(
        _int(json, 'year'),
        _int(json, 'month'),
        _int(json, 'day'),
      ),
      'month' => MonthTime(_int(json, 'year'), _int(json, 'month')),
      'quarter' => QuarterTime(_int(json, 'year'), _int(json, 'quarter')),
      'half_year' => HalfYearTime(_int(json, 'year'), _int(json, 'half')),
      'year' => YearTime(_int(json, 'year')),
      'approx_year' => ApproxYearTime(_int(json, 'year')),
      'range' => RangeTime(
        _calendarFromJson(json['start']),
        _calendarFromJson(json['end']),
      ),
      'relative' => RelativeTime(
        _string(json, 'event_id'),
        RelativeRelation.fromCode(_string(json, 'relation')),
      ),
      'age_estimate' => AgeEstimateTime(_int(json, 'age')),
      'unknown' => const UnknownTime(),
      _ => throw FormatException('未知的時間類型：$type'),
    };
  }

  static CalendarTime _calendarFromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      throw const FormatException('時間範圍的起訖必須是物件');
    }
    final parsed = TimeValue.fromJson(value);
    if (parsed is! CalendarTime) {
      throw FormatException('時間範圍的起訖不可為 ${parsed.type}');
    }
    return parsed;
  }

  static int _int(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! int) throw FormatException('欄位 $key 必須是整數', json);
    return value;
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String) throw FormatException('欄位 $key 必須是字串', json);
    return value;
  }
}

/// 可直接對應到曆法期間的時間：精確日期、年月、季度、半年、年份。
///
/// 也是時間範圍 [RangeTime] 的起點與終點可使用的類型。
sealed class CalendarTime implements TimeValue {
  /// 最早可能日期。
  CalendarDate get startDate;

  /// 最晚可能日期。
  CalendarDate get endDate;

  int get year;
}

void _checkYear(int year) {
  if (year < CalendarDate.minYear || year > CalendarDate.maxYear) {
    throw ArgumentError.value(
      year,
      'year',
      '年份須介於 ${CalendarDate.minYear} 與 ${CalendarDate.maxYear}',
    );
  }
}

/// 精確日期，例如 2003-09-15。
final class DayTime extends TimeValue implements CalendarTime {
  DayTime(int year, int month, int day) : date = CalendarDate(year, month, day);

  DayTime.fromDate(this.date);

  final CalendarDate date;

  @override
  int get year => date.year;
  int get month => date.month;
  int get day => date.day;

  @override
  String get type => 'day';

  @override
  CalendarDate get startDate => date;

  @override
  CalendarDate get endDate => date;

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'year': year,
    'month': month,
    'day': day,
  };

  @override
  bool operator ==(Object other) => other is DayTime && other.date == date;

  @override
  int get hashCode => Object.hash(type, date);

  @override
  String toString() => 'DayTime($date)';
}

/// 年月，例如 2003-09。
final class MonthTime extends TimeValue implements CalendarTime {
  MonthTime(this.year, this.month) {
    _checkYear(year);
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', '月份須介於 1 與 12');
    }
  }

  @override
  final int year;
  final int month;

  @override
  String get type => 'month';

  @override
  CalendarDate get startDate => CalendarDate(year, month, 1);

  @override
  CalendarDate get endDate => CalendarDate.lastOfMonth(year, month);

  @override
  Map<String, Object?> toJson() => {'type': type, 'year': year, 'month': month};

  @override
  bool operator ==(Object other) =>
      other is MonthTime && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(type, year, month);

  @override
  String toString() => 'MonthTime($year-$month)';
}

/// 季度，例如 2003 年第 3 季（Q1＝1–3 月…Q4＝10–12 月）。
final class QuarterTime extends TimeValue implements CalendarTime {
  QuarterTime(this.year, this.quarter) {
    _checkYear(year);
    if (quarter < 1 || quarter > 4) {
      throw ArgumentError.value(quarter, 'quarter', '季度須介於 1 與 4');
    }
  }

  @override
  final int year;
  final int quarter;

  @override
  String get type => 'quarter';

  @override
  CalendarDate get startDate => CalendarDate(year, (quarter - 1) * 3 + 1, 1);

  @override
  CalendarDate get endDate => CalendarDate.lastOfMonth(year, quarter * 3);

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'year': year,
    'quarter': quarter,
  };

  @override
  bool operator ==(Object other) =>
      other is QuarterTime && other.year == year && other.quarter == quarter;

  @override
  int get hashCode => Object.hash(type, year, quarter);

  @override
  String toString() => 'QuarterTime($year Q$quarter)';
}

/// 半年，例如 2003 年上半年（1＝上半年 1–6 月，2＝下半年 7–12 月）。
final class HalfYearTime extends TimeValue implements CalendarTime {
  HalfYearTime(this.year, this.half) {
    _checkYear(year);
    if (half != 1 && half != 2) {
      throw ArgumentError.value(half, 'half', '半年須為 1（上半年）或 2（下半年）');
    }
  }

  @override
  final int year;
  final int half;

  bool get isFirstHalf => half == 1;

  @override
  String get type => 'half_year';

  @override
  CalendarDate get startDate => CalendarDate(year, isFirstHalf ? 1 : 7, 1);

  @override
  CalendarDate get endDate =>
      isFirstHalf ? CalendarDate(year, 6, 30) : CalendarDate.lastOfYear(year);

  @override
  Map<String, Object?> toJson() => {'type': type, 'year': year, 'half': half};

  @override
  bool operator ==(Object other) =>
      other is HalfYearTime && other.year == year && other.half == half;

  @override
  int get hashCode => Object.hash(type, year, half);

  @override
  String toString() => 'HalfYearTime($year H$half)';
}

/// 年份，例如 2003 年。
final class YearTime extends TimeValue implements CalendarTime {
  YearTime(this.year) {
    _checkYear(year);
  }

  @override
  final int year;

  @override
  String get type => 'year';

  @override
  CalendarDate get startDate => CalendarDate.firstOfYear(year);

  @override
  CalendarDate get endDate => CalendarDate.lastOfYear(year);

  @override
  Map<String, Object?> toJson() => {'type': type, 'year': year};

  @override
  bool operator ==(Object other) => other is YearTime && other.year == year;

  @override
  int get hashCode => Object.hash(type, year);

  @override
  String toString() => 'YearTime($year)';
}

/// 約略年份，例如「約 2003 年」。排序區間同年份，另標記為推估。
final class ApproxYearTime extends TimeValue {
  ApproxYearTime(this.year) {
    _checkYear(year);
  }

  final int year;

  @override
  String get type => 'approx_year';

  @override
  Map<String, Object?> toJson() => {'type': type, 'year': year};

  @override
  bool operator ==(Object other) =>
      other is ApproxYearTime && other.year == year;

  @override
  int get hashCode => Object.hash(type, year);

  @override
  String toString() => 'ApproxYearTime($year)';
}

/// 時間範圍，例如 2002～2004 年；起訖可各自有不同精確度（如 2002-09～2004 年）。
final class RangeTime extends TimeValue {
  RangeTime(this.start, this.end) {
    if (start.startDate.isAfter(end.startDate)) {
      throw ArgumentError('時間範圍的起點不可晚於終點');
    }
    if (start == end) {
      throw ArgumentError('時間範圍的起點與終點不可相同');
    }
  }

  final CalendarTime start;
  final CalendarTime end;

  @override
  String get type => 'range';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'start': start.toJson(),
    'end': end.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is RangeTime && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(type, start, end);

  @override
  String toString() => 'RangeTime($start～$end)';
}

/// 相對事件的關係：之後、之前、期間。
enum RelativeRelation {
  after('after'),
  before('before'),
  during('during');

  const RelativeRelation(this.code);

  final String code;

  static RelativeRelation fromCode(String code) => values.firstWhere(
    (r) => r.code == code,
    orElse: () => throw FormatException('未知的相對關係：$code'),
  );
}

/// 相對事件，例如「大學畢業後」。
final class RelativeTime extends TimeValue {
  RelativeTime(this.eventId, this.relation) {
    if (eventId.isEmpty) {
      throw ArgumentError.value(eventId, 'eventId', '必須指定參照事件');
    }
  }

  /// 參照事件的 ID。
  final String eventId;
  final RelativeRelation relation;

  @override
  String get type => 'relative';

  @override
  Map<String, Object?> toJson() => {
    'type': type,
    'event_id': eventId,
    'relation': relation.code,
  };

  @override
  bool operator ==(Object other) =>
      other is RelativeTime &&
      other.eventId == eventId &&
      other.relation == relation;

  @override
  int get hashCode => Object.hash(type, eventId, relation);

  @override
  String toString() => 'RelativeTime(${relation.code} $eventId)';
}

/// 年齡推估，例如「約 20 歲」。
final class AgeEstimateTime extends TimeValue {
  AgeEstimateTime(this.age) {
    if (age < 0 || age > maxAge) {
      throw ArgumentError.value(age, 'age', '年齡須介於 0 與 $maxAge');
    }
  }

  static const int maxAge = 150;

  final int age;

  @override
  String get type => 'age_estimate';

  @override
  Map<String, Object?> toJson() => {'type': type, 'age': age};

  @override
  bool operator ==(Object other) =>
      other is AgeEstimateTime && other.age == age;

  @override
  int get hashCode => Object.hash(type, age);

  @override
  String toString() => 'AgeEstimateTime($age)';
}

/// 完全未知：時間未定。
final class UnknownTime extends TimeValue {
  const UnknownTime();

  @override
  String get type => 'unknown';

  @override
  Map<String, Object?> toJson() => {'type': type};

  @override
  bool operator ==(Object other) => other is UnknownTime;

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'UnknownTime()';
}
