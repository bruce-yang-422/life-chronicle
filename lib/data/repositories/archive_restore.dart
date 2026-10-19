import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/archive/archive_integrity.dart';
import '../../core/archive/archive_reading.dart';
import '../../core/archive/archive_subject_policy.dart';
import 'archive_repository.dart';
import 'archive_zip.dart';
import 'attachment_repository.dart';

enum ArchiveConflictChoice { keepLocal, useArchive }

class ArchiveConflict {
  const ArchiveConflict(
    this.key,
    this.table,
    this.local,
    this.incoming, {
    this.sourceId,
  });
  final String key;
  final String table;
  final Map<String, Object?> local;
  final Map<String, Object?> incoming;

  /// 同名參考資料原本的封存 ID；寫入及引用一律使用本機 ID。
  final String? sourceId;
}

class ArchiveRestorePlan {
  ArchiveRestorePlan(
    this.verified,
    this.data,
    this.conflicts,
    this.skipped,
    this.revision,
    this.blobIds,
  );
  final VerifiedArchive verified;
  final ArchiveRows data;
  final List<ArchiveConflict> conflicts;
  final int skipped;
  final String revision;
  final Map<String, String> blobIds;
}

class ArchiveRestoreReport {
  const ArchiveRestoreReport(
    this.inserted,
    this.replaced,
    this.skipped,
    this.excluded,
    this.extraFiles, {
    this.attachmentCount = 0,
    this.mediaBytes = 0,
  });
  final Map<String, int> inserted;
  final int replaced;
  final int skipped;
  final int excluded;
  final List<String> extraFiles;
  final int attachmentCount;
  final int mediaBytes;
}

/// 還原保留原始層級與時間；所有衝突選擇及外鍵驗證均在同一交易內完成。
class ArchiveRestore {
  ArchiveRestore(this.repository);
  final ArchiveRepository repository;

  String _key(TableInfo table, Map<String, Object?> row) =>
      '${table.actualTableName}:${jsonEncode([for (final key in table.$primaryKey) row[key.name]])}';

  bool _same(Map<String, Object?> a, Map<String, Object?> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  Map<String, String> _reuseReferenceIds(ArchiveRows data, ArchiveRows local) {
    final sources = <String, String>{};
    for (final (name, id, unique, references) in [
      ('places', 'place_id', 'name_key', [('events', 'place_id')]),
      ('people', 'person_id', 'name_key', [('event_people', 'person_id')]),
      ('tags', 'tag_id', 'label', [('event_tags', 'tag_id')]),
    ]) {
      final byName = {
        for (final row in local[name]!)
          if (row[unique] != null) row[unique]: row,
      };
      final localIds = {for (final row in local[name]!) row[id]};
      final remap = <String, String>{};
      final targets = <Object?>{};
      for (final row in data[name]!) {
        final previous = byName[row[unique]];
        final sourceId = row[id] as String;
        if (previous != null && previous[id] != sourceId) {
          // 同一 ID 與同一名稱指向不同本機項目時，不能猜測身分或覆蓋兩筆。
          if (localIds.contains(sourceId)) {
            throw ArchiveIntegrityException(['data/$name.json']);
          }
          final targetId = previous[id] as String;
          remap[sourceId] = targetId;
          row[id] = targetId;
          sources['$name:$targetId'] = sourceId;
        }
        // 不接受多個封存項目併入同一筆後由輸入順序決定內容。
        if (!targets.add(row[id])) {
          throw ArchiveIntegrityException(['data/$name.json']);
        }
      }
      for (final (table, field) in references) {
        for (final row in data[table]!) {
          row[field] = remap[row[field]] ?? row[field];
        }
      }
    }
    return sources;
  }

  Future<ArchiveRestorePlan> inspect(
    File zip, {
    required ImportCancellation cancellation,
    void Function(int done, int total)? onProgress,
  }) async {
    // 原生 StatFs 需要存在的路徑；首次還原尚未匯出時也必須能檢查容量。
    await repository.outputDirectory.create(recursive: true);
    final staging = Directory(
      p.join(
        repository.outputDirectory.path,
        'restore_${repository.ctx.newId().toLowerCase()}',
      ),
    );
    try {
      final verified = await repository.zipCodec.verify(
        zip,
        staging,
        freeBytes: await repository.attachments.platform.availableBytes(
          repository.outputDirectory.path,
        ),
        cancellation: cancellation,
        allowExtra: true,
        onProgress: onProgress,
      );
      final data = <String, List<Map<String, Object?>>>{};
      final counts = verified.manifest['counts'] as Map;
      for (final table in repository.tables) {
        final name = table.actualTableName;
        final rows = jsonDecode(
          await File(p.join(staging.path, 'data', '$name.json')).readAsString(),
        ) as List;
        if (rows.length != counts[name]) {
          throw ArchiveIntegrityException(['data/$name.json']);
        }
        final ids = <String>{};
        data[name] = [];
        for (final raw in rows) {
          final row = Map<String, Object?>.from(raw as Map);
          // 未知次版本欄位保留在原包，只有已知且型別正確的欄位可寫入。
          for (final column in table.$columns) {
            if (!row.containsKey(column.name) ||
                (row[column.name] == null && !column.$nullable)) {
              throw ArchiveIntegrityException(['data/$name.json']);
            }
            _sqlValue(column, row[column.name]);
          }
          row.removeWhere(
            (key, value) => !table.columnsByName.containsKey(key),
          );
          if (!ids.add(_key(table, row))) {
            throw ArchiveIntegrityException(['data/$name.json']);
          }
          data[name]!.add(row);
        }
      }
      final snapshot = await repository.snapshot();
      final replacesInitialProfile =
          ArchiveSubjectPolicy.replacesInitialProfile(snapshot, data);
      final local = replacesInitialProfile
          ? <String, List<Map<String, Object?>>>{
              for (final name in snapshot.keys) name: [],
            }
          : snapshot;
      final localBlobs = {
        for (final row in local['blobs']!) row['sha256'] as String: row,
      };
      final blobIds = <String, String>{};
      for (final row in data['blobs']!) {
        if (row['path'] != ArchiveRepository.mediaPath(row)) {
          throw const ArchiveIntegrityException(['data/blobs.json']);
        }
        final existing = localBlobs[row['sha256']];
        if (existing != null) {
          final file = File(existing['path'] as String);
          if (!await file.exists() ||
              await file.length() != existing['byte_size'] ||
              await ArchiveZip.fileHash(file, cancellation: cancellation) !=
                  existing['sha256']) {
            throw ArchiveIntegrityException([row['path'] as String]);
          }
          blobIds[row['blob_id'] as String] = existing['blob_id'] as String;
        }
      }
      for (final attachment in data['attachments']!) {
        attachment['blob_id'] =
            blobIds[attachment['blob_id']] ?? attachment['blob_id'];
      }
      final referenceSources = _reuseReferenceIds(data, local);
      final conflicts = <ArchiveConflict>[];
      var skipped = 0;
      for (final table in repository.tables) {
        final name = table.actualTableName;
        if (name == 'change_history') continue;
        final byId = {for (final row in local[name]!) _key(table, row): row};
        for (final row in data[name]!) {
          if (name == 'blobs' && blobIds.containsKey(row['blob_id'])) {
            skipped++;
            continue;
          }
          final key = _key(table, row);
          final previous = byId[key];
          if (previous == null) continue;
          final comparable = Map<String, Object?>.from(previous);
          if (name == 'blobs') {
            comparable['path'] = ArchiveRepository.mediaPath(previous);
          }
          final sourceId =
              referenceSources['$name:${row[table.$primaryKey.singleOrNull?.name]}'];
          if (_same(row, comparable) && sourceId == null) {
            skipped++;
          } else {
            conflicts.add(
              ArchiveConflict(key, name, previous, row, sourceId: sourceId),
            );
          }
        }
      }
      return ArchiveRestorePlan(
        verified,
        data,
        conflicts,
        skipped,
        ArchiveIntegrity.hash(utf8.encode(jsonEncode(snapshot))),
        blobIds,
      );
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  Object? _sqlValue(GeneratedColumn column, Object? value) {
    if (value == null && column.$nullable) return null;
    if (column.type == DriftSqlType.dateTime &&
        value is String &&
        RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value)) {
      return DateTime.parse(value).toUtc().toIso8601String();
    }
    if (column.type == DriftSqlType.bool && value is bool) return value ? 1 : 0;
    if (column.type == DriftSqlType.int && value is int) return value;
    if (column.type == DriftSqlType.double && value is num && value.isFinite) {
      return value;
    }
    if (column.type == DriftSqlType.string && value is String) return value;
    throw ArchiveIntegrityException([column.name]);
  }

  Future<void> discard(ArchiveRestorePlan plan) async {
    if (await plan.verified.directory.exists()) {
      await plan.verified.directory.delete(recursive: true);
    }
  }

  Future<ArchiveRestoreReport> apply(
    ArchiveRestorePlan plan,
    Map<String, ArchiveConflictChoice> choices, {
    required ImportCancellation cancellation,

    /// 工具可追加更嚴格的檢查，但不能繞過共同的單一主角政策。
    Future<void> Function(ArchiveRows local, ArchiveRows incoming)?
    validateSubjects,
  }) => repository.attachments.exclusive(() async {
    final db = repository.db;
    final created = <File>[];
    var committed = false;
    try {
      cancellation.check();
      if (plan.conflicts.any((c) => !choices.containsKey(c.key))) {
        throw const ArchiveIntegrityException(['conflicts']);
      }
      final inserted = <String, int>{};
      var replaced = 0;
      var skipped = 0;
      var attachmentCount = 0;
      var mediaBytes = 0;
      await db.transaction(() async {
        final local = await repository.snapshot();
        if (ArchiveIntegrity.hash(utf8.encode(jsonEncode(local))) !=
            plan.revision) {
          throw const ArchiveIntegrityException(['revision']);
        }
        final replacesInitialProfile =
            ArchiveSubjectPolicy.replacesInitialProfile(local, plan.data);
        await validateSubjects?.call(local, plan.data);
        // 寫入典藏設定前先檢查所有覆蓋，不能靠匯入一般模式解除唯讀限制。
        for (final conflict in plan.conflicts) {
          if (choices[conflict.key] != ArchiveConflictChoice.useArchive ||
              conflict.local['layer'] == null) {
            continue;
          }
          await repository.ctx.ensureCanModify(
            conflict.local['layer'] as String,
          );
          if (conflict.local['layer'] != conflict.incoming['layer']) {
            throw const ArchiveIntegrityException(['layer']);
          }
        }
        await db.customStatement('PRAGMA defer_foreign_keys = ON');
        if (replacesInitialProfile) {
          // 僅可清除自動產生且未填寫的三筆初始資料；失敗時由交易復原。
          await db.delete(db.archiveSettings).go();
          await db.delete(db.authors).go();
          await db.delete(db.subjects).go();
          for (final rows in local.values) {
            rows.clear();
          }
        }
        final excluded =
            ((plan.verified.manifest['scope'] as Map)['excluded'] as List)
                .map((e) => (e as Map)['path'])
                .toSet();
        for (final table in repository.tables) {
          final name = table.actualTableName;
          var rows = plan.data[name]!;
          final byId = {for (final row in local[name]!) _key(table, row): row};
          if (name == 'change_history') {
            final incomingCount = rows.length;
            rows = rows
                .where(
                  (row) => !local[name]!.any(
                    (existing) => row.entries
                        .where((e) => e.key != 'change_history_id')
                        .every((e) => existing[e.key] == e.value),
                  ),
                )
                .toList();
            skipped += incomingCount - rows.length;
          }
          inserted[name] = 0;
          for (final original in rows) {
            cancellation.check();
            final row = Map<String, Object?>.from(original);
            final key = _key(table, row);
            final conflict = plan.conflicts
                .where((c) => c.key == key)
                .firstOrNull;
            final existing = name == 'change_history' ? null : byId[key];
            if ((name == 'blobs' && plan.blobIds.containsKey(row['blob_id'])) ||
                (existing != null &&
                    (conflict == null ||
                        choices[key] == ArchiveConflictChoice.keepLocal))) {
              skipped++;
              continue;
            }
            if (name == 'blobs') {
              final archivePath = row['path'] as String;
              final destination = File(
                p.join(
                  repository.attachments.directory.path,
                  p.basename(archivePath),
                ),
              );
              if (excluded.contains(archivePath)) {
                row['verify_status'] = 'excluded';
              } else {
                final source = File(
                  p.joinAll([
                    plan.verified.directory.path,
                    ...archivePath.split('/'),
                  ]),
                );
                if (await ArchiveZip.fileHash(
                          source,
                          cancellation: cancellation,
                        ) !=
                        row['sha256'] ||
                    await source.length() != row['byte_size']) {
                  throw ArchiveIntegrityException([archivePath]);
                }
                if (await destination.exists()) {
                  if (await ArchiveZip.fileHash(
                        destination,
                        cancellation: cancellation,
                      ) !=
                      row['sha256']) {
                    throw ArchiveIntegrityException([archivePath]);
                  }
                } else {
                  final temporary = File('${destination.path}.partial');
                  created.add(temporary);
                  final sink = temporary.openWrite();
                  try {
                    await sink.addStream(
                      source.openRead().map((bytes) {
                        cancellation.check();
                        return bytes;
                      }),
                    );
                    await sink.flush();
                  } catch (_) {
                    // 串流失敗可能已關閉 sink，保留原本的取消或讀取錯誤。
                    try {
                      await sink.close();
                    } catch (_) {}
                    rethrow;
                  }
                  await sink.close();
                  if (await ArchiveZip.fileHash(
                        temporary,
                        cancellation: cancellation,
                      ) !=
                      row['sha256']) {
                    throw ArchiveIntegrityException([archivePath]);
                  }
                  cancellation.check();
                  await temporary.rename(destination.path);
                  created.add(destination);
                }
                row['verify_status'] = 'verified';
              }
              row['path'] = destination.path;
            }
            if (name == 'change_history') row.remove('change_history_id');
            final columns = table.$columns
                .where(
                  (c) =>
                      row.containsKey(c.name) &&
                      (existing == null || !table.$primaryKey.contains(c)) &&
                      (existing == null || c.name != 'layer'),
                )
                .toList();
            final values = [
              for (final column in columns) _sqlValue(column, row[column.name]),
            ];
            if (existing == null) {
              await db.customStatement(
                'INSERT INTO "$name" (${columns.map((c) => '"${c.name}"').join(',')}) '
                'VALUES (${List.filled(columns.length, '?').join(',')})',
                values,
              );
              inserted[name] = inserted[name]! + 1;
            } else {
              final keys = table.$primaryKey.toList();
              await db.customStatement(
                'UPDATE "$name" SET ${columns.map((c) => '"${c.name}" = ?').join(',')} '
                'WHERE ${keys.map((c) => '"${c.name}" = ?').join(' AND ')}',
                [
                  ...values,
                  for (final column in keys)
                    _sqlValue(column, row[column.name]),
                ],
              );
              replaced++;
            }
          }
        }
        final invalid = await db.customSelect('PRAGMA foreign_key_check').get();
        if (invalid.isNotEmpty) {
          throw const ArchiveIntegrityException(['foreign_keys']);
        }
        final subjectId = plan.data['subjects']!.single['subject_id'] as String;
        final totals = await db
            .customSelect(
              'SELECT '
              '(SELECT count(*) FROM attachments a JOIN events e ON e.event_id = a.event_id '
              'WHERE e.subject_id = ?1) AS attachment_count, '
              '(SELECT coalesce(sum(b.byte_size), 0) FROM blobs b '
              "WHERE b.verify_status = 'verified' AND EXISTS ("
              'SELECT 1 FROM attachments a JOIN events e ON e.event_id = a.event_id '
              'WHERE a.blob_id = b.blob_id AND e.subject_id = ?1)) AS media_bytes',
              variables: [Variable.withString(subjectId)],
            )
            .getSingle();
        attachmentCount = totals.read<int>('attachment_count');
        mediaBytes = totals.read<int>('media_bytes');
        cancellation.check();
      });
      committed = true;
      db.markTablesUpdated(repository.tables.toSet());
      final excluded =
          ((plan.verified.manifest['scope'] as Map)['excluded'] as List).length;
      return ArchiveRestoreReport(
        inserted,
        replaced,
        skipped,
        excluded,
        plan.verified.extraFiles,
        attachmentCount: attachmentCount,
        mediaBytes: mediaBytes,
      );
    } finally {
      if (!committed) {
        for (final file in created.reversed) {
          if (await file.exists()) await file.delete();
        }
      }
      await discard(plan);
    }
  });
}
