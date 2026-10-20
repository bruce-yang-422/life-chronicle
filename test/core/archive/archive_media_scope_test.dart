import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/archive/archive_media_scope.dart';

void main() {
  test('完整、不含媒體與自訂範圍明確區分排除原因', () {
    final all = ArchiveMediaScope();
    expect(all.type, 'full');
    expect(all.reasonFor('a'), isNull);
    final selected = ArchiveMediaScope(excludedBlobIds: {'a'});
    expect(selected.type, 'custom');
    expect(selected.reasonFor('a'), 'user_excluded');
    expect(selected.reasonFor('b'), isNull);
    final none = ArchiveMediaScope(includeMedia: false, excludedBlobIds: {'a'});
    expect(none.type, 'no_media');
    expect(none.reasonFor('a'), 'no_media');
    expect(none.reasonFor('b'), 'no_media');
    final private = ArchiveMediaScope(excludePrivateEvents: true);
    expect(private.type, 'custom');
    expect(private.reasonFor('shared'), isNull);
    final privateNoMedia = ArchiveMediaScope(
      excludePrivateEvents: true,
      includeMedia: false,
    );
    expect(privateNoMedia.type, 'custom');
    expect(privateNoMedia.reasonFor('shared'), 'no_media');
  });

  test('提交選擇後不受外部集合變動影響', () {
    final ids = {'a'};
    final scope = ArchiveMediaScope(excludedBlobIds: ids);
    ids.clear();
    expect(scope.reasonFor('a'), 'user_excluded');
    expect(() => scope.excludedBlobIds.clear(), throwsUnsupportedError);
  });
}
