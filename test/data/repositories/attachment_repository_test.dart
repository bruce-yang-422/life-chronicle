import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:path/path.dart' as p;

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/attachment_quota.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/event_draft_store.dart';

import 'harness.dart';

import 'package:life_chronicle/core/attachments/attachment_file_progress.dart';

import '../../support/media_samples.dart';
import '../../support/mpeg_samples.dart';

class FakeAttachmentPlatform implements AttachmentPlatform {
  int free = 1 << 30;
  String? opened;
  // 刻意提供錯誤 MIME，確保內容判定不採信平台回報。
  String mediaType = 'video/mp4';
  @override
  Future<int> availableBytes(String directory) async => free;
  @override
  Future<AttachmentMetadata> metadata(String path) async => AttachmentMetadata(
    mediaType: mediaType,
    capturedAt: DateTime.utc(2003, 9, 15),
  );
  @override
  Future<void> open(String path, String mediaType) async {
    opened = path;
  }
}

void main() {
  late Harness h;
  late Directory root;
  late AttachmentRepository repository;
  late FakeAttachmentPlatform platform;
  late EventContentRepository content;
  setUp(() async {
    h = await Harness.create();
    root = await Directory.systemTemp.createTemp('media-test-');
    platform = FakeAttachmentPlatform();
    repository = AttachmentRepository(
      h.context(),
      Directory('${root.path}/media'),
      platform,
    );
    content = EventContentRepository(h.context());
  });
  tearDown(() async {
    await h.close();
    await root.delete(recursive: true);
  });
  Future<AttachmentSource> source(String name, List<int> bytes) async {
    final file = File('${root.path}/$name');
    await file.writeAsBytes(bytes);
    return AttachmentSource(file.path, name);
  }

  Future<AttachmentSource> sizedSource(String name, int size) async {
    final file = File('${root.path}/$name');
    final handle = await file.open(mode: FileMode.write);
    try {
      await handle.writeByte(42);
      await handle.truncate(size);
    } finally {
      await handle.close();
    }
    return AttachmentSource(file.path, name);
  }

  test('預覽草稿額度不重算已保存引用，新引用即使相同內容仍計入', () async {
    final original = await source('note.txt', [42, 43]);
    final retry = AttachmentSource(
      original.path,
      original.name,
      referenceId: 'retry-preview',
    );
    final plan = await repository.prepare([retry]);
    final id = await repository.importBatch(
      plan,
      saveEvent: () => content.save(EventDraft(title: 'preview')),
    );
    expect(await repository.pendingBytes(id, plan), 0);
    final fresh = AttachmentSource(
      original.path,
      original.name,
      referenceId: 'new-preview',
    );
    final pending = await repository.prepare([retry, fresh, fresh]);
    expect(await repository.pendingBytes(id, pending), 2);
    expect(await repository.usedBytes(id), 2);
    final other = await content.save(EventDraft(title: 'other'));
    await expectLater(
      repository.pendingBytes(other, plan),
      throwsA(isA<ImportIntegrityException>()),
    );
  });

  test('準備、草稿與匯入逐檔回報；重複內容不漏計已處理件數', () async {
    final inputs = [
      await source('first.txt', [42, 43]),
      await source('second.txt', [42, 43]),
      await source('video.mp4', bmff(['vide'])),
    ];
    final prepared = <AttachmentFileProgress>[];
    final plan = await repository.prepare(inputs, onFileProgress: prepared.add);
    expect(prepared.map((v) => v.completed), [0, 1, 1, 2, 2, 3]);
    expect(prepared.last.remaining, 0);
    expect(prepared.last.total, 3);
    final copied = <AttachmentFileProgress>[];
    await repository.retainForDraft(
      plan,
      ImportCancellation(),
      onFileProgress: copied.add,
    );
    expect(copied.map((v) => v.completed), [0, 1, 1, 2]);
    final imported = <AttachmentFileProgress>[];
    final id = await repository.importBatch(
      plan,
      onFileProgress: imported.add,
      saveEvent: () => content.save(EventDraft(title: 'progress')),
    );
    expect(imported.map((v) => v.completed), [0, 1, 1, 2]);
    expect(imported.last.name, 'second.txt');
    expect((await repository.watch(id).first), hasLength(2));
  });

  test('混合批次依內容排除改名影片，純音訊與非媒體仍可保存', () async {
    final sources = [
      for (final name in ['fake.jpg', 'fake.pdf', 'fake.m4a'])
        await source(name, bmff(['soun', 'vide'])),
      await source('voice.m4a', bmff(['soun'])),
      await source('voice.webm', matroska([2])),
      await source('actually-a-document.mp4', ascii.encode('%PDF-1.7')),
      await source('notes.txt', ascii.encode('notes')),
    ];
    final plan = await repository.prepare(sources);
    expect(plan.files, hasLength(4));
    expect(
      plan.rejected.map((file) => file.reason),
      everyElement(AttachmentRejectionReason.video),
    );
    expect(plan.rejected, hasLength(3));
    final id = await repository.importBatch(
      plan,
      saveEvent: () => content.save(EventDraft(title: '混合匯入')),
    );
    final rows = await repository.watch(id).first;
    expect(rows, hasLength(4));
    expect(
      rows.map((row) => row.blob.mediaType),
      containsAll([
        'audio/mp4',
        'audio/webm',
        'application/pdf',
        'application/octet-stream',
      ]),
    );
    expect(
      plan.originalBytes,
      rows.fold(0, (sum, row) => sum + row.blob.byteSize),
    );
    for (final file in sources) {
      expect(await File(file.path).exists(), isTrue);
    }
  });

  test('手製影片計畫無法繞過最終保存或草稿保留的內容檢查', () async {
    final bytes = bmff(['vide']);
    final file = await source('disguised.pdf', bytes);
    final forged = AttachmentImportPlan(
      [
        PreparedAttachment(
          file,
          bytes.length,
          sha256.convert(bytes).toString(),
          const AttachmentMetadata(mediaType: 'application/pdf'),
          null,
        ),
      ],
      bytes.length,
      bytes.length,
      1 << 30,
      0,
    );
    await expectLater(
      repository.importBatch(
        forged,
        saveEvent: () => content.save(EventDraft(title: '不能保存')),
      ),
      throwsA(isA<ImportMediaException>()),
    );
    await expectLater(
      repository.retainForDraft(forged, ImportCancellation()),
      throwsA(isA<ImportMediaException>()),
    );
    expect(await h.db.select(h.db.events).get(), isEmpty);
    expect(await h.db.select(h.db.blobs).get(), isEmpty);
    expect(await repository.directory.list().toList(), isEmpty);
    expect(
      await Directory('${root.path}/draft_media').list().toList(),
      isEmpty,
    );
  });

  test('動態照片只保存靜態圖，草稿與直接匯入使用相同結果和雜湊', () async {
    final bytes = [
      ...stillJpeg,
      ...bmff(['vide']),
    ];
    final file = await source('motion.jpg', bytes);
    final plan = await repository.prepare([file]);
    expect(plan.files.single.staticImageOnly, isTrue);
    expect(plan.files.single.size, stillJpeg.length);
    expect(plan.files.single.hash, sha256.convert(stillJpeg).toString());
    final retained = await repository.retainForDraft(
      plan,
      ImportCancellation(),
    );
    expect(await File(retained.single.path).readAsBytes(), stillJpeg);
    final id = await repository.importBatch(
      plan,
      saveEvent: () => content.save(EventDraft(title: '動態照片')),
    );
    final row = (await repository.watch(id).first).single;
    expect(row.blob.mediaType, 'image/jpeg');
    expect(row.blob.byteSize, stillJpeg.length);
    expect(await File(row.blob.path).readAsBytes(), stillJpeg);
    expect(await File(file.path).readAsBytes(), bytes);
    expect(await repository.usedBytes(id), stillJpeg.length);
    await repository.releaseDraftSources(retained);
  });

  test('純音訊 MPEG 的標準 video MIME 不造成誤拒絕，含影片的版本仍排除', () async {
    final sources = [
      await source('sound.ts', transport([track(0x0f, 0x101)])),
      await source('movie.jpg', transport([track(0x1b, 0x101)])),
      await source('sound.ps', [
        ...psPack,
        ...pes(0xc0, [1]),
      ]),
      await source('movie.pdf', [
        ...psPack,
        ...pes(0xe0, [1]),
      ]),
    ];
    final plan = await repository.prepare(sources);
    expect(plan.files, hasLength(2));
    expect(plan.rejected, hasLength(2));
    final id = await repository.importBatch(
      plan,
      saveEvent: () => content.save(EventDraft(title: '錄音 MPEG')),
    );
    expect(
      (await repository.watch(id).first).map((s) => s.blob.mediaType),
      containsAll(['video/mp2t', 'video/mpeg']),
    );
  });

  test('無法驗證的容器逐檔排除，不當成未知一般附件放行', () async {
    final file = await source('broken.txt', [
      0,
      0,
      0,
      255,
      ...ascii.encode('ftyp'),
    ]);
    final plan = await repository.prepare([file]);
    expect(plan.files, isEmpty);
    expect(plan.rejected.single.reason, AttachmentRejectionReason.unverified);
    expect(plan.originalBytes, 0);
    expect(plan.addedBytes, 0);
    expect(await h.db.select(h.db.blobs).get(), isEmpty);
  });

  test('準備後來源長度增加，不默默截斷成原先大小保存', () async {
    final file = await source('growing.txt', [1, 2, 3]);
    final plan = await repository.prepare([file]);
    await File(file.path).writeAsBytes([4], mode: FileMode.append);
    await expectLater(
      repository.importBatch(
        plan,
        saveEvent: () => content.save(EventDraft(title: '長度變動')),
      ),
      throwsA(isA<ImportIntegrityException>()),
    );
    expect(await h.db.select(h.db.events).get(), isEmpty);
  });

  test('同一副本重複引用各計額度，25 MB 可保存，多 1 byte 整批回復', () async {
    final id = await content.save(EventDraft(title: '額度'));
    final file = await sizedSource('data.bin', 12500000);
    await repository.importBatch(
      await repository.prepare([file, file]),
      eventId: id,
    );
    expect(await repository.usedBytes(id), AttachmentQuota.limitBytes);
    expect(await h.db.select(h.db.blobs).get(), hasLength(1));
    final extra = await source('extra.txt', [65]);
    final before = await h.db.select(h.db.changeHistory).get();
    await expectLater(
      repository.importBatch(await repository.prepare([extra]), eventId: id),
      throwsA(
        isA<AttachmentQuotaExceeded>().having(
          (error) => error.excessBytes,
          '超額位元組',
          1,
        ),
      ),
    );
    expect(await repository.watch(id).first, hasLength(2));
    expect(await h.db.select(h.db.changeHistory).get(), before);
    expect(await h.db.select(h.db.blobs).get(), hasLength(1));
    expect(await repository.directory.list().length, 1);
    expect(await File(extra.path).readAsBytes(), [65]);
    final other = await content.save(EventDraft(title: '另一事件'));
    await repository.importBatch(
      await repository.prepare([file]),
      eventId: other,
    );
    expect(await repository.usedBytes(other), 12500000);
    expect(await repository.usedBytes(id), 25000000);
    expect(await h.db.select(h.db.blobs).get(), hasLength(1));
  });

  test('新事件超額時事件、修訂、附件與副本均不留下', () async {
    final file = await sizedSource('too-large.bin', 25000001);
    final before = await h.db.select(h.db.changeHistory).get();
    await expectLater(
      repository.importBatch(
        await repository.prepare([file]),
        saveEvent: () => content.save(EventDraft(title: '不能保存')),
      ),
      throwsA(isA<AttachmentQuotaExceeded>()),
    );
    expect(await h.db.select(h.db.events).get(), isEmpty);
    expect(await h.db.select(h.db.attachments).get(), isEmpty);
    expect(await h.db.select(h.db.blobs).get(), isEmpty);
    expect(await h.db.select(h.db.changeHistory).get(), before);
    expect(await repository.directory.list().toList(), isEmpty);
    expect(await File(file.path).length(), 25000001);
  });

  test('滿額草稿重試不重複扣額，也不新增引用', () async {
    final original = await sizedSource('full.bin', 25000000);
    final file = AttachmentSource(
      original.path,
      original.name,
      referenceId: 'retry',
    );
    final id = await content.save(EventDraft(title: '重試額度'));
    await repository.importBatch(await repository.prepare([file]), eventId: id);
    await repository.importBatch(await repository.prepare([file]), eventId: id);
    expect(await repository.usedBytes(id), 25000000);
    expect(await repository.watch(id).first, hasLength(1));
  });

  test('追憶和原始附件合併計額，失敗保留兩層既有內容', () async {
    final id = await content.save(EventDraft(title: '兩層額度'));
    final file = await sizedSource('shared.bin', 12500000);
    await repository.importBatch(await repository.prepare([file]), eventId: id);
    await h.activateArchive();
    final family = AttachmentRepository(
      h.context(actingAuthorId: h.familyAuthorId),
      repository.directory,
      platform,
    );
    await family.importBatch(await family.prepare([file]), eventId: id);
    final extra = await source('memory.txt', [1]);
    await expectLater(
      family.importBatch(await family.prepare([extra]), eventId: id),
      throwsA(isA<AttachmentQuotaExceeded>()),
    );
    final rows = await family.watch(id).first;
    expect(
      rows.map((row) => row.attachment.layer),
      containsAll(['original', 'remembrance']),
    );
    expect(rows, hasLength(2));
    expect(await family.usedBytes(id), 25000000);
  });

  test('多個 Repository 同時新增不能各自用過時額度通過', () async {
    final id = await content.save(EventDraft(title: '同時新增'));
    final a = await sizedSource('a.bin', 15000000);
    final b = await sizedSource('b.bin', 14000000);
    final other = AttachmentRepository(
      h.context(),
      repository.directory,
      platform,
    );
    final plans = await Future.wait([
      repository.prepare([a]),
      other.prepare([b]),
    ]);
    final results = await Future.wait([
      repository
          .importBatch(plans[0], eventId: id)
          .then<Object>((id) => id, onError: (Object error) => error),
      other
          .importBatch(plans[1], eventId: id)
          .then<Object>((id) => id, onError: (Object error) => error),
    ]);
    expect(results.whereType<String>(), hasLength(1));
    expect(results.whereType<AttachmentQuotaExceeded>(), hasLength(1));
    expect(await repository.usedBytes(id), lessThanOrEqualTo(25000000));
    expect(await repository.watch(id).first, hasLength(1));
    expect(await repository.directory.list().length, 1);
  });

  test('超額回報整批總和，事件編輯與修訂一併回復', () async {
    final id = await content.save(EventDraft(title: '保留標題'));
    final file = await sizedSource('batch.bin', 13000000);
    final plan = await repository.prepare([file, file, file]);
    final before = await h.db.select(h.db.changeHistory).get();
    await expectLater(
      repository.importBatch(
        plan,
        saveEvent: () =>
            content.save(EventDraft(eventId: id, title: '不應保存的標題')),
      ),
      throwsA(
        isA<AttachmentQuotaExceeded>().having(
          (error) => error.excessBytes,
          '整批超額',
          14000000,
        ),
      ),
    );
    expect((await content.load(id))!.event.title, '保留標題');
    expect(await h.db.select(h.db.changeHistory).get(), before);
    expect(await repository.usedBytes(id), 0);
    expect(await repository.directory.list().toList(), isEmpty);
  });

  test('相同草稿引用重複選取只計一次，衝突引用拒絕整批', () async {
    final original = await sizedSource('reference.bin', 25000000);
    final file = AttachmentSource(
      original.path,
      original.name,
      referenceId: 'one',
    );
    final id = await content.save(EventDraft(title: '引用身分'));
    await repository.importBatch(
      await repository.prepare([file, file]),
      eventId: id,
    );
    expect(await repository.usedBytes(id), 25000000);
    expect(await repository.watch(id).first, hasLength(1));
    final collision = AttachmentSource(
      original.path,
      'different.bin',
      referenceId: 'one',
    );
    await expectLater(
      repository.importBatch(
        await repository.prepare([collision]),
        eventId: id,
      ),
      throwsA(isA<ImportIntegrityException>()),
    );
    expect(await repository.usedBytes(id), 25000000);
  });

  test('偽造重複副本的計畫大小不能少算額度', () async {
    final file = await source('real.txt', [1, 2, 3]);
    final plan = await repository.prepare([file]);
    final prepared = plan.files.single;
    final forged = AttachmentImportPlan(
      [
        prepared,
        PreparedAttachment(file, 1, prepared.hash, prepared.metadata, null),
      ],
      4,
      3,
      plan.freeBytes,
      1,
    );
    await expectLater(
      repository.importBatch(
        forged,
        saveEvent: () => content.save(EventDraft(title: '偽造')),
      ),
      throwsA(isA<ImportIntegrityException>()),
    );
    expect(await h.db.select(h.db.events).get(), isEmpty);
    expect(await h.db.select(h.db.blobs).get(), isEmpty);
    expect(await repository.directory.list().toList(), isEmpty);
  });

  test('既有超額事件仍可只編輯文字，但不接受新的空附件', () async {
    final file = await source('legacy.txt', [1]);
    final id = await repository.importBatch(
      await repository.prepare([file]),
      saveEvent: () => content.save(EventDraft(title: '舊版資料')),
    );
    // 模擬舊版資料的額度，不經新的新增入口寫入。
    await h.db.customStatement('UPDATE blobs SET byte_size = 25000001');
    final emptyPlan = await repository.prepare([]);
    await repository.importBatch(
      emptyPlan,
      saveEvent: () => content.save(EventDraft(eventId: id, title: '仍可修改文字')),
    );
    expect((await content.load(id))!.event.title, '仍可修改文字');
    expect(await repository.usedBytes(id), 25000001);
    final emptyFile = await source('empty.txt', []);
    await expectLater(
      repository.importBatch(
        await repository.prepare([emptyFile]),
        eventId: id,
      ),
      throwsA(isA<AttachmentQuotaExceeded>()),
    );
    expect(await repository.watch(id).first, hasLength(1));
  });

  test('300 筆引用不因件數拒絕', () async {
    final file = await source('small.txt', [65]);
    final id = await repository.importBatch(
      await repository.prepare(List.filled(300, file)),
      saveEvent: () => content.save(EventDraft(title: '很多附件')),
    );
    expect(await repository.usedBytes(id), 300);
    expect(await repository.watch(id).first, hasLength(300));
    expect(await h.db.select(h.db.blobs).get(), hasLength(1));
  });

  test('提交後草稿清理中斷再試，同一待匯入附件不重複登錄', () async {
    final original = await source('retry.mp4', [1, 2, 3]);
    final retained = await repository.retainForDraft(
      await repository.prepare([original]),
      ImportCancellation(),
    );
    final draft = EventDraft(
      title: '重試',
      creationId: content.reserveCreationId(),
    );
    final plan = await repository.prepare(retained);
    final id = await repository.importBatch(
      plan,
      saveEvent: () => content.save(draft),
    );
    await repository.importBatch(
      await repository.prepare(retained),
      saveEvent: () => content.save(draft),
    );
    expect(await h.db.select(h.db.events).get(), hasLength(1));
    expect(await repository.watch(id).first, hasLength(1));
  });

  test('相同非影片測資在批次與兩事件共用一個 blob，來源刪除後副本可開啟', () async {
    final file = await source(
      'movie.mp4',
      List.generate(200000, (i) => i % 256),
    );
    final a = await content.save(EventDraft(title: 'A'));
    final b = await content.save(EventDraft(title: 'B'));
    final plan = await repository.prepare([file, file]);
    expect(plan.duplicates, 1);
    expect(plan.addedBytes, 200000);
    await repository.importBatch(plan, eventId: a);
    final duplicate = await repository.prepare([file]);
    expect(duplicate.addedBytes, 0);
    expect(duplicate.duplicates, 1);
    await repository.importBatch(duplicate, eventId: b);
    expect(await h.db.select(h.db.blobs).get(), hasLength(1));
    final stored = (await repository.watch(b).first).single;
    expect(stored.attachment.originalFilename, 'movie.mp4');
    expect(stored.attachment.capturedAt, DateTime.utc(2003, 9, 15));
    await File(file.path).delete();
    await h.events().softDelete(a);
    await h.events().purge(a);
    await repository.openAttachment(stored);
    expect(platform.opened, stored.blob.path);
    expect(await File(stored.blob.path).length(), 200000);
    expect(await repository.unreferencedFiles(), isEmpty);
  });
  test('追憶照片在軟刪除、復原及永久刪除後皆保留且可開啟', () async {
    platform.mediaType = 'image/jpeg';
    final original = await source('original.jpg', [255, 216, 1, 255, 217]);
    final memory = await source('memory.jpg', [255, 216, 2, 255, 217]);
    final eventId = await content.save(EventDraft(title: '海邊回憶'));
    await repository.importBatch(
      await repository.prepare([original]),
      eventId: eventId,
    );
    final originalStored = (await repository.watch(eventId).first).single;

    await h.activateArchive();
    final remembrance = AttachmentRepository(
      h.context(actingAuthorId: h.familyAuthorId),
      repository.directory,
      platform,
    );
    await remembrance.importBatch(
      await remembrance.prepare([memory]),
      eventId: eventId,
    );
    final memoryStored = (await remembrance.watch(eventId).first).singleWhere(
      (stored) => stored.attachment.layer == 'remembrance',
    );
    await h.deactivateArchive();

    await h.events().softDelete(eventId);
    expect(await h.events().watchTimeline().first, isEmpty);
    expect(
      (await content.load(eventId, includeDeleted: true))!.event.title,
      '海邊回憶',
    );
    expect(await repository.watch(eventId).first, hasLength(2));
    await repository.openAttachment(memoryStored);
    expect(platform.opened, memoryStored.blob.path);

    await h.events().restore(eventId);
    expect(await h.events().watchTimeline().first, hasLength(1));
    expect(await repository.watch(eventId).first, hasLength(2));

    await h.events().softDelete(eventId);
    expect(await h.events().purge(eventId), isTrue);
    final kept = (await content.load(eventId, includeDeleted: true))!.event;
    expect(kept.title, '海邊回憶');
    expect(kept.purgedAt, isNotNull);
    expect(
      (await repository.watch(eventId).first).single.attachment.id,
      memoryStored.attachment.id,
    );
    await File(memory.path).delete();
    await repository.openAttachment(memoryStored);
    expect(await File(memoryStored.blob.path).readAsBytes(), [
      255,
      216,
      2,
      255,
      217,
    ]);
    expect(await File(original.path).exists(), isTrue);
    expect(await File(originalStored.blob.path).exists(), isTrue);
    expect(
      (await repository.unreferencedFiles()).map((file) => file.path),
      contains(originalStored.blob.path),
    );
    await repository.cleanUnreferenced();
    expect(await File(memoryStored.blob.path).exists(), isTrue);
    expect(await File(original.path).exists(), isTrue);
  });

  test('後面檔案被更改導致整批失敗，不留下任何引用或副本', () async {
    final a = await source('first.mp4', [1, 2, 3]);
    final b = await source('second.mp4', [4, 5, 6]);
    final plan = await repository.prepare([a, b]);
    await File(b.path).writeAsBytes([7, 8, 9]);
    await expectLater(
      repository.importBatch(
        plan,
        saveEvent: () => content.save(EventDraft(title: '失敗')),
      ),
      throwsA(isA<ImportIntegrityException>()),
    );
    expect(await h.db.select(h.db.events).get(), isEmpty);
    expect(await h.db.select(h.db.blobs).get(), isEmpty);
    expect(await h.db.select(h.db.attachments).get(), isEmpty);
    expect(await repository.directory.list().toList(), isEmpty);
    expect(await File(a.path).readAsBytes(), [1, 2, 3]);
  });
  test('匯入取消清理 .partial，重啟後孤立暫存只在確認清理時移除', () async {
    final a = await source('big.mp4', List.filled(200000, 4));
    final plan = await repository.prepare([a]);
    final token = ImportCancellation();
    await expectLater(
      repository.importBatch(
        plan,
        saveEvent: () => content.save(EventDraft(title: '取消')),
        cancellation: token,
        onProgress: (done, total) => token.cancelled = true,
      ),
      throwsA(isA<ImportCancelled>()),
    );
    expect(await repository.directory.list().toList(), isEmpty);
    final interrupted = File(
      '${repository.directory.path}/interrupted.partial',
    );
    await interrupted.writeAsBytes([1, 2]);
    final reopened = AttachmentRepository(
      h.context(),
      repository.directory,
      platform,
    );
    expect(await reopened.unreferencedFiles(), hasLength(1));
    expect(await h.db.select(h.db.attachments).get(), isEmpty);
    expect(await interrupted.exists(), isTrue);
    await reopened.cleanUnreferenced();
    expect(await interrupted.exists(), isFalse);
  });
  test('空間不足時不建立事件，來源檔保留', () async {
    final file = await source('large.mp4', [1, 2, 3]);
    final plan = await repository.prepare([file]);
    platform.free = 2;
    await expectLater(
      repository.importBatch(
        plan,
        saveEvent: () => content.save(EventDraft(title: '不能保存')),
      ),
      throwsA(isA<ImportSpaceException>()),
    );
    expect(await File(file.path).exists(), isTrue);
    expect(await h.db.select(h.db.events).get(), isEmpty);
  });
  test('交易中的權限失敗會回復所有 blob、附件及新副本', () async {
    final id = await content.save(EventDraft(title: '原事件'));
    await h.activateArchive();
    final file = await source('movie.mp4', [1, 2, 3]);
    final plan = await repository.prepare([file]);
    await expectLater(
      repository.importBatch(plan, eventId: id),
      throwsA(isA<Exception>()),
    );
    expect(await h.db.select(h.db.blobs).get(), isEmpty);
    expect(await h.db.select(h.db.attachments).get(), isEmpty);
    expect(await repository.directory.list().toList(), isEmpty);
  });
  test('附件草稿存於持久性目錄，來源刪除後仍可提交並清理草稿副本', () async {
    final sourceFile = await source('draft.mp4', [1, 2, 3]);
    final plan = await repository.prepare([sourceFile]);
    final retained = await repository.retainForDraft(
      plan,
      ImportCancellation(),
    );
    expect(retained.single.path, contains('draft_media'));
    await File(sourceFile.path).delete();
    final retainedPlan = await repository.prepare(retained);
    final id = await repository.importBatch(
      retainedPlan,
      saveEvent: () => content.save(EventDraft(title: '有附件')),
    );
    expect(await repository.watch(id).first, hasLength(1));
    await repository.releaseDraftSources(retained);
    expect(await File(retained.single.path).exists(), isFalse);
    expect(
      await File((await repository.watch(id).first).single.blob.path).exists(),
      isTrue,
    );
  });
  test('重啟後保護草稿附件，只清理中斷的孤立草稿副本', () async {
    final draftMedia = Directory('${root.path}/draft_media');
    await draftMedia.create();
    final kept = File('${draftMedia.path}/kept.jpg');
    await kept.writeAsBytes([1, 2, 3]);
    final orphan = File('${draftMedia.path}/interrupted.partial');
    await orphan.writeAsBytes([4, 5]);
    final store = FileEventDraftStore(Directory('${root.path}/drafts'));
    await store.save(
      'new',
      EventDraft(
        title: '保留',
        attachments: [
          {'path': kept.path, 'name': 'kept.jpg'},
        ],
      ),
    );
    final unreferenced = await repository.unreferencedFiles();
    expect(unreferenced.map((file) => p.normalize(file.path)), [
      p.normalize(orphan.path),
    ]);
    await repository.cleanUnreferenced();
    expect(await kept.exists(), isTrue);
    expect(await orphan.exists(), isFalse);
  });
  test('損毀既有副本不得被當作去重成功', () async {
    final file = await source('movie.mp4', [1, 2, 3]);
    final id = await content.save(EventDraft(title: 'A'));
    await repository.importBatch(await repository.prepare([file]), eventId: id);
    final blob = (await h.db.select(h.db.blobs).get()).single;
    await File(blob.path).writeAsBytes([7, 8, 9]);
    await expectLater(
      repository.prepare([file]),
      throwsA(isA<ImportIntegrityException>()),
    );
  });
}
