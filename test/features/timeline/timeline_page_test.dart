import '../../support/security_stub.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/app/app.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/repositories/timeline_preferences_store.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/core/time/time_value.dart';

import '../../data/repositories/harness.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 25; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(tester.takeException(), isNull);
}

Future<Harness> open(
  WidgetTester tester,
  Future<void> Function(Harness) seed,
) async {
  final h = (await tester.runAsync(() async {
    final h = await Harness.create();
    await seed(h);
    return h;
  }))!;
  addTearDown(h.close);
  tester.platformDispatcher.localesTestValue = [const Locale('zh', 'TW')];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...securityTestOverrides,
        appDatabaseProvider.overrideWithValue(h.db),
        timelinePreferencesStoreProvider.overrideWith(
          (ref) async => MemoryTimelinePreferencesStore(),
        ),
      ],
      child: const LifeChronicleApp(),
    ),
  );
  await settle(tester);
  return h;
}

void main() {
  databaseTestWidgets('精簡清單與圖文卡片都顯示距今時間', (tester) async {
    final today = DateTime.now();
    final past = today.subtract(const Duration(days: 3));
    await open(tester, (h) async {
      await h.events().create(
        EventInput(
          title: 'recent',
          time: DayTime(past.year, past.month, past.day),
        ),
      );
      await h.events().create(
        EventInput(title: 'older', time: YearTime(today.year - 2)),
      );
    });
    expect(find.text('3 天前'), findsOneWidget);
    expect(find.text('約2 年前'), findsOneWidget);
    await tester.tap(find.byTooltip('圖文卡片'));
    await settle(tester);
    expect(find.text('3 天前'), findsOneWidget);
    expect(find.text('約2 年前'), findsOneWidget);
  });
  databaseTestWidgets('一般手機字級的年份、排序、篩選及顯示模式保持同一排', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, (h) async {
      await h.events().create(EventInput(title: 'demo', time: YearTime(2025)));
    });
    final sortingY = tester.getCenter(find.byIcon(Icons.swap_vert)).dy;
    expect(
      tester.getCenter(find.byIcon(Icons.expand_more)).dy,
      closeTo(sortingY, 1),
    );
    expect(
      tester.getCenter(find.byIcon(Icons.filter_list)).dy,
      closeTo(sortingY, 1),
    );
    expect(tester.getCenter(find.byTooltip('圖文卡片')).dy, closeTo(sortingY, 1));
    expect(tester.takeException(), isNull);
  });
  databaseTestWidgets('首次開啟搜尋即顯示已有紀錄，不必先提交空白條件', (tester) async {
    await open(tester, (h) async {
      await h.events().create(
        EventInput(title: 'older demo', time: YearTime(2006)),
      );
      await h.events().create(
        EventInput(title: 'newer demo', time: YearTime(2025)),
      );
    });
    await tester.tap(find.text('搜尋與視圖'));
    await settle(tester);
    expect(find.text('older demo'), findsOneWidget);
    expect(find.text('newer demo'), findsOneWidget);
  });

  databaseTestWidgets('圖文卡片顯示摘要與附件數，月份分隔不為模糊時間補月份', (tester) async {
    await open(tester, (h) async {
      final id = await h.events().create(
        EventInput(title: 'year only', time: YearTime(2003)),
      );
      await h.db
          .into(h.db.eventSections)
          .insert(
            EventSectionsCompanion.insert(
              id: 'section',
              eventId: id,
              position: 0,
              contentMd: 'a remembered story',
              layer: 'original',
              authorId: h.profile.selfAuthorId,
              createdAt: h.now,
            ),
          );
      for (var i = 0; i < 31; i++) {
        await h.events().create(
          EventInput(title: 'dated $i', time: DayTime(2003, 12, i % 28 + 1)),
        );
      }
    });
    expect(find.text('12 月'), findsOneWidget);
    await tester.tap(find.byTooltip('圖文卡片'));
    await settle(tester);
    expect(find.text('0 個附件'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('a remembered story'),
      500,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    await settle(tester);
    expect(find.text('月份未定'), findsOneWidget);
    expect(find.text('a remembered story'), findsOneWidget);
  });

  databaseTestWidgets('切換排序方向保留正在閱讀事件及其位置', (tester) async {
    await open(tester, (h) async {
      for (var i = 0; i < 100; i++) {
        await h.events().create(
          EventInput(
            title: 'event $i',
            time: DayTime(2003, i ~/ 28 + 1, i % 28 + 1),
          ),
        );
      }
    });
    final scroll = tester.widget<CustomScrollView>(
      find.byType(CustomScrollView),
    );
    scroll.controller!.jumpTo(600);
    await settle(tester);
    final viewportTop = tester.getTopLeft(find.byType(CustomScrollView)).dy;
    final texts = find.textContaining('event ').evaluate();
    final anchor = texts.firstWhere((element) {
      final box = element.renderObject as RenderBox;
      final y = box.localToGlobal(Offset.zero).dy;
      return y >= viewportTop + 56 && y < viewportTop + 136;
    });
    final title = (anchor.widget as Text).data!;
    final before = tester.getTopLeft(find.text(title)).dy;
    await tester.tap(find.text('新→舊'));
    await settle(tester);
    expect(find.text('舊→新'), findsOneWidget);
    expect(find.text(title), findsOneWidget);
    expect(tester.getTopLeft(find.text(title)).dy, closeTo(before, 1));
  });

  databaseTestWidgets('空白資料有可見提示並保留新增分頁入口', (tester) async {
    await open(tester, (_) async {});
    expect(find.text('還沒有生命紀錄，請從「新增節點」開始。'), findsOneWidget);
    expect(find.text('新增節點'), findsOneWidget);
  });

  databaseTestWidgets('20 筆完整列出，年份標題收合與展開', (tester) async {
    await open(tester, (h) async {
      for (var i = 0; i < 20; i++) {
        await h.events().create(
          EventInput(title: 'event $i', time: DayTime(2003, 1, i + 1)),
        );
      }
    });
    expect(find.text('2003 年・20 筆'), findsOneWidget);
    expect(find.text('event 19'), findsOneWidget);
    await tester.tap(find.text('2003 年・20 筆'));
    await settle(tester);
    expect(find.text('event 19'), findsNothing);
    await tester.tap(find.text('2003 年・20 筆'));
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('event 0'),
      350,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    await settle(tester);
    expect(find.text('event 0'), findsOneWidget);
  });

  databaseTestWidgets('年份清單直接跳年、可繼續跨年捲動，未知固定在最後', (tester) async {
    await open(tester, (h) async {
      for (var year = 1977; year <= 2026; year++) {
        await h.events().create(
          EventInput(title: 'entry $year', time: YearTime(year)),
        );
      }
      await h.events().create(
        const EventInput(title: 'undated', time: UnknownTime()),
      );
    });
    await tester.tap(find.byIcon(Icons.expand_more).first);
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('1990 年'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('1990 年'));
    await settle(tester);
    expect(find.text('entry 1990'), findsOneWidget);
    expect(find.text('entry 1989'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('undated'),
      350,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    await settle(tester);
    expect(find.text('時間未定・1 筆'), findsOneWidget);
  });

  databaseTestWidgets('年份與半年文字不補出未輸入的月日', (tester) async {
    await open(tester, (h) async {
      await h.events().create(EventInput(title: 'year', time: YearTime(2003)));
      await h.events().create(
        EventInput(title: 'half', time: HalfYearTime(2003, 2)),
      );
    });
    expect(find.text('月份未定'), findsOneWidget);
    expect(find.text('下半年'), findsOneWidget);
    expect(find.text('01/01'), findsNothing);
  });

  databaseTestWidgets('套用職涯篩選顯示條件與筆數，一次清除恢復全部', (tester) async {
    await open(tester, (h) async {
      await h.events().create(
        EventInput(title: 'career', time: YearTime(2003), category: '職涯'),
      );
      await h.events().create(
        EventInput(title: 'home', time: YearTime(1990), category: '家庭'),
      );
    });
    await tester.tap(find.byIcon(Icons.filter_list));
    await settle(tester);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('職涯').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('套用'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('套用'));
    await settle(tester);
    expect(find.text('符合 1／2 筆'), findsOneWidget);
    expect(find.text('home'), findsNothing);
    expect(find.text('1990 年・1 筆'), findsNothing);
    await tester.tap(find.byTooltip('清除篩選'));
    await settle(tester);
    expect(find.text('home'), findsOneWidget);
  });
}

// 先卸載 ProviderScope，再推進時間以完成 drift 的延遲監聽釋放。
void databaseTestWidgets(String description, WidgetTesterCallback callback) {
  testWidgets(description, (tester) async {
    await callback(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
