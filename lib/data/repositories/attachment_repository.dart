import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/attachments/attachment_quota.dart';
import '../../core/attachments/attachment_file_progress.dart';
import '../../core/attachments/media_probe.dart';
import '../db/app_database.dart';
import '../platform/attachment_platform.dart';
import 'event_repository.dart';
import 'repository_context.dart';
import 'photo_work_store.dart';
import 'photo_cache_files.dart';

class ImportCancelled implements Exception {}

class ImportSpaceException implements Exception {}

class ImportIntegrityException implements Exception {}

enum AttachmentRejectionReason { video, unverified }

class ImportMediaException implements Exception {
  const ImportMediaException(this.reason);
  final AttachmentRejectionReason reason;
}

class RejectedAttachment {
  const RejectedAttachment(this.source, this.reason);
  final AttachmentSource source;
  final AttachmentRejectionReason reason;
}

class ImportCancellation {
  bool cancelled = false;
  void check() {
    if (cancelled) throw ImportCancelled();
  }
}

class AttachmentSource {
  const AttachmentSource(
    this.path,
    this.name, {
    this.referenceId,
    this.metadata,
  });
  final AttachmentMetadata? metadata;
  factory AttachmentSource.fromDraft(Map<String, String> value) =>
      AttachmentSource(
        value['path']!,
        value['name']!,
        referenceId: value['referenceId'],
        metadata: value['metadataStored'] != '1'
            ? null
            : AttachmentMetadata(
                capturedAt: DateTime.tryParse(value['capturedAt'] ?? ''),
                latitude: double.tryParse(value['latitude'] ?? ''),
                longitude: double.tryParse(value['longitude'] ?? ''),
              ),
      );
  Map<String, String> toDraft() => {
    'path': path,
    'name': name,
    'referenceId': ?referenceId,
    if (metadata != null) ...{
      'metadataStored': '1',
      if (metadata!.capturedAt != null)
        'capturedAt': metadata!.capturedAt!.toIso8601String(),
      if (metadata!.latitude != null) 'latitude': metadata!.latitude.toString(),
      if (metadata!.longitude != null)
        'longitude': metadata!.longitude.toString(),
    },
  };
  final String path;
  final String name;
  final String? referenceId;
}

class PreparedAttachment {
  const PreparedAttachment(
    this.source,
    this.size,
    this.hash,
    this.metadata,
    this.existing, {
    this.staticImageOnly = false,
    this.sourceBytes,
  });
  final AttachmentSource source;
  final int size;
  final String hash;
  final AttachmentMetadata metadata;
  final Blob? existing;
  final bool staticImageOnly;
  final int? sourceBytes;
}

class AttachmentImportPlan {
  const AttachmentImportPlan(
    this.files,
    this.originalBytes,
    this.addedBytes,
    this.freeBytes,
    this.duplicates, {
    this.rejected = const [],
    this.release,
  });
  final List<PreparedAttachment> files;
  final int originalBytes;
  final int addedBytes;
  final int freeBytes;
  final int duplicates;
  final List<RejectedAttachment> rejected;
  final Future<void> Function()? release;

  /// Recompute physical storage after selection; logical bytes count every reference.
  AttachmentImportPlan select(Iterable<PreparedAttachment> selection) {
    final chosen = selection.toList(growable: false);
    final hashes = <String>{};
    var bytes = 0, added = 0, duplicates = 0;
    for (final file in chosen) {
      bytes += file.size;
      if (!hashes.add(file.hash) || file.existing != null) {
        duplicates++;
      } else {
        added += file.size;
      }
    }
    return AttachmentImportPlan(
      chosen,
      bytes,
      added,
      freeBytes,
      duplicates,
      rejected: rejected,
      release: release,
    );
  }
}

class StoredAttachment {
  const StoredAttachment(this.attachment, this.blob);
  final Attachment attachment;
  final Blob blob;
}

/// 批次匯入採全有或全無：所有檔案驗證後，才以同一資料庫交易登錄。
class AttachmentRepository {
  AttachmentRepository(
    this.ctx,
    this.directory,
    this.platform, {
    Directory? photoCacheDirectory,
  }) : photoCacheDirectory =
           photoCacheDirectory ??
           Directory(p.join(directory.parent.path, 'photo_cache'));
  final Directory photoCacheDirectory;
  final RepositoryContext ctx;
  final Directory directory;
  final AttachmentPlatform platform;
  Future<void> _operations = Future.value();
  final _activeDraftPaths = <String>{};
  String _pathKey(String path) => Platform.isWindows
      ? p.normalize(p.absolute(path)).toLowerCase()
      : p.normalize(p.absolute(path));
  static Future<AttachmentRepository> open(RepositoryContext ctx) async {
    final directory = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'media'),
    );
    await directory.create(recursive: true);
    return AttachmentRepository(
      ctx,
      directory,
      DeviceAttachmentPlatform(),
      photoCacheDirectory: Directory(
        p.join((await getTemporaryDirectory()).path, 'photo_cache'),
      ),
    );
  }

  Future<T> _exclusive<T>(Future<T> Function() action) {
    final next = _operations.then((_) => action());
    _operations = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {},
    );
    return next;
  }

  /// 封存還原與倉庫清理共用同一檔案操作鎖。
  Future<T> exclusive<T>(Future<T> Function() action) => _exclusive(action);

  Future<String> _hash(
    File file,
    ImportCancellation cancellation, {
    void Function(int bytes)? onBytes,
    int? end,
  }) async {
    final digest = await sha256
        .bind(
          file.openRead(0, end).map((bytes) {
            cancellation.check();
            onBytes?.call(bytes.length);
            return bytes;
          }),
        )
        .first;
    cancellation.check();
    return digest.toString();
  }

  Future<Blob?> _existing(String hash) => (ctx.db.select(
    ctx.db.blobs,
  )..where((blob) => blob.sha256.equals(hash))).getSingleOrNull();

  /// 每筆引用各自計入，不能用 DISTINCT 或按 blob 去重，所有層一起加總。
  Future<int> _usedBytes(String eventId) async {
    final total = ctx.db.blobs.byteSize.sum();
    final query = ctx.db.selectOnly(ctx.db.attachments)
      ..addColumns([total])
      ..join([
        innerJoin(
          ctx.db.blobs,
          ctx.db.blobs.id.equalsExp(ctx.db.attachments.blobId),
        ),
      ])
      ..where(ctx.db.attachments.eventId.equals(eventId));
    return (await query.getSingle()).read(total) ?? 0;
  }

  Future<int> usedBytes(String eventId) async {
    final event = await EventRepository(ctx).find(eventId);
    if (event == null || event.subjectId != ctx.subjectId) {
      throw const EventStateException('事件不存在');
    }
    ctx.ensureCanReadPrivate(event.privacy);
    return _usedBytes(eventId);
  }

  /// Draft references already committed by a previous save are not counted twice.
  Future<int> pendingBytes(
    String? eventId,
    AttachmentImportPlan pending,
  ) async {
    if (eventId != null) await usedBytes(eventId);
    final seen = <String, PreparedAttachment>{};
    var bytes = 0;
    for (final file in pending.files) {
      final id = file.source.referenceId;
      if (id != null) {
        final repeated = seen[id];
        if (repeated != null) {
          if (repeated.hash != file.hash ||
              repeated.source.name != file.source.name) {
            throw ImportIntegrityException();
          }
          continue;
        }
        seen[id] = file;
        final prior = await (ctx.db.select(
          ctx.db.attachments,
        )..where((a) => a.id.equals(id))).getSingleOrNull();
        if (prior != null) {
          final blob = await _existing(file.hash);
          if (prior.eventId != eventId ||
              prior.blobId != blob?.id ||
              prior.originalFilename != file.source.name) {
            throw ImportIntegrityException();
          }
          continue;
        }
      }
      bytes += file.size;
    }
    return bytes;
  }

  Future<bool> _valid(Blob blob, ImportCancellation cancellation) async {
    final file = File(blob.path);
    return blob.verifyStatus == 'verified' &&
        await file.exists() &&
        await file.length() == blob.byteSize &&
        await _hash(file, cancellation) == blob.sha256;
  }

  Future<({String type, int size, bool staticImageOnly})> _probeFile(
    File file,
    ImportCancellation token,
  ) async {
    final handle = await file.open();
    try {
      final length = await handle.length();
      final probe = MediaProbe(length, (offset, count) async {
        token.check();
        await handle.setPosition(offset);
        return handle.read(count);
      });
      final type = await probe.inspect();
      token.check();
      if (probe.containsVideo) {
        throw const ImportMediaException(AttachmentRejectionReason.video);
      }
      return (
        type: type,
        size: probe.staticImageBytes ?? length,
        staticImageOnly: probe.staticImageBytes != null,
      );
    } on FormatException {
      throw const ImportMediaException(AttachmentRejectionReason.unverified);
    } finally {
      await handle.close();
    }
  }

  Future<AttachmentImportPlan> prepare(
    List<AttachmentSource> sources, {
    ImportCancellation? cancellation,
    void Function(int done, int total)? onProgress,
    void Function(AttachmentFileProgress)? onFileProgress,
  }) async {
    final token = cancellation ?? ImportCancellation();
    await directory.create(recursive: true);
    final free = await platform.availableBytes(directory.path);
    var total = 0;
    for (final source in sources) {
      total += await File(source.path).length();
    }
    var done = 0;
    var added = 0;
    var duplicates = 0;
    final files = <PreparedAttachment>[];
    final rejected = <RejectedAttachment>[];
    final unique = <String>{};
    var completed = 0;
    for (final source in sources) {
      token.check();
      onFileProgress?.call(
        AttachmentFileProgress(source.name, completed, sources.length),
      );
      final file = File(source.path);
      final originalSize = await file.length();
      String type;
      int size;
      bool staticImageOnly;
      try {
        final result = await _probeFile(file, token);
        type = result.type;
        size = result.size;
        staticImageOnly = result.staticImageOnly;
      } on ImportMediaException catch (error) {
        rejected.add(RejectedAttachment(source, error.reason));
        done += originalSize;
        onProgress?.call(done, total);
        onFileProgress?.call(
          AttachmentFileProgress(source.name, ++completed, sources.length),
        );
        continue;
      }
      final hash = await _hash(
        file,
        token,
        end: size,
        onBytes: (bytes) {
          done += bytes;
          onProgress?.call(done, total);
        },
      );
      if (staticImageOnly) {
        done += originalSize - size;
        onProgress?.call(done, total);
      }
      final blob = await _existing(hash);
      if (blob != null &&
          (blob.byteSize != size || !await _valid(blob, token))) {
        throw ImportIntegrityException();
      }
      if (blob != null || !unique.add(hash)) {
        duplicates++;
      } else {
        added += size;
      }
      final metadata = source.metadata ?? await platform.metadata(source.path);
      files.add(
        PreparedAttachment(
          source,
          size,
          hash,
          AttachmentMetadata(
            mediaType: type,
            capturedAt: metadata.capturedAt,
            latitude: metadata.latitude,
            longitude: metadata.longitude,
          ),
          blob,
          staticImageOnly: staticImageOnly,
          sourceBytes: originalSize,
        ),
      );
      onFileProgress?.call(
        AttachmentFileProgress(source.name, ++completed, sources.length),
      );
    }
    return AttachmentImportPlan(
      files,
      files.fold(0, (sum, file) => sum + file.size),
      added,
      free,
      duplicates,
      rejected: rejected,
    );
  }

  /// 使用者確認後，將尚未提交的附件留在持久性草稿目錄，避免系統清除 picker 快取。
  Future<List<AttachmentSource>> retainForDraft(
    AttachmentImportPlan plan,
    ImportCancellation token, {
    void Function(int done, int total)? onProgress,
    void Function(AttachmentFileProgress)? onFileProgress,
  }) => _exclusive(() async {
    final draftDirectory = Directory(
      p.join(directory.parent.path, 'draft_media'),
    );
    await draftDirectory.create(recursive: true);
    if (await platform.availableBytes(directory.path) <
        plan.originalBytes + plan.addedBytes) {
      throw ImportSpaceException();
    }
    final retained = <AttachmentSource>[];
    var done = 0;
    var completed = 0;
    try {
      for (final source in plan.files) {
        token.check();
        onFileProgress?.call(
          AttachmentFileProgress(
            source.source.name,
            completed,
            plan.files.length,
          ),
        );
        if (await File(source.source.path).length() !=
            (source.sourceBytes ?? source.size)) {
          throw ImportIntegrityException();
        }
        final extension = p.extension(p.basename(source.source.name));
        final suffix = RegExp(r'^\.[a-zA-Z0-9]+$').hasMatch(extension)
            ? extension
            : '';
        final target = File(
          p.join(draftDirectory.path, '${ctx.newId()}$suffix'),
        );
        retained.add(
          AttachmentSource(
            target.path,
            source.source.name,
            referenceId: p.basenameWithoutExtension(target.path),
            metadata: source.metadata,
          ),
        );
        final sink = target.openWrite();
        try {
          await for (final bytes in File(
            source.source.path,
          ).openRead(0, source.size)) {
            token.check();
            sink.add(bytes);
            done += bytes.length;
            onProgress?.call(done, plan.originalBytes);
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
        if (await target.length() != source.size ||
            await _hash(target, token) != source.hash) {
          throw ImportIntegrityException();
        }
        final result = await _probeFile(target, token);
        if (result.staticImageOnly) {
          throw const ImportMediaException(
            AttachmentRejectionReason.unverified,
          );
        }
        onFileProgress?.call(
          AttachmentFileProgress(
            source.source.name,
            ++completed,
            plan.files.length,
          ),
        );
      }
      _activeDraftPaths.addAll(retained.map((source) => _pathKey(source.path)));
      return retained;
    } catch (_) {
      await releaseDraftSources(retained);
      rethrow;
    }
  });
  Future<void> releaseDraftSources(List<AttachmentSource> sources) async {
    final root = p.normalize(p.join(directory.parent.path, 'draft_media'));
    for (final source in sources) {
      if (!p.isWithin(root, p.normalize(source.path))) {
        throw ArgumentError('只能清理附件草稿副本');
      }
      final file = File(source.path);
      if (await file.exists()) await file.delete();
      _activeDraftPaths.remove(_pathKey(source.path));
    }
  }

  /// saveEvent 可將事件及段落一起納入此批次的交易，失敗不留下半筆事件。
  Future<String> importBatch(
    AttachmentImportPlan plan, {
    String? eventId,
    Future<String> Function()? saveEvent,
    ImportCancellation? cancellation,
    void Function(int done, int total)? onProgress,
    void Function(AttachmentFileProgress)? onFileProgress,
  }) => _exclusive(() async {
    final token = cancellation ?? ImportCancellation();
    final temporaryPaths = <String>[];
    final createdPaths = <String>[];
    final paths = <String, String>{};
    final mediaTypes = <String, String>{};
    var done = 0;
    var completed = 0;
    try {
      await directory.create(recursive: true);
      if (await platform.availableBytes(directory.path) < plan.addedBytes) {
        throw ImportSpaceException();
      }
      for (final file in plan.files) {
        token.check();
        onFileProgress?.call(
          AttachmentFileProgress(
            file.source.name,
            completed,
            plan.files.length,
          ),
        );
        if (paths.containsKey(file.hash)) {
          onFileProgress?.call(
            AttachmentFileProgress(
              file.source.name,
              ++completed,
              plan.files.length,
            ),
          );
          continue;
        }
        final existing = await _existing(file.hash);
        if (existing != null) {
          if (existing.byteSize != file.size ||
              !await _valid(existing, token)) {
            throw ImportIntegrityException();
          }
          paths[file.hash] = existing.path;
          onFileProgress?.call(
            AttachmentFileProgress(
              file.source.name,
              ++completed,
              plan.files.length,
            ),
          );
          continue;
        }
        final target = File(p.join(directory.path, file.hash));
        // 沒有登錄但完整的副本可能來自中斷的匯入；驗證後可重用。
        if (await target.exists()) {
          if (await target.length() != file.size ||
              await _hash(target, token) != file.hash) {
            throw ImportIntegrityException();
          }
          paths[file.hash] = target.path;
          onFileProgress?.call(
            AttachmentFileProgress(
              file.source.name,
              ++completed,
              plan.files.length,
            ),
          );
          continue;
        }
        final temporary = File(
          p.join(directory.path, '${ctx.newId()}.partial'),
        );
        temporaryPaths.add(temporary.path);
        if (await File(file.source.path).length() !=
            (file.sourceBytes ?? file.size)) {
          throw ImportIntegrityException();
        }
        final sink = temporary.openWrite();
        try {
          await for (final bytes in File(
            file.source.path,
          ).openRead(0, file.size)) {
            token.check();
            sink.add(bytes);
            done += bytes.length;
            onProgress?.call(done, plan.addedBytes);
          }
          await sink.flush();
        } finally {
          await sink.close();
        }
        token.check();
        if (await temporary.length() != file.size ||
            await _hash(temporary, token) != file.hash) {
          throw ImportIntegrityException();
        }
        await temporary.rename(target.path);
        createdPaths.add(target.path);
        paths[file.hash] = target.path;
        onFileProgress?.call(
          AttachmentFileProgress(
            file.source.name,
            ++completed,
            plan.files.length,
          ),
        );
      }
      token.check();
      // 計畫可由呼叫端建立；重複雜湊也須逐筆確認實際保存大小。
      for (final file in plan.files) {
        token.check();
        if (await File(paths[file.hash]!).length() != file.size) {
          throw ImportIntegrityException();
        }
        if (!mediaTypes.containsKey(file.hash)) {
          final result = await _probeFile(File(paths[file.hash]!), token);
          if (result.staticImageOnly) {
            throw const ImportMediaException(
              AttachmentRejectionReason.unverified,
            );
          }
          mediaTypes[file.hash] = result.type;
        }
      }
      return await ctx.db.transaction(() async {
        final id = saveEvent != null ? await saveEvent() : eventId!;
        final event = await EventRepository(ctx).find(id);
        if (event == null ||
            event.subjectId != ctx.subjectId ||
            event.deletedAt != null) {
          throw const EventStateException('事件不存在或已刪除');
        }
        ctx.ensureCanReadPrivate(event.privacy);
        // 先配置整批引用，排除相同草稿引用的重試；超額以整批總和回報。
        final references = <String, PreparedAttachment>{};
        for (final file in plan.files) {
          token.check();
          final referenceId = file.source.referenceId ?? ctx.newId();
          final repeated = references[referenceId];
          if (repeated != null) {
            if (repeated.hash != file.hash ||
                repeated.source.name != file.source.name) {
              throw ImportIntegrityException();
            }
            continue;
          }
          final prior = await (ctx.db.select(
            ctx.db.attachments,
          )..where((a) => a.id.equals(referenceId))).getSingleOrNull();
          if (prior != null) {
            final blob = await _existing(file.hash);
            if (prior.eventId != id ||
                prior.blobId != blob?.id ||
                prior.originalFilename != file.source.name) {
              throw ImportIntegrityException();
            }
            continue;
          }
          references[referenceId] = file;
        }
        // 沒有新引用時允許既有超額資料保存文字或重試；新增空檔仍須檢查。
        if (references.isNotEmpty) {
          AttachmentQuota.check(
            usedBytes: await _usedBytes(id),
            addedBytes: references.values.fold(
              0,
              (sum, file) => sum + file.size,
            ),
          );
        }
        for (final entry in references.entries) {
          final file = entry.value;
          token.check();
          final stamp = await ctx.stampForNew();
          var blob = await _existing(file.hash);
          if (blob == null) {
            final blobId = ctx.newId();
            await ctx.db
                .into(ctx.db.blobs)
                .insert(
                  BlobsCompanion.insert(
                    id: blobId,
                    sha256: file.hash,
                    byteSize: file.size,
                    mediaType: mediaTypes[file.hash]!,
                    path: paths[file.hash]!,
                    verifyStatus: 'verified',
                  ),
                );
            blob = await _existing(file.hash);
          } else if (blob.mediaType != mediaTypes[file.hash]) {
            await (ctx.db.update(
              ctx.db.blobs,
            )..where((b) => b.id.equals(blob!.id))).write(
              BlobsCompanion(mediaType: Value(mediaTypes[file.hash]!)),
            );
          }
          final attachmentId = entry.key;
          await ctx.db
              .into(ctx.db.attachments)
              .insert(
                AttachmentsCompanion.insert(
                  id: attachmentId,
                  eventId: id,
                  blobId: blob!.id,
                  displayName: file.source.name,
                  originalFilename: file.source.name,
                  capturedAt: Value(file.metadata.capturedAt),
                  capturedLatitude: Value(file.metadata.latitude),
                  capturedLongitude: Value(file.metadata.longitude),
                  importedAt: ctx.now(),
                  storageMode: 'full_copy',
                  layer: stamp.layerCode,
                  authorId: stamp.authorId,
                  createdAt: stamp.createdAt,
                  archiveSessionId: Value(stamp.archiveSessionId),
                ),
              );
          await ctx.recordChange(attachmentId, ChangeOperation.create);
        }
        token.check();
        return id;
      });
    } catch (_) {
      // 只清除此作業建立且未登錄的失敗副本，絕不動到來源或既有共用副本。
      for (final path in createdPaths) {
        final registered = await (ctx.db.select(
          ctx.db.blobs,
        )..where((b) => b.path.equals(path))).getSingleOrNull();
        if (registered == null && await File(path).exists()) {
          await File(path).delete();
        }
      }
      rethrow;
    } finally {
      for (final path in temporaryPaths) {
        if (await File(path).exists()) await File(path).delete();
      }
    }
  });

  Stream<List<StoredAttachment>> watch(String eventId) =>
      (ctx.db.select(ctx.db.attachments).join([
              innerJoin(
                ctx.db.events,
                ctx.db.events.id.equalsExp(ctx.db.attachments.eventId),
              ),
              innerJoin(
                ctx.db.blobs,
                ctx.db.blobs.id.equalsExp(ctx.db.attachments.blobId),
              ),
            ])
            ..where(
              ctx.db.attachments.eventId.equals(eventId) &
                  ctx.db.events.subjectId.equals(ctx.subjectId) &
                  (ctx.canReadPrivate
                      ? const Constant(true)
                      : ctx.db.events.privacy.equals('normal')),
            )
            ..orderBy([
              OrderingTerm.asc(ctx.db.attachments.importedAt),
              OrderingTerm.asc(ctx.db.attachments.id),
            ]))
          .watch()
          .map(
            (rows) => [
              for (final row in rows)
                StoredAttachment(
                  row.readTable(ctx.db.attachments),
                  row.readTable(ctx.db.blobs),
                ),
            ],
          );

  Future<void> removeReference(String id) => ctx.db.transaction(() async {
    final attachment = await (ctx.db.select(
      ctx.db.attachments,
    )..where((a) => a.id.equals(id))).getSingle();
    final event = await EventRepository(ctx).find(attachment.eventId);
    if (event == null || event.subjectId != ctx.subjectId) {
      throw const EventStateException('事件不存在');
    }
    ctx.ensureCanReadPrivate(event.privacy);
    await ctx.ensureCanModify(attachment.layer);
    await (ctx.db.delete(
      ctx.db.attachments,
    )..where((a) => a.id.equals(id))).go();
    await ctx.recordChange(id, ChangeOperation.delete);
  });

  /// 中斷後的 .partial 不會被登錄為可用附件；清理在使用者確認後進行。
  Future<List<File>> unreferencedFiles() async {
    await directory.create(recursive: true);
    final used = await ctx.db
        .customSelect(
          'SELECT DISTINCT b.path FROM blobs b '
          'JOIN attachments a ON a.blob_id=b.blob_id',
        )
        .get();
    final referenced = used
        .map((row) => _pathKey(row.read<String>('path')))
        .toSet();
    final result = (await directory.list().toList())
        .whereType<File>()
        .where((file) => !referenced.contains(_pathKey(file.path)))
        .toList();
    final draftMedia = Directory(p.join(directory.parent.path, 'draft_media'));
    final draftRecords = Directory(p.join(directory.parent.path, 'drafts'));
    final draftPaths = <String>{..._activeDraftPaths};
    if (await draftRecords.exists()) {
      for (final file
          in (await draftRecords.list().toList()).whereType<File>()) {
        try {
          final draft =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          for (final source in draft['attachments'] as List? ?? []) {
            draftPaths.add(_pathKey((source as Map)['path'] as String));
          }
        } catch (_) {
          // 無法讀取草稿時不能斷言其附件無引用，先保留所有草稿副本。
          return result;
        }
      }
    }
    if (await draftMedia.exists()) {
      result.addAll(
        (await draftMedia.list().toList()).whereType<File>().where(
          (file) => !draftPaths.contains(_pathKey(file.path)),
        ),
      );
    }
    result.addAll(
      (await PhotoWorkStore.interrupted(directory.parent)).where(
        (file) =>
            !referenced.contains(_pathKey(file.path)) &&
            !draftPaths.contains(_pathKey(file.path)),
      ),
    );
    result.addAll(
      (await PhotoCacheFiles.interrupted(photoCacheDirectory)).where(
        (file) =>
            !referenced.contains(_pathKey(file.path)) &&
            !draftPaths.contains(_pathKey(file.path)),
      ),
    );
    return result;
  }

  Future<void> cleanUnreferenced() => _exclusive(() async {
    for (final file in await unreferencedFiles()) {
      // 先刪除無引用的資料列；交易阻止其他寫入在檢查與刪除間建立新引用。
      await ctx.db.transaction(() async {
        final references = await ctx.db
            .customSelect(
              'SELECT count(*) AS n FROM attachments a '
              'JOIN blobs b ON b.blob_id=a.blob_id WHERE b.path=?',
              variables: [Variable.withString(file.path)],
            )
            .getSingle();
        if (references.read<int>('n') != 0) return;
        final blob = await (ctx.db.select(
          ctx.db.blobs,
        )..where((b) => b.path.equals(file.path))).getSingleOrNull();
        if (blob != null) {
          await (ctx.db.delete(
            ctx.db.blobs,
          )..where((b) => b.id.equals(blob.id))).go();
        }
        if (await file.exists()) await file.delete();
      });
    }
    await PhotoWorkStore.removeEmpty(directory.parent);
  });
  Future<void> openAttachment(StoredAttachment stored) async {
    final event = await EventRepository(ctx).find(stored.attachment.eventId);
    if (event == null || event.subjectId != ctx.subjectId) {
      throw const EventStateException('事件不存在');
    }
    ctx.ensureCanReadPrivate(event.privacy);
    if (!await _valid(stored.blob, ImportCancellation())) {
      throw ImportIntegrityException();
    }
    await platform.open(stored.blob.path, stored.blob.mediaType);
  }
}
