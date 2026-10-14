import 'dart:convert';

import 'package:crypto/crypto.dart';

class ArchiveIntegrityException implements Exception {
  const ArchiveIntegrityException(this.paths);
  final List<String> paths;
}

/// 控制檔的校驗層級避免自我雜湊循環；不依賴資料庫與平台。
abstract final class ArchiveIntegrity {
  static const manifestPath = 'manifest.json';
  static const sumsPath = 'SHA256SUMS.txt';
  static String hash(List<int> bytes) => sha256.convert(bytes).toString();
  static bool safePath(String name, {Set<String> controlPaths = const {}}) =>
      name.length <= 160 &&
      !name.startsWith('/') &&
      !name.contains('\\') &&
      !name.split('/').any((s) => s.isEmpty || s == '.' || s == '..') &&
      (RegExp(r'^[a-z0-9_./-]+$').hasMatch(name) ||
          controlPaths.contains(name)) &&
      !name.split('/').any((s) => s.startsWith('.'));

  static Map<String, String> parseSums(
    String text, {
    Set<String> controlPaths = const {},
  }) {
    final result = <String, String>{};
    for (final line in const LineSplitter().convert(text)) {
      final match = RegExp(r'^([0-9a-f]{64})  (.+)$').firstMatch(line);
      if (match == null ||
          !safePath(match[2]!, controlPaths: controlPaths) ||
          result.containsKey(match[2])) {
        throw const ArchiveIntegrityException([sumsPath]);
      }
      result[match[2]!] = match[1]!;
    }
    if (result.containsKey(sumsPath)) {
      throw const ArchiveIntegrityException([sumsPath]);
    }
    return result;
  }

  static String sums(Map<String, String> hashes) {
    final names = hashes.keys.toList()..sort();
    return '${names.map((name) => '${hashes[name]}  $name').join('\n')}\n';
  }
}
