import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/photo_compression.dart';

void main() {
  test('三種尺寸檔位皆等比例，短邊四捨五入', () {
    expect(PhotoCompressionPolicy.dimensions(6000, 4000, PhotoPreset.high), (
      width: 4096,
      height: 2731,
    ));
    expect(
      PhotoCompressionPolicy.dimensions(4000, 6000, PhotoPreset.standard),
      (width: 2048, height: 3072),
    );
    expect(PhotoCompressionPolicy.dimensions(3000, 1000, PhotoPreset.compact), (
      width: 2048,
      height: 683,
    ));
  });
  test('不放大，小於一像素的短邊仍保留一像素', () {
    expect(PhotoCompressionPolicy.dimensions(1024, 768, PhotoPreset.standard), (
      width: 1024,
      height: 768,
    ));
    expect(PhotoCompressionPolicy.dimensions(50000, 1, PhotoPreset.compact), (
      width: 2048,
      height: 1,
    ));
    expect(
      () => PhotoCompressionPolicy.dimensions(0, 10, PhotoPreset.high),
      throwsArgumentError,
    );
  });
}
