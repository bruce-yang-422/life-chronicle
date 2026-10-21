import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/data/platform/storage_platform.dart';
import 'package:life_chronicle/features/settings/storage_status.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    int free, {
    bool banner = true,
    bool error = false,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageSnapshotProvider.overrideWith(
            (ref) => error
                ? Stream.error(Exception('unavailable'))
                : Stream.value(StorageSnapshot(123456789, free)),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    StorageStatus(banner: banner),
                    const TextField(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('低於 1 GB 才提醒，可關閉且不阻擋文字輸入', (tester) async {
    await show(tester, 999999999);
    expect(find.textContaining('低於 1 GB'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '仍可記錄');
    await tester.tap(find.byTooltip('關閉空間提醒'));
    await tester.pump();
    expect(find.textContaining('低於 1 GB'), findsNothing);
    expect(find.text('仍可記錄'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await show(tester, 1000000000);
    expect(find.textContaining('低於 1 GB'), findsNothing);
  });
  testWidgets('分開顯示 APP 占用與手機可用量，320px 三倍字級無溢位', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester, 2000000000, banner: false, scale: 3);
    expect(find.text('APP 總占用'), findsOneWidget);
    expect(find.text('手機剩餘空間'), findsOneWidget);
    expect(find.text('117.7 MiB'), findsOneWidget);
    expect(find.text('1.86 GiB'), findsOneWidget);
  });
  testWidgets('無法查詢不冒稱零容量，也不顯示錯誤低空間提醒', (tester) async {
    await show(tester, 0, banner: false, error: true);
    expect(find.text('暫時無法取得空間資訊。'), findsOneWidget);
    expect(find.text('0 B'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await show(tester, 0, error: true);
    expect(find.textContaining('低於 1 GB'), findsNothing);
  });
}
