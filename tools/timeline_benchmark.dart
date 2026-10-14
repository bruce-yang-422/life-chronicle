import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/event_draft_store.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/repositories/profile_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/timeline_demo_repository.dart';
import 'package:life_chronicle/data/repositories/timeline_preferences_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 獨立的 5,000 筆測試資料庫，不修改 APP 的生命紀錄與偏好。
/// 執行：flutter run -d emulator-5554 -t tools/timeline_benchmark.dart
/// profile 測量須先用 debug 入口建立資料，再以同一入口建置 profile APK。
/// 首次準備資料在計時之前；每次開啟時間軸會重新開啟資料庫連線。
Future<void> main() async {
  if (kReleaseMode) throw StateError('效能測試入口不可用於 release');
  WidgetsFlutterBinding.ensureInitialized();
  final directory = await getApplicationSupportDirectory();
  final file = File(p.join(directory.path, 'timeline_benchmark_5000.sqlite'));
  if (!await file.exists()) {
    if (!kDebugMode) throw StateError('請先以 debug 效能測試入口建立 5,000 筆資料');
    final seed = AppDatabase(NativeDatabase.createInBackground(file));
    try {
      final profile = await ProfileRepository(seed).ensureDefaultProfile();
      await TimelineDemoRepository(
        RepositoryContext(
          seed,
          subjectId: profile.subjectId,
          actingAuthorId: profile.selfAuthorId,
        ),
      ).generate(
        5000,
        title: (index) => 'Benchmark $index',
        category: 'benchmark',
      );
    } finally {
      await seed.close();
    }
  }
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          final db = AppDatabase(NativeDatabase.createInBackground(file));
          ref.onDispose(db.close);
          return db;
        }),
        timelinePreferencesStoreProvider.overrideWith(
          (ref) async => MemoryTimelinePreferencesStore(),
        ),
        eventDraftStoreProvider.overrideWith(
          (ref) async => MemoryEventDraftStore(),
        ),
        attachmentRepositoryProvider.overrideWith(
          (ref) async => AttachmentRepository(
            await ref.watch(repositoryContextProvider.future),
            Directory(p.join(directory.path, 'media', 'benchmark_5000')),
            DeviceAttachmentPlatform(),
          ),
        ),
      ],
      child: const LifeChronicleApp(),
    ),
  );
}
