import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/archive/archive_media_scope.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/archive_repository.dart';
import 'package:life_chronicle/data/repositories/security_service.dart';
import 'package:life_chronicle/features/backup/export_scope_dialog.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

import '../../data/repositories/harness.dart';
import '../../support/security_stub.dart';
import '../event_editor/event_editor_test.dart' show settle;

void main() {
  late Harness h;
  ArchiveMediaScope? result;
  const options = [
    ArchiveMediaOption('shared', ['敏感影片.mp4', '共用影片.mp4'], 1024, 2),
    ArchiveMediaOption('kept', ['保留影片.mp4'], 2048, 1),
  ];
  setUp(() async {
    h = await Harness.create();
    result = null;
  });
  tearDown(() async => h.close());

  Future<void> pump(
    WidgetTester tester, {
    List<ArchiveMediaOption> items = options,
    String locale = 'zh',
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...securityTestOverrides,
          appDatabaseProvider.overrideWithValue(h.db),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await showDialog<ArchiveMediaScope>(
                    context: context,
                    builder: (_) => ExportScopeDialog(options: items),
                  );
                },
                child: const Icon(Icons.archive),
              ),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.byIcon(Icons.archive));
    await settle(tester);
  }

  testWidgets('共用副本只列一列，取消勾選後回傳精確範圍', (tester) async {
    await pump(tester);
    expect(find.byType(CheckboxListTile), findsNWidgets(3));
    expect(find.text('1.0 KiB · 2 個附件共用'), findsOneWidget);
    await tester.tap(find.text('敏感影片.mp4\n共用影片.mp4'));
    await tester.pump();
    await tester.tap(find.text('匯出 ZIP 備份'));
    await tester.pumpAndSettle();
    expect(result!.type, 'custom');
    expect(result!.excludedBlobIds, {'shared'});
  });

  testWidgets('切換不含影音後恢復選擇，取消對話框不提交', (tester) async {
    await pump(tester);
    await tester.tap(find.text('敏感影片.mp4\n共用影片.mp4'));
    await tester.tap(find.text('包含影音原始副本'));
    await tester.pump();
    expect(find.text('保留影片.mp4'), findsNothing);
    await tester.tap(find.text('包含影音原始副本'));
    await tester.pump();
    final shared = find.ancestor(
      of: find.text('敏感影片.mp4\n共用影片.mp4'),
      matching: find.byType(CheckboxListTile),
    );
    expect(tester.widget<CheckboxListTile>(shared).value, isFalse);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('無副本時英文介面仍可選擇不含影音', (tester) async {
    await pump(tester, items: [], locale: 'en');
    expect(find.text('There are no media copies.'), findsOneWidget);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.tap(find.widgetWithText(FilledButton, 'Export ZIP backup'));
    await tester.pumpAndSettle();
    expect(result!.type, 'no_media');
  });

  testWidgets('三倍字級與長檔名可捲動且不溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(
      tester,
      items: [
        ArchiveMediaOption('long', ['很長的檔案名稱' * 20], 1024, 3),
      ],
    );
    await tester.ensureVisible(find.byType(ListView));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -160));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('重新鎖定立即遮蔽副本名稱並停用提交', (tester) async {
    await pump(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ExportScopeDialog)),
    );
    await tester.runAsync(() async {
      final service = container.read(securityProvider);
      final codes = await SecurityService.prepareCodes('abc123', iterations: 2);
      await service.install(
        codes,
        const SecurityConfig(privateProtection: true),
      );
      service.lock();
    });
    await settle(tester);
    expect(find.text('敏感影片.mp4\n共用影片.mp4'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '匯出 ZIP 備份'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
