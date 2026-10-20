import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/repositories/archive_repository.dart';
import 'package:life_chronicle/data/repositories/archive_zip.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/story_repository.dart';
import 'package:life_chronicle/core/stories/theme_rule.dart';

import '../../test/data/repositories/archive_repository_test.dart'
    show reading, ArchiveTestPlatform;
import '../../test/data/repositories/harness.dart';

void main() {
  test('以正式封存器輸出全精確度、追憶及媒體／排除媒體的 Schema 驗證資料', () async {
    final h = await Harness.create();
    final root = await Directory.systemTemp.createTemp('schema-source-');
    final output = await Directory('build/archive_schema_validation')
        .create(recursive: true);
    try {
      final content = EventContentRepository(h.context());
      final anchor = await content.save(
        EventDraft(
          title: '成長 # [emoji] 🎉',
          time: DayTime(2000, 2, 29),
          place: '臺北',
          latitude: 25.03,
          longitude: 121.56,
          radiusM: 50,
          people: ['家人'],
          tags: ['紀念'],
          sections: [DraftSection(content: '**保留** Unicode 👍🏽')],
        ),
      );
      final tag = (await h.db.select(h.db.tags).get()).single.id;
      await StoryRepository(h.context()).save(
        title: '智慧主題',
        rule: ThemeRule(mode: TagMatchMode.all, include: [tag]),
      );
      final times = <TimeValue>[
        MonthTime(2001, 9),
        QuarterTime(2002, 3),
        HalfYearTime(2003, 2),
        YearTime(2004),
        ApproxYearTime(2005),
        RangeTime(MonthTime(2006, 1), YearTime(2007)),
        RelativeTime(anchor, RelativeRelation.after),
        RelativeTime(
          h.context().newId(),
          RelativeRelation.after,
          deletedReference: const DeletedTimeReference(
            '已刪除參照 <標題>',
            private: true,
          ),
        ),
        AgeEstimateTime(20),
        const UnknownTime(),
      ];
      for (final time in times) {
        await content.save(
          EventDraft(title: time.type, time: time, privacy: 'private'),
        );
      }
      await h.activateArchive();
      await EventContentRepository(h.context(actingAuthorId: h.familyAuthorId))
          .appendReflection(anchor, '後續追憶 👨‍👩‍👧‍👦');
      await h.deactivateArchive();
      final platform = ArchiveTestPlatform();
      final media = AttachmentRepository(
        h.context(),
        await Directory('${root.path}/media').create(),
        platform,
      );
      final source = File('${root.path}/sample.mp4');
      await source.writeAsBytes([1, 2, 3, 4]);
      await media.importBatch(
        await media.prepare([AttachmentSource(source.path, '模擬附件.mp4')]),
        eventId: anchor,
      );
      final second = File('${root.path}/second.mp4');
      await second.writeAsBytes([5, 6, 7]);
      await media.importBatch(
        await media.prepare([AttachmentSource(second.path, '保留副本.mp4')]),
        eventId: anchor,
      );
      final repo = ArchiveRepository(
        h.context(),
        media,
        output,
        const ArchiveZip(),
      );
      for (final scope in ['full', 'no_media', 'custom', 'private']) {
        final staging = Directory('${output.path}/$scope');
        if (await staging.exists()) {
          // 僅清理本工具在工作區 build 下的舊驗證產物，避免殘留舊 Markdown。
          final workspace = await Directory.current.resolveSymbolicLinks();
          final expected = p.join(
            workspace,
            'build',
            'archive_schema_validation',
          );
          final resolvedRoot = await output.resolveSymbolicLinks();
          final resolved = await staging.resolveSymbolicLinks();
          if (!p.equals(expected, resolvedRoot) ||
              !p.isWithin(resolvedRoot, resolved)) {
            throw StateError('驗證暫存目錄不在預期的工作區範圍');
          }
          await staging.delete(recursive: true);
        }
        final exported = await repo.export(
          await repo.prepare(
            includeMedia: scope != 'no_media',
            excludePrivateEvents: scope == 'private',
            excludedBlobIds: scope == 'custom'
                ? {(await h.db.select(h.db.blobs).get()).first.id}
                : const {},
          ),
          reading,
          readme: '# Archive\n',
          appVersion: '1.0.0+1',
        );
        final verified = await repo.zipCodec.verify(
          exported.zip,
          staging,
          freeBytes: 1 << 30,
          cancellation: ImportCancellation(),
        );
        for (final name in repo.tables.map((table) => table.actualTableName)) {
          expect(
            await File('${verified.directory.path}/schema/$name.schema.json')
                .exists(),
            isTrue,
          );
        }
        final data = jsonDecode(
          await File('${verified.directory.path}/data/events.json')
              .readAsString(),
        ) as List;
        expect(data, hasLength(scope == 'private' ? 1 : times.length + 1));
      }
    } finally {
      await h.close();
      await root.delete(recursive: true);
    }
  });
}
