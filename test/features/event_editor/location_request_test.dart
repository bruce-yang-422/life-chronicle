import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/app/theme.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/location/location_anchor.dart';
import 'package:life_chronicle/data/platform/location_platform.dart';
import 'package:life_chronicle/data/providers.dart';
import 'package:life_chronicle/data/repositories/event_draft_store.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/features/event_editor/location_picker_page.dart';
import 'package:life_chronicle/features/event_editor/new_event_page.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

import '../../data/repositories/harness.dart';
import '../../support/security_stub.dart';
import 'event_editor_test.dart' show settle, StubAttachmentPlatform;

class PendingLocation implements LocationPlatform {
  final requests = <Completer<LocationAnchor>>[];
  int cancellations = 0;
  bool cancellationFails = false;

  @override
  Future<LocationAnchor> current() {
    final request = Completer<LocationAnchor>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<void> cancel() async {
    cancellations++;
    if (cancellationFails) throw PlatformException(code: 'cancel_failed');
    // 模擬平台取消後仍可能送來的延遲結果。
  }

  @override
  Future<void> openMap(LocationAnchor anchor) async {}
  @override
  Future<void> openCopyright() async {}
}

void main() {
  late Harness h;
  late MemoryEventDraftStore store;
  late PendingLocation location;
  late Directory media;

  setUp(() async {
    h = await Harness.create();
    store = MemoryEventDraftStore();
    location = PendingLocation();
    media = await Directory.systemTemp.createTemp('location-test-');
    await store.save('new', EventDraft(title: '定位測試', place: '文字地點'));
  });
  tearDown(() async {
    await h.close();
    await media.delete(recursive: true);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...securityTestOverrides,
          appDatabaseProvider.overrideWithValue(h.db),
          eventDraftStoreProvider.overrideWith((ref) async => store),
          locationPlatformProvider.overrideWithValue(location),
          attachmentRepositoryProvider.overrideWith(
            (ref) async => AttachmentRepository(
              h.context(),
              media,
              StubAttachmentPlatform(),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('zh', 'TW'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light(),
          home: const Scaffold(body: NewEventPage()),
        ),
      ),
    );
    await settle(tester);
    await tester.ensureVisible(find.byIcon(Icons.my_location));
    await tester.pumpAndSettle();
  }

  Future<void> start(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  for (final error in [
    'location_denied',
    'location_timeout',
    'location_disabled',
  ]) {
    testWidgets('定位失敗 $error 保留文字地點並可重試', (tester) async {
      await open(tester);
      await start(tester);
      location.requests.single.completeError(PlatformException(code: error));
      await tester.pump();
      expect(find.byType(SnackBar), findsOneWidget);
      expect((await store.load('new'))!.place, '文字地點');
      expect((await store.load('new'))!.latitude, isNull);
      await start(tester);
      expect(location.requests, hasLength(2));
      location.requests.last.complete(LocationAnchor(25.03, 121.56));
      await tester.pump();
      expect((await store.load('new'))!.latitude, 25.03);
      expect(tester.takeException(), isNull);
      await close(tester);
    });
  }

  testWidgets('取消後舊定位不得覆寫新定位，也不結束新請求的等待狀態', (tester) async {
    await open(tester);
    await start(tester);
    await tester.tap(find.text('取消'));
    await tester.pump();
    expect(location.cancellations, 1);
    await start(tester);
    location.requests.first.complete(LocationAnchor(1, 2));
    await tester.pump();
    expect((await store.load('new'))!.latitude, isNull);
    expect(find.text('取消'), findsOneWidget);
    location.requests.last.complete(LocationAnchor(25, 121, radiusM: 15));
    await tester.pump();
    final draft = (await store.load('new'))!;
    expect([draft.latitude, draft.longitude, draft.radiusM], [25, 121, 15]);
    expect(find.text('取消'), findsNothing);
    await close(tester);
    expect(location.cancellations, 1);
  });

  testWidgets('平台取消失敗也能重試，舊請求錯誤不顯示提示', (tester) async {
    location.cancellationFails = true;
    await open(tester);
    await start(tester);
    await tester.tap(find.text('取消'));
    await tester.pump();
    await start(tester);
    location.requests.first.completeError(
      PlatformException(code: 'location_timeout'),
    );
    await tester.pump();
    expect(find.byType(SnackBar), findsNothing);
    location.requests.last.complete(LocationAnchor(24, 120));
    await tester.pump();
    expect((await store.load('new'))!.latitude, 24);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('離開編輯頁取消定位，延遲成功不寫回草稿', (tester) async {
    await open(tester);
    await start(tester);
    await close(tester);
    expect(location.cancellations, 1);
    location.requests.single.complete(LocationAnchor(25, 121));
    await tester.pump();
    expect((await store.load('new'))!.latitude, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('改用地圖前取消定位，延遲結果不覆寫手動選點', (tester) async {
    await open(tester);
    await start(tester);
    await tester.tap(find.byIcon(Icons.map_outlined));
    await tester.pump();
    await tester.pump();
    expect(location.cancellations, 1);
    expect(find.byType(LocationPickerPage), findsOneWidget);
    // 驗證選點頁回傳資料；圖資與拖曳操作另行驗收。
    Navigator.of(tester.element(find.byType(LocationPickerPage)))
        .pop(LocationAnchor(23.5, 120.5, radiusM: 100));
    await tester.pumpAndSettle();
    location.requests.single.complete(LocationAnchor(1, 2));
    await tester.pump();
    final draft = (await store.load('new'))!;
    expect(
      [draft.latitude, draft.longitude, draft.radiusM],
      [23.5, 120.5, 100],
    );
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('拒絕定位後仍可儲存只有文字地點的事件', (tester) async {
    await open(tester);
    await start(tester);
    location.requests.single.completeError(
      PlatformException(code: 'location_denied'),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('儲存事件'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('儲存事件'));
    await settle(tester);
    final events = (await tester.runAsync(
      () => h.db.select(h.db.events).get(),
    ))!;
    expect(events.single.title, '定位測試');
    final place = (await tester.runAsync(() => h.db.select(h.db.places).get()))!
        .single;
    expect(place.name, '文字地點');
    expect(place.latitude, isNull);
    expect(place.longitude, isNull);
    await close(tester);
  });

  testWidgets('捨棄草稿取消定位，延遲結果不得重建已捨棄的草稿', (tester) async {
    await open(tester);
    await start(tester);
    await tester.scrollUntilVisible(
      find.text('捨棄草稿'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('捨棄草稿'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('捨棄草稿'),
      ),
    );
    await tester.pumpAndSettle();
    expect(location.cancellations, 1);
    location.requests.single.complete(LocationAnchor(25, 121));
    await tester.pump();
    expect(await store.load('new'), isNull);
    expect(tester.takeException(), isNull);
    await close(tester);
  });
}
