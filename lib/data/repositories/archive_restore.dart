import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/archive/archive_integrity.dart';
import '../../core/archive/archive_reading.dart';
import 'archive_repository.dart';
import 'archive_zip.dart';
import 'attachment_repository.dart';

enum ArchiveConflictChoice { keepLocal, useArchive }

class ArchiveConflict {
  const ArchiveConflict(this.key, this.table, this.local, this.incoming);
  final String key;
  final String table;
  final Map<String, Object?> local;
  final Map<String, Object?> incoming;
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
    this.extraFiles,
  );
  final Map<String, int> inserted;
  final int replaced;
  final int skipped;
  final int excluded;
  final List<String> extraFiles;
}

/// 還原保留原始層級與時間；所有衝突選擇及外鍵驗證均在同一交易內完成。
class ArchiveRestore {
  ArchiveRestore(this.repository);
  final ArchiveRepository repository;

  String _key(TableInfo table, Map<String, Object?> row) =>
      '${table.actualTableName}:${jsonEncode([for (final key in table.$primaryKey) row[key.name]])}';

  bool _same(Map<String, Object?> a, Map<String, Object?> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

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
      final local = await repository.snapshot();
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
              await ArchiveZip.fileHash(file) != existing['sha256']) {
            throw ArchiveIntegrityException([row['path'] as String]);
          }
          blobIds[row['blob_id'] as String] = existing['blob_id'] as String;
        }
      }
      for (final attachment in data['attachments']!) {
        attachment['blob_id'] =
            blobIds[attachment['blob_id']] ?? attachment['blob_id'];
      }
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
          if (_same(row, comparable)) {
            skipped++;
          } else {
            conflicts.add(ArchiveConflict(key, name, previous, row));
          }
        }
      }
      return ArchiveRestorePlan(
        verified,
        data,
        conflicts,
        skipped,
        ArchiveIntegrity.hash(utf8.encode(jsonEncode(local))),
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

    /// 第一階段的跨主角政策由畫面確認後傳入，核心不擅自選擇。
    required Future<void> Function(ArchiveRows local, ArchiveRows incoming)
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
      await db.transaction(() async {
        final local = await repository.snapshot();
        if (ArchiveIntegrity.hash(utf8.encode(jsonEncode(local))) !=
            plan.revision) {
          throw const ArchiveIntegrityException(['revision']);
        }
        await validateSubjects(local, plan.data);
        await db.customStatement('PRAGMA defer_foreign_keys = ON');
        final excluded =
            ((plan.verified.manifest['scope'] as Map)['excluded'] as List)
                .map((e) => (e as Map)['path'])
                .toSet();
        for (final table in repository.tables) {
          final name = table.actualTableName;
          var rows = plan.data[name]!;
          final byId = {for (final row in local[name]!) _key(table, row): row};
          if (name == 'change_history') {
            rows = rows
                .where(
                  (row) => !local[name]!.any(
                    (existing) => row.entries
                        .where((e) => e.key != 'change_history_id')
                        .every((e) => existing[e.key] == e.value),
                  ),
                )
                .toList();
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
            if (existing != null && existing['layer'] != null) {
              // 權限與不可變層級使用共同規則，不能以還原繞過。
              await repository.ctx.ensureCanModify(existing['layer'] as String);
              if (existing['layer'] != row['layer']) {
                throw const ArchiveIntegrityException(['layer']);
              }
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
                if (await ArchiveZip.fileHash(source) != row['sha256'] ||
                    await source.length() != row['byte_size']) {
                  throw ArchiveIntegrityException([archivePath]);
                }
                if (await destination.exists()) {
                  if (await ArchiveZip.fileHash(destination) != row['sha256']) {
                    throw ArchiveIntegrityException([archivePath]);
                  }
                } else {
                  final temporary = File('${destination.path}.partial');
                  created.add(temporary);
                  await source.copy(temporary.path);
                  if (await ArchiveZip.fileHash(temporary) != row['sha256']) {
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
