import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/event_draft_store.dart';
import 'package:life_chronicle/features/event_detail/event_detail_page.dart';

import '../../data/repositories/harness.dart';
import 'event_editor_test.dart' as editor;

void main() {
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
