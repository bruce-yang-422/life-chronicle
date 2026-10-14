import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/text/search_tokens.dart';

void main() {
  test('中文、代理對 Unicode 與混合語言字元不被拆壞', () {
    final tokens = SearchTokens.of('大學😀Project');
    expect(tokens, contains('u1f600'));
    expect(tokens, containsAll(SearchTokens.of('大學')));
    expect(tokens, containsAll(SearchTokens.of('project')));
    expect(SearchTokens.match('" OR *'), isNot(contains('" OR ')));
  });
}
