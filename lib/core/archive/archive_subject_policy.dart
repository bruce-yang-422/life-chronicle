import 'archive_reading.dart';

enum ArchiveSubjectFailure { invalidArchive, differentSubject }

class ArchiveSubjectException implements Exception {
  const ArchiveSubjectException(this.reason);
  final ArchiveSubjectFailure reason;
}

/// 第一階段只還原單一主角，不把不同主角的生命檔案合併。
abstract final class ArchiveSubjectPolicy {
  /// 回傳是否應在交易內取代 APP 自動產生、尚未填寫的初始主角。
  static bool replacesInitialProfile(ArchiveRows local, ArchiveRows incoming) {
    final subjects = incoming['subjects'] ?? const [];
    if (subjects.length != 1 ||
        subjects.single['subject_id'] is! String ||
        (subjects.single['subject_id'] as String).isEmpty ||
        (incoming['authors'] ?? const [])
                .where((row) => row['is_subject_self'] == true)
                .length !=
            1) {
      throw const ArchiveSubjectException(ArchiveSubjectFailure.invalidArchive);
    }
    final id = subjects.single['subject_id'];
    final settings = incoming['archive_settings'] ?? const [];
    if (settings.length != 1 ||
        settings.single['subject_id'] != id ||
        ['events', 'archive_sessions'].any(
          (name) => (incoming[name] ?? const []).any(
            (row) => row['subject_id'] != id,
          ),
        )) {
      throw const ArchiveSubjectException(ArchiveSubjectFailure.invalidArchive);
    }
    final existing = local['subjects'] ?? const [];
    if (existing.length == 1 && existing.single['subject_id'] == id) {
      return false;
    }
    if (local.values.every((rows) => rows.isEmpty)) return false;
    if (!_isInitialProfile(local)) {
      throw const ArchiveSubjectException(
        ArchiveSubjectFailure.differentSubject,
      );
    }
    return true;
  }

  static bool _isInitialProfile(ArchiveRows local) {
    for (final entry in local.entries) {
      if (!{'subjects', 'authors', 'archive_settings'}.contains(entry.key) &&
          entry.value.isNotEmpty) {
        return false;
      }
    }
    final subjects = local['subjects'] ?? const [];
    final authors = local['authors'] ?? const [];
    final settings = local['archive_settings'] ?? const [];
    return subjects.length == 1 &&
        subjects.single['display_name'] == '' &&
        subjects.single['birth_date'] == null &&
        subjects.single['death_date'] == null &&
        authors.length == 1 &&
        authors.single['display_name'] == '' &&
        authors.single['role'] == 'self' &&
        authors.single['is_subject_self'] == true &&
        settings.length == 1 &&
        settings.single['subject_id'] == subjects.single['subject_id'] &&
        settings.single['mode'] == 'normal' &&
        settings.single['current_session_id'] == null;
  }
}
