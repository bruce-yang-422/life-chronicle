import 'package:drift/drift.dart';

// 資料表定義（企劃書第 10 節）。
//
// 第一階段用不到的資料表也先建立，避免日後遷移。
// 欄位名稱以 snake_case 對應到 SQL（見 build.yaml）。

/// 層級代號（企劃書第 9 節）：原始生命紀錄層、後續追憶層。
abstract final class Layer {
  static const original = 'original';
  static const remembrance = 'remembrance';
}

/// 典藏模式代號：一般模式、生命典藏模式。
abstract final class ArchiveMode {
  static const normal = 'normal';
  static const lifeArchive = 'life_archive';
}

/// 層級與 archive_session_id 必須一致：
/// 原始生命紀錄層不屬於任何典藏期間；後續追憶層必須指向建立時的典藏期間。
const _layerCheck =
    "CHECK ((layer = 'original' AND archive_session_id IS NULL) OR "
    "(layer = 'remembrance' AND archive_session_id IS NOT NULL))";

/// 所有內容表共用的層級欄位（企劃書第 10 節）。
///
/// `layer` 由資料存取層在建立時寫入，之後禁止更新（以觸發器拒絕）。
mixin LayerColumns on Table {
  TextColumn get layer => text()();
  TextColumn get authorId => text().references(Authors, #id)();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get archiveSessionId =>
      text().nullable().references(ArchiveSessions, #id)();
}

/// 生命檔案主角。
class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();

  /// 生日，以時間值 JSON 保存（精確日期、年月或年份）。
  TextColumn get birthDate => text().nullable()();

  /// 死亡日期（選填），格式同 [birthDate]。
  TextColumn get deathDate => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 作者：本人或家人，與主角分離。
class Authors extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text()();
  TextColumn get role => text()();

  /// 是否為主角本人。後續追憶層內容的作者不得為本人。
  BoolColumn get isSubjectSelf =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// 目前典藏狀態（每位主角一筆）。
class ArchiveSettings extends Table {
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get mode =>
      text().withDefault(const Constant(ArchiveMode.normal))();
  TextColumn get currentSessionId =>
      text().nullable().references(ArchiveSessions, #id)();

  @override
  Set<Column> get primaryKey => {subjectId};

  @override
  List<String> get customConstraints => [
    "CHECK (mode IN ('${ArchiveMode.normal}', '${ArchiveMode.lifeArchive}'))",
  ];
}

/// 每段生命典藏期間。
class ArchiveSessions extends Table {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  DateTimeColumn get activatedAt => dateTime()();
  @ReferenceName('activatedArchiveSessions')
  TextColumn get activatedBy => text().references(Authors, #id)();
  DateTimeColumn get deactivatedAt => dateTime().nullable()();
  @ReferenceName('deactivatedArchiveSessions')
  TextColumn get deactivatedBy => text().nullable().references(Authors, #id)();

  @override
  Set<Column> get primaryKey => {id};
}

/// 人生節點。
@TableIndex(name: 'events_sort_start', columns: {#sortStart})
@TableIndex(name: 'events_sort_end', columns: {#sortEnd})
class Events extends Table with LayerColumns {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get title => text()();
  TextColumn get category => text().nullable()();

  /// 時間值 JSON（企劃書第 5 節）。
  TextColumn get timePayload => text()();

  /// 排序區間（`YYYY-MM-DD`，依企劃書 5.1 換算）；時間未定時為 null。
  TextColumn get sortStart => text().nullable()();
  TextColumn get sortEnd => text().nullable()();

  IntColumn get manualOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [_layerCheck];
}

/// 記述段落：使用者自由組成（企劃書 4.2）。
class EventSections extends Table with LayerColumns {
  TextColumn get id => text()();
  TextColumn get eventId => text().references(Events, #id)();

  /// 顯示標題；未命名的「記述」可為 null。
  TextColumn get title => text().nullable()();

  /// 來自哪個建議項目；自訂段落為 null。
  TextColumn get suggestionKey => text().nullable()();
  IntColumn get position => integer()();
  TextColumn get contentMd => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [_layerCheck];
}

/// 求學、任職等區間。
class LifePeriods extends Table with LayerColumns {
  TextColumn get id => text()();
  TextColumn get subjectId => text().references(Subjects, #id)();
  TextColumn get type => text()();

  /// 起訖時間，以時間值 JSON 保存。
  TextColumn get startTime => text()();
  TextColumn get endTime => text().nullable()();
  TextColumn get organization => text().nullable()();
  TextColumn get role => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [_layerCheck];
}

/// 多次回顧與後續追憶（只能追加）。
class Reflections extends Table with LayerColumns {
  TextColumn get id => text()();
  TextColumn get eventId => text().references(Events, #id)();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get contentMd => text()();
  TextColumn get provenance => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [_layerCheck];
}

/// 紀事本末篇章。
class Stories extends Table with LayerColumns {
  TextColumn get id => text()();
  TextColumn get title => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [_layerCheck];
}

/// 篇章引用的事件與順序。
class StoryEvents extends Table {
  TextColumn get storyId => text().references(Stories, #id)();
  TextColumn get eventId => text().references(Events, #id)();

  /// 企劃書的 `order`（SQL 保留字，改名為 position）。
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {storyId, eventId};
}

/// 單一實體檔案（以 SHA-256 去重）。
class Blobs extends Table {
  TextColumn get id => text()();
  TextColumn get sha256 => text().unique()();
  IntColumn get byteSize => integer()();
  TextColumn get mediaType => text()();
  TextColumn get path => text()();
  TextColumn get verifyStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// 附件引用：多個事件可共用同一個 blob。
class Attachments extends Table with LayerColumns {
  TextColumn get id => text()();
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get blobId => text().references(Blobs, #id)();
  TextColumn get displayName => text()();
  TextColumn get originalFilename => text()();
  TextColumn get role => text().nullable()();

  /// 拍攝或內容時間（可取得時）。
  DateTimeColumn get capturedAt => dateTime().nullable()();
  DateTimeColumn get importedAt => dateTime()();
  TextColumn get storageMode => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [_layerCheck];
}

class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get label => text().unique()();

  @override
  Set<Column> get primaryKey => {id};
}

class EventTags extends Table with LayerColumns {
  TextColumn get eventId => text().references(Events, #id)();
  TextColumn get tagId => text().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {eventId, tagId};

  @override
  List<String> get customConstraints => [_layerCheck];
}

/// 修訂來源紀錄。第一階段只記錄，不實作清除機制（保存期限待決策）。
class ChangeHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()();
  TextColumn get authorId => text().references(Authors, #id)();
  DateTimeColumn get timestamp => dateTime()();
}

/// 含層級欄位的內容表（觸發器套用對象）。
const layeredTables = [
  'events',
  'event_sections',
  'life_periods',
  'reflections',
  'stories',
  'attachments',
  'event_tags',
];
