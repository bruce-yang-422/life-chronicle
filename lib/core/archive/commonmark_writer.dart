/// 使用者純文字不得意外成為 Markdown 語法；換行使用可見的硬換行。
abstract final class CommonMarkWriter {
  static String text(String value) => value
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n')
      .map(
        (line) => line.replaceAllMapped(
          RegExp(r'[!"#$%&\x27()*+,\-./:;<=>?@\[\\\]^_`{|}~]'),
          (match) => '\\${match[0]}',
        ),
      )
      .join('\\\n');

  /// 標題是一個邏輯行，避免使用者換行產生額外標題。
  static String heading(String value, {int level = 1}) {
    if (level < 1 || level > 2) throw ArgumentError('封存標題只使用第一與第二級');
    return '${'#' * level} ${text(value.replaceAll(RegExp(r'[\r\n]+'), ' '))}\n\n';
  }

  static String section(String? title, String content) {
    if (content.trim().isEmpty) return '';
    return '${title == null || title.trim().isEmpty ? '' : heading(title, level: 2)}${text(content)}\n\n';
  }

  static String link(String label, String path, {bool image = false}) {
    if (!RegExp(r'^[a-z0-9_./-]+$').hasMatch(path)) {
      throw ArgumentError('閱讀版本連結必須使用 ASCII 相對路徑');
    }
    return '${image ? '!' : ''}[${text(label.replaceAll(RegExp(r'[\r\n]+'), ' '))}]($path)';
  }

  static String html(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
