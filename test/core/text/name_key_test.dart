import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/text/name_key.dart';

void main() {
  test('台／臺視為相同（驗收 #33）', () {
    expect(NameKey.of('臺北市'), NameKey.of('台北市'));
  });

  test('忽略空白與全形空白', () {
    expect(NameKey.of(' 台北 市 '), '台北市');
    expect(NameKey.of('台北　市'), '台北市');
  });

  test('全形英數轉半形並轉小寫', () {
    expect(NameKey.of('ＡＢＣ　１０１'), 'abc101');
    expect(NameKey.of('Taipei 101'), 'taipei101');
  });

  test('相近但不同的名稱不視為相同', () {
    expect(NameKey.of('台北'), isNot(NameKey.of('臺北市')));
  });

  test('只有空白時為 null', () {
    expect(NameKey.of('   '), isNull);
    expect(NameKey.of('　'), isNull);
    expect(NameKey.displayName('  '), isNull);
    expect(NameKey.displayName(' 臺北市 '), '臺北市');
  });
}
