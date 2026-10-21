import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/photo_preferences.dart';
import 'package:life_chronicle/core/attachments/photo_compression.dart';
import 'package:life_chronicle/data/repositories/photo_preferences_store.dart';
import 'package:life_chronicle/features/settings/photo_settings.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

class MemoryPhotos implements PhotoPreferencesStore {
  PhotoPreferences value = const PhotoPreferences();
  bool fail = false;
  @override
  Future<PhotoPreferences> load() async => value;
  @override
  Future<void> save(PhotoPreferences preferences) async {
    if (fail) throw StateError('failed');
    value = preferences;
  }
}

void main() {
  Widget app(MemoryPhotos store, {double scale = 1}) => ProviderScope(
    overrides: [
      photoPreferencesStoreProvider.overrideWith((ref) async => store),
    ],
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const SettingsPage(),
    ),
  );
  testWidgets('設定頁有照片入口，偏好與 GPS 選擇均可保存', (tester) async {
    final store = MemoryPhotos();
    await tester.pumpWidget(app(store));
    await tester.tap(find.text('照片保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(store.value.alwaysCompress, isTrue);
    await tester.ensureVisible(find.byType(SwitchListTile).last);
    await tester.tap(find.byType(SwitchListTile).last);
    await tester.pumpAndSettle();
    expect(store.value.keepGps, isFalse);
    expect(find.textContaining('拍攝座標仍保存於資料庫'), findsOneWidget);
  });
  testWidgets('保存失敗保留原設定，窄畫面放大文字可操作', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryPhotos()..fail = true;
    await tester.pumpWidget(app(store, scale: 2));
    await tester.tap(find.text('照片保存'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(SwitchListTile).first);
    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(store.value.alwaysCompress, isFalse);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile).first).value,
      isFalse,
    );
    expect(find.textContaining('無法讀取或保存'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('檔位保存失敗時，畫面恢復已保存的標準檔位', (tester) async {
    final store = MemoryPhotos()..fail = true;
    await tester.pumpWidget(app(store));
    await tester.tap(find.text('照片保存'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<PhotoPreset>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('精簡 · 2048 px').last);
    await tester.pumpAndSettle();
    expect(store.value.preset, PhotoPreset.standard);
    expect(
      tester
          .widget<DropdownButton<PhotoPreset>>(
            find.byType(DropdownButton<PhotoPreset>),
          )
          .value,
      PhotoPreset.standard,
    );
  });
}
