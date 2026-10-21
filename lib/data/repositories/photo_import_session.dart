import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/attachments/photo_compression.dart';
import '../../core/attachments/photo_preferences.dart';
import 'photo_work_store.dart';
import 'photo_preview_cache.dart';
import '../platform/attachment_platform.dart';
import '../platform/photo_platform.dart';
import 'attachment_repository.dart';

/// Owns only a freshly created work directory; external originals are never disposable.
class PhotoImportSession {
  PhotoImportSession(
    this.repository,
    this.platform, {
    this.preferences = const PhotoPreferences(),
  });
  final PhotoPreferences preferences;
  final AttachmentRepository repository;
  final PhotoPlatform platform;
  Directory? _work;

  Future<PhotoInfo?> inspect(PreparedAttachment file) async {
    if (!const {
      'image/jpeg',
      'image/png',
      'image/heif',
      'image/heic',
      'image/webp',
    }.contains(file.metadata.mediaType)) {
      return null;
    }
    return platform.inspect(file.source.path);
  }

  late final _previews = PhotoPreviewCache(
    repository.photoCacheDirectory,
    platform,
    repository.ctx.newId,
  );

  Future<File> preview(
    PreparedAttachment file,
    int edge,
    ImportCancellation token,
  ) async {
    await _verifyOriginal(file, token);
    final result = await _previews.get(file, edge, token);
    try {
      await _verifyOriginal(file, token);
    } catch (_) {
      await _previews.invalidate(file, edge);
      rethrow;
    }
    return result;
  }

  Future<void> _verifyOriginal(
    PreparedAttachment original,
    ImportCancellation token,
  ) async {
    final check = await repository.prepare([
      original.source,
    ], cancellation: token);
    if (check.files.length != 1 ||
        check.files.single.hash != original.hash ||
        check.files.single.size != original.size) {
      throw ImportIntegrityException();
    }
  }

  Future<({PreparedAttachment file, PhotoOutput output})> compress(
    PreparedAttachment original,
    PhotoPreset preset,
    ImportCancellation token,
  ) async {
    token.check();
    await _verifyOriginal(original, token);
    final info = await inspect(original);
    if (info == null) throw ImportIntegrityException();
    final expected = PhotoCompressionPolicy.dimensions(
      info.width,
      info.height,
      preset,
    );
    // 先保留安全餘量，再建立壓縮暫存；以 RGBA 原始像素作保守估算。
    await repository.ensureSpace(expected.width * expected.height * 4 + 65536);
    _work ??= await PhotoWorkStore.create(repository.directory.parent);
    final id = repository.ctx.newId();
    final outputPath = p.join(_work!.path, '$id.photo');
    var cancelling = false;
    final timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (token.cancelled && !cancelling) {
        cancelling = true;
        unawaited(platform.cancel(id).catchError((Object _) {}));
      }
    });
    try {
      final output = await platform.compress(
        original.source.path,
        outputPath,
        preset,
        id,
        keepGps: preferences.keepGps,
      );
      token.check();
      await _verifyOriginal(original, token);
      if (output.path != outputPath && output.path != original.source.path) {
        throw ImportIntegrityException();
      }
      if (output.keptOriginal) {
        if (!preferences.keepGps || output.path != original.source.path) {
          throw ImportIntegrityException();
        }
        return (file: original, output: output);
      }
      if (output.path != outputPath ||
          output.width != expected.width ||
          output.height != expected.height ||
          (output.width > preset.longEdge || output.height > preset.longEdge) ||
          !const {'image/jpeg', 'image/png'}.contains(output.mediaType) ||
          (output.mediaType == 'image/jpeg' &&
              !PhotoCompressionPolicy.qualities.contains(output.quality)) ||
          (output.mediaType == 'image/png' && output.quality != null)) {
        throw ImportIntegrityException();
      }
      final extension = output.mediaType == 'image/png' ? '.png' : '.jpg';
      final plan = await repository.prepare([
        AttachmentSource(
          output.path,
          '${p.basenameWithoutExtension(original.source.name)}$extension',
        ),
      ], cancellation: token);
      if (plan.files.length != 1 || plan.rejected.isNotEmpty) {
        throw ImportIntegrityException();
      }
      final file = plan.files.single;
      if (file.size != output.bytes ||
          file.metadata.mediaType != output.mediaType) {
        throw ImportIntegrityException();
      }
      if (preferences.keepGps && file.size >= original.size) {
        await File(outputPath).delete();
        return (
          file: original,
          output: PhotoOutput(
            original.source.path,
            output.width,
            output.height,
            original.size,
            original.metadata.mediaType,
            null,
            true,
          ),
        );
      }
      return (
        file: PreparedAttachment(
          file.source,
          file.size,
          file.hash,
          AttachmentMetadata(
            mediaType: file.metadata.mediaType,
            capturedAt: original.metadata.capturedAt,
            latitude: original.metadata.latitude,
            longitude: original.metadata.longitude,
          ),
          file.existing,
          sourceBytes: file.sourceBytes,
        ),
        output: output,
      );
    } finally {
      timer.cancel();
    }
  }

  Future<void> dispose() async {
    final work = _work;
    _work = null;
    if (work != null) {
      await PhotoWorkStore.release(repository.directory.parent, work);
    }
  }
}
