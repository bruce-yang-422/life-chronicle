import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/features/attachments/attachment_import.dart';
import 'package:life_chronicle/l10n/app_localizations.dart';

void main() {
  Widget app(AttachmentImportPlan plan, Locale locale) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: AttachmentImportDialog(plan: plan, usedBytes: 0)),
  );

  testWidgets('只有排除檔案時不可匯入，原因以文字顯示', (tester) async {
    const plan = AttachmentImportPlan(
      [],
      0,
      0,
      1000000,
      0,
      rejected: [
        RejectedAttachment(
          AttachmentSource('/video', 'renamed.jpg'),
          AttachmentRejectionReason.video,
        ),
        RejectedAttachment(
          AttachmentSource('/broken', 'broken.pdf'),
          AttachmentRejectionReason.unverified,
        ),
      ],
    );
    await tester.pumpWidget(app(plan, const Locale('zh')));
    await tester.pumpAndSettle();
    expect(find.textContaining('renamed.jpg'), findsOneWidget);
    expect(find.textContaining('影片不支援'), findsOneWidget);
    expect(find.textContaining('無法確認媒體軌道'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('混合批次保留合格檔案，英文顯示排除與靜態圖像提示', (tester) async {
    const plan = AttachmentImportPlan(
      [
        PreparedAttachment(
          AttachmentSource('/photo', 'motion.jpg'),
          100,
          'hash',
          AttachmentMetadata(mediaType: 'image/jpeg'),
          null,
          staticImageOnly: true,
        ),
      ],
      100,
      100,
      1000000,
      0,
      rejected: [
        RejectedAttachment(
          AttachmentSource('/video', 'video.pdf'),
          AttachmentRejectionReason.video,
        ),
      ],
    );
    await tester.pumpWidget(app(plan, const Locale('en')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Only the still image'), findsOneWidget);
    expect(find.textContaining('Videos are not supported'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
  PreparedAttachment file(String name, int bytes, {String? hash}) =>
      PreparedAttachment(
        AttachmentSource('/$name', name),
        bytes,
        hash ?? name,
        const AttachmentMetadata(),
        null,
      );

  testWidgets('超額一 byte 停用匯入，取消一檔後恰好可保存', (tester) async {
    final plan = AttachmentImportPlan(
      [file('first', 12500000), file('second', 12500000), file('extra', 1)],
      25000001,
      25000001,
      1000000000,
      0,
    );
    await tester.pumpWidget(app(plan, const Locale('en')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.textContaining('0.000001'), findsWidgets);
    await tester.ensureVisible(find.byType(Checkbox).last);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(plan.files, hasLength(3));
  });

  testWidgets('單檔超額不可勾選，不妨礙同批其餘檔案', (tester) async {
    final plan = AttachmentImportPlan(
      [file('huge', 25000001), file('small', 1)],
      25000002,
      25000002,
      1000000000,
      0,
    );
    await tester.pumpWidget(app(plan, const Locale('zh')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Checkbox>(find.byType(Checkbox).first).onChanged,
      isNull,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    await tester.ensureVisible(find.byType(Checkbox).last);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  test('勾選重算：邏輯引用逐筆計算、實體雜湊去重', () {
    final first = file('first', 100, hash: 'same');
    final second = file('second', 100, hash: 'same');
    final plan = AttachmentImportPlan([first, second], 200, 100, 1000, 1);
    expect(plan.select([first, second]).originalBytes, 200);
    expect(plan.select([second]).addedBytes, 100);
    expect(plan.select([second]).duplicates, 0);
    expect(plan.select([]).originalBytes, 0);
    expect(plan.files, hasLength(2));
  });

  testWidgets('既有與草稿皆納入額度，空間不足可取消勾選解決', (tester) async {
    final plan = AttachmentImportPlan(
      [file('first', 2), file('second', 1)],
      3,
      3,
      2,
      0,
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AttachmentImportDialog(
            plan: plan,
            usedBytes: 24999997,
            pendingBytes: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byType(Checkbox).last);
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('窄螢幕與放大文字可捲動選檔，不溢出且回傳所選計畫', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final plan = AttachmentImportPlan(
      [
        file('a-very-long-file-name-that-wraps.txt', 100),
        file('second.txt', 200),
      ],
      300,
      300,
      1000000,
      0,
    );
    AttachmentImportPlan? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<AttachmentImportPlan>(
                  context: context,
                  builder: (_) => AttachmentImportDialog(plan: plan),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(result?.files.single.source.name, 'second.txt');
    expect(result?.originalBytes, 200);
    expect(result?.addedBytes, 200);
    expect(tester.takeException(), isNull);
  });
}
