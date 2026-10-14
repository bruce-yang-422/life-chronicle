import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256，輸入輸出皆為位元組，不涉及平台安全儲存區。
abstract final class PasswordCrypto {
  static Uint8List derive(
    List<int> password,
    List<int> salt, {
    required int iterations,
    int length = 32,
  }) {
    if (iterations < 1 || length < 1 || length > 32 * 0xffffffff) {
      throw ArgumentError('無效的 PBKDF2 參數');
    }
    final hmac = Hmac(sha256, password);
    final output = BytesBuilder(copy: false);
    for (var block = 1; output.length < length; block++) {
      final suffix = ByteData(4)..setUint32(0, block, Endian.big);
      var u = hmac.convert([...salt, ...suffix.buffer.asUint8List()]).bytes;
      final t = Uint8List.fromList(u);
      for (var round = 1; round < iterations; round++) {
        u = hmac.convert(u).bytes;
        for (var i = 0; i < t.length; i++) {
          t[i] ^= u[i];
        }
      }
      output.add(t);
    }
    return Uint8List.sublistView(output.takeBytes(), 0, length);
  }

  static bool constantTimeEquals(List<int> a, List<int> b) {
    var difference = a.length ^ b.length;
    for (var i = 0; i < max(a.length, b.length); i++) {
      difference |= (i < a.length ? a[i] : 0) ^ (i < b.length ? b[i] : 0);
    }
    return difference == 0;
  }

  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  static String generateCode() {
    const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
    final random = Random.secure();
    final raw = List.generate(16, (_) => alphabet[random.nextInt(32)]).join();
    return List.generate(4, (i) => raw.substring(i * 4, i * 4 + 4)).join('-');
  }

  static String? normalizeCode(String value) {
    final normalized = value.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^[0-9A-HJKMNP-TV-Z]{16}$').hasMatch(normalized)
        ? normalized
        : null;
  }

  static Map<String, Object> hash(String value, {int iterations = 600000}) {
    final salt = randomBytes(16);
    return {
      'algorithm': 'pbkdf2-hmac-sha256',
      'iterations': iterations,
      'salt': base64Encode(salt),
      'hash': base64Encode(
        derive(utf8.encode(value), salt, iterations: iterations),
      ),
    };
  }

  static bool verify(String value, Map<String, Object?> record) {
    if (record['algorithm'] != 'pbkdf2-hmac-sha256') return false;
    final iterations = record['iterations'];
    if (iterations is! int || iterations < 1 || iterations > 10000000) {
      return false;
    }
    final salt = base64Decode(record['salt'] as String);
    final expected = base64Decode(record['hash'] as String);
    if (salt.length < 16 || expected.length != 32) return false;
    return constantTimeEquals(
      derive(utf8.encode(value), salt, iterations: iterations),
      expected,
    );
  }
}

/// 各種密碼共用失敗計數；五次後 30 秒，後續每次再錯加倍。
class PasswordAttempts {
  PasswordAttempts({this.failures = 0, this.blockedUntil});
  int failures;
  DateTime? blockedUntil;
  Duration remaining(DateTime now) {
    final duration = blockedUntil?.difference(now) ?? Duration.zero;
    return duration.isNegative ? Duration.zero : duration;
  }

  bool get hasFailures => failures > 0;
  void failed(DateTime now) {
    failures++;
    if (failures >= 5) {
      // 在整數可表示範圍內保留加倍語意，避免無限次輸錯溢位。
      final multiplier = 1 << min(failures - 5, 30);
      blockedUntil = now.add(Duration(seconds: 30 * multiplier));
    }
  }

  void succeeded() {
    failures = 0;
    blockedUntil = null;
  }

  Map<String, Object?> toJson() => {
    'failures': failures,
    'blocked_until': blockedUntil?.toUtc().toIso8601String(),
  };
  factory PasswordAttempts.fromJson(Map<String, Object?> json) =>
      PasswordAttempts(
        failures: json['failures'] as int? ?? 0,
        blockedUntil: json['blocked_until'] == null
            ? null
            : DateTime.parse(json['blocked_until'] as String),
      );
}
