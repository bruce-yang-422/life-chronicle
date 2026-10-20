import 'dart:convert';

import 'archive_reading.dart';

/// 只處理匯出快照，不回寫生命紀錄或變更保留資料的作者、層級及時間。
class ArchivePrivacyFilter {
  ArchivePrivacyFilter(ArchiveRows source) {
    data = {
      for (final entry in source.entries)
        entry.key: [
          for (final row in entry.value) Map<String, Object?>.of(row),
        ],
    };
    final privateIds = {
      for (final row in data['events']!)
        if (row['privacy'] == 'private') row['event_id'],
    };
    excludedEvents = privateIds.length;
    final privateBlobIds = {
      for (final row in data['attachments']!)
        if (privateIds.contains(row['event_id'])) row['blob_id'],
    };
    data['events']!.removeWhere((row) => privateIds.contains(row['event_id']));
    for (final name in [
      'event_sections',
      'reflections',
      'attachments',
      'event_tags',
      'event_people',
      'event_life_periods',
      'story_events',
    ]) {
      data[name]!.removeWhere((row) => privateIds.contains(row['event_id']));
    }
    data['event_links']!.removeWhere(
      (row) =>
          privateIds.contains(row['event_a_id']) ||
          privateIds.contains(row['event_b_id']),
    );
    final retainedBlobIds = {
      for (final row in data['attachments']!) row['blob_id'],
    };
    final removedBlobIds = privateBlobIds.difference(retainedBlobIds);
    excludedMedia = removedBlobIds.length;
    data['blobs']!.removeWhere(
      (row) => removedBlobIds.contains(row['blob_id']),
    );

    // 快照亦可能來自已永久移除的私密事件，不能只看本次排除的 ID。
    for (final rows in data.values) {
      for (final row in rows) {
        for (final field in [
          'time_payload',
          'birth_date',
          'death_date',
          'start_time',
          'end_time',
        ]) {
          if (row[field] is! String) continue;
          final time = jsonDecode(row[field] as String) as Map<String, dynamic>;
          final snapshot = time['deleted_reference'];
          if (snapshot is Map && snapshot['private'] == true ||
              privateIds.contains(time['event_id']) && snapshot != null) {
            time.remove('deleted_reference');
            row[field] = jsonEncode(time);
            excludedSnapshots++;
          }
        }
      }
    }
    // 修訂表沒有所有權欄位；無法辨識歸屬的已移除實體亦不帶入。
    const identifiers = {
      'subject_id',
      'author_id',
      'archive_session_id',
      'event_id',
      'event_section_id',
      'life_period_id',
      'reflection_id',
      'story_id',
      'blob_id',
      'attachment_id',
      'place_id',
      'person_id',
      'tag_id',
    };
    final retainedIds = {
      for (final entry in data.entries)
        if (entry.key != 'change_history')
          for (final row in entry.value)
            for (final field in identifiers)
              if (row[field] != null && !privateIds.contains(row[field]))
                row[field],
    };
    final history = data['change_history']!;
    final before = history.length;
    history.removeWhere((row) => !retainedIds.contains(row['entity_id']));
    excludedHistory = before - history.length;
  }

  late final ArchiveRows data;
  late final int excludedEvents;
  late final int excludedMedia;
  late final int excludedHistory;
  int excludedSnapshots = 0;

  /// 不列私密識別碼、標題、檔名或雜湊；以規則與總數記錄刻意排除。
  Map<String, Object?> get manifest => {
    'reason': 'private_events',
    'events': excludedEvents,
    'media': excludedMedia,
    'snapshots': excludedSnapshots,
    'history': excludedHistory,
  };
}
