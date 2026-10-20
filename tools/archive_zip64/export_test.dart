import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/repositories/archive_repository.dart';
import 'package:life_chronicle/data/repositories/archive_restore.dart';
import 'package:life_chronicle/data/repositories/archive_zip.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/profile_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';

import '../../test/data/repositories/archive_repository_test.dart'
    show reading, ArchiveTestPlatform;
import '../../test/data/repositories/harness.dart';

// ignore_for_file: avoid_print

/// 明確執行的大型驗收；產物限 build，不併入一般回歸或模擬器資料。
/// flutter test tools/archive_zip64/export_test.dart --timeout 30m
void main() {
  test('超過 4 GiB 的單檔經正式 ZIP 匯出與完整還原，校驗一致', () async {
    final root = await Directory('build/zip64_acceptance')
        .create(recursive: true);
    final source = File('${root.path}/source.bin');
    const size = 0x100000000 + 65536;
    final writer = await source.open(mode: FileMode.write);
    try {
      await writer.truncate(size);
      await writer.setPosition(0);
      await writer.writeString('ZIP64_HEAD_MARKER');
      await writer.setPosition(size - 32);
      await writer.writeString('ZIP64_TAIL_MARKER');
      await writer.flush();
    } finally {
      await writer.close();
    }
    expect(await source.length(), size);
    final sourceHash = await ArchiveZip.fileHash(source);
    print('ZIP64_STAGE=source_ready BYTES=$size HASH=$sourceHash');
    final h = await Harness.create();
    final targetDb = AppDatabase(NativeDatabase.memory());
    try {
      await h.db
          .into(h.db.blobs)
          .insert(
            BlobsCompanion.insert(
              id: h.context().newId(),
              sha256: sourceHash,
              byteSize: size,
              mediaType: 'application/octet-stream',
              path: source.absolute.path,
              verifyStatus: 'verified',
            ),
          );
      final platform = ArchiveTestPlatform();
      final repo = ArchiveRepository(
        h.context(),
        AttachmentRepository(
          h.context(),
          await Directory('${root.path}/source_media').create(),
          platform,
        ),
        await Directory('${root.path}/exports').create(),
        const ArchiveZip(),
      );
      final before = await repo.snapshot();
      final result = await repo.export(
        await repo.prepare(),
        reading,
        readme: '# ZIP64 acceptance\n',
        appVersion: '1.0.0',
        onProgress: (done, total) {
          if (done == total) print('ZIP64_STAGE=export_phase_complete');
        },
      );
      expect(await result.zip.length(), greaterThan(0xffffffff));
      print('ZIP64_STAGE=export_verified ZIP=${result.zip.path}');
      final profile = await ProfileRepository(targetDb).ensureDefaultProfile();
      final targetCtx = RepositoryContext(
        targetDb,
        subjectId: profile.subjectId,
        actingAuthorId: profile.selfAuthorId,
      );
      final target = ArchiveRepository(
        targetCtx,
        AttachmentRepository(
          targetCtx,
          await Directory('${root.path}/restored_media').create(),
          platform,
        ),
        await Directory('${root.path}/restore_work').create(),
        const ArchiveZip(),
      );
      final restore = ArchiveRestore(target);
      final incoming = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      print('ZIP64_STAGE=restore_inspected');
      await restore.apply(incoming, {}, cancellation: ImportCancellation());
      final blob = (await targetDb.select(targetDb.blobs).get()).single;
      final restored = File(blob.path);
      expect(await restored.length(), size);
      expect(await ArchiveZip.fileHash(restored), sourceHash);
      expect(await repo.snapshot(), before);
      expect(await source.exists(), isTrue);
      final report = {
        'source': source.absolute.path,
        'zip': result.zip.absolute.path,
        'restored': restored.absolute.path,
        'bytes': size,
        'sha256': sourceHash,
        'zip_sha256': result.hash,
        'source_unchanged': true,
        'restore_integrity':
            (await targetDb.customSelect('PRAGMA integrity_check').getSingle())
                .data,
        'foreign_keys':
            (await targetDb.customSelect('PRAGMA foreign_key_check').get())
                .length,
      };
      await File('${root.path}/report.json')
          .writeAsString(jsonEncode(report), flush: true);
      print('ZIP64_STAGE=complete REPORT=${root.path}/report.json');
    } finally {
      await targetDb.close();
      await h.close();
    }
  }, timeout: const Timeout(Duration(minutes: 30)));
}
