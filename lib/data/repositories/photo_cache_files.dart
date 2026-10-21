import 'dart:io';

import 'package:path/path.dart' as p;

/// 預覽產生中的檔案不可被倉庫清理；中斷殘檔須經既有確認流程。
abstract final class PhotoCacheFiles {
  static final _active = <String>{};
  static String _key(String path) => Platform.isWindows
      ? p.normalize(p.absolute(path)).toLowerCase()
      : p.normalize(p.absolute(path));
  static void protect(File file) => _active.add(_key(file.path));
  static void release(File file) => _active.remove(_key(file.path));
  static Future<List<File>> interrupted(Directory root) async {
    if (await FileSystemEntity.type(root.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      return [];
    }
    final result = <File>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is File &&
          p.basename(entity.path).endsWith('.partial') &&
          !_active.contains(_key(entity.path))) {
        result.add(entity);
      }
    }
    return result;
  }
}
