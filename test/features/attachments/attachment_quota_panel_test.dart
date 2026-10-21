import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/attachment_quota.dart';
import 'package:life_chronicle/features/attachments/attachment_quota_panel.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    AttachmentUsage usage, {
    String language = 'zh',
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(language),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: SingleChildScrollView(
              child: AttachmentQuotaPanel(usage: usage),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  testWidgets('十進位容量、件數與剩餘額度；不足 5 MB 才提醒', (tester) async {
    await show(tester, const AttachmentUsage(usedBytes: 20000000, count: 8));
    expect(find.text('已用 20.0 MB／25 MB・8 個附件'), findsOneWidget);
    expect(find.text('剩餘 5.0 MB'), findsOneWidget);
    expect(find.text('剩餘額度較少，照片可改用壓縮。'), findsNothing);
    await show(tester, const AttachmentUsage(usedBytes: 20000001, count: 8));
    expect(find.text('剩餘額度較少，照片可改用壓縮。'), findsOneWidget);
  });

  testWidgets('草稿容量計入剩餘，既有超額與 1 byte 邊界都有文字說明', (tester) async {
    await show(
      tester,
      const AttachmentUsage(
        usedBytes: 22000000,
        count: 2,
        pendingBytes: 3000000,
        pendingCount: 1,
      ),
    );
    expect(find.text('待保存 3.0 MB・1 個附件（已計入剩餘額度）'), findsOneWidget);
    expect(find.text('剩餘 0.0 MB'), findsOneWidget);
    await show(tester, const AttachmentUsage(usedBytes: 25000001, count: 2));
    expect(find.textContaining('超出 0.1 MB'), findsOneWidget);
    expect(find.text('剩餘 0.0 MB'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
  });

  testWidgets('英文與 320px 兩倍字級不溢位', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(
      tester,
      const AttachmentUsage(
        usedBytes: 24000000,
        count: 18,
        pendingBytes: 2000000,
        pendingCount: 2,
      ),
      language: 'en',
      scale: 2,
    );
    expect(find.text('24.0 MB / 25 MB used · 18 attachments'), findsOneWidget);
    expect(find.textContaining('1.0 MB over capacity'), findsOneWidget);
  });
}
