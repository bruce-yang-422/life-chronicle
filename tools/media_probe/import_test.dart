import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';

import '../../test/data/repositories/harness.dart';

class _SamplePlatform implements AttachmentPlatform {
  @override
  Future<int> availableBytes(String directory) async => 1 << 30;
  @override
  Future<AttachmentMetadata> metadata(String path) async =>
      const AttachmentMetadata(mediaType: 'application/pdf');
  @override
  Future<void> open(String path, String mediaType) async {}
}

void main() {
  test('Android 實際樣本經正式 Repository 保存、排除及去重，原檔不變', () async {
    const samples = String.fromEnvironment(
      'MEDIA_PROBE_SAMPLES',
      defaultValue: 'build/media_probe_native/samples',
    );
    final names = [
      'video.mp4',
      'voice.m4a',
      'renamed_video.jpg',
      'renamed_video.pdf',
      'renamed_video.m4a',
      'renamed_audio.jpg',
      'video.webm',
      'audio.aac',
      'audio.ts',
      'video.ts',
      'audio.ps',
      'video.ps',
      'video.h264',
      'motion.jpg',
    ];
    final h = await Harness.create();
    final root = await Directory.systemTemp.createTemp(
      'media-probe-acceptance-',
    );
    try {
      final sources = [
        for (final name in names) AttachmentSource('$samples/$name', name),
      ];
      final hashes = <String, String>{};
      for (final source in sources) {
        hashes[source.name] =
            (await sha256.bind(File(source.path).openRead()).first).toString();
      }
      final repository = AttachmentRepository(
        h.context(),
        Directory('${root.path}/media'),
        _SamplePlatform(),
      );
      final plan = await repository.prepare(sources);
      expect(plan.rejected, hasLength(8));
      expect(
        plan.rejected.map((file) => file.reason),
        everyElement(AttachmentRejectionReason.video),
      );
      expect(plan.files, hasLength(6));
      expect(plan.files.where((file) => file.staticImageOnly), hasLength(1));
      final id = await repository.importBatch(
        plan,
        saveEvent: () =>
            EventContentRepository(h.context())
                .save(EventDraft(title: '獨立影音驗收')),
      );
      final stored = await repository.watch(id).first;
      expect(stored, hasLength(6));
      expect(await h.db.select(h.db.blobs).get(), hasLength(5));
      expect(
        stored.where((file) => file.blob.mediaType == 'video/mp2t'),
        hasLength(1),
      );
      expect(
        stored.where((file) => file.blob.mediaType == 'video/mpeg'),
        hasLength(1),
      );
      final photo = stored.singleWhere(
        (file) => file.attachment.originalFilename == 'motion.jpg',
      );
      expect(
        await File(photo.blob.path).readAsBytes(),
        await File('$samples/still.jpg').readAsBytes(),
      );
      expect(
        await repository.usedBytes(id),
        plan.files.fold(0, (sum, file) => sum + file.size),
      );
      for (final source in sources) {
        expect(
          (await sha256.bind(File(source.path).openRead()).first).toString(),
          hashes[source.name],
        );
      }
    } finally {
      await h.close();
      final target = await root.resolveSymbolicLinks();
      final temp = await Directory.systemTemp.resolveSymbolicLinks();
      if (!p.isWithin(temp, target) ||
          !p.basename(target).startsWith('media-probe-acceptance-')) {
        throw StateError(target);
      }
      await root.delete(recursive: true);
    }
  });
}
