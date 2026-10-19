import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/archive/archive_integrity.dart';
import 'attachment_repository.dart';

class VerifiedArchive {
  VerifiedArchive(this.directory, this.manifest, this.extraFiles);
  final Directory directory;
  final Map<String, Object?> manifest;
  final List<String> extraFiles;
}

/// 串流讀寫媒體，解壓前先檢查中央目錄，絕不使用 ZIP 內的路徑直接寫檔。
class ArchiveZip {
  const ArchiveZip();

  static Future<String> fileHash(
    File file, {
    ImportCancellation? cancellation,
  }) async =>
      (await sha256
              .bind(
                file.openRead().map((bytes) {
                  cancellation?.check();
                  return bytes;
                }),
              )
              .first)
          .toString();

  Future<void> write(
    File output,
    Map<String, File> files, {
    required ImportCancellation cancellation,
    void Function(int done, int total)? onProgress,
  }) async {
    final stream = OutputFileStream(output.path);
    final encoder = ZipEncoder()..startEncode(stream);
    try {
      var done = 0;
      for (final entry in files.entries) {
        cancellation.check();
        if (!ArchiveIntegrity.safePath(entry.key)) {
          throw ArchiveIntegrityException([entry.key]);
        }
        final input = InputFileStream(entry.value.path);
        try {
          encoder.add(
            ArchiveFile.stream(entry.key, input)
              ..compression = entry.key.startsWith('media/')
                  ? CompressionType.none
                  : CompressionType.deflate,
          );
        } finally {
          input.closeSync();
        }
        onProgress?.call(++done, files.length);
        await Future<void>.delayed(Duration.zero);
      }
      cancellation.check();
      encoder.endEncode();
    } finally {
      stream.closeSync();
    }
  }

  Future<VerifiedArchive> verify(
    File zip,
    Directory staging, {
    required int freeBytes,
    required ImportCancellation cancellation,
    bool allowExtra = false,
    void Function(int done, int total)? onProgress,
  }) async {
    final input = InputFileStream(zip.path);
    try {
      final directory = ZipDirectory()..read(input);
      final names = <String>{};
      var declared = 0;
      for (final header in directory.fileHeaders) {
        cancellation.check();
        final name = header.filename;
        final fileType = (header.externalFileAttributes >> 16) & 0xf000;
        if (!ArchiveIntegrity.safePath(name) ||
            !names.add(name) ||
            fileType == 0xa000 ||
            fileType == 0x4000 ||
            (header.generalPurposeBitFlag & 1) != 0 ||
            ![0, 8].contains(header.compressionMethod) ||
            header.uncompressedSize < 0 ||
            header.compressedSize < 0 ||
            (header.uncompressedSize > 1024 * 1024 &&
                header.uncompressedSize > (header.compressedSize + 1) * 1000)) {
          throw ArchiveIntegrityException([name]);
        }
        declared += header.uncompressedSize;
      }
      // 暫存與還原副本可能同時存在，先保留雙倍解壓容量。
      if (declared * 2 > freeBytes) throw ImportSpaceException();
      if (!names.contains(ArchiveIntegrity.manifestPath) ||
          !names.contains(ArchiveIntegrity.sumsPath)) {
        throw const ArchiveIntegrityException([
          'manifest.json',
          'SHA256SUMS.txt',
        ]);
      }
      await staging.create(recursive: true);
      var done = 0;
      // 所有輸出路徑均已驗證，仍以絕對路径檢查限定在暫存目錄。
      for (final header in directory.fileHeaders) {
        cancellation.check();
        final target = p.joinAll([staging.path, ...header.filename.split('/')]);
        if (!p.isWithin(p.absolute(staging.path), p.absolute(target))) {
          throw ArchiveIntegrityException([header.filename]);
        }
        final file = File(target);
        await file.parent.create(recursive: true);
        final output = OutputFileStream(file.path);
        try {
          header.file!.decompress(output);
        } finally {
          output.closeSync();
        }
        if (await file.length() != header.uncompressedSize) {
          throw ArchiveIntegrityException([header.filename]);
        }
        onProgress?.call(++done, directory.fileHeaders.length * 2);
        await Future<void>.delayed(Duration.zero);
      }
      final hashes = ArchiveIntegrity.parseSums(
        await File(p.join(staging.path, ArchiveIntegrity.sumsPath))
            .readAsString(),
      );
      if (await fileHash(
            File(p.join(staging.path, ArchiveIntegrity.manifestPath)),
          ) !=
          hashes[ArchiveIntegrity.manifestPath]) {
        throw const ArchiveIntegrityException(['manifest.json']);
      }
      final manifest = jsonDecode(
        await File(p.join(staging.path, ArchiveIntegrity.manifestPath))
            .readAsString(),
      ) as Map<String, Object?>;
      final version = (manifest['format_version'] as String).split('.');
      if (manifest['format'] != 'life-chronicle-archive' ||
          version.length != 2 ||
          int.tryParse(version[0]) != 1 ||
          int.tryParse(version[1]) == null ||
          manifest['schema_version'] != 1) {
        throw const ArchiveIntegrityException(['manifest.json']);
      }
      final listed = <String, Map<String, Object?>>{};
      for (final item in manifest['files'] as List) {
        final row = Map<String, Object?>.from(item as Map);
        final name = row['path'] as String;
        if (!ArchiveIntegrity.safePath(name) ||
            name == ArchiveIntegrity.manifestPath ||
            name == ArchiveIntegrity.sumsPath ||
            listed.containsKey(name) ||
            row['sha256'] != hashes[name]) {
          throw ArchiveIntegrityException([name]);
        }
        listed[name] = row;
      }
      final expected = {...listed.keys, ArchiveIntegrity.manifestPath};
      if (hashes.keys.toSet().difference(expected).isNotEmpty ||
          expected.difference(hashes.keys.toSet()).isNotEmpty) {
        throw const ArchiveIntegrityException(['SHA256SUMS.txt']);
      }
      final extras = names.difference({
        ...expected,
        ArchiveIntegrity.sumsPath,
      }).toList();
      if ((!allowExtra && extras.isNotEmpty) ||
          expected.difference(names).isNotEmpty) {
        throw ArchiveIntegrityException([
          ...extras,
          ...expected.difference(names),
        ]);
      }
      final damaged = <String>[];
      for (final name in expected) {
        cancellation.check();
        final file = File(p.joinAll([staging.path, ...name.split('/')]));
        if (!await file.exists() ||
            await fileHash(file) != hashes[name] ||
            (listed.containsKey(name) &&
                await file.length() != listed[name]!['byte_size'])) {
          damaged.add(name);
        }
        onProgress?.call(++done, directory.fileHeaders.length * 2);
      }
      if (damaged.isNotEmpty) throw ArchiveIntegrityException(damaged);
      cancellation.check();
      return VerifiedArchive(staging, manifest, extras);
    } finally {
      input.closeSync();
    }
  }
}
