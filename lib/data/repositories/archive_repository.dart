import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../core/archive/archive_integrity.dart';
import '../../core/archive/archive_reading.dart';
import '../../core/archive/archive_media_scope.dart';
import '../../core/archive/archive_privacy_filter.dart';
import '../../core/archive/archive_part_plan.dart';
import '../../core/archive/archive_schema.dart';
import '../db/app_database.dart';
import 'attachment_repository.dart';
import 'archive_zip.dart';
import 'repository_context.dart';

class ArchiveExport {
  const ArchiveExport(
    this.zip,
    this.sidecar,
    this.hash,
    this.counts, {
    this.additionalZips = const [],
    this.additionalHashes = const [],
    this.partsIndex,
  });
  final File zip;
  final File sidecar;
  final String hash;
  final Map<String, int> counts;
  final List<File> additionalZips;
  final List<String> additionalHashes;
  final File? partsIndex;
  List<File> get zips => [zip, ...additionalZips];
  List<File> get sidecars => [
    sidecar,
    for (final file in additionalZips) File('${file.path}.sha256'),
  ];
  List<File> get shareFiles => [
    ...zips,
    ...sidecars,
    ?partsIndex,
  ];
}

class ArchiveExportPlan {
  const ArchiveExportPlan(
    this.data,
    this.media,
    this.requiredBytes,
    this.freeBytes,
    this.scope, [
    this.privacyFilter,
  ]);
  final ArchiveRows data;
  final Map<String, File> media;
  final int requiredBytes;
  final int freeBytes;
  final ArchiveMediaScope scope;
  final ArchivePrivacyFilter? privacyFilter;
  bool get includeMedia => scope.includeMedia;
  Map<String, String> get excludedMedia => {
    for (final blob in data['blobs']!)
      if (scope.reasonFor(blob['blob_id'] as String) case final String reason)
        blob['path'] as String: reason,
  };
}

class ArchiveMediaOption {
  const ArchiveMediaOption(
    this.blobId,
    this.names,
    this.byteSize,
    this.references, {
    this.normalNames,
    this.normalReferences,
  });
  final String blobId;
  final List<String> names;
  final int byteSize;
  final int references;
  final List<String>? normalNames;
  final int? normalReferences;
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

  Future<List<ArchiveMediaOption>> mediaOptions() async {
    final data = await snapshot();
    final normalEvents = {
      for (final event in data['events']!)
        if (event['privacy'] != 'private') event['event_id'],
    };
    final byBlob = <Object?, List<Map<String, Object?>>>{};
    for (final attachment in data['attachments']!) {
      (byBlob[attachment['blob_id']] ??= []).add(attachment);
    }
    final options = [
      for (final blob in data['blobs']!)
        ArchiveMediaOption(
          blob['blob_id'] as String,
          {
            if ((byBlob[blob['blob_id']] ?? []).isEmpty)
              p.basename(mediaPath(blob)),
            for (final attachment in byBlob[blob['blob_id']] ?? [])
              attachment['original_filename'] as String,
          }.toList()..sort(),
          blob['byte_size'] as int,
          (byBlob[blob['blob_id']] ?? []).length,
          normalNames: {
            for (final attachment in byBlob[blob['blob_id']] ?? [])
              if (normalEvents.contains(attachment['event_id']))
                attachment['original_filename'] as String,
          }.toList()..sort(),
          normalReferences: (byBlob[blob['blob_id']] ?? [])
              .where((a) => normalEvents.contains(a['event_id']))
              .length,
        ),
    ];
    options.sort((a, b) {
      if ((a.references == 0) != (b.references == 0)) {
        return a.references == 0 ? 1 : -1;
      }
      return a.names.first.compareTo(b.names.first);
    });
    return options;
  }

  Future<ArchiveExportPlan> prepare({
    bool includeMedia = true,
    bool excludePrivateEvents = false,
    int? maxPartBytes,
    Set<String> excludedBlobIds = const {},
  }) async {
    await outputDirectory.create(recursive: true);
    final snapshotData = await snapshot();
    final privacyFilter = excludePrivateEvents
        ? ArchivePrivacyFilter(snapshotData)
        : null;
    final data = privacyFilter?.data ?? snapshotData;
    final scope = ArchiveMediaScope(
      includeMedia: includeMedia,
      excludePrivateEvents: excludePrivateEvents,
      maxPartBytes: maxPartBytes,
      excludedBlobIds: excludedBlobIds,
    );
    final knownIds = {
      for (final blob in snapshotData['blobs']!) blob['blob_id'],
    };
    if (excludedBlobIds.difference(knownIds).isNotEmpty) {
      throw const ArchiveIntegrityException(['data/blobs.json']);
    }
    final media = <String, File>{};
    var mediaBytes = 0;
    for (final blob in data['blobs']!) {
      final source = File(blob['path'] as String);
      final path = mediaPath(blob);
      if (scope.reasonFor(blob['blob_id'] as String) == null) {
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
    return ArchiveExportPlan(data, media, required, free, scope, privacyFilter);
  }

  Map<String, Map<String, Object?>> _schemas() => ArchiveSchema.generate({
    for (final table in tables)
      table.actualTableName: [
        for (final column in table.$columns)
          ArchiveSchemaColumn(column.name, switch (column.type) {
            DriftSqlType.int => ArchiveColumnType.integer,
            DriftSqlType.double => ArchiveColumnType.number,
            DriftSqlType.bool => ArchiveColumnType.boolean,
            DriftSqlType.dateTime => ArchiveColumnType.timestamp,
            _ => ArchiveColumnType.text,
          }, column.$nullable),
      ],
  });

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
    void ensureReadable() {
      for (final event in plan.data['events']!) {
        ctx.ensureCanReadPrivate(event['privacy'] as String);
      }
    }

    ensureReadable();
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
    final base = 'LifeChronicle_${stamp}_${session}_${plan.scope.type}';
    final pendingFiles = <File>[];
    final publishedFiles = <File>[];
    var completed = false;
    try {
      await work.create(recursive: true);
      final text = <String, String>{
        'README.md': readme,
        ...reading.generate(
          plan.data,
          excludedMedia: plan.excludedMedia.keys.toSet(),
        ),
        for (final entry in plan.data.entries)
          'data/${entry.key}.json': '${jsonEncode(entry.value)}\n',
        for (final entry in _schemas().entries)
          'schema/${entry.key}': '${jsonEncode(entry.value)}\n',
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
        final hash = await ArchiveZip.fileHash(
          entry.value,
          cancellation: token,
        );
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
        'format_version': plan.scope.excludePrivateEvents ? '1.2' : '1.1',
        'schema_version': 2,
        'app_version': appVersion,
        'exported_at': date.toIso8601String(),
        'exported_by': ctx.actingAuthorId,
        'subjects': plan.data['subjects'],
        'counts': counts,
        'scope': {
          'type': plan.scope.type,
          if (plan.privacyFilter != null)
            'private_events': plan.privacyFilter!.manifest,
          'excluded': [
            for (final entry in plan.excludedMedia.entries)
              {'path': entry.key, 'reason': entry.value},
          ],
        },
        'files': inventory,
        'parts': [
          {'filename': '$base.zip', 'files': files.keys.toList()},
        ],
        'archive_state': {
          'settings': plan.data['archive_settings'],
          'sessions': plan.data['archive_sessions'],
        },
        'encryption': {'encrypted': false},
      };
      final sizes = {
        for (final row in inventory)
          row['path'] as String: row['byte_size'] as int,
      };
      // 每個媒體各一包是 manifest 最長的情況，實際分組只會更短。
      final mediaNames = sizes.keys
          .where((name) => name.startsWith('media/'))
          .toList();
      final worstParts = [
        {
          'filename': ArchivePartPlan.partName(base, 1, mediaNames.length + 1),
          'files': sizes.keys
              .where((name) => !name.startsWith('media/'))
              .toList(),
        },
        for (var i = 0; i < mediaNames.length; i++)
          {
            'filename': ArchivePartPlan.partName(
              base,
              i + 2,
              mediaNames.length + 1,
            ),
            'files': [mediaNames[i]],
          },
      ];
      final partPlan = ArchivePartPlan(
        sizes: sizes,
        base: base,
        maxBytes: plan.scope.maxPartBytes,
        manifestBytes:
            utf8.encode(jsonEncode({...manifest, 'parts': worstParts})).length +
            1,
      );
      manifest['parts'] = [
        for (var i = 0; i < partPlan.files.length; i++)
          {'filename': partPlan.names[i], 'files': partPlan.files[i]},
      ];
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
      final partials = <File>[];
      final finalZips = <File>[];
      for (var i = 0; i < partPlan.files.length; i++) {
        token.check();
        final partFiles = {
          for (final name in partPlan.files[i]) name: files[name]!,
        };
        if (i == 0) partFiles[ArchiveIntegrity.manifestPath] = manifestFile;
        final sums = File(p.join(work.path, 'sums_$i.txt'));
        await sums.writeAsString(
          ArchiveIntegrity.sums({
            for (final name in partFiles.keys) name: hashes[name]!,
          }),
          flush: true,
        );
        partFiles[ArchiveIntegrity.sumsPath] = sums;
        final destination = File(
          p.join(outputDirectory.path, partPlan.names[i]),
        );
        final partial = File('${destination.path}.partial');
        pendingFiles.add(partial);
        partials.add(partial);
        finalZips.add(destination);
        await zipCodec.write(
          partial,
          partFiles,
          cancellation: token,
          onProgress: onProgress,
        );
        if (plan.scope.maxPartBytes != null &&
            await partial.length() > plan.scope.maxPartBytes!) {
          throw ArchivePartSizeException(partPlan.files[i]);
        }
      }
      await zipCodec.verifyParts(
        partials,
        verify,
        freeBytes: await attachments.platform.availableBytes(
          outputDirectory.path,
        ),
        cancellation: token,
        onProgress: onProgress,
      );
      token.check();
      final zipHashes = <String>[];
      for (var i = 0; i < partials.length; i++) {
        final hash = await ArchiveZip.fileHash(
          partials[i],
          cancellation: token,
        );
        zipHashes.add(hash);
        final sidePartial = File('${finalZips[i].path}.sha256.partial');
        pendingFiles.add(sidePartial);
        await sidePartial.writeAsString(
          '$hash  ${partPlan.names[i]}\n',
          flush: true,
        );
      }
      token.check();
      ensureReadable();
      for (var i = 0; i < partials.length; i++) {
        final zip = finalZips[i];
        await partials[i].rename(zip.path);
        publishedFiles.add(zip);
        final sidecar = File('${zip.path}.sha256');
        await File('${sidecar.path}.partial').rename(sidecar.path);
        publishedFiles.add(sidecar);
      }
      final finalZip = finalZips.first;
      final hash = zipHashes.first;
      final partRecords = [
        for (var i = 0; i < finalZips.length; i++)
          {
            'filename': p.basename(finalZips[i].path),
            'byte_size': await finalZips[i].length(),
            'sha256': zipHashes[i],
          },
      ];
      File? partsIndex;
      if (finalZips.length > 1) {
        partsIndex = File('${finalZip.path}.parts.json');
        final indexPartial = File('${partsIndex.path}.partial');
        pendingFiles.add(indexPartial);
        await indexPartial.writeAsString(
          '${jsonEncode({'format': 'life-chronicle-archive-parts', 'format_version': '1.0', 'parts': partRecords})}\n',
          flush: true,
        );
        await indexPartial.rename(partsIndex.path);
        publishedFiles.add(partsIndex);
      }
      final record = File(p.join(outputDirectory.path, 'latest.json'));
      final recordPartial = File('${record.path}.partial');
      pendingFiles.add(recordPartial);
      await recordPartial.writeAsString(
        jsonEncode({
          'exported_at': date.toIso8601String(),
          'scope': manifest['scope'],
          'path': finalZip.path,
          'byte_size': await finalZip.length(),
          'sha256': hash,
          'verified': true,
          'counts': counts,
          if (partsIndex != null) 'parts_index': partsIndex.path,
          'parts': [
            for (var i = 0; i < finalZips.length; i++)
              {'path': finalZips[i].path, ...partRecords[i]},
          ],
        }),
        flush: true,
      );
      await recordPartial.rename(record.path);
      completed = true;
      return ArchiveExport(
        finalZip,
        File('${finalZip.path}.sha256'),
        hash,
        counts,
        additionalZips: finalZips.skip(1).toList(),
        additionalHashes: zipHashes.skip(1).toList(),
        partsIndex: partsIndex,
      );
    } finally {
      for (final dir in [work, verify]) {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
      for (final file in [...pendingFiles, if (!completed) ...publishedFiles]) {
        if (await file.exists()) await file.delete();
      }
    }
  }
}
