import 'package:flutter_test/flutter_test.dart';

import 'export.dart';

/// AppDatabase 連線工廠包含 Flutter 平台介面，因此以 Flutter 執行環境匯出。
void main() {
  test('匯出實際 schema 的 DBML 與 SQL，並驗證空白 SQLite 重建', exportSchema);
}
