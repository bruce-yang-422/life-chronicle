import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/app/theme.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/stories/theme_rule.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/story_repository.dart';
import 'package:life_chronicle/features/stories/stories_page.dart';
import 'package:life_chronicle/features/stories/story_detail_page.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

import '../../data/repositories/harness.dart';
import '../../support/security_stub.dart';
import '../event_editor/event_editor_test.dart'
    show settle, StubAttachmentPlatform;

void main() {
  late Harness h;
  late Directory media;
  setUp(() async {
    h = await Harness.create();
    media = await Directory.systemTemp.createTemp('story-ui-');
  });
  tearDown(() async {
    await h.close();
    await media.delete(recursive: true);
  });
  void ui(String name, WidgetTesterCallback body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        }
      });
  Future<void> open(
    WidgetTester tester, {

    Locale locale = const Locale('zh', 'TW'),
    Size size = const Size(400, 850),
    double scale = 1,
    Widget? home,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...securityTestOverrides,
          appDatabaseProvider.overrideWithValue(h.db),
          attachmentRepositoryProvider.overrideWith(
            (ref) async => AttachmentRepository(
              h.context(),
              media,
              StubAttachmentPlatform(),
            ),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: home ?? const Scaffold(body: StoriesPage()),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> reveal(
    WidgetTester tester,
    Finder finder, {
    double delta = 250,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();
  }

  Future<String> event(
    WidgetTester tester,
    String title, {
    String privacy = 'normal',
    List<String> tags = const [],
  }) async => (await tester.runAsync(
    () => EventContentRepository(h.context()).save(
      EventDraft(
        title: title,
        time: YearTime(2003),
        privacy: privacy,
        tags: tags,
      ),
    ),
  ))!;

  Future<Map<String, String>> tagIds(WidgetTester tester) async => {
    for (final tag in (await tester.runAsync(
      () => h.db.select(h.db.tags).get(),
    ))!)
      tag.label: tag.id,
  };
  Future<void> pick(
    WidgetTester tester,
    String id, {
    bool exclude = false,
  }) async {
    final chip = find.byKey(ValueKey('${exclude ? 'exclude' : 'include'}-$id'));
    await reveal(tester, chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester, {String label = '儲存主題'}) async {
    await reveal(tester, find.text(label));
    await tester.tap(find.text(label));
    await settle(tester);
  }

  ui('設定 AND 與排除標籤，儲存後只顯示符合事件並可閱讀詳情', (tester) async {
    await event(tester, '家庭出遊', tags: ['家庭', '旅行']);
    await event(tester, '工作出差', tags: ['家庭', '旅行', '工作']);
    await event(tester, '單人旅行', tags: ['旅行']);
    final tags = await tagIds(tester);
    await open(tester);
    await tester.tap(find.text('新增智慧主題'));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('story-title')), '家庭旅行');
    await pick(tester, tags['家庭']!);
    await pick(tester, tags['旅行']!);
    await pick(tester, tags['工作']!, exclude: true);
    await save(tester);
    await tester.tap(find.text('家庭旅行'));
    await settle(tester);
    await reveal(tester, find.text('家庭出遊'));
    expect(find.text('工作出差'), findsNothing);
    expect(find.text('單人旅行'), findsNothing);
    await tester.tap(find.text('家庭出遊'));
    await settle(tester);
    expect(find.text('日後回顧'), findsOneWidget);
  });

  ui('切換 OR、改名與刪除主題，事件與標籤仍保留', (tester) async {
    await event(tester, '學業事件', tags: ['學業']);
    await event(tester, '工作事件', tags: ['工作']);
    final tags = await tagIds(tester);
    final id = (await tester.runAsync(
      () => StoryRepository(h.context()).save(
        title: '舊主題',
        rule: ThemeRule(mode: TagMatchMode.all, include: tags.values),
      ),
    ))!;
    await open(tester);
    await tester.tap(find.text('舊主題'));
    await settle(tester);
    await tester.tap(find.text('編輯主題'));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('story-title')), '成長主題');
    await tester.tap(find.byKey(const ValueKey('theme-mode')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('任一符合（OR）').last);
    await tester.pumpAndSettle();
    await save(tester);
    final content = (await tester.runAsync(
      () => StoryRepository(h.context()).load(id),
    ))!;
    expect(content.entries, hasLength(2));
    await reveal(tester, find.text('刪除主題'));
    await tester.tap(find.text('刪除主題'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(of: find.byType(AlertDialog), matching: find.text('刪除主題'))
          .last,
    );
    await settle(tester);
    expect(find.text('成長主題'), findsNothing);
    expect(
      (await tester.runAsync(() => h.db.select(h.db.events).get()))!,
      hasLength(2),
    );
    expect(
      (await tester.runAsync(() => h.db.select(h.db.tags).get()))!,
      hasLength(2),
    );
  });

  ui('智慧主題排除私密，即使已解鎖也不顯示；新增符合事件會自動更新', (tester) async {
    await event(tester, '不能洩露的標題', privacy: 'private', tags: ['旅行']);
    final tags = await tagIds(tester);
    final id = (await tester.runAsync(
      () => StoryRepository(h.context()).save(
        title: '旅行主題',
        rule: ThemeRule(mode: TagMatchMode.any, include: tags.values),
      ),
    ))!;
    await open(tester, home: StoryDetailPage(storyId: id));
    expect(find.text('不能洩露的標題'), findsNothing);
    await event(tester, '公開旅行', tags: ['旅行']);
    await settle(tester);
    await reveal(tester, find.text('公開旅行'));
    expect(find.text('公開旅行'), findsOneWidget);
  });

  ui('英文 320dp 三倍字級與鍵盤下可設定條件，寬度改變保留輸入', (tester) async {
    await event(tester, 'Trip', tags: ['Travel']);
    final tags = await tagIds(tester);
    await open(
      tester,
      locale: const Locale('en'),
      size: const Size(320, 640),
      scale: 3,
    );
    await tester.tap(find.text('New Smart Topic'));
    await settle(tester);
    await tester.enterText(
      find.byKey(const ValueKey('story-title')),
      'Travel topic',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    await tester.pumpAndSettle();
    await pick(tester, tags['Travel']!);
    tester.view.physicalSize = const Size(950, 700);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    await save(tester, label: 'Save Topic');
    expect(find.text('Travel topic'), findsOneWidget);
  });

  ui('未選納入標籤不可儲存，不建立空條件主題', (tester) async {
    await open(tester);
    await tester.tap(find.text('新增智慧主題'));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('story-title')), '空條件');
    await save(tester);
    expect(find.text('請至少選一個納入標籤。'), findsOneWidget);
    expect(
      (await tester.runAsync(() => h.db.select(h.db.stories).get()))!,
      isEmpty,
    );
  });
}
