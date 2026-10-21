import 'dart:io';

import 'package:path/path.dart' as p;

/// 僅管理照片預覽工作目錄；不遍歷草稿、倉庫或外部原件。
abstract final class PhotoWorkStore {
  static final _active = <String>{};
  static String _key(String path) => Platform.isWindows
      ? p.normalize(p.absolute(path)).toLowerCase()
      : p.normalize(p.absolute(path));
  static Directory root(Directory support) =>
      Directory(p.join(support.path, 'photo_work'));
  static Future<void> _checkRoot(Directory support) async {
    final parent = root(support);
    final type = await FileSystemEntity.type(parent.path, followLinks: false);
    if (type != FileSystemEntityType.notFound &&
        type != FileSystemEntityType.directory) {
      throw FileSystemException('照片暫存根目錄不可為連結或檔案', parent.path);
    }
  }

  static Future<Directory> create(Directory support) async {
    await _checkRoot(support);
    final parent = await root(support).create(recursive: true);
    final work = await parent.createTemp('import-');
    _active.add(_key(work.path));
    return work;
  }

  static Future<void> release(Directory support, Directory work) async {
    await _checkRoot(support);
    if (!p.equals(p.dirname(_key(work.path)), _key(root(support).path)) ||
        !p.basename(work.path).startsWith('import-')) {
      throw FileSystemException('無效的照片暫存目錄', work.path);
    }
    try {
      if (await work.exists()) await work.delete(recursive: true);
    } finally {
      _active.remove(_key(work.path));
    }
  }

  static Future<List<File>> interrupted(Directory support) async {
    await _checkRoot(support);
    final parent = root(support);
    if (!await parent.exists()) return [];
    final files = <File>[];
    await for (final entity in parent.list(followLinks: false)) {
      if (entity is! Directory ||
          !p.basename(entity.path).startsWith('import-') ||
          _active.contains(_key(entity.path))) {
        continue;
      }
      await for (final file in entity.list(
        recursive: true,
        followLinks: false,
      )) {
        if (file is File) files.add(file);
      }
    }
    return files;
  }

  static Future<void> removeEmpty(Directory support) async {
    await _checkRoot(support);
    final parent = root(support);
    if (!await parent.exists()) return;
    await for (final entity in parent.list(followLinks: false)) {
      if (entity is! Directory ||
          !p.basename(entity.path).startsWith('import-') ||
          _active.contains(_key(entity.path))) {
        continue;
      }
      // 非遞迴刪除：若另有檔案或連結，必須保留。
      try {
        await entity.delete();
      } on FileSystemException {
        /* 非空或已移除 */
      }
    }
  }
}
