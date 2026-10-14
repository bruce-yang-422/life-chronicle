import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:life_chronicle/core/time/timestamp_display.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh'));
  test('繁中／英文時間不含 ISO 分隔符或毫秒', () {
    final instant = DateTime.utc(2026, 10, 14, 1, 18, 42, 123);
    expect(
      TimestampDisplay.format(
        instant,
        'Asia/Taipei',
        'y 年 M 月 d 日 ah:mm',
        'zh',
      ),
      '2026 年 10 月 14 日 上午9:18',
    );
    expect(
      TimestampDisplay.format(instant, 'Asia/Tokyo', 'MMM d, y, h:mm a', 'en'),
      'Oct 14, 2026, 10:18 AM',
    );
    expect(instant, DateTime.utc(2026, 10, 14, 1, 18, 42, 123));
  });
  test('紐約夏令時間及跨年，只改顯示', () {
    final before = TimestampDisplay.convert(
      DateTime.utc(2026, 3, 8, 6, 59),
      'America/New_York',
    );
    final after = TimestampDisplay.convert(
      DateTime.utc(2026, 3, 8, 7),
      'America/New_York',
    );
    expect(before.hour, 1);
    expect(after.hour, 3);
    expect(before.timeZoneOffset, const Duration(hours: -5));
    expect(after.timeZoneOffset, const Duration(hours: -4));
    expect(
      TimestampDisplay.convert(
        DateTime.utc(2026, 1, 1, 1),
        'America/Los_Angeles',
      ).year,
      2025,
    );
  });
}
