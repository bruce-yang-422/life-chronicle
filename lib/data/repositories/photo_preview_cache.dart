import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';

import '../platform/photo_platform.dart';
import 'attachment_repository.dart';
import 'photo_cache_files.dart';

/// 可重建的去定位預覽，與附件倉庫及事件容量完全分開。
class PhotoPreviewCache {
  PhotoPreviewCache(this.directory, this.platform, this.newId);
  final Directory directory;
  final PhotoPlatform platform;
  final String Function() newId;
  static final _pending = <String, Future<File>>{};

  Future<bool> _valid(File file, int edge, {bool checksum = true}) async {
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return false;
    }
    try {
      if (checksum) {
        final manifest = File('${file.path}.sha256');
        if (await FileSystemEntity.type(manifest.path, followLinks: false) !=
            FileSystemEntityType.file) {
          return false;
        }
        final expected = (await manifest.readAsString()).trim();
        if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(expected) ||
            (await sha256.bind(file.openRead()).first).toString() != expected) {
          return false;
        }
      }
      final info = await platform.inspect(file.path);
      return info != null &&
          info.hasGps == false &&
          info.width > 0 &&
          info.height > 0 &&
          info.width <= edge &&
          info.height <= edge &&
          await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  Future<File> get(
    PreparedAttachment source,
    int edge,
    ImportCancellation token,
  ) async {
    if (!const [80, 512, 1600].contains(edge) ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(source.hash)) {
      throw ImportIntegrityException();
    }
    token.check();
    final rootType = await FileSystemEntity.type(
      directory.path,
      followLinks: false,
    );
    if (rootType != FileSystemEntityType.notFound &&
        rootType != FileSystemEntityType.directory) {
      throw ImportIntegrityException();
    }
    await directory.create(recursive: true);
    final target = File(
      p.join(directory.path, '${source.hash}_${edge}_v1.preview'),
    );
    final key = p.normalize(p.absolute(target.path));
    final pending = _pending[key];
    if (pending != null) {
      final result = await pending;
      token.check();
      return result;
    }
    final operation = _generate(source, target, edge, token);
    _pending[key] = operation;
    try {
      return await operation;
    } finally {
      _pending.remove(key);
    }
  }

  Future<void> invalidate(PreparedAttachment source, int edge) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(source.hash) ||
        !const [80, 512, 1600].contains(edge)) {
      throw ImportIntegrityException();
    }
    final file = File(
      p.join(directory.path, '${source.hash}_${edge}_v1.preview'),
    );
    for (final owned in [file, File('${file.path}.sha256')]) {
      if (await FileSystemEntity.type(owned.path, followLinks: false) ==
          FileSystemEntityType.file) {
        await owned.delete();
      }
    }
  }

  Future<File> _generate(
    PreparedAttachment source,
    File target,
    int edge,
    ImportCancellation token,
  ) async {
    if (await _valid(target, edge)) {
      token.check();
      return target;
    }
    final id = newId();
    final temporary = File(p.join(directory.path, '$id.partial'));
    final digest = File(p.join(directory.path, '$id.digest.partial'));
    PhotoCacheFiles.protect(temporary);
    PhotoCacheFiles.protect(digest);
    var cancelling = false;
    final timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (token.cancelled && !cancelling) {
        cancelling = true;
        unawaited(platform.cancel(id).catchError((Object _) {}));
      }
    });
    try {
      final output = await platform.preview(
        source.source.path,
        temporary.path,
        edge,
        id,
      );
      token.check();
      if (output.path != temporary.path ||
          output.keptOriginal ||
          output.width > edge ||
          output.height > edge ||
          output.width <= 0 ||
          output.height <= 0 ||
          !const {'image/png', 'image/jpeg'}.contains(output.mediaType) ||
          !await _valid(temporary, edge, checksum: false) ||
          await temporary.length() != output.bytes) {
        throw ImportIntegrityException();
      }
      await digest.writeAsString(
        (await sha256.bind(temporary.openRead()).first).toString(),
        flush: true,
      );
      token.check();
      await temporary.rename(target.path);
      await digest.rename('${target.path}.sha256');
      return target;
    } finally {
      timer.cancel();
      try {
        if (await temporary.exists()) await temporary.delete();
        if (await digest.exists()) await digest.delete();
      } finally {
        PhotoCacheFiles.release(temporary);
        PhotoCacheFiles.release(digest);
      }
    }
  }
}
