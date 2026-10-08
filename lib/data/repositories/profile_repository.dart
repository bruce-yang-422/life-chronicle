import 'package:drift/drift.dart';

import '../../core/ids/ulid.dart';
import '../db/app_database.dart';
import '../db/tables.dart';

/// 生命檔案主角與其本人作者。
class Profile {
  const Profile({required this.subjectId, required this.selfAuthorId});

  final String subjectId;
  final String selfAuthorId;
}

/// 主角、作者與典藏狀態的管理。
class ProfileRepository {
  ProfileRepository(this.db, {DateTime Function()? clock, UlidGenerator? ids})
    : _clock = clock ?? DateTime.now,
      _ids = ids ?? UlidGenerator();

  final AppDatabase db;
  final DateTime Function() _clock;
  final UlidGenerator _ids;

  /// 第一階段只有一位主角：不存在時建立主角、本人作者與典藏設定。
  ///
  /// 名稱先留空，由介面顯示為「我」，日後可在設定中修改。
  Future<Profile> ensureDefaultProfile() => db.transaction(() async {
    final subject = await (db.select(db.subjects)..limit(1)).getSingleOrNull();
    if (subject != null) {
      final self = await (db.select(
        db.authors,
      )..where((a) => a.isSubjectSelf.equals(true))).getSingle();
      return Profile(subjectId: subject.id, selfAuthorId: self.id);
    }
    final subjectId = _ids.next();
    final authorId = _ids.next();
    await db
        .into(db.subjects)
        .insert(SubjectsCompanion.insert(id: subjectId, displayName: ''));
    await db
        .into(db.authors)
        .insert(
          AuthorsCompanion.insert(
            id: authorId,
            displayName: '',
            role: AuthorRole.self,
            isSubjectSelf: const Value(true),
          ),
        );
    await db
        .into(db.archiveSettings)
        .insert(ArchiveSettingsCompanion.insert(subjectId: subjectId));
    return Profile(subjectId: subjectId, selfAuthorId: authorId);
  });

  /// 新增作者（家人等）。
  Future<String> addAuthor(String displayName, {required String role}) async {
    final id = _ids.next();
    await db
        .into(db.authors)
        .insert(
          AuthorsCompanion.insert(
            id: id,
            displayName: displayName.trim(),
            role: role,
          ),
        );
    return id;
  }

  /// 啟用生命典藏：建立新的典藏期間（企劃書 9.4）。
  Future<String> activateLifeArchive(
    String subjectId, {
    required String byAuthorId,
  }) => db.transaction(() async {
    final settings = await _settings(subjectId);
    if (settings.mode == ArchiveMode.lifeArchive) {
      return settings.currentSessionId!;
    }
    final sessionId = _ids.next();
    await db
        .into(db.archiveSessions)
        .insert(
          ArchiveSessionsCompanion.insert(
            id: sessionId,
            subjectId: subjectId,
            activatedAt: _clock().toUtc(),
            activatedBy: byAuthorId,
          ),
        );
    await (db.update(
      db.archiveSettings,
    )..where((s) => s.subjectId.equals(subjectId))).write(
      ArchiveSettingsCompanion(
        mode: const Value(ArchiveMode.lifeArchive),
        currentSessionId: Value(sessionId),
      ),
    );
    return sessionId;
  });

  /// 解除生命典藏：結束目前典藏期間；後續追憶層內容維持原層級（企劃書 9.4）。
  Future<void> deactivateLifeArchive(
    String subjectId, {
    required String byAuthorId,
  }) => db.transaction(() async {
    final settings = await _settings(subjectId);
    final sessionId = settings.currentSessionId;
    if (settings.mode != ArchiveMode.lifeArchive || sessionId == null) return;
    await (db.update(
      db.archiveSessions,
    )..where((s) => s.id.equals(sessionId))).write(
      ArchiveSessionsCompanion(
        deactivatedAt: Value(_clock().toUtc()),
        deactivatedBy: Value(byAuthorId),
      ),
    );
    await (db.update(
      db.archiveSettings,
    )..where((s) => s.subjectId.equals(subjectId))).write(
      const ArchiveSettingsCompanion(
        mode: Value(ArchiveMode.normal),
        currentSessionId: Value(null),
      ),
    );
  });

  Future<ArchiveSetting> _settings(String subjectId) => (db.select(
    db.archiveSettings,
  )..where((s) => s.subjectId.equals(subjectId))).getSingle();
}

/// 作者角色代號。
abstract final class AuthorRole {
  static const self = 'self';
  static const family = 'family';
}
