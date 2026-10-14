import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/archive/archive_integrity.dart';
import '../../core/archive/archive_reading.dart';
import '../db/app_database.dart';
import 'attachment_repository.dart';
import 'archive_zip.dart';
import 'repository_context.dart';

class ArchiveExport {
  const ArchiveExport(this.zip, this.sidecar, this.hash, this.counts);
  final File zip;
  final File sidecar;
  final String hash;
  final Map<String, int> counts;
}

class ArchiveExportPlan {
  const ArchiveExportPlan(
    this.data,
    this.media,
    this.requiredBytes,
    this.freeBytes,
    this.includeMedia,
  );
  final ArchiveRows data;
  final Map<String, File> media;
  final int requiredBytes;
  final int freeBytes;
  final bool includeMedia;
}

/// 開放 JSON 匯出；原始檔位置、SQLite 與衍生搜尋快取不進入封存包。
class ArchiveRepository {
  ArchiveRepository(
    this.ctx,
    this.attachments,
    this.outputDirectory,
    this.zipCodec,
  );
  final RepositoryContext ctx;
  final AttachmentRepository attachments;
  final Directory outputDirectory;
  final ArchiveZip zipCodec;
  AppDatabase get db => ctx.db;

  List<TableInfo> get tables => [
    db.subjects,
    db.authors,
    db.archiveSessions,
    db.archiveSettings,
    db.places,
    db.people,
    db.tags,
    db.events,
    db.eventSections,
    db.lifePeriods,
    db.eventLifePeriods,
    db.reflections,
    db.stories,
    db.storyEvents,
    db.blobs,
    db.attachments,
    db.eventTags,
    db.eventPeople,
    db.eventLinks,
    db.changeHistory,
  ];

  Future<ArchiveRows> snapshot() => db.transaction(() async {
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in tables) {
      final rows = await db
          .customSelect('SELECT * FROM "${table.actualTableName}"')
          .get();
      result[table.actualTableName] = [
        for (final row in rows)
          {
            for (final column in table.$columns)
              column.name: _jsonValue(column, row.data[column.name]),
          },
      ];
    }
    for (final event in result['events']!) {
      ctx.ensureCanReadPrivate(event['privacy'] as String);
    }
    return result;
  });

  Object? _jsonValue(GeneratedColumn column, Object? value) {
    if (value == null) return null;
    if (column.type == DriftSqlType.dateTime) {
      if (value is String) {
        return DateTime.parse(value).toUtc().toIso8601String();
      }
      return DateTime.fromMillisecondsSinceEpoch(
        (value as int) * 1000,
        isUtc: true,
      ).toIso8601String();
    }
    if (column.type == DriftSqlType.bool) return value == 1;
    return value;
  }

  static String mediaPath(Map<String, Object?> blob) {
    final hash = blob['sha256'] as String;
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const ArchiveIntegrityException(['blobs.json']);
    }
    final extension = switch (blob['media_type']) {
      'image/jpeg' => 'jpg',
      'image/png' => 'png',
      'image/webp' => 'webp',
      'image/heic' || 'image/heif' => 'heic',
      'image/gif' => 'gif',
      'video/mp4' => 'mp4',
      'video/quicktime' => 'mov',
      'audio/mpeg' => 'mp3',
      'audio/mp4' => 'm4a',
      'application/pdf' => 'pdf',
      _ => 'bin',
    };
    return 'media/${hash.substring(0, 2)}/$hash.$extension';
  }

  Future<ArchiveExportPlan> prepare({bool includeMedia = true}) async {
    await outputDirectory.create(recursive: true);
    final data = await snapshot();
    final media = <String, File>{};
    var mediaBytes = 0;
    for (final blob in data['blobs']!) {
      final source = File(blob['path'] as String);
      final path = mediaPath(blob);
      if (includeMedia) {
        if (!await source.exists()) throw ArchiveIntegrityException([path]);
        media[path] = source;
        mediaBytes += blob['byte_size'] as int;
      }
      blob['path'] = path;
    }
    final textBytes = utf8.encode(jsonEncode(data)).length;
    // 文字閱讀版、校驗後的解壓副本與 ZIP 暫存均需容量。
    final required = mediaBytes * 3 + textBytes * 12 + 1024 * 1024;
    final free = await attachments.platform.availableBytes(
      outputDirectory.path,
    );
    return ArchiveExportPlan(data, media, required, free, includeMedia);
  }

  Map<String, Object?> _dataSchema() => {
    r'$schema': 'https://json-schema.org/draft/2020-12/schema',
    'title': 'Life Chronicle data version 1',
    'type': 'object',
    'additionalProperties': false,
    'required': [for (final table in tables) table.actualTableName],
    'properties': {
      for (final table in tables)
        table.actualTableName: {
          'type': 'array',
          'items': {
            'type': 'object',
            'additionalProperties': false,
            'required': [for (final column in table.$columns) column.name],
            'properties': {
              for (final column in table.$columns)
                column.name: {
                  'type': [
                    switch (column.type) {
                      DriftSqlType.int => 'integer',
                      DriftSqlType.double => 'number',
                      DriftSqlType.bool => 'boolean',
                      _ => 'string',
                    },
                    if (column.$nullable) 'null',
                  ],
                  if (column.type == DriftSqlType.dateTime)
                    'format': 'date-time',
                },
            },
          },
        },
    },
  };

  Future<ArchiveExport> export(
    ArchiveExportPlan plan,
    ArchiveReading reading, {
    required String readme,
    required String appVersion,
    ImportCancellation? cancellation,
    void Function(int done, int total)? onProgress,
  }) async {
    final token = cancellation ?? ImportCancellation();
    token.check();
    final free = await attachments.platform.availableBytes(
      outputDirectory.path,
    );
    if (plan.requiredBytes > free) throw ImportSpaceException();
    final session = ctx.newId().toLowerCase();
    final work = Directory(p.join(outputDirectory.path, 'work_$session'));
    final verify = Directory(p.join(outputDirectory.path, 'verify_$session'));
    final date = ctx.now();
    final stamp = date
        .toIso8601String()
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(0, 14);
    final base =
        'LifeChronicle_${stamp}_${session}_${plan.includeMedia ? 'full' : 'no_media'}.zip';
    final partial = File(p.join(outputDirectory.path, '$base.partial'));
    final finalZip = File(p.join(outputDirectory.path, base));
    final sidecar = File('${finalZip.path}.sha256');
    var completed = false;
    try {
      await work.create(recursive: true);
      final text = <String, String>{
        'README.md': readme,
        ...reading.generate(plan.data),
        for (final entry in plan.data.entries)
          'data/${entry.key}.json': '${jsonEncode(entry.value)}\n',
        'schema/data.schema.json': '${jsonEncode(_dataSchema())}\n',
        'schema/manifest.schema.json':
            '${jsonEncode({
              r'$schema': 'https://json-schema.org/draft/2020-12/schema',
              'type': 'object',
              'required': ['format', 'format_version', 'schema_version', 'files', 'counts', 'scope'],
              'properties': {
                'format': {'const': 'life-chronicle-archive'},
                'format_version': {'const': '1.0'},
                'schema_version': {'const': 1},
                'files': {'type': 'array'},
                'counts': {'type': 'object'},
                'scope': {'type': 'object'},
              },
            })}\n',
      };
      final files = <String, File>{...plan.media};
      for (final entry in text.entries) {
        token.check();
        final file = File(p.joinAll([work.path, ...entry.key.split('/')]));
        await file.parent.create(recursive: true);
        await file.writeAsString(
          entry.value.replaceAll('\r\n', '\n'),
          flush: true,
        );
        files[entry.key] = file;
      }
      final hashes = <String, String>{};
      final inventory = <Map<String, Object?>>[];
      for (final entry in files.entries) {
        token.check();
        final hash = await ArchiveZip.fileHash(entry.value);
        hashes[entry.key] = hash;
        if (entry.key.startsWith('media/') &&
            hash != p.basename(entry.key).split('.').first) {
          throw ArchiveIntegrityException([entry.key]);
        }
        inventory.add({
          'path': entry.key,
          'byte_size': await entry.value.length(),
          'sha256': hash,
          'media_type': entry.key.startsWith('media/')
              ? plan.data['blobs']!.firstWhere(
                  (b) => b['path'] == entry.key,
                )['media_type']
              : 'text/plain',
        });
      }
      final counts = {
        for (final entry in plan.data.entries) entry.key: entry.value.length,
      };
      final manifest = {
        'format': 'life-chronicle-archive',
        'format_version': '1.0',
        'schema_version': 1,
        'app_version': appVersion,
        'exported_at': date.toIso8601String(),
        'exported_by': ctx.actingAuthorId,
        'subjects': plan.data['subjects'],
        'counts': counts,
        'scope': {
          'type': plan.includeMedia ? 'full' : 'no_media',
          'excluded': [
            if (!plan.includeMedia)
              for (final blob in plan.data['blobs']!)
                {'path': blob['path'], 'reason': 'no_media'},
          ],
        },
        'files': inventory,
        'parts': [
          {'filename': base, 'files': files.keys.toList()},
        ],
        'archive_state': {
          'settings': plan.data['archive_settings'],
          'sessions': plan.data['archive_sessions'],
        },
        'encryption': {'encrypted': false},
      };
      final manifestFile = File(
        p.join(work.path, ArchiveIntegrity.manifestPath),
      );
      await manifestFile.writeAsString(
        '${jsonEncode(manifest)}\n',
        flush: true,
      );
      files[ArchiveIntegrity.manifestPath] = manifestFile;
      hashes[ArchiveIntegrity.manifestPath] = await ArchiveZip.fileHash(
        manifestFile,
      );
      final sums = File(p.join(work.path, ArchiveIntegrity.sumsPath));
      await sums.writeAsString(ArchiveIntegrity.sums(hashes), flush: true);
      files[ArchiveIntegrity.sumsPath] = sums;
      await zipCodec.write(
        partial,
        files,
        cancellation: token,
        onProgress: onProgress,
      );
      await zipCodec.verify(
        partial,
        verify,
        freeBytes: await attachments.platform.availableBytes(
          outputDirectory.path,
        ),
        cancellation: token,
        onProgress: onProgress,
      );
      token.check();
      final hash = await ArchiveZip.fileHash(partial);
      await File('${sidecar.path}.partial')
          .writeAsString('$hash  $base\n', flush: true);
      token.check();
      await partial.rename(finalZip.path);
      await File('${sidecar.path}.partial').rename(sidecar.path);
      final record = File(p.join(outputDirectory.path, 'latest.json'));
      final recordPartial = File('${record.path}.partial');
      await recordPartial.writeAsString(
        jsonEncode({
          'exported_at': date.toIso8601String(),
          'scope': manifest['scope'],
          'path': finalZip.path,
          'byte_size': await finalZip.length(),
          'sha256': hash,
          'verified': true,
          'counts': counts,
        }),
        flush: true,
      );
      await recordPartial.rename(record.path);
      completed = true;
      return ArchiveExport(finalZip, sidecar, hash, counts);
    } finally {
      for (final dir in [work, verify]) {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
      if (await partial.exists()) await partial.delete();
      final sidePartial = File('${sidecar.path}.partial');
      if (await sidePartial.exists()) await sidePartial.delete();
      if (!completed) {
        if (await finalZip.exists()) await finalZip.delete();
        if (await sidecar.exists()) await sidecar.delete();
      }
    }
  }
}
