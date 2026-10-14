import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/core/archive/archive_reading.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/platform/security_platform.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/archive_repository.dart';
import 'package:life_chronicle/data/repositories/archive_restore.dart';
import 'package:life_chronicle/data/repositories/archive_zip.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/data/repositories/profile_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/security_service.dart';

/// 僅由本次使用者明確授權的命令啟動；一般 main.dart 不會匯入或刪資料。
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const updateFormatting = bool.fromEnvironment('DEMO_UPDATE_FORMATTING');
  if (!kDebugMode ||
      !(const bool.fromEnvironment('DEMO_REPLACE_INVALID') ||
          updateFormatting)) {
    throw StateError('此工具僅限明確指定 DEMO_REPLACE_INVALID 的 debug 版');
  }
  final directory = await getApplicationSupportDirectory();
  final db = AppDatabase.open();
  final security = SecurityService(
    DeviceSecurityStorage(),
    DeviceSecurityPlatform(),
    db,
  );
  await security.load();
  if (security.configured || security.error != null) {
    throw StateError('已有安全保護設定時不可使用 demo 取代工具');
  }
  final profile = await ProfileRepository(db).ensureDefaultProfile();
  final ctx = RepositoryContext(
    db,
    subjectId: profile.subjectId,
    actingAuthorId: profile.selfAuthorId,
  );
  final media = await AttachmentRepository.open(ctx);
  final restore = ArchiveRestore(
    ArchiveRepository(
      ctx,
      media,
      Directory(p.join(directory.path, 'demo_restore')),
      const ArchiveZip(controlPaths: {'README.md', 'SHA256SUMS.txt'}),
    ),
  );
  final zip = File(p.join(directory.path, 'demo_fixture.zip'));
  final proof = jsonDecode(
    await File(p.join(directory.path, 'demo_before.json')).readAsString(),
  ) as Map;
  final metadata = jsonDecode(
    await File(p.join(directory.path, 'demo_package.json')).readAsString(),
  ) as Map;
  final knownIds = Set<String>.from(metadata['event_ids'] as List);
  final oldRows = (proof['data'] as Map)['events'] as List;
  final oldById = {
    for (final row in oldRows) row['event_id'] as String: row as Map,
  };
  final before = await db.select(db.events).get();
  final repeated =
      before.length == 50 && before.every((e) => knownIds.contains(e.id));
  if (updateFormatting && !repeated) throw StateError('只允許更新既有 50 筆 demo');
  final baseline = updateFormatting
      ? jsonDecode(
          await File(p.join(directory.path, 'demo_baseline_sections.json'))
              .readAsString(),
        ) as List
      : const [];
  final originalContent = {
    for (final row in baseline) row['event_section_id']: row['content_md'],
  };
  if (!repeated &&
      (before.length != 1002 ||
          before.any((event) {
            final expected = oldById[event.id];
            return expected == null ||
                expected['title'] != event.title ||
                DateTime.parse(expected['updated_at'] as String) !=
                    event.updatedAt ||
                expected['layer'] != event.layer ||
                expected['time_payload'] != event.timePayload;
          }))) {
    throw StateError('装置內容與匯入前備份不符，停止取代');
  }
  Future<void> validateSubjects(ArchiveRows local, ArchiveRows incoming) async {
    if (incoming['subjects']!.length != 1 ||
        incoming['subjects']!.single['subject_id'] != profile.subjectId ||
        incoming['events']!.length != 50 ||
        incoming['attachments']!.length != 5 ||
        incoming['blobs']!.length != 5 ||
        incoming['events']!.any(
          (e) =>
              !knownIds.contains(e['event_id']) ||
              !(e['title'] as String).startsWith('【模擬・'),
        )) {
      throw StateError('測試包的主角、筆數或事件識別碼不符');
    }
  }

  // 在任何删除前先完成 ZIP 安全檢查、逐檔校驗及語意檢查。
  var plan = await restore.inspect(zip, cancellation: ImportCancellation());
  await validateSubjects(const {}, plan.data);
  await restore.discard(plan);
  final priorFiles = (await media.directory.list().toList())
      .map((f) => f.path)
      .toSet();
  try {
    late ArchiveRestoreReport report;
    await db.transaction(() async {
      if (!repeated) {
        final events = EventRepository(ctx);
        for (final event in before) {
          if (event.layer != 'original' ||
              await events.hasRemembranceContent(event.id)) {
            throw StateError('發現非原始層或追憶，停止刪除');
          }
          await events.softDelete(event.id);
          if (await events.purge(event.id)) throw StateError('無效事件仍有追憶，停止取代');
        }
      }
      plan = await restore.inspect(zip, cancellation: ImportCancellation());
      report = await restore.apply(
        plan,
        {
          for (final conflict in plan.conflicts)
            conflict.key:
                updateFormatting &&
                    conflict.table == 'event_sections' &&
                    conflict.local['content_md'] ==
                        originalContent[conflict.local['event_section_id']]
                ? ArchiveConflictChoice.useArchive
                : ArchiveConflictChoice.keepLocal,
        },
        cancellation: ImportCancellation(),
        validateSubjects: validateSubjects,
      );
      final rows = await db.select(db.events).get();
      if (rows.length != 50 || rows.any((e) => !knownIds.contains(e.id))) {
        throw StateError('匯入後事件核對失敗');
      }
      if ((await db.select(db.attachments).get()).length != 5 ||
          (await db.customSelect('PRAGMA foreign_key_check').get())
              .isNotEmpty) {
        throw StateError('匯入後附件或外鍵核對失敗');
      }
    });
    final result = {
      'status': 'passed',
      'removed_invalid_events': repeated ? 0 : before.length,
      'events': (await db.select(db.events).get()).length,
      'attachments': (await db.select(db.attachments).get()).length,
      'inserted': report.inserted,
      'replaced': report.replaced,
      'skipped': report.skipped,
      'repeat_import': repeated,
      'formatting_update': updateFormatting,
      'integrity':
          (await db.customSelect('PRAGMA integrity_check').getSingle()).data,
    };
    await File(p.join(directory.path, 'demo_import_report.json'))
        .writeAsString(jsonEncode(result), flush: true);
    debugPrint('DEMO_IMPORT_RESULT ${jsonEncode(result)}');
  } catch (_) {
    // 外層交易失敗時只移除本工具新建的倉庫副本，既有副本保持原樣。
    for (final file in await media.directory.list().toList()) {
      if (!priorFiles.contains(file.path) && file is File) await file.delete();
    }
    rethrow;
  } finally {
    security.dispose();
  }
  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const LifeChronicleApp(),
    ),
  );
}
