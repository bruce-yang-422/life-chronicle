// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '人生編年史';

  @override
  String get navTimeline => '人生時間軸';

  @override
  String get navSearch => '搜尋與視圖';

  @override
  String get navNewEvent => '新增節點';

  @override
  String get navStories => '故事篇章';

  @override
  String get navBackup => '資料與備份';

  @override
  String get placeholderComingSoon => '此功能開發中';

  @override
  String timeQuarterFull(String year, String quarter) {
    return '$year 年第 $quarter 季';
  }

  @override
  String timeHalfYearFull(String year, String half) {
    String _temp0 = intl.Intl.selectLogic(half, {
      'first': '上半年',
      'other': '下半年',
    });
    return '$year 年$_temp0';
  }

  @override
  String timeYearFull(String year) {
    return '$year 年';
  }

  @override
  String timeApproxYear(String year) {
    return '約 $year 年';
  }

  @override
  String timeRangeYearsFull(String start, String end) {
    return '$start～$end 年';
  }

  @override
  String timeRangeYearsList(String start, String end) {
    return '$start～$end';
  }

  @override
  String timeRange(String start, String end) {
    return '$start～$end';
  }

  @override
  String timeRelativeAfter(String title) {
    return '$title後';
  }

  @override
  String timeRelativeBefore(String title) {
    return '$title前';
  }

  @override
  String timeRelativeDuring(String title) {
    return '$title期間';
  }

  @override
  String get timeDeletedReference => '（參照事件已刪除）';

  @override
  String timeAgeEstimate(String age) {
    return '約 $age 歲';
  }

  @override
  String get timeUnknown => '時間未定';

  @override
  String timeListDay(String month, String day) {
    return '$month/$day';
  }

  @override
  String timeListMonth(String month) {
    return '$month 月';
  }

  @override
  String timeListQuarter(String quarter) {
    return '第 $quarter 季';
  }

  @override
  String timeListHalfYear(String half) {
    String _temp0 = intl.Intl.selectLogic(half, {
      'first': '上半年',
      'other': '下半年',
    });
    return '$_temp0';
  }

  @override
  String get timeListYearOnly => '月份未定';
}
