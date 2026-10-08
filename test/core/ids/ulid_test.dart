import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/ids/ulid.dart';

void main() {
  group('UlidGenerator', () {
    test('格式：26 字元、Crockford Base32 字元集', () {
      final id = UlidGenerator().next();
      expect(id.length, 26);
      expect(UlidGenerator.isValid(id), isTrue);
      for (final ch in id.split('')) {
        expect(UlidGenerator.alphabet.contains(ch), isTrue, reason: ch);
      }
      // Crockford 不使用易混淆字元
      expect(id, isNot(matches(RegExp('[ILOU]'))));
    });

    test('可解析出產生時的毫秒時間戳記', () {
      final now = DateTime.utc(2026, 10, 8, 14, 30, 15, 123);
      final id = UlidGenerator(clock: () => now).next();
      expect(UlidGenerator.timestampOf(id), now);
    });

    test('已知時間戳記的編碼與規格一致', () {
      // ULID 規格範例的時間戳記與編碼
      const cases = {1469922850259: '01ARZ3NDEK', 1469918176385: '01ARYZ6S41'};
      cases.forEach((ms, encoded) {
        final time = DateTime.fromMillisecondsSinceEpoch(ms);
        final id = UlidGenerator(clock: () => time).next();
        expect(id.substring(0, 10), encoded);
        expect(UlidGenerator.timestampOf(id).millisecondsSinceEpoch, ms);
      });
    });

    test('同一毫秒內連續產生時單調遞增', () {
      final fixed = DateTime.utc(2026, 1, 1);
      final gen = UlidGenerator(clock: () => fixed);
      final ids = List.generate(1000, (_) => gen.next());
      for (var i = 1; i < ids.length; i++) {
        expect(ids[i].compareTo(ids[i - 1]), greaterThan(0));
        expect(ids[i].substring(0, 10), ids[0].substring(0, 10));
      }
    });

    test('時鐘回撥時仍保持單調遞增', () {
      var time = DateTime.utc(2026, 1, 1, 0, 0, 1);
      final gen = UlidGenerator(clock: () => time);
      final first = gen.next();
      time = DateTime.utc(2026, 1, 1); // 時鐘往回調整 1 秒
      final second = gen.next();
      expect(second.compareTo(first), greaterThan(0));
    });

    test('不同毫秒產生的 ULID 依時間排序', () {
      var ms = 1700000000000;
      final gen = UlidGenerator(
        clock: () => DateTime.fromMillisecondsSinceEpoch(ms++),
      );
      final ids = List.generate(100, (_) => gen.next());
      final sorted = [...ids]..sort();
      expect(ids, sorted);
    });

    test('大量產生無重複', () {
      final gen = UlidGenerator();
      final ids = <String>{};
      for (var i = 0; i < 100000; i++) {
        ids.add(gen.next());
      }
      expect(ids.length, 100000);
    });

    test('同一毫秒亂數溢位時拋出錯誤', () {
      final fixed = DateTime.utc(2026, 1, 1);
      // 亂數全部為 31（最大值），下一次遞增即溢位
      final gen = UlidGenerator(clock: () => fixed, random: _MaxRandom());
      gen.next();
      expect(gen.next, throwsStateError);
    });

    test('isValid 拒絕格式錯誤的字串', () {
      expect(UlidGenerator.isValid(''), isFalse);
      expect(UlidGenerator.isValid('01ARYZ6S41'), isFalse);
      expect(UlidGenerator.isValid('01arz3ndektsv4rrffq69g5fav'), isFalse);
      expect(UlidGenerator.isValid('01ARZ3NDEKTSV4RRFFQ69G5FAI'), isFalse);
      // 第一個字元超過 7 代表時間超出 48 位元
      expect(UlidGenerator.isValid('81ARZ3NDEKTSV4RRFFQ69G5FAV'), isFalse);
      expect(UlidGenerator.isValid('01ARZ3NDEKTSV4RRFFQ69G5FAV'), isTrue);
    });

    test('timestampOf 拒絕無效 ULID', () {
      expect(() => UlidGenerator.timestampOf('abc'), throwsFormatException);
    });
  });
}

class _MaxRandom implements Random {
  @override
  int nextInt(int max) => max - 1;

  @override
  bool nextBool() => true;

  @override
  double nextDouble() => 0.999;
}
