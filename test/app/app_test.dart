import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/app/theme.dart';

Future<void> _pumpApp(WidgetTester tester, List<Locale> systemLocales) async {
  tester.platformDispatcher.localesTestValue = systemLocales;
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const ProviderScope(child: LifeChronicleApp()));
  await tester.pumpAndSettle();
}

void _expectTabs(List<String> labels) {
  final navBar = find.byType(NavigationBar);
  expect(navBar, findsOneWidget);
  for (final label in labels) {
    expect(
      find.descendant(of: navBar, matching: find.text(label)),
      findsOneWidget,
    );
  }
}

const _zhTabs = ['人生時間軸', '搜尋與視圖', '新增節點', '故事篇章', '資料與備份'];
const _enTabs = ['Timeline', 'Search', 'New Entry', 'Stories', 'Backup'];

void main() {
  group('語系跟隨系統（企劃書 4.7）', () {
    testWidgets('系統為繁體中文：介面與 Material 元件皆為繁體中文', (tester) async {
      await _pumpApp(tester, [const Locale('zh', 'TW')]);
      _expectTabs(_zhTabs);

      final context = tester.element(find.byType(NavigationBar));
      final locale = Localizations.localeOf(context);
      expect(locale.scriptCode, 'Hant');
      expect(MaterialLocalizations.of(context).okButtonLabel, '確定');
    });

    testWidgets('系統為英文：介面皆為英文（驗收 #31）', (tester) async {
      await _pumpApp(tester, [const Locale('en', 'US')]);
      _expectTabs(_enTabs);

      final context = tester.element(find.byType(NavigationBar));
      expect(MaterialLocalizations.of(context).okButtonLabel, 'OK');
    });

    test('語系解析規則', () {
      expect(resolveAppLocale([const Locale('zh', 'TW')]), zhHantLocale);
      expect(resolveAppLocale([const Locale('zh', 'HK')]), zhHantLocale);
      // 第一階段：簡體中文系統先顯示繁體中文
      expect(
        resolveAppLocale([
          const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ]),
        zhHantLocale,
      );
      expect(resolveAppLocale([const Locale('en', 'GB')]), enLocale);
      // 不支援的語言：依偏好清單找下一個，皆不支援則為英文
      expect(
        resolveAppLocale([const Locale('ja'), const Locale('zh', 'TW')]),
        zhHantLocale,
      );
      expect(resolveAppLocale([const Locale('ja')]), enLocale);
      expect(resolveAppLocale(null), enLocale);
    });
  });

  testWidgets('點選分頁會切換畫面', (tester) async {
    await _pumpApp(tester, [const Locale('zh', 'TW')]);

    await tester.tap(find.text('資料與備份'));
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 4);
  });

  testWidgets('主題跟隨系統淺色／深色設定', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpApp(tester, [const Locale('zh', 'TW')]);

    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  test('淺色與深色主題', () {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
    expect(AppTheme.light().useMaterial3, isTrue);
  });
}
