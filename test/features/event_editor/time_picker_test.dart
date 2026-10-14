import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/features/event_editor/time_picker_sheet.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

void main() {
  final times = <TimeValue>[
    YearTime(2003),
    HalfYearTime(2003, 2),
    QuarterTime(2003, 3),
    MonthTime(2003, 9),
    DayTime(2003, 9, 15),
    ApproxYearTime(2003),
    RangeTime(YearTime(2002), MonthTime(2004, 6)),
    AgeEstimateTime(20),
    RelativeTime('reference', RelativeRelation.after),
  ];
  for (final value in times) {
    testWidgets('時間選擇器完整保留 ${value.type} 原有精確度', (tester) async {
      TimeValue? selected;
      await tester.pumpWidget(
        MaterialApp(
          locale: zhHantLocale,
          supportedLocales: appSupportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    selected = await chooseTime(context, value),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsNothing);
      await tester.ensureVisible(find.text('套用時間'));
      await tester.tap(find.text('套用時間'));
      await tester.pumpAndSettle();
      expect(selected, value);
    });
  }
  testWidgets('先點選年份，未選擇不偽造日期；可明確選時間未定', (tester) async {
    TimeValue? selected;
    await tester.pumpWidget(
      MaterialApp(
        locale: zhHantLocale,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  selected = await chooseTime(context, const UnknownTime()),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('年份'), findsWidgets);
    await tester.tap(find.text('套用時間'));
    await tester.pumpAndSettle();
    expect(find.text('請檢查時間輸入及起訖順序'), findsOneWidget);
    expect(selected, isNull);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('時間未定').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('套用時間'));
    await tester.pumpAndSettle();
    expect(selected, const UnknownTime());
  });
}
