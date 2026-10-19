import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/archive_repository.dart';
import 'package:life_chronicle/data/repositories/archive_zip.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/features/backup/backup_page.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

import '../../data/repositories/archive_repository_test.dart'
    show ArchiveTestPlatform;
import '../../data/repositories/harness.dart';
import '../../support/security_stub.dart';
import '../event_editor/event_editor_test.dart' show settle;

void main() {
  late Harness h;
  late Directory root;
  late ArchiveRepository repository;
  setUp(() async {
    h = await Harness.create();
    root = await Directory.systemTemp.createTemp('export-ui-');
    final media = AttachmentRepository(
      h.context(),
      await Directory('${root.path}/media').create(),
      ArchiveTestPlatform(),
    );
    repository = ArchiveRepository(
      h.context(),
      media,
      Directory('${root.path}/backups'),
      const ArchiveZip(),
    );
    final event = await EventContentRepository(h.context())
        .save(EventDraft(title: '可選副本'));
    final first = File('${root.path}/first.mp4')..writeAsBytesSync([1, 2, 3]);
    final second = File('${root.path}/second.mp4')..writeAsBytesSync([4, 5, 6]);
    await media.importBatch(
      await media.prepare([
        AttachmentSource(first.path, '敏感影片.mp4'),
        AttachmentSource(second.path, '保留影片.mp4'),
      ]),
      eventId: event,
    );
  });
  tearDown(() async {
    await h.close();
    await root.delete(recursive: true);
  });
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(430, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...securityTestOverrides,
          appDatabaseProvider.overrideWithValue(h.db),
          archiveRepositoryProvider.overrideWith((ref) async => repository),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: BackupPage()),
        ),
      ),
    );
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '匯出 ZIP 備份'));
    await settle(tester);
    expect(find.text('選擇要包含的副本'), findsOneWidget);
  }

  Future<void> accept(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(tester);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('從備份頁選擇個別排除並完成正式自訂 ZIP', (tester) async {
    final before = jsonEncode(await repository.snapshot());
    await pump(tester);
    await tester.tap(find.text('敏感影片.mp4'));
    await accept(tester);
    expect(find.text('範圍：自訂影音範圍；排除 1 個副本'), findsOneWidget);
    await accept(tester);
    for (var i = 0; i < 100; i++) {
      await settle(tester);
      if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
    }
    expect(find.byType(LinearProgressIndicator), findsNothing);
    await tester.runAsync(() async {
      final record = jsonDecode(
        await File('${repository.outputDirectory.path}/latest.json')
            .readAsString(),
      ) as Map;
      expect((record['scope'] as Map)['type'], 'custom');
      final verified = await repository.zipCodec.verify(
        File(record['path'] as String),
        Directory('${root.path}/verified'),
        freeBytes: 1 << 30,
        cancellation: ImportCancellation(),
      );
      expect((verified.manifest['scope'] as Map)['excluded'], hasLength(1));
      expect(
        (verified.manifest['files'] as List).where(
          (row) => (row as Map)['path'].toString().startsWith('media/'),
        ),
        hasLength(1),
      );
      expect(jsonEncode(await repository.snapshot()), before);
      expect(await File('${root.path}/first.mp4').readAsBytes(), [1, 2, 3]);
      expect(await File('${root.path}/second.mp4').readAsBytes(), [4, 5, 6]);
    });
    await unmount(tester);
  });

  testWidgets('預估容量畫面取消時不建立 ZIP 或備份紀錄', (tester) async {
    await pump(tester);
    await tester.tap(find.text('敏感影片.mp4'));
    await accept(tester);
    await tester.tap(find.text('取消'));
    await settle(tester);
    await tester.runAsync(() async {
      expect(await repository.outputDirectory.list().toList(), isEmpty);
    });
    await unmount(tester);
  });
}
