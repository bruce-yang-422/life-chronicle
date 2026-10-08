import '../core/time/time_texts.dart';
import 'app_localizations.dart';

/// 以 ARB 介面文字實作時間格式的文字來源（企劃書 4.7）。
///
/// 用法：`TimeFormat.full(value, L10nTimeTexts(AppLocalizations.of(context)))`。
class L10nTimeTexts implements TimeTexts {
  const L10nTimeTexts(this.l10n);

  final AppLocalizations l10n;

  static String _half(bool firstHalf) => firstHalf ? 'first' : 'second';

  static String _two(int n) => n.toString().padLeft(2, '0');

  @override
  String quarterFull(int year, int quarter) =>
      l10n.timeQuarterFull('$year', '$quarter');

  @override
  String halfYearFull(int year, {required bool firstHalf}) =>
      l10n.timeHalfYearFull('$year', _half(firstHalf));

  @override
  String yearFull(int year) => l10n.timeYearFull('$year');

  @override
  String approxYear(int year) => l10n.timeApproxYear('$year');

  @override
  String rangeYearsFull(int startYear, int endYear) =>
      l10n.timeRangeYearsFull('$startYear', '$endYear');

  @override
  String rangeYearsList(int startYear, int endYear) =>
      l10n.timeRangeYearsList('$startYear', '$endYear');

  @override
  String range(String start, String end) => l10n.timeRange(start, end);

  @override
  String relativeAfter(String title) => l10n.timeRelativeAfter(title);

  @override
  String relativeBefore(String title) => l10n.timeRelativeBefore(title);

  @override
  String relativeDuring(String title) => l10n.timeRelativeDuring(title);

  @override
  String deletedReference() => l10n.timeDeletedReference;

  @override
  String ageEstimate(int age) => l10n.timeAgeEstimate('$age');

  @override
  String unknown() => l10n.timeUnknown;

  @override
  String listDay(int month, int day) =>
      l10n.timeListDay(_two(month), _two(day));

  @override
  String listMonth(int month) => l10n.timeListMonth('$month');

  @override
  String listQuarter(int quarter) => l10n.timeListQuarter('$quarter');

  @override
  String listHalfYear({required bool firstHalf}) =>
      l10n.timeListHalfYear(_half(firstHalf));

  @override
  String listYearOnly() => l10n.timeListYearOnly;
}
