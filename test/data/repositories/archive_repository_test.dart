import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:life_chronicle/core/archive/archive_integrity.dart';
import 'package:life_chronicle/core/archive/archive_reading.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/repositories/archive_repository.dart';
import 'package:life_chronicle/data/repositories/archive_restore.dart';
import 'package:life_chronicle/data/repositories/archive_zip.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/l10n/app_localizations_en.dart';
import 'package:life_chronicle/l10n/l10n_time_texts.dart';

import 'harness.dart';

class ArchiveTestPlatform implements AttachmentPlatform {
  int free = 1 << 40;
  @override
  Future<int> availableBytes(String path) async {
    if (!await Directory(path).exists()) {
      throw StateError('原生容量檢查需要存在的目錄');
    }
    return free;
  }

  @override
  Future<AttachmentMetadata> metadata(String path) async =>
      const AttachmentMetadata(mediaType: 'video/mp4');
  @override
  Future<void> open(String path, String mediaType) async {}
}

final reading = ArchiveReading({
  for (final key in [
    'timeline',
    'time',
    'layer',
    'author',
    'recorded',
    'category',
    'deleted',
    'original',
    'remembrance',
    'reflections',
    'attachments',
  ])
    key: key,
}, L10nTimeTexts(AppLocalizationsEn()));

const codec = ArchiveZip(controlPaths: {'README.md', 'SHA256SUMS.txt'});

void main() {
  late Harness h;
  late Directory root;
  late AttachmentRepository media;
  late ArchiveRepository repository;
  late ArchiveTestPlatform platform;
  setUp(() async {
    h = await Harness.create();
    root = await Directory.systemTemp.createTemp('archive-test-');
    platform = ArchiveTestPlatform();
    media = AttachmentRepository(
      h.context(),
      await Directory(p.join(root.path, 'media')).create(),
      platform,
    );
    repository = ArchiveRepository(
      h.context(),
      media,
      Directory(p.join(root.path, 'backups')),
      codec,
    );
  });
  tearDown(() async {
    await h.close();
    await root.delete(recursive: true);
  });

  Future<ArchiveExport> export({bool includeMedia = true}) async =>
      repository.export(
        await repository.prepare(includeMedia: includeMedia),
        reading,
        readme: '# Archive\n',
        appVersion: '1.0.0',
      );

  test('100 事件與共用媒體封存，另一個空資料庫還原筆數／層級／作者／時間／關聯', () async {
    final content = EventContentRepository(h.context());
    final ids = <String>[];
    for (var i = 0; i < 100; i++) {
      ids.add(
        await content.save(
          EventDraft(
            title: '# event * [$i]',
            time: HalfYearTime(2003, i.isEven ? 1 : 2),
            sections: [
              DraftSection(content: 'line one\nline two'),
              DraftSection(title: 'empty', content: ' '),
            ],
          ),
        ),
      );
    }
    await h.relations().link(ids[0], ids[1]);
    final original = File(p.join(root.path, 'original.mp4'));
    await original.writeAsBytes([1, 2, 3, 4]);
    final plan = await media.prepare([
      AttachmentSource(original.path, 'original.mp4'),
    ]);
    await media.importBatch(plan, eventId: ids[0]);
    await media.importBatch(plan, eventId: ids[1]);
    final result = await export();
    expect(await original.readAsBytes(), [1, 2, 3, 4]);
    expect(result.counts['events'], 100);
    expect(await ArchiveZip.fileHash(result.zip), result.hash);
    expect(await result.sidecar.readAsString(), startsWith(result.hash));
    final target = AppDatabase(NativeDatabase.memory());
    try {
      final ctx = RepositoryContext(
        target,
        subjectId: h.profile.subjectId,
        actingAuthorId: h.profile.selfAuthorId,
      );
      final targetMedia = AttachmentRepository(
        ctx,
        await Directory(p.join(root.path, 'target-media')).create(),
        platform,
      );
      final restore = ArchiveRestore(
        ArchiveRepository(
          ctx,
          targetMedia,
          Directory(p.join(root.path, 'new-target-backups')),
          codec,
        ),
      );
      final imported = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      expect(imported.conflicts, isEmpty);
      final report = await restore.apply(
        imported,
        {},
        cancellation: ImportCancellation(),
        validateSubjects: (_, _) async {},
      );
      expect(report.inserted['events'], 100);
      expect(
        await target.select(target.events).get(),
        await h.db.select(h.db.events).get(),
      );
      expect((await target.select(target.attachments).get()).length, 2);
      expect((await target.select(target.blobs).get()).length, 1);
      expect((await target.select(target.eventLinks).get()).length, 1);
      expect(
        await target.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      final file = File((await target.select(target.blobs).getSingle()).path);
      await original.delete();
      expect(await file.readAsBytes(), [1, 2, 3, 4]);
    } finally {
      await target.close();
    }
  });

  test('遭竄改 manifest、路徑逃逸、符號連結與容量不足均不改資料庫', () async {
    await EventContentRepository(h.context()).save(EventDraft(title: 'event'));
    final result = await export();
    final before = jsonEncode(await repository.snapshot());
    final decoded = ZipDecoder().decodeBytes(await result.zip.readAsBytes());
    decoded.add(ArchiveFile.string('manifest.json', '{}'));
    final corrupt = File(p.join(root.path, 'corrupt.zip'));
    await corrupt.writeAsBytes(ZipEncoder().encode(decoded));
    final restore = ArchiveRestore(repository);
    await expectLater(
      restore.inspect(corrupt, cancellation: ImportCancellation()),
      throwsA(isA<ArchiveIntegrityException>()),
    );
    for (final entry in [
      ArchiveFile.string('../escape.txt', 'bad'),
      ArchiveFile.string('link', 'data/events.json')
        ..symbolicLink = 'data/events.json'
        ..mode = 0xa1ff,
    ]) {
      final malicious = File(p.join(root.path, 'malicious.zip'));
      await malicious.writeAsBytes(ZipEncoder().encode(Archive()..add(entry)));
      await expectLater(
        restore.inspect(malicious, cancellation: ImportCancellation()),
        throwsA(isA<ArchiveIntegrityException>()),
      );
    }
    platform.free = 1;
    await expectLater(
      restore.inspect(result.zip, cancellation: ImportCancellation()),
      throwsA(isA<ImportSpaceException>()),
    );
    expect(jsonEncode(await repository.snapshot()), before);
    expect(
      await File(p.join(root.parent.path, 'escape.txt')).exists(),
      isFalse,
    );
  });

  test('附件損毀或取消匯出不留下正式 ZIP，原資料與原件不變', () async {
    final id = await EventContentRepository(h.context())
        .save(EventDraft(title: 'event'));
    final original = File(p.join(root.path, 'original.mp4'));
    await original.writeAsBytes([7, 8, 9]);
    await media.importBatch(
      await media.prepare([AttachmentSource(original.path, 'original.mp4')]),
      eventId: id,
    );
    final plan = await repository.prepare();
    await plan.media.values.single.writeAsBytes([0]);
    await expectLater(
      repository.export(plan, reading, readme: '# Archive\n', appVersion: '1'),
      throwsA(isA<ArchiveIntegrityException>()),
    );
    expect(
      (await repository.outputDirectory.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip')),
      isEmpty,
    );
    expect(await original.readAsBytes(), [7, 8, 9]);
    final token = ImportCancellation()..cancelled = true;
    await expectLater(
      repository.export(
        plan,
        reading,
        readme: '# Archive\n',
        appVersion: '1',
        cancellation: token,
      ),
      throwsA(isA<ImportCancelled>()),
    );
    expect((await h.db.select(h.db.events).get()).length, 1);
  });
}
