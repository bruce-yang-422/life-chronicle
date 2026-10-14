import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/app_database.dart';
import '../platform/attachment_platform.dart';
import 'event_repository.dart';
import 'repository_context.dart';

class ImportCancelled implements Exception {}

class ImportSpaceException implements Exception {}

class ImportIntegrityException implements Exception {}

class ImportCancellation {
  bool cancelled = false;
  void check() {
    if (cancelled) throw ImportCancelled();
  }
}

class AttachmentSource {
  const AttachmentSource(this.path, this.name, {this.referenceId});
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
    this.existing,
  );
  final AttachmentSource source;
  final int size;
  final String hash;
  final AttachmentMetadata metadata;
  final Blob? existing;
}

class AttachmentImportPlan {
  const AttachmentImportPlan(
    this.files,
    this.originalBytes,
    this.addedBytes,
    this.freeBytes,
    this.duplicates,
  );
  final List<PreparedAttachment> files;
  final int originalBytes;
  final int addedBytes;
  final int freeBytes;
  final int duplicates;
}

class StoredAttachment {
  const StoredAttachment(this.attachment, this.blob);
  final Attachment attachment;
  final Blob blob;
}

/// 批次匯入採全有或全無：所有檔案驗證後，才以同一資料庫交易登錄。
class AttachmentRepository {
  AttachmentRepository(this.ctx, this.directory, this.platform);
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
    return AttachmentRepository(ctx, directory, DeviceAttachmentPlatform());
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
  }) async {
    final digest = await sha256
        .bind(
          file.openRead().map((bytes) {
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
  Future<bool> _valid(Blob blob, ImportCancellation cancellation) async {
    final file = File(blob.path);
    return blob.verifyStatus == 'verified' &&
        await file.exists() &&
        await file.length() == blob.byteSize &&
        await _hash(file, cancellation) == blob.sha256;
  }

  Future<AttachmentImportPlan> prepare(
    List<AttachmentSource> sources, {
    ImportCancellation? cancellation,
    void Function(int done, int total)? onProgress,
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
    final unique = <String>{};
    for (final source in sources) {
      token.check();
      final file = File(source.path);
      final size = await file.length();
      final hash = await _hash(
        file,
        token,
        onBytes: (bytes) {
          done += bytes;
          onProgress?.call(done, total);
        },
      );
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
      files.add(
        PreparedAttachment(
          source,
          size,
          hash,
          await platform.metadata(source.path),
          blob,
        ),
      );
    }
    return AttachmentImportPlan(files, total, added, free, duplicates);
  }

  /// 使用者確認後，將尚未提交的附件留在持久性草稿目錄，避免系統清除 picker 快取。
  Future<List<AttachmentSource>> retainForDraft(
    AttachmentImportPlan plan,
    ImportCancellation token, {
    void Function(int done, int total)? onProgress,
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
    try {
      for (final source in plan.files) {
        token.check();
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
          ),
        );
        final sink = target.openWrite();
        try {
          await for (final bytes in File(source.source.path).openRead()) {
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
  }) => _exclusive(() async {
    final token = cancellation ?? ImportCancellation();
    final temporaryPaths = <String>[];
    final createdPaths = <String>[];
    final paths = <String, String>{};
    var done = 0;
    try {
      if (await platform.availableBytes(directory.path) < plan.addedBytes) {
        throw ImportSpaceException();
      }
      for (final file in plan.files) {
        token.check();
        if (paths.containsKey(file.hash)) continue;
        final existing = await _existing(file.hash);
        if (existing != null) {
          if (existing.byteSize != file.size ||
              !await _valid(existing, token)) {
            throw ImportIntegrityException();
          }
          paths[file.hash] = existing.path;
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
          continue;
        }
        final temporary = File(
          p.join(directory.path, '${ctx.newId()}.partial'),
        );
        temporaryPaths.add(temporary.path);
        final sink = temporary.openWrite();
        try {
          await for (final bytes in File(file.source.path).openRead()) {
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
      }
      token.check();
      return await ctx.db.transaction(() async {
        final id = saveEvent != null ? await saveEvent() : eventId!;
        final event = await EventRepository(ctx).find(id);
        if (event == null ||
            event.subjectId != ctx.subjectId ||
            event.deletedAt != null) {
          throw const EventStateException('事件不存在或已刪除');
        }
        ctx.ensureCanReadPrivate(event.privacy);
        for (final file in plan.files) {
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
                    mediaType: file.metadata.mediaType,
                    path: paths[file.hash]!,
                    verifyStatus: 'verified',
                  ),
                );
            blob = await _existing(file.hash);
          }
          final attachmentId = file.source.referenceId ?? ctx.newId();
          final prior = await (ctx.db.select(
            ctx.db.attachments,
          )..where((a) => a.id.equals(attachmentId))).getSingleOrNull();
          if (prior != null) {
            if (prior.eventId != id ||
                prior.blobId != blob!.id ||
                prior.originalFilename != file.source.name) {
              throw ImportIntegrityException();
            }
            continue;
          }
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
