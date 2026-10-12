import 'dart:io';

import 'package:drift/native.dart';

import 'package:life_chronicle/data/db/app_database.dart';

/// 從全新記憶體資料庫匯出結構；不開啟使用者的資料庫、不匯出任何紀錄。
Future<void> exportSchema() async {
  if (!File('pubspec.yaml').existsSync() ||
      !File('lib/data/db/tables.dart').existsSync()) {
    throw StateError('請從 life_chronicle 專案根目錄執行匯出指令');
  }
  final db = AppDatabase(NativeDatabase.memory());
  var sourceClosed = false;
  try {
    final names = [
      ...db.allTables.map((table) => table.actualTableName),
      'search_index',
    ];
    final schema = await db
        .customSelect(
          "SELECT type, name, tbl_name, sql FROM sqlite_schema WHERE sql IS NOT NULL "
          "AND name NOT LIKE 'sqlite_%' ORDER BY type, name",
        )
        .get();
    final statements = schema
        .where((row) => names.contains(row.read<String>('tbl_name')))
        .toList();
    final output = Directory('docs/database');
    await output.create(recursive: true);
    final diagram = StringBuffer()
      ..writeln(
        '// 人生編年史 Life Chronicle：APP 實際 SQLite schema v${db.schemaVersion}',
      )
      ..writeln('// 產生指令：flutter test tools/db_schema/export_test.dart')
      ..writeln('// 全選本檔內容，貼到 https://dbdiagram.io/ 的左側 DBML 編輯器。')
      ..writeln('// 不包含使用者資料；SQLite 自動產生的 FTS5 輔助表與內部表不另畫出。')
      ..writeln('Project life_chronicle {')
      ..writeln("  database_type: 'SQLite'")
      ..writeln(
        '  Note: ${quote('人生編年史／Life Chronicle；schema v${db.schemaVersion}。20 張業務資料表與 1 張 FTS5 虛擬表。欄位使用 SQLite 實際型別：時間戳記為 TEXT（ISO 8601；build.yaml 已啟用文字儲存），時間值 JSON 與排序日期為 TEXT。層級建立後不可修改，追憶作者不得為本人，相關觸發器見同目錄 life_chronicle.sql。')}',
      )
      ..writeln('}')
      ..writeln();
    var foreignKeyCount = 0;
    for (final name in names) {
      final sql = statements
          .singleWhere(
            (row) =>
                row.read<String>('type') == 'table' &&
                row.read<String>('name') == name,
          )
          .read<String>('sql');
      final columns = await db.customSelect('PRAGMA table_info("$name")').get();
      final foreignKeys = await db
          .customSelect('PRAGMA foreign_key_list("$name")')
          .get();
      final indices = await db.customSelect('PRAGMA index_list("$name")').get();
      final primary =
          columns.where((column) => column.read<int>('pk') > 0).toList()
            ..sort((a, b) => a.read<int>('pk').compareTo(b.read<int>('pk')));
      final unique = <String>{};
      final indexLines = <String>[];
      for (final index in indices) {
        final indexName = index.read<String>('name');
        if (index.read<String>('origin') == 'pk') continue;
        final fields = await db
            .customSelect('PRAGMA index_info("$indexName")')
            .get();
        final indexedNames = fields
            .map((field) => field.read<String>('name'))
            .toList();
        if (index.read<int>('unique') == 1 && indexedNames.length == 1) {
          unique.add(indexedNames.single);
        } else {
          final fieldList = indexedNames.length == 1
              ? indexedNames.single
              : '(${indexedNames.join(', ')})';
          indexLines.add(
            '    $fieldList [name: ${quote(indexName)}${index.read<int>('unique') == 1 ? ', unique' : ''}]',
          );
        }
      }
      diagram.writeln('Table $name {');
      diagram.writeln('  Note: ${quote(tableNotes[name] ?? name)}');
      for (final column in columns) {
        final columnName = column.read<String>('name');
        final type = column.read<String>('type').toLowerCase();
        final isPrimary = column.read<int>('pk') > 0;
        final settings = <String>[
          if (column.read<int>('notnull') == 1 || isPrimary)
            'not null'
          else
            'null',
          if (isPrimary && primary.length == 1) 'pk',
          if (isPrimary && sql.contains('AUTOINCREMENT')) 'increment',
          if (unique.contains(columnName)) 'unique',
        ];
        final defaultValue = column.readNullable<String>('dflt_value');
        if (defaultValue != null) settings.add('default: `$defaultValue`');
        final key = foreignKeys
            .where((key) => key.read<String>('from') == columnName)
            .firstOrNull;
        if (key != null) {
          final relation = isPrimary && primary.length == 1 ? '-' : '>';
          settings.add(
            'ref: $relation ${key.read<String>('table')}.${key.read<String>('to')}',
          );
          foreignKeyCount++;
        }
        final note =
            fieldNotes['$name.$columnName'] ??
            (isPrimary && primary.length == 1
                ? commonNotes['id']
                : commonNotes[columnName]);
        if (note != null) settings.add('note: ${quote(note)}');
        diagram.writeln(
          '  $columnName ${type.isEmpty ? 'text' : type} [${settings.join(', ')}]',
        );
      }
      if (primary.length > 1 || indexLines.isNotEmpty) {
        diagram.writeln('  indexes {');
        if (primary.length > 1) {
          diagram.writeln(
            '    (${primary.map((column) => column.read<String>('name')).join(', ')}) [pk]',
          );
        }
        indexLines.forEach(diagram.writeln);
        diagram.writeln('  }');
      }
      final constraints = checks(sql);
      if (constraints.isNotEmpty) {
        diagram.writeln('  checks {');
        for (final constraint in constraints) {
          diagram.writeln('    `$constraint`');
        }
        diagram.writeln('  }');
      }
      diagram
        ..writeln('}')
        ..writeln();
    }
    final dbmlFile = File('${output.path}/life_chronicle.dbml');
    await dbmlFile.writeAsString('${diagram.toString().trimRight()}\n');
    final sqlFile = File('${output.path}/life_chronicle.sql');
    final ddl = StringBuffer()
      ..writeln('-- 人生編年史 Life Chronicle：空白 SQLite schema v${db.schemaVersion}')
      ..writeln('-- 由實際 APP schema 產生；含 CHECK、索引、FTS5 與層級觸發器。')
      ..writeln('-- 只能用於新建空白資料庫，不是既有資料庫的遷移腳本。')
      ..writeln('PRAGMA foreign_keys = ON;')
      ..writeln('BEGIN TRANSACTION;');
    for (final type in ['table', 'index', 'trigger']) {
      for (final row in statements.where(
        (row) => row.read<String>('type') == type,
      )) {
        ddl
          ..writeln()
          ..writeln('${row.read<String>('sql')};');
      }
    }
    ddl
      ..writeln()
      ..writeln('PRAGMA user_version = ${db.schemaVersion};')
      ..writeln('COMMIT;');
    await sqlFile.writeAsString(ddl.toString());
    // 用另一個空白資料庫驗證 SQL 可以重建全部結構與觸發器。
    await db.close();
    sourceClosed = true;
    final rebuilt = AppDatabase(NativeDatabase.memory());
    try {
      await rebuilt.customSelect('SELECT 1').get();
      for (final row
          in (await rebuilt
              .customSelect(
                "SELECT name FROM sqlite_schema WHERE type = 'trigger'",
              )
              .get())) {
        await rebuilt.customStatement(
          'DROP TRIGGER "${row.read<String>('name')}"',
        );
      }
      await rebuilt.customStatement('PRAGMA foreign_keys = OFF');
      await rebuilt.customStatement('DROP TABLE search_index');
      for (final name
          in names.where((name) => name != 'search_index').toList().reversed) {
        await rebuilt.customStatement('DROP TABLE "$name"');
      }
      await rebuilt.customStatement(ddl.toString());
      final actual = await rebuilt
          .customSelect(
            "SELECT type, name, sql FROM sqlite_schema WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      for (final row in statements) {
        final found = actual.singleWhere(
          (actual) => actual.read<String>('name') == row.read<String>('name'),
        );
        if (found.read<String>('sql') != row.read<String>('sql')) {
          throw StateError('重建結構不一致：${row.read<String>('name')}');
        }
      }
    } finally {
      await rebuilt.close();
    }
    stdout.writeln(
      '已產生 ${dbmlFile.path} 與 ${sqlFile.path}；${names.length} 張表、$foreignKeyCount 個外鍵；SQL 重建驗證通過。',
    );
  } finally {
    if (!sourceClosed) await db.close();
  }
}

String quote(String value) =>
    "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll('\n', r'\n')}'";

/// 讀取 CHECK 的括號區間；忽略 SQL 字串中的括號與跳脫單引號。
List<String> checks(String sql) {
  final result = <String>[];
  for (final match in RegExp(
    r'\bCHECK\s*\(',
    caseSensitive: false,
  ).allMatches(sql)) {
    var depth = 1;
    var quoted = false;
    var end = match.end;
    for (; end < sql.length; end++) {
      final char = sql[end];
      if (char == "'") {
        if (quoted && end + 1 < sql.length && sql[end + 1] == "'") {
          end++;
          continue;
        }
        quoted = !quoted;
      } else if (!quoted) {
        if (char == '(') depth++;
        if (char == ')' && --depth == 0) break;
      }
    }
    if (depth != 0) throw StateError('CHECK 括號不完整');
    result.add(sql.substring(match.end, end));
  }
  return result;
}

const tableNotes = <String, String>{
  'subjects': '生命檔案主角；生日與死亡日期以時間值 JSON 保存。',
  'authors': '作者（本人或家人），與生命檔案主角、參與人物分開。本人作者名稱可為空，由介面顯示「我」。',
  'archive_settings': '每位主角最多一筆目前典藏狀態，透過 subject_id 與主角一對一對應。',
  'archive_sessions': '每段生命典藏期間及啟用／停用操作者。',
  'events': '人生節點。年份依 sort_start 分組；雙向排序由純 Dart 唯一比較器完成，不能用 SQL 排序取代。',
  'event_sections': '可自訂標題與順序的記述段落；不是固定的起因／經過／結果欄位。',
  'life_periods': '求學、任職等人生階段的起訖區間。',
  'event_life_periods':
      '事件與人生階段的明確多對多連結；只按連結篩選，不以時間重疊推斷。相同主角檢查在 Repository 執行。',
  'reflections': '日後回顧與後續追憶；Repository 採追加，保存各自作者及時間。',
  'stories': '紀事本末篇章，以 story_events 引用既有事件，不重複保存事件本體。',
  'story_events': '篇章與事件的多對多對照；position 為企劃書 order 欄位的實際 SQL 名稱。',
  'blobs': '單一實體檔案，以完整 SHA-256 去重；多個附件可共用同一 blob。',
  'attachments': '事件的附件引用，區分拍攝時間與匯入時間，並保存原檔名與可取得的 EXIF 座標。',
  'places': '共用地點，不分層級；名稱或座標至少有一個。名稱正規化後唯一。',
  'people': '事件中的參與人物，與作者不同；共用參考資料，不分層級。',
  'event_people': '事件與參與人物的多對多對照，對照本身保有層級與作者。',
  'event_links': '無方向的事件關聯；每對只存一列，以 event_a_id < event_b_id 排除反向重複及自我關聯。',
  'tags': '共用標籤；標籤文字唯一。',
  'event_tags': '事件與標籤的多對多對照，對照本身保有層級與作者。',
  'change_history': '修訂來源紀錄。entity_id 為多型實體識別碼，沒有單一資料表外鍵。第一階段不實作清除機制。',
  'search_index': 'SQLite FTS5 虛擬表，tokenize=unicode61；entity_type、entity_id 設為 UNINDEXED。本圖僅呈現三個邏輯欄位，不是一般 CREATE TABLE，也不呈現 FTS5 自動產生的輔助表。',
};

const commonNotes = <String, String>{
  'id': '識別碼；除自增修訂流水號外，APP 以 26 字元 ULID 產生。SQLite 本身未限制字元長度。',
  'layer': 'original＝原始生命紀錄層；remembrance＝後續追憶層。由 Repository 在建立時判定；資料庫觸發器禁止任何 UPDATE layer。',
  'author_id': '內容作者；觸發器拒絕後續追憶使用 is_subject_self=1 的作者。',
  'created_at': '建立紀錄時間，UTC ISO 8601 文字（TEXT）（Drift DateTime 的 SQLite 儲存型別）。',
  'archive_session_id': 'original 必須為 NULL；remembrance 必須指向建立時的典藏期間。',
  'name_key': '比對用正規化名稱：忽略台／臺、全半形與空白，唯一。',
  'position': '使用者指定的內容順序。',
};

const fieldNotes = <String, String>{
  'archive_settings.subject_id': '主角外鍵，同時為本表主鍵；每位主角最多一筆設定。',
  'change_history.change_history_id':
      '自增的修訂流水號，INTEGER PRIMARY KEY AUTOINCREMENT。',
  'change_history.author_id': '修訂操作者，指向作者；本表不具有 layer 欄位。',
  'subjects.display_name': '主角名稱；首次建立可為空。',
  'subjects.birth_date': '生日時間值 JSON，不補造未輸入的月日。',
  'subjects.death_date': '選填的死亡日期時間值 JSON。',
  'authors.is_subject_self': 'SQLite INTEGER 布林值：0＝否、1＝本人；作者若已撰寫追憶，觸發器不允許改為本人。',
  'archive_settings.mode': 'normal＝一般模式；life_archive＝生命典藏模式。',
  'events.time_payload': '時間值 JSON：day、month、quarter、half_year、year、approx_year、range、relative、age_estimate、unknown；由 Dart 核心邏輯驗證。',
  'events.sort_start': '供排序及年份分段查詢的衍生 TEXT 日期 YYYY-MM-DD；不是顯示用的確定發生日期。',
  'events.sort_end': '衍生排序區間終點 TEXT 日期 YYYY-MM-DD；時間未定時為 NULL。',
  'events.manual_order': '同一天多件事的手動順序；方向切換由唯一比較器處理。',
  'events.privacy': 'normal＝一般；private＝私密。',
  'events.deleted_at': '軟刪除時間 UTC ISO 8601 文字（TEXT）；一般查詢預設排除，最近刪除可復原。',
  'events.purged_at': '永久刪除但保留標題供追憶依附的時間；必須已有 deleted_at。',
  'event_sections.title': 'NULL 為未命名的記述段落。',
  'event_sections.suggestion_key': '記錄建議項目的來源；自訂段落為 NULL。',
  'blobs.sha256': '完整 SHA-256 雜湊；SQLite 未另外限制字元長度。',
  'attachments.captured_at':
      '可取得的拍攝／內容時間 UTC ISO 8601 文字（TEXT），與 imported_at 分開。',
  'attachments.imported_at': '加入 APP 的時間 UTC ISO 8601 文字（TEXT）。',
  'places.radius_m': '地點範圍或定位精確度的半徑，單位公尺；存在時須大於 0 且有座標。',
  'change_history.entity_id': '可能指向不同類型的實體，因此未宣告外鍵。',
  'change_history.timestamp': '修訂時間 UTC ISO 8601 文字（TEXT）。',
  'search_index.entity_type': '多型資料來源類型；UNINDEXED，不建立實體表外鍵。',
  'search_index.entity_id': '多型資料來源識別碼；UNINDEXED，不建立實體表外鍵。',
};
