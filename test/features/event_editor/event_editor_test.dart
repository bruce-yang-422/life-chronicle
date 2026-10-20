import '../../support/security_stub.dart';

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/event_draft_store.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/features/event_detail/event_detail_page.dart';
import 'package:life_chronicle/data/repositories/timeline_preferences_store.dart';

import '../../data/repositories/harness.dart';

class StubAttachmentPlatform implements AttachmentPlatform {
  @override
  Future<int> availableBytes(String path) async => 1 << 30;
  @override
  Future<AttachmentMetadata> metadata(String path) async =>
      const AttachmentMetadata();
  @override
  Future<void> open(String path, String mediaType) async {}
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(tester.takeException(), isNull);
}

Future<void> pump(WidgetTester tester, Harness h, EventDraftStore store) async {
  final directory = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('editor-media-'),
  ))!;
  addTearDown(() => directory.delete(recursive: true));
  final media = AttachmentRepository(
    h.context(),
    directory,
    StubAttachmentPlatform(),
  );
  tester.platformDispatcher.localesTestValue = [const Locale('zh', 'TW')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...securityTestOverrides,
        appDatabaseProvider.overrideWithValue(h.db),
        eventDraftStoreProvider.overrideWith((ref) async => store),
        attachmentRepositoryProvider.overrideWith((ref) async => media),
        timelinePreferencesStoreProvider.overrideWith(
          (ref) async => MemoryTimelinePreferencesStore(),
        ),
      ],
      child: const LifeChronicleApp(),
    ),
  );
  await settle(tester);
}

void main() {
  void ui(String name, WidgetTesterCallback callback) =>
      testWidgets(name, (tester) async {
        tester.view.physicalSize = const Size(400, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        try {
          await callback(tester);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(seconds: 1));
        }
      });
  ui('新增直接提供完整欄位，年份與半年不補月日，儲存後開啟詳情', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    final store = MemoryEventDraftStore();
    await pump(tester, h, store);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('新增節點'),
      ),
    );
    await settle(tester);
    expect(find.text('何時發生: 時間未定'), findsOneWidget);
    expect(find.text('進階編輯'), findsNothing);
    await tester.scrollUntilVisible(
      find.byIcon(Icons.person_add),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byIcon(Icons.person_add), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<String>),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(ReorderableListView),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(ReorderableListView), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-title-field')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextFormField).first, '我的大學');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.calendar_month));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(DropdownButtonFormField<String>),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('半年').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('year')));
    await tester.tap(find.byKey(const ValueKey('year')));
    await tester.pumpAndSettle();
    final yearPicker = tester.widget<YearPicker>(find.byType(YearPicker));
    yearPicker.onChanged(DateTime(2003));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('下半年').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('套用時間'));
    await tester.pumpAndSettle();
    expect(find.text('何時發生: 2003 年下半年'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('儲存事件'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('儲存事件'));
    await settle(tester);
    expect(find.text('日後回顧'), findsOneWidget);
    final events = (await tester.runAsync(
      () => h.db.select(h.db.events).get(),
    ))!;
    expect(decodeTime(events.single.timePayload), HalfYearTime(2003, 2));
  });
  ui('減少動態效果時停用共享元素及詳情轉場', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    await tester.runAsync(
      () =>
          EventContentRepository(h.context())
              .save(EventDraft(title: '減少動態', time: YearTime(2003))),
    );
    await pump(tester, h, MemoryEventDraftStore());
    await tester.tap(find.text('減少動態'));
    await settle(tester);
    final element = tester.element(find.byType(EventDetailPage));
    expect(ModalRoute.of(element)!.transitionDuration, Duration.zero);
    final heroes = tester.widgetList<HeroMode>(find.byType(HeroMode));
    expect(heroes.every((hero) => !hero.enabled), isTrue);
  });
  ui('編輯直接提供自訂段落標題並用可見按鈕排序', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    final id = (await tester.runAsync(
      () => EventContentRepository(h.context()).save(
        EventDraft(
          title: '段落排序',
          time: YearTime(2003),
          sections: [
            DraftSection(content: '第一段'),
            DraftSection(title: '原標題', content: '第二段'),
          ],
        ),
      ),
    ))!;
    await pump(tester, h, MemoryEventDraftStore());
    await tester.tap(find.text('段落排序'));
    await settle(tester);
    await tester.tap(find.byTooltip('編輯事件'));
    await settle(tester);
    expect(find.text('進階編輯'), findsNothing);
    final title = find.byWidgetPredicate(
      (widget) => widget is TextField && widget.controller?.text == '原標題',
    );
    await tester.scrollUntilVisible(
      title,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(title, '想對你說的話');
    await tester.ensureVisible(find.byTooltip('上移').last);
    await tester.tap(find.byTooltip('上移').last);
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('儲存事件'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('儲存事件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('儲存事件'));
    await settle(tester);
    final data = (await tester.runAsync(
      () => EventContentRepository(h.context()).load(id),
    ))!;
    expect(data.sections.map((section) => section.contentMd), ['第二段', '第一段']);
    expect(data.sections.first.title, '想對你說的話');
  });
  ui('退出與重建畫面後恢復草稿，包含自訂段落順序', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    final store = MemoryEventDraftStore();
    await store.save(
      'new',
      EventDraft(
        title: '草稿標題',
        time: YearTime(2003),
        sections: [
          DraftSection(title: '想對你說的話', content: '保留內容'),
          DraftSection(content: '第二段'),
        ],
      ),
    );
    await pump(tester, h, store);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('新增節點'),
      ),
    );
    await settle(tester);
    expect(find.text('已恢復尚未儲存的草稿'), findsOneWidget);
    expect(find.text('草稿標題'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('保留內容'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('保留內容'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('event-title-field')),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextFormField).first, '更新草稿');
    await settle(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await pump(tester, h, store);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('新增節點'),
      ),
    );
    await settle(tester);
    expect(find.text('更新草稿'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('保留內容'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('保留內容'), findsOneWidget);
  });
  ui('時間軸詳情顯示段落，新增回顧不覆寫，搜尋可開啟同一事件', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    final id = (await tester.runAsync(
      () => EventContentRepository(h.context()).save(
        EventDraft(
          title: '大學畢業',
          time: YearTime(2003),
          sections: [
            DraftSection(content: '單段記述'),
            DraftSection(title: '空白'),
          ],
        ),
      ),
    ))!;
    await tester.runAsync(
      () => EventContentRepository(h.context()).appendReflection(id, '原有回顧'),
    );
    await pump(tester, h, MemoryEventDraftStore());
    await tester.tap(find.text('大學畢業'));
    await settle(tester);
    expect(find.text('單段記述'), findsOneWidget);
    expect(find.text('空白'), findsNothing);
    await tester.tap(find.text('新增回顧'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '新的回顧');
    await tester.tap(find.text('儲存回顧'));
    await settle(tester);
    expect(find.text('原有回顧'), findsOneWidget);
    expect(find.text('新的回顧'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settle(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('搜尋與視圖'),
      ),
    );
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, '大學');
    await tester.tap(find.text('搜尋'));
    await settle(tester);
    await tester.tap(find.text('大學畢業'));
    await settle(tester);
    expect(find.text('單段記述'), findsOneWidget);
  });
}
