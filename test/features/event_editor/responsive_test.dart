import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/event_draft_store.dart';
import 'package:life_chronicle/features/event_detail/event_detail_page.dart';

import '../../data/repositories/harness.dart';
import 'event_editor_test.dart' as editor;

void main() {
  testWidgets('可見拖曳把手交換段落，標題與內文隨同移動並保存草稿', (tester) async {
    final semantics = tester.ensureSemantics();
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    final store = MemoryEventDraftStore();
    await store.save(
      'new',
      EventDraft(
        title: '拖曳驗收',
        sections: [
          DraftSection(title: '第一標題', content: '第一內文'),
          DraftSection(title: '想對你說的話', content: '第二內文'),
        ],
      ),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    try {
      await editor.pump(tester, h, store);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('新增節點'),
        ),
      );
      await editor.settle(tester);
      final handles = find.byWidgetPredicate(
        (w) => w is Tooltip && w.message?.startsWith('拖曳第 ') == true,
      );
      await tester.scrollUntilVisible(
        handles.last,
        350,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      expect(handles.hitTestable(), findsNWidgets(2));
      expect(
        find.bySemanticsLabel(RegExp('拖曳第 [12] 段以調整順序')),
        findsNWidgets(2),
      );
      final gesture = await tester.startGesture(tester.getCenter(handles.last));
      await gesture.moveBy(const Offset(0, -24));
      await tester.pump(const Duration(milliseconds: 100));
      final target = tester.getCenter(handles.first) - const Offset(0, 100);
      for (var step = 0; step < 20; step++) {
        await gesture.moveTo(
          Offset.lerp(tester.getCenter(handles.last), target, (step + 1) / 20)!,
        );
        await tester.pump(const Duration(milliseconds: 30));
      }
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();
      await tester.pumpAndSettle();
      final draft = (await store.load('new'))!;
      expect(draft.sections.map((s) => s.title), ['想對你說的話', '第一標題']);
      expect(draft.sections.map((s) => s.content), ['第二內文', '第一內文']);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  });
  testWidgets('段落標題與內文具有固定標籤，輸入及預覽後草稿仍分開保存', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    final store = MemoryEventDraftStore();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    Finder field(String hint) => find.byWidgetPredicate(
      (widget) => widget is TextField && widget.decoration?.hintText == hint,
    );
    Future<void> reveal(Finder finder) async {
      await tester.scrollUntilVisible(
        finder,
        250,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
    }

    try {
      await editor.pump(tester, h, store);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('新增節點'),
        ),
      );
      await editor.settle(tester);
      final title = field('例如：第一次見面的那一天（可以留空）');
      final body = field('從這裡開始寫下發生的事、當時的感受或想留下的話……');
      await reveal(title);
      await tester.enterText(title, '那一天');
      await reveal(body);
      await tester.enterText(body, '留下完整的內文。');
      expect(find.text('段落標題（選填）'), findsOneWidget);
      expect(find.text('內文'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('內文')).dy,
        lessThan(tester.getTopLeft(body).dy),
      );
      await reveal(find.text('預覽'));
      await tester.tap(find.text('預覽'));
      await tester.pumpAndSettle();
      expect(find.text('留下完整的內文。'), findsOneWidget);
      await tester.tap(find.text('編輯原文'));
      await tester.pumpAndSettle();
      final draft = (await store.load('new'))!;
      expect(draft.sections.single.title, '那一天');
      expect(draft.sections.single.content, '留下完整的內文。');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  });
  testWidgets('320dp 三倍字級的分組表單可捲到儲存且保留草稿', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    final store = MemoryEventDraftStore();
    await store.save(
      'new',
      EventDraft(
        title: '大字級草稿',
        sections: [DraftSection(content: '草稿記述')],
      ),
    );
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 900);
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    try {
      await editor.pump(tester, h, store);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('新增節點'),
        ),
      );
      await editor.settle(tester);
      expect(find.text('事件資訊'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('儲存事件'),
        400,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 60,
      );
      await editor.settle(tester);
      expect(find.text('儲存事件').hitTestable(), findsOneWidget);
      expect((await store.load('new'))!.title, '大字級草稿');
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  });
  testWidgets('雙欄選取在旋轉與分割視窗後保留，編輯內容不重建', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    try {
      await tester.runAsync(
        () => EventContentRepository(h.context()).save(
          EventDraft(
            title: 'selected event',
            sections: [DraftSection(content: 'narrative')],
          ),
        ),
      );
      await editor.pump(tester, h, MemoryEventDraftStore());
      expect(find.byType(NavigationRail), findsOneWidget);
      await tester.tap(find.text('selected event').first);
      await editor.settle(tester);
      expect(find.byType(EventDetailPage), findsOneWidget);
      tester.view.physicalSize = const Size(400, 900);
      await editor.settle(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('narrative'), findsOneWidget);
      tester.view.physicalSize = const Size(700, 900);
      await editor.settle(tester);
      expect(find.text('narrative'), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text('新增節點'),
        ),
      );
      await editor.settle(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        'draft survives',
      );
      tester.view.physicalSize = const Size(400, 900);
      await editor.settle(tester);
      expect(find.text('draft survives'), findsOneWidget);
      tester.view.physicalSize = const Size(1200, 900);
      await editor.settle(tester);
      expect(find.text('draft survives'), findsOneWidget);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  });

  testWidgets('繁中字級三倍及深色手機首頁沒有版面溢出', (tester) async {
    final h = (await tester.runAsync(Harness.create))!;
    addTearDown(h.close);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 1000);
    tester.platformDispatcher.textScaleFactorTestValue = 3;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    try {
      await tester.runAsync(
        () => EventContentRepository(h.context()).save(
          EventDraft(
            title: 'readable',
            sections: [DraftSection(content: 'body')],
          ),
        ),
      );
      await editor.pump(tester, h, MemoryEventDraftStore());
      expect(
        Theme.of(tester.element(find.byType(NavigationBar))).brightness,
        Brightness.dark,
      );
      expect(find.text('readable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  });
}
