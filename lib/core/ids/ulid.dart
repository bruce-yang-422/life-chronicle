import 'dart:math';

/// ULID（Universally Unique Lexicographically Sortable Identifier）產生器。
///
/// 企劃書 8.3：事件等實體的識別碼採 ULID，全域唯一且可依時間排序，
/// 避免不同裝置的封存包合併時發生 ID 衝突。
///
/// 格式：26 字元 Crockford Base32。前 10 字元為 48 位元毫秒時間戳記，
/// 後 16 字元為 80 位元亂數。同一毫秒內連續產生時，亂數部分遞增 1，
/// 保證產生順序與字串排序一致（單調遞增）。
class UlidGenerator {
  UlidGenerator({DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  /// Crockford Base32 字元集（不含 I、L、O、U）。
  static const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  static const int length = 26;
  static const int _timeLength = 10;
  static const int _randomLength = 16;

  /// 48 位元時間戳記上限（10889 年）。
  static const int maxTimestamp = 0xFFFFFFFFFFFF;

  static final RegExp _pattern = RegExp(r'^[0-7][0-9A-HJKMNP-TV-Z]{25}$');

  final DateTime Function() _clock;
  final Random _random;

  int _lastTimestamp = -1;

  /// 亂數部分，每個元素為 0–31（5 位元），共 16 個。
  final List<int> _lastRandom = List<int>.filled(_randomLength, 0);

  /// 產生新的 ULID。
  ///
  /// 時鐘回撥（時間早於上一次）時沿用上一次的時間戳記並遞增，
  /// 仍保證單調遞增。同一毫秒內亂數溢位時拋出 [StateError]。
  String next() {
    var timestamp = _clock().toUtc().millisecondsSinceEpoch;
    if (timestamp < 0 || timestamp > maxTimestamp) {
      throw StateError('時間超出 ULID 可表示範圍：$timestamp');
    }
    if (timestamp <= _lastTimestamp) {
      timestamp = _lastTimestamp;
      _increment();
    } else {
      _lastTimestamp = timestamp;
      for (var i = 0; i < _randomLength; i++) {
        _lastRandom[i] = _random.nextInt(32);
      }
    }
    return _encodeTime(timestamp) + _lastRandom.map((d) => alphabet[d]).join();
  }

  void _increment() {
    for (var i = _randomLength - 1; i >= 0; i--) {
      if (_lastRandom[i] < 31) {
        _lastRandom[i]++;
        return;
      }
      _lastRandom[i] = 0;
    }
    throw StateError('同一毫秒內產生的 ULID 數量超過上限');
  }

  static String _encodeTime(int timestamp) {
    final chars = List<String>.filled(_timeLength, '0');
    var value = timestamp;
    for (var i = _timeLength - 1; i >= 0; i--) {
      chars[i] = alphabet[value % 32];
      value ~/= 32;
    }
    return chars.join();
  }

  /// 是否為格式正確的 ULID（大寫、Crockford Base32、26 字元、不超過時間上限）。
  static bool isValid(String value) => _pattern.hasMatch(value);

  /// 解析 ULID 內含的時間戳記（UTC）。
  static DateTime timestampOf(String ulid) {
    if (!isValid(ulid)) {
      throw FormatException('不是有效的 ULID', ulid);
    }
    var value = 0;
    for (var i = 0; i < _timeLength; i++) {
      value = value * 32 + alphabet.indexOf(ulid[i]);
    }
    return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }
}
