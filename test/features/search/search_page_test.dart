import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/app/theme.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/platform/security_platform.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/data/repositories/security_service.dart';
import 'package:life_chronicle/features/event_detail/event_detail_page.dart';
import 'package:life_chronicle/features/search/search_page.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

import '../../data/repositories/harness.dart';
import '../../support/security_stub.dart';
import '../event_editor/event_editor_test.dart'
    show settle, StubAttachmentPlatform;

void main() {
  late Harness h;
  late Directory media;
  final semanticDisposers = <VoidCallback>[];
  void ui(String name, WidgetTesterCallback body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          for (final dispose in semanticDisposers) {
            dispose();
          }
          semanticDisposers.clear();
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        }
      });
  setUp(() async {
    h = await Harness.create();
    media = await Directory.systemTemp.createTemp('search-layout-');
  });
  tearDown(() async {
    await h.close();
    await media.delete(recursive: true);
  });

  Future<void> open(
    WidgetTester tester, {
    Locale locale = zhHantLocale,
    Size size = const Size(320, 640),
    double scale = 3,
    SecurityService? security,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...securityTestOverrides,
          if (security != null)
            securityProvider.overrideWith((ref) => security),
          appDatabaseProvider.overrideWithValue(h.db),
          attachmentRepositoryProvider.overrideWith(
            (ref) async => AttachmentRepository(
              h.context(),
              media,
              StubAttachmentPlatform(),
            ),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: appSupportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const Scaffold(body: SearchPage()),
        ),
      ),
    );
    await settle(tester);
  }

  Finder field(String name) => find.byKey(ValueKey('search-$name'));
  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    double delta = 240,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();
  }

  for (final locale in [zhHantLocale, enLocale]) {
    ui('320dp 三倍字級與鍵盤下可搜尋並開啟完整詳情：${locale.languageCode}', (tester) async {
      await tester.runAsync(
        () => EventContentRepository(h.context()).save(
          EventDraft(
            title: 'Graduation',
            time: YearTime(2003),
            sections: [DraftSection(content: 'Saved narrative')],
          ),
        ),
      );
      await open(tester, locale: locale);
      await reveal(tester, field('query'));
      await tester.enterText(field('query'), 'Graduation');
      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await settle(tester);
      expect(tester.takeException(), isNull);
      await reveal(tester, field('submit'));
      expect(tester.getSize(field('submit')).height, greaterThanOrEqualTo(48));
      await tester.tap(field('submit'));
      await settle(tester);
      expect(tester.testTextInput.isVisible, isFalse);
      tester.view.resetViewInsets();
      await settle(tester);
      await reveal(
        tester,
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('Graduation'),
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(ListTile),
          matching: find.text('Graduation'),
        ),
      );
      await settle(tester);
      expect(find.byType(EventDetailPage), findsOneWidget);
      await reveal(tester, find.text('Saved narrative'));
      expect(find.text('Saved narrative'), findsOneWidget);
    });
  }

  ui('錯誤年份可在大字級捲動修正，錯誤提示有即時朗讀語意', (tester) async {
    await tester.runAsync(
      () => h.events().create(EventInput(title: '大學', time: YearTime(2003))),
    );
    await open(tester);
    final semantics = tester.ensureSemantics();
    semanticDisposers.add(semantics.dispose);
    await reveal(tester, field('from'));
    await tester.enterText(field('from'), '2005');
    await reveal(tester, field('to'));
    await tester.enterText(field('to'), '2000');
    await reveal(tester, field('submit'));
    await tester.tap(field('submit'));
    await settle(tester);
    final l = AppLocalizations.of(tester.element(find.byType(SearchPage)));
    final error = find.text(l.searchInvalid);
    await reveal(tester, error, delta: -200);
    expect(
      tester.getSemantics(error),
      matchesSemantics(
        label: l.searchInvalid,
        isLiveRegion: true,
        textDirection: TextDirection.ltr,
      ),
    );
    await reveal(tester, field('from'), delta: -200);
    await tester.enterText(field('from'), '2000');
    await reveal(tester, field('to'));
    await tester.enterText(field('to'), '2005');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.text(l.searchInvalid), findsNothing);
    await reveal(tester, find.text('大學'));
    expect(find.text('大學'), findsOneWidget);
  });

  ui('切換寬度與字級保留條件，年份欄位改為上下排列且空結果可見', (tester) async {
    await open(tester, size: const Size(900, 700), scale: 1);
    await tester.enterText(field('query'), 'No match');
    await tester.enterText(field('from'), '2000');
    await tester.enterText(field('to'), '2005');
    expect(
      tester.getTopLeft(field('from')).dy,
      tester.getTopLeft(field('to')).dy,
    );
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    await settle(tester);
    expect(
      tester.widget<TextField>(field('query')).controller!.text,
      'No match',
    );
    expect(tester.widget<TextField>(field('from')).controller!.text, '2000');
    expect(
      tester.getTopLeft(field('to')).dy,
      greaterThan(tester.getBottomLeft(field('from')).dy),
    );
    await reveal(tester, field('submit'));
    await tester.tap(field('submit'));
    await settle(tester);
    final l = AppLocalizations.of(tester.element(find.byType(SearchPage)));
    await reveal(tester, find.text(l.searchNoResults));
    expect(find.text(l.searchNoResults).hitTestable(), findsOneWidget);
  });

  ui('大字級結果捲動後重新鎖定立即移除私密內容', (tester) async {
    final security = SecurityService(
      MemorySecurityStorage(),
      SecurityStub(),
      h.db,
      iterations: 2,
    );
    await tester.runAsync(() async {
      await h.events().create(
        EventInput(
          title: 'Private entry',
          time: YearTime(2004),
          privacy: 'private',
        ),
      );
      await h.events().create(
        EventInput(title: 'Public entry', time: YearTime(2003)),
      );
      await security.load();
      await security.install(
        await SecurityService.prepareCodes('abc123', iterations: 2),
        const SecurityConfig(privateProtection: true),
      );
      await security.authenticatePassword('abc123', privateAccess: true);
    });
    await open(tester, security: security);
    await reveal(tester, find.text('Private entry'));
    expect(find.text('Private entry').hitTestable(), findsOneWidget);
    security.lock();
    await settle(tester);
    expect(find.text('Private entry'), findsNothing);
    await reveal(tester, find.text('Public entry'));
    expect(find.text('Public entry'), findsOneWidget);
  });

  ui('多筆結果按需建立，整頁可捲到最後一筆並保留搜尋條件', (tester) async {
    await tester.runAsync(() async {
      for (var index = 0; index < 60; index++) {
        await h.events().create(
          EventInput(title: 'Entry $index', time: YearTime(2000 + index)),
        );
      }
    });
    await open(tester, size: const Size(400, 700), scale: 1);
    expect(find.byType(ListTile).evaluate().length, lessThan(60));
    await reveal(tester, find.text('Entry 0'));
    expect(find.text('Entry 0').hitTestable(), findsOneWidget);
    await reveal(tester, field('query'), delta: -400);
    expect(field('query').hitTestable(), findsOneWidget);
    expect(tester.widget<TextField>(field('query')).controller!.text, isEmpty);
  });
}
