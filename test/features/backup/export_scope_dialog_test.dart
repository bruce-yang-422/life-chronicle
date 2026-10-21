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

  testWidgets('大量附件維持兩個開關，不顯示逐檔名稱，預設完整備份', (tester) async {
    await pump(
      tester,
      items: [
        for (var i = 0; i < 10000; i++)
          ArchiveMediaOption(
            'blob$i',
            ['附件$i.jpg'],
            1024,
            1,
            normalReferences: 1,
          ),
      ],
    );
    expect(find.byType(SwitchListTile), findsNWidgets(2));
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('附件0.jpg'), findsNothing);
    expect(find.textContaining('10000'), findsOneWidget);
    expect(
      find.byType(DropdownButtonFormField<int>).hitTestable(),
      findsNothing,
    );
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(result!.type, 'full');
    expect(result!.excludedBlobIds, isEmpty);
  });

  testWidgets('進階選項可選分包，關閉附件時不提交分包設定', (tester) async {
    await pump(tester);
    await tester.tap(find.text('進階選項'));
    await tester.pumpAndSettle();
    final dropdown = find.byType(DropdownButtonFormField<int>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('每包最多 1.00 GiB').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('每個分包可獨立解壓'), findsOneWidget);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(result!.maxPartBytes, 1024 * 1024 * 1024);
    await pump(tester);
    await tester.tap(find.text('包含附件檔案'));
    await tester.pump();
    expect(find.textContaining('還原後無法開啟'), findsOneWidget);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(result!.type, 'no_media');
    expect(result!.maxPartBytes, isNull);
  });

  testWidgets('切換範圍後取消不提交', (tester) async {
    await pump(tester);
    await tester.tap(find.text('包含附件檔案'));
    await tester.tap(find.text('包含私密事件'));
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('無附件的英文介面可選不含附件備份', (tester) async {
    await pump(tester, items: [], locale: 'en');
    expect(find.text('There are no attachment files.'), findsOneWidget);
    await tester.tap(find.text('Include attachment files'));
    await tester.tap(find.widgetWithText(FilledButton, 'Next'));
    await tester.pumpAndSettle();
    expect(result!.type, 'no_media');
  });

  testWidgets('三倍字級可捲動而且不載入長檔名清單', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(
      tester,
      items: [
        ArchiveMediaOption('long', ['很長的檔名' * 100], 1024, 3),
      ],
    );
    await tester.ensureVisible(find.text('進階選項'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
  });

  testWidgets('重新鎖定遮蔽摘要並停用下一步', (tester) async {
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
    expect(find.textContaining('附件檔案：'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '下一步'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('排除私密時摘要扣除專屬檔案，共用與未引用檔案仍納入', (tester) async {
    await pump(
      tester,
      items: const [
        ArchiveMediaOption(
          'shared',
          ['一般.pdf', '私密.pdf'],
          10,
          2,
          normalReferences: 1,
        ),
        ArchiveMediaOption('private', ['私密專屬.pdf'], 10, 1, normalReferences: 0),
        ArchiveMediaOption('unused', ['倉庫.pdf'], 10, 0, normalReferences: 0),
      ],
    );
    expect(find.textContaining('附件檔案：3 個'), findsOneWidget);
    await tester.tap(find.text('包含私密事件'));
    await tester.pump();
    expect(find.textContaining('附件檔案：2 個・20 B'), findsOneWidget);
    expect(find.text('私密專屬.pdf'), findsNothing);
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(result!.excludePrivateEvents, isTrue);
    expect(result!.excludedBlobIds, isEmpty);
  });
}
