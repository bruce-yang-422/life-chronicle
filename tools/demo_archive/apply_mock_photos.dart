import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/core/attachments/attachment_quota.dart';
import 'package:life_chronicle/core/ids/ulid.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/platform/security_platform.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/profile_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/security_service.dart';

/// 明確啟用的 debug 測資入口。只追加附件，不刪除或替換現有內容。
/// 每篇交易保存；部分中斷可重跑同一份集合，固定引用 ID 避免重複追加。
Future<void> main() async {
  if (!kDebugMode || !const bool.fromEnvironment('APPLY_DEMO_PHOTOS')) {
    throw StateError('僅允許明確啟用的 debug 測資工作');
  }
  WidgetsFlutterBinding.ensureInitialized();
  final progress = ValueNotifier('正在核對 demo 照片集合…');
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ValueListenableBuilder(
            valueListenable: progress,
            builder: (_, value, _) => Text(value),
          ),
        ),
      ),
    ),
  );
  final support = await getApplicationSupportDirectory();
  final input = Directory(p.join(support.path, 'mock_photo_input'));
  final report = File(p.join(support.path, 'mock_photo_apply_report.json'));
  final db = AppDatabase.open();
  final security = SecurityService(
    DeviceSecurityStorage(),
    DeviceSecurityPlatform(),
    db,
  );
  final completed = <String>[];
  try {
    await security.load();
    if (security.configured || security.error != null) {
      throw StateError('已有安全保護設定，不允許測資入口');
    }
    final bundle = jsonDecode(
      await File(p.join(input.path, 'demo_bundle.json')).readAsString(),
    ) as Map;
    final entries = (bundle['events'] as List).cast<Map>();
    final profile = await ProfileRepository(db).ensureDefaultProfile();
    final events = await db.select(db.events).get();
    final ids = entries.map((e) => e['event_id'] as String).toSet();
    if (bundle['synthetic'] != true ||
        entries.length != 50 ||
        ids.length != 50 ||
        profile.subjectId != bundle['subject_id'] ||
        events.length != 50 ||
        events.any((e) => !ids.contains(e.id) || !e.title.startsWith('【模擬・'))) {
      throw StateError('資料庫不是指定的 50 筆 demo，停止');
    }
    final ctx = RepositoryContext(
      db,
      subjectId: profile.subjectId,
      actingAuthorId: profile.selfAuthorId,
    );
    if ((await ctx.archiveState()).name != 'normal') {
      throw StateError('典藏模式不允許此測資入口');
    }
    final media = await AttachmentRepository.open(ctx);
    final plans = <String, AttachmentImportPlan>{};
    var requiredSpace = 500000000;
    for (final entry in entries) {
      final id = entry['event_id'] as String;
      final photos = (entry['photos'] as List).cast<Map>();
      if (photos.length != bundle['photos_per_event']) {
        throw StateError('照片數不符');
      }
      final ownIds = photos.map((f) => f['reference_id'] as String).toSet();
      if (ownIds.length != photos.length ||
          ownIds.any((id) => !UlidGenerator.isValid(id))) {
        throw StateError('引用 ID 不符');
      }
      final existing = await media.watch(id).first;
      final originalIds = (entry['existing_ids'] as List)
          .cast<String>()
          .toSet();
      final originals = existing
          .where((a) => !ownIds.contains(a.attachment.id))
          .toList();
      if (!setEquals(
            originalIds,
            originals.map((a) => a.attachment.id).toSet(),
          ) ||
          originals.fold(0, (sum, a) => sum + a.blob.byteSize) !=
              entry['existing_bytes']) {
        throw StateError('原有附件已變更，停止追加');
      }
      progress.value = '預先驗證照片：${plans.length + 1}／50 篇';
      final sources = <AttachmentSource>[];
      for (final photo in photos) {
        final name = photo['file'] as String;
        if (p.basename(name) != name || !name.endsWith('.jpg')) {
          throw StateError('非法路徑');
        }
        sources.add(
          AttachmentSource(
            p.join(input.path, name),
            name,
            referenceId: photo['reference_id'] as String,
          ),
        );
      }
      final plan = await media.prepare(sources);
      if (plan.rejected.isNotEmpty || plan.files.length != photos.length) {
        throw StateError('照片驗證失敗');
      }
      for (var i = 0; i < photos.length; i++) {
        if (plan.files[i].hash != photos[i]['sha256'] ||
            plan.files[i].size != photos[i]['bytes']) {
          throw StateError('來源照片大小或雜湊不符');
        }
      }
      AttachmentQuota.check(
        usedBytes: await media.usedBytes(id),
        addedBytes: await media.pendingBytes(id, plan),
      );
      requiredSpace += plan.addedBytes;
      plans[id] = plan;
    }
    if (await media.platform.availableBytes(media.directory.path) <
        requiredSpace) {
      throw ImportSpaceException();
    }
    for (final entry in entries) {
      final id = entry['event_id'] as String;
      progress.value = '保存測試照片：${completed.length + 1}／50 篇';
      await media.importBatch(plans[id]!, eventId: id);
      completed.add(id);
      await report.writeAsString(
        jsonEncode({'status': 'in_progress', 'completed': completed}),
        flush: true,
      );
    }
    final counts = <Map<String, Object>>[];
    for (final entry in entries) {
      final id = entry['event_id'] as String;
      final usage = await media.watchUsage(id).first;
      final expectedCount =
          (entry['existing_ids'] as List).length +
          (entry['photos'] as List).length;
      if (usage.count != expectedCount ||
          usage.usedBytes != entry['total_bytes'] ||
          usage.isOverLimit) {
        throw StateError('保存後件數或額度不符');
      }
      counts.add({
        'event_id': id,
        'bytes': usage.usedBytes,
        'attachments': usage.count,
      });
    }
    await report.writeAsString(
      jsonEncode({
        'status': 'passed',
        'completed': completed,
        'events': counts,
      }),
      flush: true,
    );
    debugPrint('MOCK_PHOTOS_APPLIED ${completed.length}');
    security.dispose();
    progress.dispose();
    runApp(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const LifeChronicleApp(),
      ),
    );
  } catch (error, stack) {
    await report.writeAsString(
      jsonEncode({
        'status': 'failed',
        'completed': completed,
        'error': '$error',
      }),
      flush: true,
    );
    debugPrint('$error\n$stack');
    progress.value = '測資追加停止，已完成 ${completed.length} 篇。\n$error';
    security.dispose();
  }
}
