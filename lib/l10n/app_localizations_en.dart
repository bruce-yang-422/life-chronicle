// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Life Chronicle';

  @override
  String get navTimeline => 'Timeline';

  @override
  String get navSearch => 'Search';

  @override
  String get navNewEvent => 'New Entry';

  @override
  String get navStories => 'Stories';

  @override
  String get navBackup => 'Backup';

  @override
  String get placeholderComingSoon => 'Coming soon';

  @override
  String timeQuarterFull(String year, String quarter) {
    return 'Q$quarter $year';
  }

  @override
  String timeHalfYearFull(String year, String half) {
    String _temp0 = intl.Intl.selectLogic(half, {'first': 'H1', 'other': 'H2'});
    return '$_temp0 $year';
  }

  @override
  String timeYearFull(String year) {
    return '$year';
  }

  @override
  String timeApproxYear(String year) {
    return 'c. $year';
  }

  @override
  String timeRangeYearsFull(String start, String end) {
    return '$start–$end';
  }

  @override
  String timeRangeYearsList(String start, String end) {
    return '$start–$end';
  }

  @override
  String timeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String timeRelativeAfter(String title) {
    return 'After $title';
  }

  @override
  String timeRelativeBefore(String title) {
    return 'Before $title';
  }

  @override
  String timeRelativeDuring(String title) {
    return 'During $title';
  }

  @override
  String get timeDeletedReference => '(deleted event)';

  @override
  String timeAgeEstimate(String age) {
    return 'About age $age';
  }

  @override
  String get timeUnknown => 'Date unknown';

  @override
  String timeListDay(String month, String day) {
    return '$month/$day';
  }

  @override
  String timeListMonth(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'Jan',
      '2': 'Feb',
      '3': 'Mar',
      '4': 'Apr',
      '5': 'May',
      '6': 'Jun',
      '7': 'Jul',
      '8': 'Aug',
      '9': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dec',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String timeListQuarter(String quarter) {
    return 'Q$quarter';
  }

  @override
  String timeListHalfYear(String half) {
    String _temp0 = intl.Intl.selectLogic(half, {'first': 'H1', 'other': 'H2'});
    return '$_temp0';
  }

  @override
  String get timeListYearOnly => 'Month unknown';
}
