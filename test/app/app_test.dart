import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/app/theme.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: LifeChronicleApp()));
  await tester.pumpAndSettle();
}

void main() {
  const tabs = ['人生時間軸', '搜尋與視圖', '新增節點', '故事篇章', '資料與備份'];

  testWidgets('底部導覽列以繁體中文顯示五個主分頁', (tester) async {
    await _pumpApp(tester);

    final navBar = find.byType(NavigationBar);
    expect(navBar, findsOneWidget);
    for (final label in tabs) {
      expect(
        find.descendant(of: navBar, matching: find.text(label)),
        findsOneWidget,
      );
    }
  });

  testWidgets('點選分頁會切換畫面', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('資料與備份'));
    await tester.pumpAndSettle();

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 4);
  });

  testWidgets('Material 元件使用繁體中文（Hant）語系', (tester) async {
    await _pumpApp(tester);

    final context = tester.element(find.byType(NavigationBar));
    final locale = Localizations.localeOf(context);
    expect(locale.languageCode, 'zh');
    expect(locale.scriptCode, 'Hant');
    // 繁體中文的「確定」按鈕文字
    expect(MaterialLocalizations.of(context).okButtonLabel, '確定');
  });

  testWidgets('主題跟隨系統淺色／深色設定', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await _pumpApp(tester);

    final context = tester.element(find.byType(NavigationBar));
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  test('淺色與深色主題使用同一主色', () {
    expect(AppTheme.light().brightness, Brightness.light);
    expect(AppTheme.dark().brightness, Brightness.dark);
    expect(AppTheme.light().useMaterial3, isTrue);
  });
}
