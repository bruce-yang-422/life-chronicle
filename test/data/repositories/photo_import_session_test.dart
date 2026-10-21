import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/photo_compression.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/data/platform/photo_platform.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/photo_import_session.dart';

import 'attachment_repository_test.dart' show FakeAttachmentPlatform;
import 'harness.dart';

import 'package:life_chronicle/core/attachments/photo_preferences.dart';
import 'package:life_chronicle/data/repositories/photo_work_store.dart';

import 'package:path/path.dart' as p;
import 'package:life_chronicle/data/platform/attachment_platform.dart';

class FakePhotos implements PhotoPlatform {
  static final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a/RcAAAAASUVORK5CYII=',
  );
  bool fail = false,
      wrongBytes = false,
      waitForCancel = false,
      cancelled = false;
  bool? receivedKeepGps;
  int? outputLength;
  String? foreignPath;
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<PhotoInfo?> inspect(String path) async => const PhotoInfo(5000, 3000);
  @override
  Future<PhotoOutput> compress(
    String path,
    String output,
    PhotoPreset preset,
    String requestId, {
    bool keepGps = true,
  }) async {
    receivedKeepGps = keepGps;
    if (fail) throw PlatformException(code: 'photo_error');
    if (!started.isCompleted) started.complete();
    if (waitForCancel) {
      await release.future;
      throw PlatformException(code: 'photo_cancelled');
    }
    await File(output).writeAsBytes([
      ...png,
      if (outputLength != null) ...List.filled(outputLength!, 0),
    ]);
    final size = PhotoCompressionPolicy.dimensions(5000, 3000, preset);
    return PhotoOutput(
      foreignPath ?? output,
      size.width,
      size.height,
      await File(output).length() + (wrongBytes ? 1 : 0),
      'image/png',
      null,
      false,
    );
  }

  @override
  Future<PhotoOutput> preview(
    String path,
    String output,
    int longEdge,
    String requestId,
  ) async {
    await File(output).writeAsBytes(png);
    return PhotoOutput(output, 1, 1, png.length, 'image/png', null, false);
  }

  @override
  Future<void> cancel(String requestId) async {
    cancelled = true;
    if (!release.isCompleted) release.complete();
  }
}

void main() {
  late Harness h;
  late Directory root;
  late AttachmentRepository repository;
  late FakePhotos platform;
  late PhotoImportSession session;
  late PreparedAttachment original;
  setUp(() async {
    h = await Harness.create();
    root = await Directory.systemTemp.createTemp('photo-pipeline-');
    repository = AttachmentRepository(
      h.context(),
      Directory('${root.path}/media'),
      FakeAttachmentPlatform(),
    );
    platform = FakePhotos();
    session = PhotoImportSession(repository, platform);
    final input = File('${root.path}/original.png');
    await input.writeAsBytes([...FakePhotos.png, ...List.filled(10000, 0)]);
    original = (await repository.prepare([
      AttachmentSource(input.path, 'original.png'),
    ])).files.single;
  });
  tearDown(() async {
    await session.dispose();
    await h.close();
    await root.delete(recursive: true);
  });

  test('實際壓縮內容重新驗證及雜湊，保存後清理不影響入庫副本與原件', () async {
    final before = await File(original.source.path).readAsBytes();
    final result = await session.compress(
      original,
      PhotoPreset.standard,
      ImportCancellation(),
    );
    expect(result.file.size, FakePhotos.png.length);
    expect(result.file.hash, isNot(original.hash));
    expect(result.file.metadata.capturedAt, original.metadata.capturedAt);
    final plan = await repository.prepare([result.file.source]);
    final id = await repository.importBatch(
      plan,
      saveEvent: () =>
          EventContentRepository(h.context()).save(EventDraft(title: 'photo')),
    );
    final stored = (await repository.watch(id).first).single;
    await session.dispose();
    expect(await File(result.file.source.path).exists(), isFalse);
    expect(await File(stored.blob.path).readAsBytes(), FakePhotos.png);
    expect(await File(original.source.path).readAsBytes(), before);
  });
  test('壓縮結果較大時沿用原始 PreparedAttachment，不增加容量', () async {
    platform.outputLength = 20000;
    final result = await session.compress(
      original,
      PhotoPreset.compact,
      ImportCancellation(),
    );
    expect(identical(result.file, original), isTrue);
    expect(result.output.keptOriginal, isTrue);
    expect(await File(original.source.path).exists(), isTrue);
  });
  test('結果大小不一致或回傳非本次路徑時拒絕，不刪外部原件', () async {
    platform.wrongBytes = true;
    await expectLater(
      session.compress(original, PhotoPreset.standard, ImportCancellation()),
      throwsA(isA<ImportIntegrityException>()),
    );
    platform.wrongBytes = false;
    platform.foreignPath = '${root.path}/unrelated.png';
    await File(platform.foreignPath!).writeAsBytes([42]);
    await expectLater(
      session.compress(original, PhotoPreset.standard, ImportCancellation()),
      throwsA(isA<ImportIntegrityException>()),
    );
    await session.dispose();
    expect(await File(platform.foreignPath!).readAsBytes(), [42]);
  });
  test('原件在準備後改變則拒絕，不拿舊的中繼資料保存新內容', () async {
    await File(original.source.path).writeAsBytes(FakePhotos.png);
    await expectLater(
      session.compress(original, PhotoPreset.standard, ImportCancellation()),
      throwsA(isA<ImportIntegrityException>()),
    );
    expect(platform.started.isCompleted, isFalse);
  });
  test('取消會轉送到原生工作並且不建立事件或附件', () async {
    platform.waitForCancel = true;
    final token = ImportCancellation();
    final operation = session.compress(original, PhotoPreset.standard, token);
    final expected = expectLater(operation, throwsA(isA<PlatformException>()));
    await platform.started.future;
    token.cancelled = true;
    await expected;
    expect(platform.cancelled, isTrue);
    expect(await h.db.select(h.db.attachments).get(), isEmpty);
    expect(await File(original.source.path).exists(), isTrue);
  });
  test('移除 GPS 時，即使變大仍保留處理結果，草稿保存來源座標', () async {
    await session.dispose();
    session = PhotoImportSession(
      repository,
      platform,
      preferences: const PhotoPreferences(keepGps: false),
    );
    platform.outputLength = 20000;
    original = PreparedAttachment(
      original.source,
      original.size,
      original.hash,
      AttachmentMetadata(
        mediaType: original.metadata.mediaType,
        capturedAt: original.metadata.capturedAt,
        latitude: 25.03,
        longitude: 121.56,
      ),
      original.existing,
      sourceBytes: original.sourceBytes,
    );
    final result = await session.compress(
      original,
      PhotoPreset.standard,
      ImportCancellation(),
    );
    expect(platform.receivedKeepGps, isFalse);
    expect(result.output.keptOriginal, isFalse);
    expect(result.file.size, greaterThan(original.size));
    final sources = await repository.retainForDraft(
      AttachmentImportPlan(
        [result.file],
        result.file.size,
        result.file.size,
        1000000000,
        0,
      ),
      ImportCancellation(),
    );
    final restored = AttachmentSource.fromDraft(sources.single.toDraft());
    expect(restored.metadata?.capturedAt, original.metadata.capturedAt);
    expect(
      (await repository.prepare([restored])).files.single.metadata.capturedAt,
      original.metadata.capturedAt,
    );
    expect(restored.metadata?.latitude, 25.03);
    expect(restored.metadata?.longitude, 121.56);
    final finalPlan = await repository.prepare([restored]);
    final id = await repository.importBatch(
      finalPlan,
      saveEvent: () =>
          EventContentRepository(h.context())
              .save(EventDraft(title: 'GPS removed')),
    );
    final saved = (await repository.watch(id).first).single;
    expect(saved.attachment.capturedLatitude, 25.03);
    expect(saved.attachment.capturedLongitude, 121.56);
    expect(await File(original.source.path).exists(), isTrue);
  });

  test('確認清理僅移除中斷照片，使用中工作目錄與草稿引用保留', () async {
    final active = await PhotoWorkStore.create(root);
    final current = File('${active.path}/current.photo');
    await current.writeAsBytes([1]);
    final stale = await Directory('${root.path}/photo_work/import-interrupted')
        .create(recursive: true);
    final abandoned = File('${stale.path}/abandoned.photo');
    final protected = File('${stale.path}/draft.photo');
    await abandoned.writeAsBytes([2]);
    await protected.writeAsBytes([3]);
    final drafts = await Directory('${root.path}/drafts').create();
    await File('${drafts.path}/new.json').writeAsString(
      jsonEncode({
        'attachments': [
          {'path': protected.path, 'name': 'draft.photo'},
        ],
      }),
    );
    final pending = await repository.unreferencedFiles();
    expect(
      pending.map((file) => p.normalize(file.path)),
      contains(p.normalize(abandoned.path)),
    );
    expect(
      pending.map((file) => p.normalize(file.path)),
      isNot(contains(p.normalize(current.path))),
    );
    expect(
      pending.map((file) => p.normalize(file.path)),
      isNot(contains(p.normalize(protected.path))),
    );
    await repository.cleanUnreferenced();
    expect(await abandoned.exists(), isFalse);
    expect(await current.exists(), isTrue);
    expect(await protected.exists(), isTrue);
    await PhotoWorkStore.release(root, active);
  });
  test('損毀草稿時保守保留中斷照片，不跟隨未知工作目錄', () async {
    final stale = await Directory('${root.path}/photo_work/import-interrupted')
        .create(recursive: true);
    final unknown = await Directory('${root.path}/photo_work/other').create();
    final candidate = File('${stale.path}/a.photo');
    final unrelated = File('${unknown.path}/keep.photo');
    await candidate.writeAsBytes([1]);
    await unrelated.writeAsBytes([2]);
    final drafts = await Directory('${root.path}/drafts').create();
    await File('${drafts.path}/new.json').writeAsString('broken');
    await repository.cleanUnreferenced();
    expect(await candidate.exists(), isTrue);
    expect(await unrelated.exists(), isTrue);
  });
  test('拒絕釋放非本次照片工作根目錄，不刪其他資料', () async {
    final unrelated = await Directory('${root.path}/outside/import-other')
        .create(recursive: true);
    final file = File('${unrelated.path}/keep.photo');
    await file.writeAsBytes([42]);
    await expectLater(
      PhotoWorkStore.release(root, unrelated),
      throwsA(isA<FileSystemException>()),
    );
    expect(await file.readAsBytes(), [42]);
  });
}
