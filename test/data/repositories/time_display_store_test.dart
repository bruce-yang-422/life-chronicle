import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/data/repositories/time_display_store.dart';

void main() {
  test('時區設定重開仍保留，無設定跟隨手機，拒絕無效值', () async {
    final directory = await Directory.systemTemp.createTemp('time-display-');
    try {
      final file = File('${directory.path}/time_display.json');
      final store = FileTimeDisplayStore(file);
      expect(await store.load(), 'system');
      await store.save('Asia/Taipei');
      expect(await FileTimeDisplayStore(file).load(), 'Asia/Taipei');
      await expectLater(store.save('invalid'), throwsArgumentError);
      expect(await store.load(), 'Asia/Taipei');
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
