import 'dart:io';
import 'dart:async';

import 'package:life_chronicle/core/attachments/photo_preferences.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/core/attachments/photo_compression.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/platform/photo_platform.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/photo_import_session.dart';
import 'package:life_chronicle/features/attachments/attachment_import.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

import '../../data/repositories/attachment_repository_test.dart'
    show FakeAttachmentPlatform;
import '../../data/repositories/harness.dart';
import '../../data/repositories/photo_import_session_test.dart' show FakePhotos;

class PreviewPhotos extends PhotoImportSession {
  PreviewPhotos(AttachmentRepository repository, {super.preferences})
    : super(repository, FakePhotos());
  bool fail = false;
  final calls = <PhotoPreset>[];
  final gates = <Completer<void>>[];
  @override
  Future<File> preview(
    PreparedAttachment file,
    int edge,
    ImportCancellation token,
  ) async => File('/preview');
  @override
  Future<PhotoInfo?> inspect(PreparedAttachment file) async =>
      const PhotoInfo(5000, 3000);
  @override
  Future<({PreparedAttachment file, PhotoOutput output})> compress(
    PreparedAttachment original,
    PhotoPreset preset,
    ImportCancellation token,
  ) async {
    calls.add(preset);
    if (calls.length <= gates.length) await gates[calls.length - 1].future;
    token.check();
    if (fail) throw ImportIntegrityException();
    return (
      file: const PreparedAttachment(
        AttachmentSource('/compressed', 'photo.jpg'),
        68,
        'compressed',
        AttachmentMetadata(mediaType: 'image/jpeg'),
        null,
      ),
      output: const PhotoOutput(
        '/compressed',
        3072,
        1843,
        68,
        'image/jpeg',
        90,
        false,
      ),
    );
  }
}

void main() {
  late Harness h;
  late PreviewPhotos photos;
  setUp(() async {
    h = await Harness.create();
    photos = PreviewPhotos(
      AttachmentRepository(
        h.context(),
        Directory('unused'),
        FakeAttachmentPlatform(),
      ),
    );
  });
  tearDown(() async {
    await h.close();
  });
  Widget app({
    int used = 0,
    double textScale = 1,
    AttachmentImportPlan? plan,
  }) => MaterialApp(
    locale: const Locale('en'),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AttachmentImportDialog(
        photos: photos,
        usedBytes: used,
        plan:
            plan ??
            const AttachmentImportPlan(
              [
                PreparedAttachment(
                  AttachmentSource('/original', 'photo.jpg'),
                  10000,
                  'original',
                  AttachmentMetadata(mediaType: 'image/jpeg'),
                  null,
                ),
              ],
              10000,
              10000,
              1000000000,
              0,
            ),
      ),
    ),
  );
  testWidgets('可容納時維持原檔，提供尺寸與個別壓縮選項', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(photos.calls, isEmpty);
    expect(find.text('5000 × 3000 px'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      'original',
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
  testWidgets('原檔放不下時預設標準壓縮，以實際大小恢復可保存', (tester) async {
    await tester.pumpWidget(app(used: 24999900));
    await tester.pumpAndSettle();
    expect(photos.calls, [PhotoPreset.standard]);
    expect(
      find.textContaining('the default compression preset was selected'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('壓縮失敗不靜默保存原檔，取消勾選後不保存失敗檔', (tester) async {
    photos.fail = true;
    await tester.pumpWidget(app(used: 24999900));
    await tester.pumpAndSettle();
    expect(find.textContaining('could not be processed'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byType(Checkbox));
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('照片壓縮控制在 320px 與兩倍文字下不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(used: 24999900, textScale: 2));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(DropdownButton<String>));
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      'standard',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('一律壓縮採用保存的精簡檔位，提示移除 GPS', (tester) async {
    photos = PreviewPhotos(
      photos.repository,
      preferences: const PhotoPreferences(
        alwaysCompress: true,
        preset: PhotoPreset.compact,
        keepGps: false,
      ),
    );
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(photos.calls, [PhotoPreset.compact]);
    expect(find.textContaining('GPS will be removed'), findsOneWidget);
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      'compact',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('照片處理顯示目前檔名與逐檔剩餘件數，完成前不能保存', (tester) async {
    photos = PreviewPhotos(
      photos.repository,
      preferences: const PhotoPreferences(alwaysCompress: true),
    );
    photos.gates.addAll([Completer<void>(), Completer<void>()]);
    const plan = AttachmentImportPlan(
      [
        PreparedAttachment(
          AttachmentSource('/one', 'first.jpg'),
          10000,
          'first',
          AttachmentMetadata(mediaType: 'image/jpeg'),
          null,
        ),
        PreparedAttachment(
          AttachmentSource('/two', 'second.jpg'),
          10000,
          'second',
          AttachmentMetadata(mediaType: 'image/jpeg'),
          null,
        ),
      ],
      20000,
      20000,
      1000000000,
      0,
    );
    await tester.pumpWidget(app(plan: plan));
    await tester.pump();
    expect(find.textContaining('Processed 0 / 2; 2 remaining'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    photos.gates[0].complete();
    await tester.pumpAndSettle();
    expect(find.textContaining('Processed 1 / 2; 1 remaining'), findsOneWidget);
    expect(find.textContaining('Processing: second.jpg'), findsOneWidget);
    photos.gates[1].complete();
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
