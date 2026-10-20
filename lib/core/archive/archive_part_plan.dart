import 'dart:convert';

import 'archive_integrity.dart';

class ArchivePartSizeException implements Exception {
  const ArchivePartSizeException(this.paths);
  final List<String> paths;
}

class ArchiveMissingPartsException extends ArchiveIntegrityException {
  const ArchiveMissingPartsException(this.names) : super(names);
  final List<String> names;
}

/// 媒體不切碎；每個 ZIP 都是獨立檔。文字與完整 manifest 留在第一包。
class ArchivePartPlan {
  ArchivePartPlan({
    required Map<String, int> sizes,
    required String base,
    required int manifestBytes,
    int? maxBytes,
  }) {
    if (maxBytes != null && maxBytes <= 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes');
    }
    final text = sizes.keys.where((name) => !name.startsWith('media/')).toList()
      ..sort();
    final media = sizes.keys.where((name) => name.startsWith('media/')).toList()
      ..sort();
    final groups = [
      <String>[...text],
    ];
    if (maxBytes == null) {
      groups.first.addAll(media);
    } else {
      int budget(List<String> paths, bool first) {
        final sumsBytes = [
          ...paths,
          if (first) ArchiveIntegrity.manifestPath,
        ].fold<int>(0, (sum, name) => sum + 67 + utf8.encode(name).length);
        return 128 +
            bound(ArchiveIntegrity.sumsPath, sumsBytes) +
            (first ? bound(ArchiveIntegrity.manifestPath, manifestBytes) : 0) +
            paths.fold<int>(0, (sum, name) => sum + bound(name, sizes[name]!));
      }

      if (budget(groups.first, true) > maxBytes) {
        throw ArchivePartSizeException(text);
      }
      for (final name in media) {
        if (budget([...groups.last, name], groups.length == 1) > maxBytes) {
          if (budget([name], false) > maxBytes) {
            throw ArchivePartSizeException([name]);
          }
          groups.add([]);
        }
        groups.last.add(name);
      }
    }
    files = [for (final group in groups) List.unmodifiable(group)];
    names = [
      for (var i = 0; i < groups.length; i++)
        groups.length == 1 ? '$base.zip' : partName(base, i + 1, groups.length),
    ];
  }

  late final List<List<String>> files;
  late final List<String> names;

  static String partName(String base, int index, int total) =>
      '${base}_part${'$index'.padLeft(2, '0')}-of-${'$total'.padLeft(2, '0')}.zip';

  /// Store 媒體用實際長度；文字預留 Deflate 最壞膨脹與 ZIP64 標頭。
  /// 寫完仍核對實際 ZIP 長度，不會將超限包宣稱為成功。
  static int bound(String name, int size) =>
      size +
      (name.startsWith('media/')
          ? 0
          : (size + 7) ~/ 8 + (size + 63) ~/ 64 + 64) +
      256 +
      2 * utf8.encode(name).length;
}
