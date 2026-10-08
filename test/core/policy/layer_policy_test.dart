import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/policy/layer_policy.dart';

/// 企劃書 9.3 操作權限矩陣：每一格各一個測試。
void main() {
  const normal = ArchiveState.normal;
  const archive = ArchiveState.lifeArchive;
  const original = ContentLayer.original;
  const remembrance = ContentLayer.remembrance;

  group('新增內容的層級只看典藏狀態', () {
    test('一般模式 → original', () {
      expect(LayerPolicy.layerForNewContent(normal), original);
    });
    test('生命典藏模式 → remembrance', () {
      expect(LayerPolicy.layerForNewContent(archive), remembrance);
    });
  });

  group('修改／刪除 original 內容', () {
    test('一般模式：可', () {
      expect(LayerPolicy.canModify(original, normal), isTrue);
    });
    test('生命典藏模式：不可（唯讀）', () {
      expect(LayerPolicy.canModify(original, archive), isFalse);
      expect(
        () => LayerPolicy.ensureCanModify(original, archive),
        throwsA(
          isA<PermissionDeniedException>().having(
            (e) => e.reason,
            'reason',
            PermissionDeniedReason.originalIsReadOnly,
          ),
        ),
      );
    });
  });

  group('修改／刪除 remembrance 內容', () {
    test('一般模式：可', () {
      expect(LayerPolicy.canModify(remembrance, normal), isTrue);
    });
    test('生命典藏模式：可', () {
      expect(LayerPolicy.canModify(remembrance, archive), isTrue);
    });
  });

  group('作者設為主角本人', () {
    test('original：可', () {
      expect(LayerPolicy.canAuthor(original, authorIsSubject: true), isTrue);
    });
    test('remembrance：不可', () {
      expect(
        LayerPolicy.canAuthor(remembrance, authorIsSubject: true),
        isFalse,
      );
      expect(
        () => LayerPolicy.ensureCanAuthor(remembrance, authorIsSubject: true),
        throwsA(isA<PermissionDeniedException>()),
      );
    });
    test('家人作者在兩層皆可', () {
      for (final layer in ContentLayer.values) {
        expect(LayerPolicy.canAuthor(layer, authorIsSubject: false), isTrue);
      }
    });
  });
}
