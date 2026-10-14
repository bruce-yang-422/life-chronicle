import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/archive/markdown_document.dart';
import 'package:markdown/markdown.dart' as md;

void main() {
  test('H1～H6、項目／編號／巢狀清單、行內程式碼及連結保存格式', () {
    const input =
        '# 一級\n\n## 二級\n\n### 三級\n\n#### 四級\n\n##### 五級\n\n###### 六級\n\n- 外層\n  - 內層 `文字`\n    1. 第一步\n    2. 第二步\n\n3. 編號從三開始\n4. 下一項\n\n[連結文字](https://example.com/path?q=demo)';
    final html = MarkdownDocument.html(input);
    expect(html, contains('<code>文字</code>'));
    expect(html, contains('<ol start="3">'));
    expect(
      html,
      contains('<a href="https://example.com/path?q=demo">連結文字</a>'),
    );
    final restored = md.markdownToHtml(
      MarkdownDocument.source(input),
      extensionSet: md.ExtensionSet.commonMark,
    );
    expect(restored, contains('<code>文字</code>'));
    expect(restored, contains('<ol start="3">'));
    expect(
      restored,
      contains('<a href="https://example.com/path?q=demo">連結文字</a>'),
    );
    expect(RegExp('<ul>').allMatches(restored).length, 2);
    expect(RegExp('<ol').allMatches(restored).length, 2);
  });
  test('表格保留欄位、對齊、粗體及 emoji；CommonMark 匯出轉為分組清單', () {
    const input =
        '| 年齡 | 回憶 |\n| ---: | :--- |\n| 16 | **科展** 🎉 |\n| 35 | 新家 👨‍👩‍👧‍👦 |';
    final html = MarkdownDocument.html(input);
    expect(html, contains('<table>'));
    expect(html, contains('text-align:right'));
    expect(html, contains('<strong>科展</strong> 🎉'));
    final source = MarkdownDocument.source(input);
    expect(source, contains('年齡: 16'));
    expect(source, contains('回憶: **科展** 🎉'));
    expect(source, contains('年齡: 35'));
    final common = md.markdownToHtml(
      source,
      extensionSet: md.ExtensionSet.commonMark,
    );
    expect(common, isNot(contains('<table>')));
    expect(common, contains('新家 👨‍👩‍👧‍👦'));
  });
  test('清單中的粗體與行內程式碼仍留在同一個清單項目', () {
    final source = MarkdownDocument.source('- 重要 **回憶** 與 `code` 🎉');
    expect(source, '- 重要 **回憶** 與 `code` 🎉');
  });
  test('保留 CommonMark 格式及手機複合 emoji，內容標題不增加封存的一級標題', () {
    const input =
        '# 成長 🎉\n\n**重要** 與 *感謝* 👍🏽 👨‍👩‍👧‍👦\n\n- 一起旅行\n- 保留回憶\n\n> 慢慢前進\n\n```\n# 不是標題\n```';
    final source = MarkdownDocument.source(input);
    final html = MarkdownDocument.html(input);
    expect(source, contains('### 成長 🎉'));
    expect(source, contains('**重要**'));
    expect(source, contains('👍🏽 👨‍👩‍👧‍👦'));
    expect(html, contains('<strong>重要</strong>'));
    expect(html, contains('<blockquote>'));
    expect(html, contains('<pre><code># 不是標題'));
    expect(html, isNot(contains('<h1>')));
    expect(
      md.markdownToHtml(source, extensionSet: md.ExtensionSet.commonMark),
      contains('<strong>重要</strong>'),
    );
  });
  test('閱讀 HTML 不執行使用者 HTML，也不載入外部圖片或危險連結', () {
    const input =
        '<script>alert(1)</script>\n\n![旅途](https://example.com/track.jpg)\n\n[危險](javascript:alert)\n\n[正常](https://example.com)';
    final html = MarkdownDocument.html(input);
    expect(html, isNot(contains('<script>')));
    expect(html, isNot(contains('<img')));
    expect(html, isNot(contains('href="javascript:')));
    expect(html, contains('href="https://example.com"'));
  });
}
