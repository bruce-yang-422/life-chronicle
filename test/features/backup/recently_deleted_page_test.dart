import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/platform/security_platform.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/data/repositories/security_service.dart';
import 'package:life_chronicle/features/backup/recently_deleted_page.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

import '../../data/repositories/harness.dart';
import '../event_editor/event_editor_test.dart' show settle;
import '../../support/security_stub.dart';

void main() {
  late Harness h;
  late SecurityService security;
  late SecurityStub platform;

  setUp(() async {
    h = await Harness.create();
    platform = SecurityStub();
    security = SecurityService(
      MemorySecurityStorage(),
      platform,
      h.db,
      iterations: 2,
    );
    await security.load();
    await security.install(
      await SecurityService.prepareCodes('abc123', iterations: 2),
      const SecurityConfig(privateProtection: true),
    );
  });
  tearDown(() async {
    await h.close();
  });

  Future<String> deleted({bool private = false}) async {
    final id = await h.events().create(
      EventInput(
        title: '不可洩漏的標題',
        time: YearTime(2003),
        privacy: private ? 'private' : 'normal',
      ),
    );
    await h.events().softDelete(id);
    return id;
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...securityTestOverrides,
          appDatabaseProvider.overrideWithValue(h.db),
          securityProvider.overrideWith((ref) => security),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'TW'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RecentlyDeletedPage(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('未驗證私密刪除事件隱藏標題與修改入口，取消查看不洩漏', (tester) async {
    final id = await tester.runAsync(() => deleted(private: true));
    await pump(tester);
    expect(find.text('不可洩漏的標題'), findsNothing);
    expect(find.text('私密事件'), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsNothing);
    expect(find.byIcon(Icons.delete_forever), findsNothing);
    await tester.tap(find.byIcon(Icons.menu_book));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('不可洩漏的標題'), findsNothing);
    await tester.tap(find.text('取消'));
    await settle(tester);
    expect(find.byType(RecentlyDeletedPage), findsOneWidget);
    expect(find.text('不可洩漏的標題'), findsNothing);
    expect(
      (await tester.runAsync(() => h.events().find(id!)))!.deletedAt,
      isNotNull,
    );
    await unmount(tester);
  });

  testWidgets('驗證後顯示標題及復原入口，重新鎖定立即隱藏', (tester) async {
    await tester.runAsync(() => deleted(private: true));
    await pump(tester);
    platform.succeeds = true;
    await tester.tap(find.byIcon(Icons.lock_outline));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.fingerprint));
    await settle(tester);
    expect(find.text('不可洩漏的標題'), findsOneWidget);
    expect(find.byIcon(Icons.restore), findsOneWidget);
    security.lock();
    await settle(tester);
    expect(find.text('不可洩漏的標題'), findsNothing);
    expect(find.byIcon(Icons.restore), findsNothing);
    await unmount(tester);
  });

  testWidgets('復原後即時從最近刪除移除並保留事件', (tester) async {
    final id = await tester.runAsync(deleted);
    await pump(tester);
    await tester.tap(find.byIcon(Icons.restore));
    await settle(tester);
    expect(find.text('不可洩漏的標題'), findsNothing);
    expect(
      (await tester.runAsync(() => h.events().find(id!)))!.deletedAt,
      isNull,
    );
    await unmount(tester);
  });

  testWidgets('遺族未獲私密權限時不能查看、復原或永久刪除', (tester) async {
    await tester.runAsync(() => deleted(private: true));
    final codes = await tester.runAsync(
      () => SecurityService.prepareCodes('abc123', iterations: 2),
    );
    await tester.runAsync(
      () => security.install(
        codes!,
        const SecurityConfig(privateProtection: true),
      ),
    );
    await tester.runAsync(
      () => security.authenticatePassword(codes!.family, familyName: '家屬'),
    );
    await pump(tester);
    await tester.tap(find.byIcon(Icons.menu_book));
    await settle(tester);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('不可洩漏的標題'), findsNothing);
    expect(find.byIcon(Icons.restore), findsNothing);
    expect(find.byIcon(Icons.delete_forever), findsNothing);
    await tester.tap(find.text('取消'));
    await settle(tester);
    await unmount(tester);
  });

  testWidgets('窄螢幕三倍字級的私密刪除清單沒有溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.runAsync(() => deleted(private: true));
    await pump(tester);
    expect(find.text('私密事件'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('永久刪除必須確認，取消保留事件，確認才移除', (tester) async {
    final id = await tester.runAsync(deleted);
    await pump(tester);
    await tester.tap(find.byIcon(Icons.delete_forever));
    await settle(tester);
    await tester.tap(find.text('取消'));
    await settle(tester);
    expect(await tester.runAsync(() => h.events().find(id!)), isNotNull);
    await tester.tap(find.byIcon(Icons.delete_forever));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(tester);
    expect(await tester.runAsync(() => h.events().find(id!)), isNull);
    expect(find.text('不可洩漏的標題'), findsNothing);
    await unmount(tester);
  });
}
