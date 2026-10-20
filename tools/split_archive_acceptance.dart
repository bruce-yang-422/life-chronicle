import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/platform/security_platform.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/data/repositories/event_draft_store.dart';
import 'package:life_chronicle/data/repositories/profile_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/time_display_store.dart';
import 'package:life_chronicle/data/repositories/timeline_preferences_store.dart';
import 'package:life_chronicle/features/settings/time_display_settings.dart';
import 'package:life_chronicle/features/backup/export_scope_dialog.dart';

/// T12 獨立分包裝置驗收入口；只使用獨立資料庫、草稿、附件、備份與記憶體偏好。
/// 不可作為一般入口，禁止 release；驗收後安裝回 lib/main.dart 建置。
Future<void> main() async {
  if (kReleaseMode) throw StateError('acceptance_entry_not_for_release');
  WidgetsFlutterBinding.ensureInitialized();
  final root = await Directory(
    p.join(
      (await getApplicationSupportDirectory()).path,
      'split_archive_acceptance',
    ),
  ).create(recursive: true);
  final db = AppDatabase(
    NativeDatabase.createInBackground(
      File(p.join(root.path, 'acceptance.sqlite')),
    ),
  );
  final profile = await ProfileRepository(db).ensureDefaultProfile();
  final ctx = RepositoryContext(
    db,
    subjectId: profile.subjectId,
    actingAuthorId: profile.selfAuthorId,
  );
  final media = await Directory(p.join(root.path, 'media')).create();
  final attachments = AttachmentRepository(
    ctx,
    media,
    DeviceAttachmentPlatform(),
  );
  if ((await db.select(db.events).get()).isEmpty) {
    final content = EventContentRepository(ctx);
    final privateId = await content.save(
      EventDraft(
        title: 'PRIVATE_TITLE_MARKER',
        privacy: 'private',
        time: YearTime(2001),
        sections: [DraftSection(content: 'PRIVATE_BODY_MARKER')],
      ),
    );
    await content.appendReflection(privateId, 'PRIVATE_REFLECTION_MARKER');
    final publicId = await content.save(
      EventDraft(
        title: 'Public_entry',
        time: RelativeTime(privateId, RelativeRelation.after),
        sections: [DraftSection(content: 'Public_body')],
        relatedIds: [privateId],
      ),
    );
    final events = EventRepository(ctx);
    final purged = await events.create(
      EventInput(
        title: 'PRIVATE_SNAPSHOT_MARKER',
        privacy: 'private',
        time: YearTime(2002),
      ),
    );
    await events.create(
      EventInput(
        title: 'Public_snapshot_reference',
        time: RelativeTime(purged, RelativeRelation.after),
      ),
    );
    await events.softDelete(purged);
    await events.purge(purged);
    final sources = await Directory(p.join(root.path, 'fixture_sources'))
        .create();
    final files = <AttachmentSource>[];
    for (final name in ['shared', 'private_only', 'warehouse']) {
      final file = File(p.join(sources.path, '$name.pdf'));
      await file.writeAsString(
        '%PDF-1.4\n$name\n%%EOF\n${name * (240 * 1024 ~/ name.length)}',
      );
      files.add(AttachmentSource(file.path, '$name.pdf'));
    }
    await attachments.importBatch(
      await attachments.prepare(files),
      eventId: privateId,
    );
    final unused = (await db.select(db.attachments).get()).singleWhere(
      (a) => a.originalFilename == 'warehouse.pdf',
    );
    await attachments.removeReference(unused.id);
    await attachments.importBatch(
      await attachments.prepare([files.first]),
      eventId: publicId,
    );
    await File(p.join(root.path, 'context.json'))
        .writeAsString(jsonEncode({'private': privateId, 'public': publicId}));
  }
  runApp(
    ProviderScope(
      overrides: [
        archivePartLimitsProvider.overrideWithValue([512 * 1024]),
        appDatabaseProvider.overrideWithValue(db),
        securityStorageProvider.overrideWith((ref) => MemorySecurityStorage()),
        timelinePreferencesStoreProvider.overrideWith(
          (ref) async => MemoryTimelinePreferencesStore(),
        ),
        timeDisplayStoreProvider.overrideWith(
          (ref) async => MemoryTimeDisplayStore(),
        ),
        eventDraftStoreProvider.overrideWith(
          (ref) async =>
              FileEventDraftStore(Directory(p.join(root.path, 'drafts'))),
        ),
        attachmentRepositoryProvider.overrideWith(
          (ref) async => AttachmentRepository(
            await ref.watch(repositoryContextProvider.future),
            media,
            DeviceAttachmentPlatform(),
          ),
        ),
      ],
      child: const LifeChronicleApp(),
    ),
  );
}
