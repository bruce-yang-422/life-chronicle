import 'package:drift/drift.dart';

import '../../core/ids/ulid.dart';
import '../../core/policy/layer_policy.dart';
import '../db/app_database.dart';
import '../db/tables.dart';

/// 新增內容時由資料存取層自動決定的層級欄位（企劃書第 10 節）。
class LayerStamp {
  const LayerStamp({
    required this.layer,
    required this.authorId,
    required this.createdAt,
    required this.archiveSessionId,
  });

  final ContentLayer layer;
  final String authorId;
  final DateTime createdAt;
  final String? archiveSessionId;

  String get layerCode => layerCodeOf(layer);
}

String layerCodeOf(ContentLayer layer) => switch (layer) {
  ContentLayer.original => Layer.original,
  ContentLayer.remembrance => Layer.remembrance,
};

ContentLayer layerFromCode(String code) => switch (code) {
  Layer.original => ContentLayer.original,
  Layer.remembrance => ContentLayer.remembrance,
  _ => throw StateError('未知的層級代號：$code'),
};

/// 各 repository 共用的執行環境：目前主角、操作者、時鐘與 ID 產生器。
///
/// 所有寫入都透過 [stampForNew] 取得層級，並以 [ensureCanModify] 檢查權限，
/// 呼叫端不得自行指定層級。
class RepositoryContext {
  RepositoryContext(
    this.db, {
    required this.subjectId,
    required this.actingAuthorId,
    DateTime Function()? clock,
    UlidGenerator? ids,
  }) : _clock = clock ?? DateTime.now,
       _ids = ids ?? UlidGenerator();

  final AppDatabase db;
  final String subjectId;

  /// 目前操作的作者（預設為主角本人）。
  final String actingAuthorId;
  final DateTime Function() _clock;
  final UlidGenerator _ids;

  DateTime now() => _clock().toUtc();

  String newId() => _ids.next();

  Future<ArchiveSetting> _settings() => (db.select(
    db.archiveSettings,
  )..where((s) => s.subjectId.equals(subjectId))).getSingle();

  Future<ArchiveState> archiveState() async =>
      (await _settings()).mode == ArchiveMode.lifeArchive
      ? ArchiveState.lifeArchive
      : ArchiveState.normal;

  /// 新增內容的層級欄位：依當下典藏狀態決定，並檢查作者是否允許。
  Future<LayerStamp> stampForNew({String? authorId}) async {
    final settings = await _settings();
    final state = settings.mode == ArchiveMode.lifeArchive
        ? ArchiveState.lifeArchive
        : ArchiveState.normal;
    final layer = LayerPolicy.layerForNewContent(state);
    final author = authorId ?? actingAuthorId;
    LayerPolicy.ensureCanAuthor(
      layer,
      authorIsSubject: await isSubjectSelf(author),
    );
    return LayerStamp(
      layer: layer,
      authorId: author,
      createdAt: now(),
      archiveSessionId: layer == ContentLayer.remembrance
          ? settings.currentSessionId
          : null,
    );
  }

  /// 檢查既有內容（以層級代號表示）是否可修改或刪除。
  Future<void> ensureCanModify(String layerCode) async {
    LayerPolicy.ensureCanModify(layerFromCode(layerCode), await archiveState());
  }

  Future<bool> isSubjectSelf(String authorId) async {
    final author = await (db.select(
      db.authors,
    )..where((a) => a.id.equals(authorId))).getSingleOrNull();
    return author?.isSubjectSelf ?? false;
  }

  /// 記錄修訂來源（企劃書第 10 節 change_history）。
  Future<void> recordChange(String entityId, String operation) => db
      .into(db.changeHistory)
      .insert(
        ChangeHistoryCompanion.insert(
          entityId: entityId,
          operation: operation,
          authorId: actingAuthorId,
          timestamp: now(),
        ),
      );
}

/// 修訂操作代號。
abstract final class ChangeOperation {
  static const create = 'create';
  static const update = 'update';
  static const delete = 'delete';
  static const restore = 'restore';
  static const purge = 'purge';
}

extension ValueOrAbsent<T> on Value<T> {
  /// 取出值；未提供時回傳 [fallback]。
  T or(T fallback) => present ? value : fallback;
}
