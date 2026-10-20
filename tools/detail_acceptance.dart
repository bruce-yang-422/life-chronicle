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
import 'package:life_chronicle/data/repositories/event_draft_store.dart';
import 'package:life_chronicle/data/repositories/profile_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/time_display_store.dart';
import 'package:life_chronicle/data/repositories/timeline_preferences_store.dart';
import 'package:life_chronicle/features/settings/time_display_settings.dart';

/// T09 裝置驗收入口；只使用獨立資料庫、草稿、附件、備份與記憶體偏好。
/// 不可作為一般入口，禁止 release；驗收後安裝回 lib/main.dart 建置。
Future<void> main() async {
  if (kReleaseMode) throw StateError('acceptance_entry_not_for_release');
  WidgetsFlutterBinding.ensureInitialized();
  final root = await Directory(
    p.join((await getApplicationSupportDirectory()).path, 'detail_acceptance'),
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
  if ((await db.select(db.events).get()).isEmpty) {
    final content = EventContentRepository(ctx);
    final single = await content.save(
      EventDraft(
        title: 'Acceptance_single',
        time: YearTime(2003),
        sections: [DraftSection(content: 'Acceptance_single_body')],
      ),
    );
    final sections = await content.save(
      EventDraft(
        title: 'Acceptance_sections',
        time: YearTime(2004),
        sections: [
          DraftSection(
            title: 'Acceptance_start',
            content: 'Acceptance_start_body',
          ),
          DraftSection(title: '想對你說的話', content: 'Acceptance_message_body'),
          DraftSection(title: 'Acceptance_empty_marker', content: '   '),
        ],
      ),
    );
    await content.appendReflection(sections, 'Acceptance_old_reflection');
    await File(
      p.join(root.path, 'context.json'),
    ).writeAsString(jsonEncode({'single_id': single, 'sections_id': sections}));
  }
  final media = await Directory(p.join(root.path, 'media')).create();
  runApp(
    ProviderScope(
      overrides: [
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
