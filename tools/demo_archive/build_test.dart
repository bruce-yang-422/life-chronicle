import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:life_chronicle/core/archive/archive_reading.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/ids/ulid.dart';
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/repositories/archive_repository.dart';
import 'package:life_chronicle/data/repositories/archive_restore.dart';
import 'package:life_chronicle/data/repositories/archive_zip.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/search_repository.dart';
import 'package:life_chronicle/l10n/app_localizations_zh.dart';
import 'package:life_chronicle/l10n/l10n_time_texts.dart';

class FixtureMediaPlatform implements AttachmentPlatform {
  @override
  Future<int> availableBytes(String directory) async => 1 << 40;
  @override
  Future<AttachmentMetadata> metadata(String path) async =>
      const AttachmentMetadata(mediaType: 'image/jpeg');
  @override
  Future<void> open(String path, String mediaType) async {}
}

const fixtureCodec = ArchiveZip(controlPaths: {'README.md', 'SHA256SUMS.txt'});

void main() {
  test('建立 50 筆擬真紀錄及 5 個 JPG，ZIP 還原、重複匯入、搜尋與媒體校驗', () async {
    final root = Directory.current;
    final output = Directory(p.join(root.path, 'demo_data'));
    final work = await Directory(
      p.join(root.path, 'build', 'demo_archive_validation', 'generator'),
    ).create(recursive: true);
    final profile = jsonDecode(
      await File(p.join(work.parent.path, 'target_context.json'))
          .readAsString(),
    ) as Map;
    final stories = jsonDecode(
      await File(p.join(root.path, 'tools', 'demo_archive', 'events.json'))
          .readAsString(),
    ) as List;
    expect(stories.length, 50);
    expect(stories.map((e) => e['age']).toSet(), {
      for (var age = 16; age <= 35; age++) age,
    });
    final db = AppDatabase(NativeDatabase.memory());
    final now = DateTime.utc(2026, 10, 14, 8);
    final ctx = RepositoryContext(
      db,
      subjectId: (profile['subjects'] as List).single['subject_id'] as String,
      actingAuthorId:
          (profile['authors'] as List).firstWhere(
                (a) => a['is_subject_self'] == 1,
              )['author_id']
              as String,
      clock: () => now,
      ids: UlidGenerator(clock: () => now, random: Random(16035)),
    );
    final platform = FixtureMediaPlatform();
    final media = AttachmentRepository(
      ctx,
      await Directory(p.join(work.path, 'media')).create(),
      platform,
    );
    final repository = ArchiveRepository(
      ctx,
      media,
      Directory(p.join(work.path, 'export')),
      fixtureCodec,
    );
    try {
      // 只帶主角及作者的原樣資料；不攜入裝置既有事件或個人附件。
      for (final name in [
        'subjects',
        'authors',
        'archive_sessions',
        'archive_settings',
      ]) {
        for (final raw in profile[name] as List) {
          final row = Map<String, Object?>.from(raw as Map);
          await db.customStatement(
            'INSERT INTO "$name" (${row.keys.map((k) => '"$k"').join(',')}) VALUES (${List.filled(row.length, '?').join(',')})',
            row.values.toList(),
          );
        }
      }
      final ids = <String>[];
      for (var i = 0; i < stories.length; i++) {
        final row = stories[i] as Map;
        final year = row['year'] as int;
        final month = row['month'] as int;
        final time = switch (i % 5) {
          0 => DayTime(year, month, 15),
          1 => MonthTime(year, month),
          2 => HalfYearTime(year, month <= 6 ? 1 : 2),
          3 => QuarterTime(year, (month - 1) ~/ 3 + 1),
          _ => YearTime(year),
        };
        var narrative = row['narrative'] as String;
        if (i == 19) {
          narrative = '利用課餘時間完成基礎設計選修，把色彩與排版串成小專案。先從簡單練習累積作品，為日後的在職進修打下基礎。';
        }
        if (i == 27) {
          narrative += '\n2015 年 6 月完成數位設計基礎進修，附上明確標示「模擬／無效」的結業證書樣張。';
        }
        narrative +=
            '\n\n### 記憶片段 🎉\n\n- **${row['category']}**：${row['reflection']}\n  - 當時${row['age']}歲，故事發生在${row['year']}年。\n\n1. 記下當時的心情\n2. 留住值得回看的細節\n\n| 年齡 | 分類 | 地點 |\n| ---: | :--- | :--- |\n| ${row['age']} | ${row['category']} | ${row['place']} |\n\n`DEMO-${row['age']}` · 👍🏽 👨‍👩‍👧‍👦\n\n[閱讀示範連結](https://example.com)';
        if (i == 49) {
          narrative += '\n\n# 我的二十年\n\n## 青春起點\n\n### 學習與工作\n\n#### 身邊的人\n\n##### 日常小事\n\n###### 下一步\n\n> 不用把每一年都寫成成就。';
        }
        ids.add(
          await EventContentRepository(ctx).save(
            EventDraft(
              title:
                  '【模擬・${row['age']}歲】${i == 19 ? '完成基礎設計選修' : row['title']}',
              time: time,
              category: row['category'] as String,
              place: row['place'] as String,
              tags: ['擬真模擬包', '${row['age']}歲', '林沐辰（虛構）'],
              people: ['林沐辰（虛構）', if (i >= 36) '周以晴（虛構伴侶）'],
              relatedIds: [if (ids.isNotEmpty) ids.last],
              sections: [
                DraftSection(title: '當時的故事', content: narrative),
                DraftSection(
                  title: '留給未來的話',
                  content:
                      '> ${row['reflection']}\n\n**本紀錄屬於虛構角色林沐辰**，故事假設 1990 年出生，與 APP 主角的真實資料無關。🙂',
                ),
              ],
            ),
          ),
        );
      }
      final attachments = <(int, String, String)>[
        (0, 'school_photo.jpg', '16歲_科展合照_虛構.jpg'),
        (7, 'student_card.jpg', '18歲_學生證_模擬無效.jpg'),
        (25, 'travel_photo.jpg', '24歲_山海旅行_虛構.jpg'),
        (27, 'course_certificate.jpg', '25歲_結業證書_模擬無效.jpg'),
        (48, 'home_photo.jpg', '35歲_新居生活_虛構.jpg'),
      ];
      for (final (index, filename, title) in attachments) {
        final plan = await media.prepare([
          AttachmentSource(p.join(output.path, 'source', filename), title),
        ]);
        await media.importBatch(plan, eventId: ids[index]);
      }
      final l = AppLocalizationsZh();
      final reading = ArchiveReading({
        'timeline': '人生時間軸',
        'time': '時間',
        'layer': '層級',
        'author': '作者',
        'recorded': '記錄時間',
        'category': '分類',
        'deleted': '已刪除',
        'original': '原始生命紀錄',
        'remembrance': '後續追憶',
        'reflections': '回顧',
        'attachments': '附件',
      }, L10nTimeTexts(l));
      final exportPlan = await repository.prepare();
      final originalZip = File(p.join(output.path, 'v1', 'LifeChronicle_20261014080000_01m4wpss006k64hsnp9e489t2d_full.zip'));
      if (await originalZip.exists()) {
        final verified = await fixtureCodec.verify(originalZip, Directory(p.join(work.path, 'v1_original')),
          freeBytes: 1 << 40, cancellation: ImportCancellation());
        final newTitles = {for (final e in exportPlan.data['events']!) e['event_id']: e['title']};
        final formatted = {for (final s in exportPlan.data['event_sections']!)
          '${newTitles[s['event_id']]}:${s['position']}': s['content_md']};
        final original = <String, List<Map<String, Object?>>>{};
        for (final name in exportPlan.data.keys) {
          original[name] = (jsonDecode(await File(p.join(verified.directory.path, 'data', '$name.json')).readAsString()) as List)
            .map((row) => Map<String, Object?>.from(row as Map)).toList();
        }
        final originalTitles = {for (final e in original['events']!) e['event_id']: e['title']};
        for (final section in original['event_sections']!) {
          section['content_md'] = formatted['${originalTitles[section['event_id']]}:${section['position']}']!;
        }
        exportPlan.data.clear();
        exportPlan.data.addAll(original);
      }
      final exported = await repository.export(
        exportPlan,
        reading,
        readme: '# 16～35 歲擬真人生模擬資料包\n\n50 筆繁體中文創作紀錄，2006～2025 年，虛構角色林沐辰，故事假設 1990 年出生。\n\n共 5 個 JPG：3 張 AI 生成生活照片、1 張無效模擬學生證、1 張無效模擬結業證書；沒有影片。全部人物、機構及經歷均為虛構。\n\n本包綁定建立當下的模擬器主角 ID；不修改既有主角姓名、生日或安全設定。僅供測試。控制檔大小寫沿用目前開發中的封存編碼器，尚非所有封存驗收已完成。\n',
        appVersion: 'demo-age16-35-v1',
      );
      final destination = File(
        p.join(output.path, p.basename(exported.zip.path)),
      );
      await exported.zip.copy(destination.path);
      await exported.sidecar.copy('${destination.path}.sha256');
      final target = AppDatabase(NativeDatabase.memory());
      try {
        final targetCtx = RepositoryContext(
          target,
          subjectId: ctx.subjectId,
          actingAuthorId: ctx.actingAuthorId,
        );
        final restoredMedia = AttachmentRepository(
          targetCtx,
          await Directory(p.join(work.path, 'restored_media')).create(),
          platform,
        );
        final restore = ArchiveRestore(
          ArchiveRepository(
            targetCtx,
            restoredMedia,
            Directory(p.join(work.path, 'restore')),
            fixtureCodec,
          ),
        );
        Future<void> checkSubject(
          ArchiveRows local,
          ArchiveRows incoming,
        ) async {
          expect(incoming['subjects']!.single['subject_id'], ctx.subjectId);
        }

        var plan = await restore.inspect(
          destination,
          cancellation: ImportCancellation(),
        );
        final report = await restore.apply(
          plan,
          {},
          cancellation: ImportCancellation(),
          validateSubjects: checkSubject,
        );
        expect(report.inserted['events'], 50);
        expect((await target.select(target.events).get()).length, 50);
        expect((await target.select(target.attachments).get()).length, 5);
        expect((await target.select(target.blobs).get()).length, 5);
        expect((await target.select(target.eventSections).get()).length, 100);
        expect(
          await target.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
        for (final blob in await target.select(target.blobs).get()) {
          expect(await ArchiveZip.fileHash(File(blob.path)), blob.sha256);
          final bytes = await File(blob.path).openRead(0, 2).first;
          expect(bytes, [255, 216]);
        }
        final search = SearchRepository(targetCtx);
        expect((await search.watch('擬真模擬包').first).length, 50);
        expect((await search.watch('學生證').first).length, 1);
        expect((await search.watch('新家').first).isNotEmpty, isTrue);
        plan = await restore.inspect(
          destination,
          cancellation: ImportCancellation(),
        );
        expect(plan.conflicts, isEmpty);
        final repeated = await restore.apply(
          plan,
          {},
          cancellation: ImportCancellation(),
          validateSubjects: checkSubject,
        );
        expect(repeated.inserted['events'], 0);
        expect((await target.select(target.events).get()).length, 50);
        final info = {
          'zip': destination.path,
          'sha256': exported.hash,
          'counts': exported.counts,
          'subject_id': ctx.subjectId,
          'event_ids': ids,
          'years': [2006, 2025],
          'ages': [16, 35],
          'local_restore': 'passed',
          'repeat_import': 'passed',
          'search': 'passed',
        };
        await File(p.join(output.path, 'demo_package.json')).writeAsString(
          '${const JsonEncoder.withIndent('  ').convert(info)}\n',
        );
        // ignore: avoid_print
        print(jsonEncode(info));
      } finally {
        await target.close();
      }
    } finally {
      await db.close();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
