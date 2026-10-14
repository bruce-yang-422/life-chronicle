import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/security/password_crypto.dart';

String hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('PBKDF2-HMAC-SHA256 標準向量與多個輸出區塊', () {
    final password = utf8.encode('password'), salt = utf8.encode('salt');
    expect(
      hex(PasswordCrypto.derive(password, salt, iterations: 1)),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
    expect(
      hex(PasswordCrypto.derive(password, salt, iterations: 2)),
      'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
    );
    expect(
      hex(PasswordCrypto.derive(password, salt, iterations: 4096)),
      'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
    );
    expect(
      hex(PasswordCrypto.derive(password, salt, iterations: 2, length: 40)),
      'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43830651afcb5c862f',
    );
  });
  test('加鹽雜湊可驗證且不保存密碼，相同密碼取得不同鹽', () {
    final first = PasswordCrypto.hash('abc123', iterations: 2);
    final second = PasswordCrypto.hash('abc123', iterations: 2);
    expect(PasswordCrypto.verify('abc123', first), isTrue);
    expect(PasswordCrypto.verify('wrong', first), isFalse);
    expect(first['salt'], isNot(second['salt']));
    expect(jsonEncode(first), isNot(contains('abc123')));
    expect(PasswordCrypto.constantTimeEquals([1], [1, 0]), isFalse);
  });
  test('Crockford 密碼為 16 字元分四段，忽略大小寫、空白與連字號', () {
    final codes = {for (var i = 0; i < 100; i++) PasswordCrypto.generateCode()};
    expect(codes.length, 100);
    for (final code in codes) {
      expect(code.split('-').map((part) => part.length), [4, 4, 4, 4]);
      expect(
        PasswordCrypto.normalizeCode(' ${code.toLowerCase()} '),
        code.replaceAll('-', ''),
      );
      expect(code, isNot(matches('[ILOU]')));
    }
    expect(PasswordCrypto.normalizeCode('invalid'), isNull);
  });
  test('共用連錯五次暫停 30 秒，每次再錯加倍；成功才重設', () {
    final attempts = PasswordAttempts();
    final now = DateTime.utc(2026);
    for (var i = 0; i < 4; i++) {
      attempts.failed(now);
      expect(attempts.remaining(now), Duration.zero);
    }
    attempts.failed(now);
    expect(attempts.remaining(now), const Duration(seconds: 30));
    final restored = PasswordAttempts.fromJson(attempts.toJson());
    restored.failed(now.add(const Duration(seconds: 30)));
    expect(
      restored.remaining(now.add(const Duration(seconds: 30))),
      const Duration(seconds: 60),
    );
    restored.succeeded();
    expect(restored.failures, 0);
    expect(restored.remaining(now), Duration.zero);
  });
}
