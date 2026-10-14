import '../core/time/elapsed_time.dart';
import 'app_localizations.dart';

String elapsedTimeLabel(ElapsedTime value, AppLocalizations l) {
  if (value.special != null) {
    return switch (value.special!) {
      ElapsedSpecial.today => l.elapsedToday,
      ElapsedSpecial.thisMonth => l.elapsedThisMonth,
      ElapsedSpecial.thisYear => l.elapsedThisYear,
      ElapsedSpecial.includesToday => l.elapsedIncludesToday,
      ElapsedSpecial.unknown => l.elapsedUnknown,
    };
  }
  final count = value.maximum == null
      ? value.count.toString()
      : l.elapsedRange(value.count, value.maximum!);
  final text = switch (value.unit!) {
    ElapsedUnit.days =>
      value.future ? l.elapsedDaysFuture(count) : l.elapsedDaysAgo(count),
    ElapsedUnit.months =>
      value.future ? l.elapsedMonthsFuture(count) : l.elapsedMonthsAgo(count),
    ElapsedUnit.years =>
      value.future ? l.elapsedYearsFuture(count) : l.elapsedYearsAgo(count),
  };
  return value.approximate ? l.elapsedApprox(text) : text;
}
