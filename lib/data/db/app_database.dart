import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// 本機 SQLite 資料庫（企劃書第 8、10 節）。
@DriftDatabase(
  tables: [
    Subjects,
    Authors,
    ArchiveSettings,
    ArchiveSessions,
    Events,
    EventSections,
    LifePeriods,
    Reflections,
    Stories,
    StoryEvents,
    Blobs,
    Attachments,
    Tags,
    EventTags,
    Places,
    People,
    EventPeople,
    EventLinks,
    ChangeHistory,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// 開啟裝置上的資料庫，存放於持久性的 Application Support 目錄
  /// （企劃書 7.5：不得使用快取或暫存目錄）。
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'life_chronicle',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    ),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      for (final statement in schemaStatements) {
        await customStatement(statement);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// drift 無法直接宣告的結構：層級觸發器與全文索引。
final List<String> schemaStatements = [
  for (final table in layeredTables) ...layerTriggers(table),
  _authorSelfFlagTrigger,
  // 全文索引（T11 使用）。中文斷詞方式於 T11 實作時決定，內容由資料層寫入。
  "CREATE VIRTUAL TABLE search_index USING fts5("
      "entity_type UNINDEXED, entity_id UNINDEXED, content, "
      "tokenize = 'unicode61')",
];

/// 單一內容表的層級觸發器（企劃書 9.2、第 10 節）。
List<String> layerTriggers(String table) => [
  // 層級建立後不可變更：拒絕任何對 layer 的 UPDATE
  'CREATE TRIGGER ${table}_layer_immutable '
      'BEFORE UPDATE OF layer ON $table '
      "BEGIN SELECT RAISE(ABORT, '層級建立後不可變更'); END",
  // 後續追憶層內容的作者不得為主角本人
  'CREATE TRIGGER ${table}_remembrance_author_insert '
      'BEFORE INSERT ON $table '
      "WHEN NEW.layer = 'remembrance' AND EXISTS ("
      'SELECT 1 FROM authors WHERE id = NEW.author_id AND is_subject_self = 1) '
      "BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END",
  'CREATE TRIGGER ${table}_remembrance_author_update '
      'BEFORE UPDATE OF author_id ON $table '
      "WHEN NEW.layer = 'remembrance' AND EXISTS ("
      'SELECT 1 FROM authors WHERE id = NEW.author_id AND is_subject_self = 1) '
      "BEGIN SELECT RAISE(ABORT, '後續追憶層內容的作者不得為主角本人'); END",
];

/// 已撰寫後續追憶的作者，不可改標記為主角本人。
final String _authorSelfFlagTrigger =
    'CREATE TRIGGER authors_self_flag_guard '
    'BEFORE UPDATE OF is_subject_self ON authors '
    'WHEN NEW.is_subject_self = 1 AND ('
    '${layeredTables.map((t) => "EXISTS (SELECT 1 FROM $t WHERE author_id = NEW.id AND layer = 'remembrance')").join(' OR ')}'
    ') '
    "BEGIN SELECT RAISE(ABORT, '此作者已撰寫後續追憶，不可標記為主角本人'); END";
