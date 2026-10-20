import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/stories/theme_rule.dart';

void main() {
  test('AND、OR 與排除優先序', () {
    final all = ThemeRule(
      mode: TagMatchMode.all,
      include: ['family', 'travel'],
      exclude: ['work'],
    );
    final any = ThemeRule(
      mode: TagMatchMode.any,
      include: ['family', 'travel'],
      exclude: ['work'],
    );
    expect(all.matches({'family', 'travel'}), isTrue);
    expect(all.matches({'travel'}), isFalse);
    expect(any.matches({'travel'}), isTrue);
    expect(any.matches({}), isFalse);
    expect(all.matches({'family', 'travel', 'work'}), isFalse);
    expect(any.matches({'family', 'work'}), isFalse);
  });
  test('拒絕空納入、交錯標籤與未知規則', () {
    expect(
      () => ThemeRule(mode: TagMatchMode.all, include: []),
      throwsFormatException,
    );
    expect(
      () => ThemeRule(mode: TagMatchMode.all, include: ['a'], exclude: ['a']),
      throwsFormatException,
    );
    expect(
      () => ThemeRule.decode(
        '{"mode":"all","include":["a"],"exclude":[],"extra":true}',
      ),
      throwsFormatException,
    );
    expect(
      () => ThemeRule.decode('{"mode":"bad","include":["a"],"exclude":[]}'),
      throwsArgumentError,
    );
  });
  test('規則保存與標籤 ID 重連保持條件，不修改原規則', () {
    final rule = ThemeRule(
      mode: TagMatchMode.any,
      include: ['b', 'a'],
      exclude: ['c'],
    );
    expect(ThemeRule.decode(rule.encode()).encode(), rule.encode());
    final mapped = rule.remap({'a': 'x', 'c': 'z'});
    expect(mapped.include, {'b', 'x'});
    expect(mapped.exclude, {'z'});
    expect(rule.include, {'a', 'b'});
  });
}
