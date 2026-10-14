import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/features/shared/markdown_content.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

void main() {
  testWidgets('完整工具列可操作標題、清單、縮排、程式碼與連結', (tester) async {
    final controller = TextEditingController(text: '甲\n乙');
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: MarkdownEditor(
        controller: controller, label: '記述', onChanged: (_) {})))));
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    await tester.tap(find.byTooltip('項目符號清單'));
    expect(controller.text, '- 甲\n- 乙');
    controller.selection = TextSelection(baseOffset: 4, extentOffset: controller.text.length);
    await tester.tap(find.byTooltip('增加縮排（巢狀清單）'));
    expect(controller.text, '- 甲\n    - 乙');
    await tester.tap(find.byTooltip('減少縮排'));
    expect(controller.text, '- 甲\n- 乙');
    controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    await tester.tap(find.byTooltip('編號清單'));
    expect(controller.text, '1. 甲\n2. 乙');
    controller.text = '回憶';
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    await tester.tap(find.byTooltip('標題層級'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 級標題'));
    await tester.pumpAndSettle();
    expect(controller.text, '## 回憶');
    controller.text = '文字';
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    await tester.tap(find.byTooltip('行內程式碼'));
    expect(controller.text, '`文字`');
    controller.text = '示範';
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    await tester.tap(find.byTooltip('插入連結'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'https://example.com');
    await tester.tap(find.text('插入'));
    await tester.pumpAndSettle();
    expect(controller.text, '[示範](<https://example.com>)');
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('實際渲染六級標題、巢狀清單、行內程式碼與可點擊連結', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarkdownContent(
              '# H1\n\n## H2\n\n### H3\n\n#### H4\n\n##### H5\n\n###### H6\n\n- 外層\n  - 內層\n    1. 第一步\n    2. 第二步\n\n`文字`\n\n[連結文字](https://example.com)',
            ),
          ),
        ),
      ),
    );
    for (var level = 1; level <= 6; level++) {
      expect(find.text('H$level'), findsOneWidget);
    }
    expect(find.text('文字'), findsOneWidget);
    await tester.ensureVisible(find.text('連結文字'));
    await tester.tap(find.text('連結文字'));
    await tester.pump();
    expect(copied, 'https://example.com');
    expect(find.text('已複製連結'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('窄畫面渲染表格並提供水平捲動，儲存格 emoji 及格式保留', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            child: MarkdownContent(
              '| 年齡 | 生活紀錄 |\n| ---: | :--- |\n| 16 | **科展** 🎉 |\n| 35 | 搬入新家 👨‍👩‍👧‍👦 |',
            ),
          ),
        ),
      ),
    );
    expect(find.byType(Table), findsOneWidget);
    expect(
      tester
          .widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .any((scroll) => scroll.scrollDirection == Axis.horizontal),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('手機 emoji 組合不被截斷，選取粗體與預覽切換保留原文', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var saved = '';
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MarkdownEditor(
              controller: controller,
              label: '記述',
              onChanged: (value) => saved = value,
            ),
          ),
        ),
      ),
    );
    const content = '感謝 🎉 👍🏽 👨‍👩‍👧‍👦';
    await tester.enterText(find.byType(TextFormField), content);
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    await tester.tap(find.byTooltip('粗體'));
    expect(saved, '**感謝** 🎉 👍🏽 👨‍👩‍👧‍👦');
    await tester.tap(find.text('預覽'));
    await tester.pumpAndSettle();
    expect(find.byType(MarkdownContent), findsOneWidget);
    await tester.tap(find.text('編輯原文'));
    await tester.pumpAndSettle();
    expect(controller.text, saved);
    expect(controller.text, contains('👨‍👩‍👧‍👦'));
    await tester.pumpWidget(const SizedBox());
  });
}
