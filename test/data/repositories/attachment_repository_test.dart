import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/event_draft_store.dart';

import 'harness.dart';

class FakeAttachmentPlatform implements AttachmentPlatform {
  int free = 1 << 30;
  String? opened;
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

  test('相同影片在批次與兩事件共用一個 blob，來源刪除後副本可開啟', () async {
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
