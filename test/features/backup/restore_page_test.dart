import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/archive_repository.dart';
import 'package:life_chronicle/data/repositories/archive_zip.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/data/repositories/security_service.dart';
import 'package:life_chronicle/features/backup/restore_page.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

import '../../data/repositories/archive_repository_test.dart'
    show ArchiveTestPlatform, reading;
import '../../data/repositories/harness.dart';
import '../../support/security_stub.dart';
import '../event_editor/event_editor_test.dart' show settle;

void main() {
  late Harness h;
  late Directory root;
  late ArchiveRepository repository;
  late File zip;
  late String id;

  setUp(() async {
    h = await Harness.create();
    root = await Directory.systemTemp.createTemp('restore-ui-');
    repository = ArchiveRepository(
      h.context(),
      AttachmentRepository(
        h.context(),
        await Directory('${root.path}/media').create(),
        ArchiveTestPlatform(),
      ),
      Directory('${root.path}/backups'),
      const ArchiveZip(),
    );
    id = await EventContentRepository(h.context())
        .save(EventDraft(title: '備份標題'));
    zip = (await repository.export(
      await repository.prepare(),
      reading,
      readme: '# Archive\n',
      appVersion: '1.0.0',
    )).zip;
    await h.events().update(id, const EventChanges(title: Value('目前標題')));
  });
  tearDown(() async {
    await h.close();
    await root.delete(recursive: true);
  });

  Future<void> pump(
    WidgetTester tester, {
    File? selected,
    List<File>? parts,
    bool cancelPicker = false,
    String locale = 'zh',
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...securityTestOverrides,
          appDatabaseProvider.overrideWithValue(h.db),
          archiveRepositoryProvider.overrideWith((ref) async => repository),
          restoreFilePickerProvider.overrideWithValue(
            () async => cancelPicker ? [] : parts ?? [selected ?? zip],
          ),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RestorePage(),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> select(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.folder_open));
    for (var i = 0; i < 20; i++) {
      await settle(tester);
      if (find.byType(LinearProgressIndicator).evaluate().isEmpty) break;
    }
    expect(find.byType(LinearProgressIndicator), findsNothing);
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.pump(const Duration(seconds: 2));
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    final scrollable = find.byType(Scrollable).first;
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pump();
    await tester.scrollUntilVisible(finder, 300, scrollable: scrollable);
    await tester.ensureVisible(finder);
    await tester.pump();
  }

  testWidgets('列出差異且不預選，全部選擇後才可還原，確認採用備份並顯示報告', (tester) async {
    await pump(tester);
    await select(tester);
    final button = find.widgetWithText(FilledButton, '確認還原');
    await reveal(tester, button);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(find.text('目前：目前標題'), findsOneWidget);
    expect(find.text('備份：備份標題'), findsOneWidget);
    await tester.tap(find.text('使用封存內容'));
    await settle(tester);
    await tester.tap(button);
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(tester);
    expect((await tester.runAsync(() => h.events().find(id)))!.title, '備份標題');
    await reveal(tester, find.text('還原核對報告'));
    expect(find.text('還原核對報告'), findsOneWidget);
    expect(
      (await tester.runAsync(() => repository.outputDirectory.list().toList()))!
          .whereType<Directory>(),
      isEmpty,
    );
    await unmount(tester);
  });

  testWidgets('保留本機並取消最後確認不修改資料，離頁清除預覽暫存', (tester) async {
    final before = await tester.runAsync(
      () async => jsonEncode(await repository.snapshot()),
    );
    await pump(tester);
    await select(tester);
    await reveal(tester, find.text('保留目前資料'));
    await tester.tap(find.text('保留目前資料'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '確認還原'));
    await settle(tester);
    await tester.tap(find.text('取消'));
    await settle(tester);
    expect(
      await tester.runAsync(
        () async => jsonEncode(await repository.snapshot()),
      ),
      before,
    );
    await unmount(tester);
    expect(
      (await tester.runAsync(() => repository.outputDirectory.list().toList()))!
          .whereType<Directory>(),
      isEmpty,
    );
  });

  testWidgets('預覽後資料變更會拒絕寫入並顯示重新核對提示', (tester) async {
    await pump(tester);
    await select(tester);
    await reveal(tester, find.text('使用封存內容'));
    await tester.tap(find.text('使用封存內容'));
    await settle(tester);
    await tester.runAsync(
      () => h.events().update(id, const EventChanges(title: Value('最新變更'))),
    );
    await tester.tap(find.widgetWithText(FilledButton, '確認還原'));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(tester);
    expect(find.textContaining('預覽後原有資料已變更'), findsOneWidget);
    expect((await tester.runAsync(() => h.events().find(id)))!.title, '最新變更');
    await unmount(tester);
  });

  testWidgets('取消檔案選取不建立預覽也不修改資料', (tester) async {
    await pump(tester, cancelPicker: true);
    await select(tester);
    expect(find.text('還原預覽'), findsNothing);
    expect((await tester.runAsync(() => h.events().find(id)))!.title, '目前標題');
    await unmount(tester);
  });

  testWidgets('選擇保留目前資料後可完成還原並保持本機標題', (tester) async {
    await pump(tester);
    await select(tester);
    await reveal(tester, find.text('保留目前資料'));
    await tester.tap(find.text('保留目前資料'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, '確認還原'));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(tester);
    expect((await tester.runAsync(() => h.events().find(id)))!.title, '目前標題');
    await reveal(tester, find.text('還原核對報告'));
    expect(find.text('還原核對報告'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('預覽時重新鎖定即遮蔽差異及還原入口', (tester) async {
    await pump(tester);
    await select(tester);
    await reveal(tester, find.text('使用封存內容'));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(RestorePage)),
    );
    final service = container.read(securityProvider);
    await tester.runAsync(() async {
      final codes = await SecurityService.prepareCodes('abc123', iterations: 2);
      await service.install(
        codes,
        const SecurityConfig(privateProtection: true),
      );
    });
    await settle(tester);
    expect(find.textContaining('目前標題'), findsNothing);
    expect(find.textContaining('備份標題'), findsNothing);
    expect(find.widgetWithText(FilledButton, '確認還原'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('同名不同 ID 顯示重用說明且內容相同仍需選擇', (tester) async {
    late String sourceId;
    late String localId;
    await tester.runAsync(() async {
      await EventContentRepository(h.context())
          .save(EventDraft(eventId: id, title: '目前標題', tags: ['相聚']));
      sourceId = (await h.db.select(h.db.tags).get()).single.id;
      zip = (await repository.export(
        await repository.prepare(),
        reading,
        readme: '# Archive\n',
        appVersion: '1.0.0',
      )).zip;
      localId = h.context().newId();
      await h.db.transaction(() async {
        await h.db.customStatement('PRAGMA defer_foreign_keys = ON');
        await h.db.customStatement('UPDATE tags SET tag_id = ?', [localId]);
        await h.db.customStatement('UPDATE event_tags SET tag_id = ?', [
          localId,
        ]);
      });
    });
    await pump(tester);
    await select(tester);
    final explanation = find.byWidgetPredicate(
      (widget) =>
          widget is SelectableText &&
          (widget.data?.contains('同名資料將重用本機 ID') ?? false),
    );
    await reveal(tester, explanation);
    expect(explanation, findsOneWidget);
    expect(tester.widget<SelectableText>(explanation).data, contains(sourceId));
    expect(tester.widget<SelectableText>(explanation).data, contains(localId));
    expect(find.text('目前：相聚'), findsOneWidget);
    expect(find.text('備份：相聚'), findsOneWidget);
    final button = find.widgetWithText(FilledButton, '確認還原');
    await reveal(tester, button);
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await tester.tap(find.text('保留目前資料'));
    await settle(tester);
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.tap(button);
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await settle(tester);
    expect(
      (await tester.runAsync(() => h.db.select(h.db.tags).get()))!.single.id,
      localId,
    );
    expect(
      (await tester.runAsync(() => h.db.select(h.db.eventTags).get()))!
          .single
          .tagId,
      localId,
    );
    await unmount(tester);
  });

  testWidgets('三倍字級窄畫面的差異內容與選擇不溢出', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pump(tester);
    await select(tester);
    await reveal(tester, find.text('使用封存內容'));
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });

  testWidgets('損毀 ZIP 在英文介面顯示失敗，沒有還原按鈕', (tester) async {
    final invalid = File('${root.path}/bad.zip')..writeAsStringSync('broken');
    await pump(tester, selected: invalid, locale: 'en');
    await select(tester);
    expect(find.textContaining('Archive processing failed'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Confirm restore'), findsNothing);
    expect((await tester.runAsync(() => h.events().find(id)))!.title, '目前標題');
    await unmount(tester);
  });

  testWidgets('多包反向選取可預覽，僅選第一包顯示缺包且不寫入', (tester) async {
    late List<File> parts;
    await tester.runAsync(() async {
      for (var i = 0; i < 2; i++) {
        final file = File('${root.path}/part_$i.mp4');
        await file.writeAsBytes(List.filled(600 * 1024, i + 1));
        await repository.attachments.importBatch(
          await repository.attachments.prepare([
            AttachmentSource(file.path, 'clip_$i.mp4'),
          ]),
          eventId: id,
        );
      }
      parts = (await repository.export(
        await repository.prepare(maxPartBytes: 1024 * 1024),
        reading,
        readme: '# Archive\n',
        appVersion: '1.0.0',
      )).zips;
      expect(parts.length, greaterThan(1));
    });
    final before = await tester.runAsync(() async => repository.snapshot());
    await pump(tester, parts: parts.reversed.toList());
    await select(tester);
    expect(find.text('還原預覽'), findsOneWidget);
    await unmount(tester);
    await pump(tester, parts: [parts.first]);
    await select(tester);
    expect(find.textContaining('分包不完整，尚缺：'), findsOneWidget);
    expect(find.text('確認還原'), findsNothing);
    await tester.runAsync(
      () async => expect(await repository.snapshot(), before),
    );
    await unmount(tester);
  });

  testWidgets('私密排除預覽明示刻意排除筆數，不當作較新未知格式', (tester) async {
    await tester.runAsync(() async {
      await EventContentRepository(h.context())
          .save(EventDraft(title: 'private marker', privacy: 'private'));
      zip = (await repository.export(
        await repository.prepare(excludePrivateEvents: true),
        reading,
        readme: '# Archive\n',
        appVersion: '1.0.0',
      )).zip;
    });
    await pump(tester);
    await select(tester);
    final warning = find.textContaining('已排除 1 筆私密事件');
    await reveal(tester, warning);
    expect(warning, findsOneWidget);
    expect(find.textContaining('private marker'), findsNothing);
    await unmount(tester);
  });

  testWidgets('不含媒體的封存預覽列出排除警示與具體項目', (tester) async {
    await tester.runAsync(() async {
      final source = File('${root.path}/excluded.mp4');
      await source.writeAsBytes([1, 2, 3]);
      await repository.attachments.importBatch(
        await repository.attachments.prepare([
          AttachmentSource(source.path, 'excluded.mp4'),
        ]),
        eventId: id,
      );
      zip = (await repository.export(
        await repository.prepare(includeMedia: false),
        reading,
        readme: '# Archive\n',
        appVersion: '1.0.0',
      )).zip;
    });
    await pump(tester);
    await select(tester);
    final warning = find.textContaining('此備份刻意排除部分附件檔案');
    await reveal(tester, warning);
    expect(warning, findsOneWidget);
    expect(find.textContaining('media/'), findsWidgets);
    await unmount(tester);
  });
}
