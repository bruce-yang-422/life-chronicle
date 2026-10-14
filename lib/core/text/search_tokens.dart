/// 將 Unicode 字元及相鄰字元編碼成 FTS5 unicode61 可辨識的詞。
/// 同時支援一字與兩字中文搜尋，不依賴網路斷詞服務。
abstract final class SearchTokens {
  static String normalize(String value) => value.toLowerCase();
  static List<String> terms(String query) =>
      normalize(query)
          .trim()
          .split(RegExp(r'\s+'))
          .where((term) => term.isNotEmpty)
          .toList();
  static Set<String> of(String value) {
    final runes = normalize(value).runes.toList();
    final tokens = <String>{};
    for (var i = 0; i < runes.length; i++) {
      tokens.add('u${runes[i].toRadixString(16)}');
      if (i + 1 < runes.length) {
        tokens.add(
          'p${runes[i].toRadixString(16)}z${runes[i + 1].toRadixString(16)}',
        );
      }
    }
    return tokens;
  }

  static String match(String query) =>
      terms(query).expand(of).toSet().map((token) => '"$token"').join(' AND ');
}
