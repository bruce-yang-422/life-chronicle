import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

/// 顯示偏好不改變 UTC 儲存值，也不處理事件的模糊日期。
abstract final class TimestampDisplay {
  static const zones = [
    'system',
    'Asia/Taipei',
    'Asia/Tokyo',
    'Asia/Shanghai',
    'Asia/Hong_Kong',
    'Asia/Singapore',
    'Australia/Sydney',
    'Europe/London',
    'Europe/Paris',
    'America/New_York',
    'America/Los_Angeles',
    'UTC',
  ];
  static bool _ready = false;
  static DateTime convert(DateTime value, String zone) {
    if (zone == 'system') return value.toLocal();
    if (!_ready) {
      data.initializeTimeZones();
      _ready = true;
    }
    return tz.TZDateTime.from(value.toUtc(), tz.getLocation(zone));
  }

  static String format(
    DateTime value,
    String zone,
    String pattern,
    String locale,
  ) => DateFormat(pattern, locale).format(convert(value, zone));
}
