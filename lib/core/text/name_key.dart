/// 地點與人物名稱的比對用正規化（企劃書 4.1）。
///
/// 忽略常見寫法差異，讓「台北市」「臺北市」「台北 市」「ＡＢＣ」「abc」
/// 視為同一個名稱，避免同一地點或人物被重複建立。
///
/// 規則：
/// 1. 全形英數與符號轉為半形
/// 2. 移除所有空白（含全形空白）
/// 3. 英文字母轉小寫
/// 4. 異體字統一（臺→台）
abstract final class NameKey {
  /// 異體字對照：左邊統一為右邊。
  static const Map<String, String> _variants = {'臺': '台'};

  /// 回傳正規化後的比對鍵；名稱只有空白時回傳 null。
  static String? of(String name) {
    final buffer = StringBuffer();
    for (final rune in name.runes) {
      var r = rune;
      // 全形 ASCII（！～）轉半形
      if (r >= 0xFF01 && r <= 0xFF5E) r -= 0xFEE0;
      final ch = String.fromCharCode(r);
      if (ch.trim().isEmpty) continue; // 空白（含全形空白 U+3000）
      buffer.write(_variants[ch] ?? ch);
    }
    final key = buffer.toString().toLowerCase();
    return key.isEmpty ? null : key;
  }

  /// 顯示用名稱：去除前後空白；只有空白時回傳 null。
  static String? displayName(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
