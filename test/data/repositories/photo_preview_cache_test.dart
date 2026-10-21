import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/features/attachments/cached_attachment_photo.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/policy/layer_policy.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/photo_compression.dart';
import 'package:life_chronicle/data/platform/photo_platform.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/photo_preview_cache.dart';
import 'package:life_chronicle/data/repositories/photo_cache_files.dart';
import 'package:life_chronicle/data/repositories/photo_import_session.dart';

import 'attachment_repository_test.dart' show FakeAttachmentPlatform;
import 'photo_import_session_test.dart' show FakePhotos;
import 'harness.dart';

class PreviewPlatform implements PhotoPlatform {
  int calls = 0;
  bool emitGps = false, cancelRequested = false, block = false;
  final started = Completer<void>(), release = Completer<void>();
  @override
  Future<PhotoInfo?> inspect(String path) async {
    final file = File(path);
    if (!await file.exists() || await file.length() == 0) return null;
    return PhotoInfo(1, 1, hasGps: (await file.readAsBytes()).last == 99);
  }

  @override
  Future<PhotoOutput> preview(
    String path,
    String output,
    int longEdge,
    String requestId,
  ) async {
    calls++;
    await File(output).writeAsBytes([...FakePhotos.png, if (emitGps) 99]);
    if (!started.isCompleted) started.complete();
    if (block) {
      await release.future;
      if (cancelRequested) throw ImportCancelled();
    }
    return PhotoOutput(
      output,
      1,
      1,
      await File(output).length(),
      'image/png',
      null,
      false,
    );
  }

  @override
  Future<void> cancel(String requestId) async {
    cancelRequested = true;
    if (!release.isCompleted) release.complete();
  }

  @override
  Future<PhotoOutput> compress(
    String path,
    String output,
    PhotoPreset preset,
    String requestId, {
    bool keepGps = true,
  }) => throw UnimplementedError();
}

void main() {
  late Harness h;
  late Directory root;
  late AttachmentRepository repository;
  late PreparedAttachment source;
  late PreviewPlatform platform;
  late PhotoPreviewCache cache;
  var sequence = 0;
  setUp(() async {
    h = await Harness.create();
    root = await Directory.systemTemp.createTemp('preview-cache-');
    repository = AttachmentRepository(
      h.context(),
      Directory('${root.path}/media'),
      FakeAttachmentPlatform(),
    );
    final file = File('${root.path}/source.png');
    await file.writeAsBytes(FakePhotos.png);
    source = (await repository.prepare([
      AttachmentSource(file.path, 'source.png'),
    ])).files.single;
    platform = PreviewPlatform();
    cache = PhotoPreviewCache(
      Directory('${root.path}/photo_cache'),
      platform,
      () => 'preview-${sequence++}',
    );
  });
  tearDown(() async {
    await h.close();
    await root.delete(recursive: true);
  });
  test('同內容與尺寸重用快取，刪除或損毀後可重建，不增加附件容量', () async {
    final first = await cache.get(source, 80, ImportCancellation());
    final second = await cache.get(source, 80, ImportCancellation());
    expect(first.path, second.path);
    expect(platform.calls, 1);
    await first.writeAsBytes([...FakePhotos.png, 99]);
    await cache.get(source, 80, ImportCancellation());
    expect(platform.calls, 2);
    expect((await platform.inspect(first.path))?.hasGps, isFalse);
    await first.delete();
    await cache.get(source, 80, ImportCancellation());
    expect(platform.calls, 3);
    await cache.get(source, 1600, ImportCancellation());
    expect(platform.calls, 4);
    expect(await h.db.select(h.db.blobs).get(), isEmpty);
    expect(await h.db.select(h.db.attachments).get(), isEmpty);
    expect(await File(source.source.path).readAsBytes(), FakePhotos.png);
  });
  test('同一快取同時請求只產生一次', () async {
    platform.block = true;
    final first = cache.get(source, 512, ImportCancellation());
    await platform.started.future;
    final second = cache.get(source, 512, ImportCancellation());
    platform.release.complete();
    final outputs = await Future.wait([first, second]);
    expect(outputs.first.path, outputs.last.path);
    expect(platform.calls, 1);
  });
  test('原生回傳仍含 GPS 的預覽不得使用，也不退回原件', () async {
    platform.emitGps = true;
    await expectLater(
      cache.get(source, 80, ImportCancellation()),
      throwsA(isA<ImportIntegrityException>()),
    );
    expect(await cache.directory.list().toList(), isEmpty);
    expect(await File(source.source.path).exists(), isTrue);
  });
  test('取消轉送原生，使用中 partial 不可清理，中斷 partial 可確認清理', () async {
    platform.block = true;
    final token = ImportCancellation();
    final operation = cache.get(source, 80, token);
    final expected = expectLater(operation, throwsA(isA<ImportCancelled>()));
    await platform.started.future;
    expect(await PhotoCacheFiles.interrupted(cache.directory), isEmpty);
    await repository.cleanUnreferenced();
    token.cancelled = true;
    await expected;
    expect(platform.cancelRequested, isTrue);
    expect(await cache.directory.list().toList(), isEmpty);
    final stale = File('${cache.directory.path}/stale.partial');
    await stale.writeAsBytes([42]);
    final ready = await File('${cache.directory.path}/ready.preview')
        .writeAsBytes(FakePhotos.png);
    await repository.cleanUnreferenced();
    expect(await stale.exists(), isFalse);
    expect(await ready.exists(), isTrue);
  });
  test('照片預覽完成後若來源改變，拒絕並移除對應快取', () async {
    platform.block = true;
    final session = PhotoImportSession(repository, platform);
    final operation = session.preview(source, 80, ImportCancellation());
    final expected = expectLater(
      operation,
      throwsA(isA<ImportIntegrityException>()),
    );
    await platform.started.future;
    await File(source.source.path).writeAsBytes([...FakePhotos.png, 1]);
    platform.release.complete();
    await expected;
    expect(await cache.directory.list().toList(), isEmpty);
    await session.dispose();
  });
  test('沒有 GPS 的像素損毀或校驗檔損毀也必須重建', () async {
    final file = await cache.get(source, 512, ImportCancellation());
    await file.writeAsBytes([...FakePhotos.png, 1]);
    expect((await platform.inspect(file.path))?.hasGps, isFalse);
    await cache.get(source, 512, ImportCancellation());
    expect(platform.calls, 2);
    await File('${file.path}.sha256').writeAsString('broken');
    await cache.get(source, 512, ImportCancellation());
    expect(platform.calls, 3);
  });
  test('已存在私密照片快取也不能繞過私密驗證', () async {
    final plan = await repository.prepare([source.source]);
    final id = await repository.importBatch(
      plan,
      saveEvent: () =>
          EventContentRepository(h.context())
              .save(EventDraft(title: 'private', privacy: 'private')),
    );
    final stored = (await repository.watch(id).first).single;
    final key = (eventId: id, path: stored.blob.path);
    final provider = attachmentThumbnailProvider(key);
    final unlocked = ProviderContainer(
      overrides: [
        attachmentRepositoryProvider.overrideWith((ref) async => repository),
        photoPreviewPlatformProvider.overrideWithValue(platform),
      ],
    );
    final subscription = unlocked.listen(provider, (_, next) {});
    try {
      expect(await (await unlocked.read(provider.future)).exists(), isTrue);
    } finally {
      subscription.close();
      unlocked.dispose();
    }
    final before = platform.calls;
    final denied = AttachmentRepository(
      RepositoryContext(
        h.db,
        subjectId: h.profile.subjectId,
        actingAuthorId: h.profile.selfAuthorId,
        canReadPrivate: false,
      ),
      repository.directory,
      FakeAttachmentPlatform(),
    );
    final locked = ProviderContainer(
      overrides: [
        attachmentRepositoryProvider.overrideWith((ref) async => denied),
        photoPreviewPlatformProvider.overrideWithValue(platform),
      ],
    );
    final lockedSubscription = locked.listen(provider, (_, next) {});
    try {
      await expectLater(
        locked.read(provider.future),
        throwsA(isA<PermissionDeniedException>()),
      );
    } finally {
      lockedSubscription.close();
      locked.dispose();
    }
    expect(platform.calls, before);
  });
}
