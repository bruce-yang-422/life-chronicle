import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../core/archive/archive_integrity.dart';
import '../../core/archive/archive_part_plan.dart';
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
    List<File> additionalParts = const [],
    void Function(int done, int total)? onProgress,
  }) async {
    final input = InputFileStream(zip.path);
    try {
      final directory = ZipDirectory()..read(input);
      final names = <String>{};
      var declared = 0;
      var headerCount = directory.fileHeaders.length;
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
      for (final part in additionalParts) {
        final stream = InputFileStream(part.path);
        try {
          final other = ZipDirectory()..read(stream);
          headerCount += other.fileHeaders.length - 1;
          for (final header in other.fileHeaders) {
            if (header.uncompressedSize < 0) {
              throw ArchiveIntegrityException([header.filename]);
            }
            declared += header.uncompressedSize;
          }
        } finally {
          stream.closeSync();
        }
      }
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
        onProgress?.call(++done, headerCount * 2 - 1);
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
      final parts = manifest['parts'] as List;
      if (parts.length > 1 || additionalParts.isNotEmpty) {
        final required = <String, Set<String>>{};
        final assigned = <String>{};
        for (final item in parts) {
          final part = item as Map;
          final filename = part['filename'] as String;
          final paths = (part['files'] as List).cast<String>();
          if (p.basename(filename) != filename ||
              !RegExp(r'^[A-Za-z0-9_.-]+\.zip$').hasMatch(filename) ||
              required.containsKey(filename) ||
              paths.any(
                (name) =>
                    !ArchiveIntegrity.safePath(name) || !assigned.add(name),
              )) {
            throw const ArchiveIntegrityException(['manifest.json']);
          }
          required[filename] = paths.toSet();
        }
        if (required.isEmpty) {
          throw const ArchiveIntegrityException(['manifest.json']);
        }
        final actualMain = names.difference({
          ArchiveIntegrity.manifestPath,
          ArchiveIntegrity.sumsPath,
        });
        final expectedMain = required.values.first;
        if (expectedMain.difference(actualMain).isNotEmpty ||
            (!allowExtra && actualMain.difference(expectedMain).isNotEmpty)) {
          throw const ArchiveIntegrityException(['manifest.json']);
        }
        final pending = required.keys.skip(1).toSet();
        for (final part in additionalParts) {
          var name = p.basename(part.path);
          if (name.endsWith('.partial')) {
            name = name.substring(0, name.length - 8);
          }
          if (!pending.remove(name)) throw ArchiveIntegrityException([name]);
          final result = await _readMediaPart(
            part,
            staging,
            names,
            freeBytes: freeBytes,
            cancellation: cancellation,
            onEntry: () => onProgress?.call(++done, headerCount * 2 - 1),
          );
          if (result.names.difference(required[name]!).isNotEmpty ||
              required[name]!.difference(result.names).isNotEmpty) {
            throw ArchiveIntegrityException([name]);
          }
          names.addAll(result.names);
          hashes.addAll(result.hashes);
        }
        if (pending.isNotEmpty) {
          throw ArchiveMissingPartsException(pending.toList());
        }
        if (assigned
                .difference(
                  (manifest['files'] as List)
                      .map((row) => (row as Map)['path'])
                      .toSet(),
                )
                .isNotEmpty ||
            (manifest['files'] as List).any(
              (row) => !assigned.contains((row as Map)['path']),
            )) {
          throw const ArchiveIntegrityException(['manifest.json']);
        }
      }
      final version = (manifest['format_version'] as String).split('.');
      if (manifest['format'] != 'life-chronicle-archive' ||
          version.length != 2 ||
          int.tryParse(version[0]) != 1 ||
          int.tryParse(version[1]) == null ||
          ![1, 2].contains(manifest['schema_version'])) {
        throw const ArchiveIntegrityException(['manifest.json']);
      }
      final listed = <String, Map<String, Object?>>{};
      final scope = manifest['scope'] as Map;
      final privacy = scope['private_events'];
      if (privacy != null &&
          (privacy is! Map ||
              scope['type'] != 'custom' ||
              privacy['reason'] != 'private_events' ||
              ['events', 'media', 'snapshots', 'history'].any(
                (field) =>
                    privacy[field] is! int || (privacy[field] as int) < 0,
              ))) {
        throw const ArchiveIntegrityException(['manifest.json']);
      }
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
            await fileHash(file, cancellation: cancellation) != hashes[name] ||
            (listed.containsKey(name) &&
                await file.length() != listed[name]!['byte_size'])) {
          damaged.add(name);
        }
        onProgress?.call(++done, headerCount * 2 - 1);
      }
      if (damaged.isNotEmpty) throw ArchiveIntegrityException(damaged);
      cancellation.check();
      return VerifiedArchive(staging, manifest, extras);
    } finally {
      input.closeSync();
    }
  }

  /// 選取順序無關；完整組合恰有一個含 manifest 的第一包。
  Future<VerifiedArchive> verifyParts(
    List<File> parts,
    Directory staging, {
    required int freeBytes,
    required ImportCancellation cancellation,
    bool allowExtra = false,
    void Function(int done, int total)? onProgress,
  }) async {
    File? first;
    var mediaOnly = false;
    for (final file in parts) {
      cancellation.check();
      final input = InputFileStream(file.path);
      try {
        final directory = ZipDirectory()..read(input);
        mediaOnly =
            mediaOnly ||
            directory.fileHeaders.any((h) => h.filename.startsWith('media/'));
        if (directory.fileHeaders.any(
          (h) => h.filename == ArchiveIntegrity.manifestPath,
        )) {
          if (first != null) {
            throw const ArchiveIntegrityException(['manifest.json']);
          }
          first = file;
        }
      } finally {
        input.closeSync();
      }
    }
    if (first == null) {
      if (mediaOnly) {
        throw const ArchiveMissingPartsException(['manifest.json']);
      }
      throw const ArchiveIntegrityException(['manifest.json']);
    }
    return verify(
      first,
      staging,
      freeBytes: freeBytes,
      cancellation: cancellation,
      allowExtra: allowExtra,
      additionalParts: parts.where((f) => f != first).toList(),
      onProgress: onProgress,
    );
  }

  Future<({Set<String> names, Map<String, String> hashes})> _readMediaPart(
    File zip,
    Directory staging,
    Set<String> existing, {
    required int freeBytes,
    required ImportCancellation cancellation,
    void Function()? onEntry,
  }) async {
    final input = InputFileStream(zip.path);
    try {
      final directory = ZipDirectory()..read(input);
      final names = <String>{};
      var declared = 0;
      for (final header in directory.fileHeaders) {
        final name = header.filename;
        final type = (header.externalFileAttributes >> 16) & 0xf000;
        if (!ArchiveIntegrity.safePath(name) ||
            !names.add(name) ||
            (name != ArchiveIntegrity.sumsPath && !name.startsWith('media/')) ||
            existing.contains(name) && name != ArchiveIntegrity.sumsPath ||
            type == 0xa000 ||
            type == 0x4000 ||
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
      if (declared * 2 > freeBytes) throw ImportSpaceException();
      if (!names.remove(ArchiveIntegrity.sumsPath)) {
        throw const ArchiveIntegrityException(['SHA256SUMS.txt']);
      }
      final sumHeader = directory.fileHeaders.singleWhere(
        (h) => h.filename == ArchiveIntegrity.sumsPath,
      );
      // 校驗清單有明確上界，不能利用文字控制檔耗盡記憶體。
      if (sumHeader.uncompressedSize > (names.length + 1) * 256) {
        throw const ArchiveIntegrityException(['SHA256SUMS.txt']);
      }
      final sumOutput = OutputMemoryStream();
      sumHeader.file!.decompress(sumOutput);
      final hashes = ArchiveIntegrity.parseSums(
        utf8.decode(sumOutput.getBytes()),
      );
      if (hashes.keys.toSet().difference(names).isNotEmpty ||
          names.difference(hashes.keys.toSet()).isNotEmpty) {
        throw const ArchiveIntegrityException(['SHA256SUMS.txt']);
      }
      for (final header in directory.fileHeaders) {
        if (header.filename == ArchiveIntegrity.sumsPath) continue;
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
        if (await file.length() != header.uncompressedSize ||
            await fileHash(file, cancellation: cancellation) !=
                hashes[header.filename]) {
          throw ArchiveIntegrityException([header.filename]);
        }
        onEntry?.call();
      }
      return (names: names, hashes: hashes);
    } finally {
      input.closeSync();
    }
  }
}
