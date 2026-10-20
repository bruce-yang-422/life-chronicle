import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:life_chronicle/core/archive/archive_integrity.dart';
import 'package:life_chronicle/core/archive/commonmark_writer.dart';
import 'package:life_chronicle/core/archive/archive_reading.dart';
import 'package:life_chronicle/core/archive/archive_subject_policy.dart';
import 'package:life_chronicle/core/editor/event_draft.dart';
import 'package:life_chronicle/core/policy/layer_policy.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:life_chronicle/core/time/time_value.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/platform/attachment_platform.dart';
import 'package:life_chronicle/data/repositories/archive_repository.dart';
import 'package:life_chronicle/data/repositories/archive_restore.dart';
import 'package:life_chronicle/data/repositories/archive_zip.dart';
import 'package:life_chronicle/data/repositories/attachment_repository.dart';
import 'package:life_chronicle/data/repositories/event_content_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';
import 'package:life_chronicle/data/repositories/profile_repository.dart';
import 'package:life_chronicle/l10n/app_localizations_en.dart';
import 'package:life_chronicle/l10n/l10n_time_texts.dart';

import 'harness.dart';

import 'package:life_chronicle/data/repositories/story_repository.dart';
import 'package:life_chronicle/core/stories/theme_rule.dart';

class ArchiveTestPlatform implements AttachmentPlatform {
  int free = 1 << 40;
  @override
  Future<int> availableBytes(String path) async {
    if (!await Directory(path).exists()) {
      throw StateError('原生容量檢查需要存在的目錄');
    }
    return free;
  }

  @override
  Future<AttachmentMetadata> metadata(String path) async =>
      const AttachmentMetadata(mediaType: 'video/mp4');
  @override
  Future<void> open(String path, String mediaType) async {}
}

class CancelDuringRestoreCopy extends ImportCancellation {
  CancelDuringRestoreCopy(this.directory);
  final Directory directory;
  @override
  void check() {
    if (directory.listSync().whereType<File>().any(
      (file) => file.path.endsWith('.partial') && file.lengthSync() > 0,
    )) {
      cancelled = true;
    }
    super.check();
  }
}

final reading = ArchiveReading({
  for (final key in [
    'timeline',
    'time',
    'layer',
    'author',
    'recorded',
    'category',
    'deleted',
    'original',
    'remembrance',
    'reflections',
    'attachments',
    'privacy',
    'private',
    'normal',
    'place',
    'people',
    'tags',
    'related',
    'coordinates',
    'radius',
    'captured',
    'imported',
    'filename',
    'unavailable',
    'selfAuthor',
    'narrative',
    'deletedReference',
    'periods',
    'stories',
    'themeAll',
    'themeAny',
    'themeExclude',
    'themeMissing',
  ])
    key: key,
}, L10nTimeTexts(AppLocalizationsEn()));

const codec = ArchiveZip();

void main() {
  late Harness h;
  late Directory root;
  late AttachmentRepository media;
  late ArchiveRepository repository;
  late ArchiveTestPlatform platform;
  setUp(() async {
    h = await Harness.create();
    root = await Directory.systemTemp.createTemp('archive-test-');
    platform = ArchiveTestPlatform();
    media = AttachmentRepository(
      h.context(),
      await Directory(p.join(root.path, 'media')).create(),
      platform,
    );
    repository = ArchiveRepository(
      h.context(),
      media,
      Directory(p.join(root.path, 'backups')),
      codec,
    );
  });
  tearDown(() async {
    await h.close();
    await root.delete(recursive: true);
  });

  Future<ArchiveExport> export({bool includeMedia = true}) async =>
      repository.export(
        await repository.prepare(includeMedia: includeMedia),
        reading,
        readme: '# Archive\n',
        appVersion: '1.0.0',
      );

  test('篇章與引用順序透過正式 ZIP 還原，不複製事件且含閱讀版', () async {
    final a = await h.events().create(
      EventInput(title: '事件甲', time: YearTime(2003)),
    );
    final b = await h.events().create(
      EventInput(title: '事件乙', time: YearTime(2004)),
    );
    final id = await StoryRepository(h.context())
        .save(title: '大學生活', eventIds: [b, a]);
    await EventContentRepository(h.context()).save(
      EventDraft(eventId: a, title: '事件甲', time: YearTime(2003), tags: ['旅行']),
    );
    final tag = (await h.db.select(h.db.tags).get()).single.id;
    final smart = await StoryRepository(h.context()).save(
      title: '旅行主題',
      rule: ThemeRule(mode: TagMatchMode.any, include: [tag]),
    );
    final result = await export();
    final target = AppDatabase(NativeDatabase.memory());
    try {
      final ctx = RepositoryContext(
        target,
        subjectId: h.profile.subjectId,
        actingAuthorId: h.profile.selfAuthorId,
      );
      final restore = ArchiveRestore(
        ArchiveRepository(
          ctx,
          AttachmentRepository(
            ctx,
            await Directory(p.join(root.path, 'story-media')).create(),
            platform,
          ),
          Directory(p.join(root.path, 'story-backups')),
          codec,
        ),
      );
      final plan = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      await restore.apply(
        plan,
        {},
        cancellation: ImportCancellation(),
        validateSubjects: (_, _) async {},
      );
      final content = (await StoryRepository(ctx).load(id))!;
      expect(content.summary.story.title, '大學生活');
      expect(content.entries.map((e) => e.eventId), [b, a]);
      final smartContent = (await StoryRepository(ctx).load(smart))!;
      expect(ThemeRule.decode(smartContent.summary.story.rulesJson!).include, {
        tag,
      });
      expect(smartContent.entries.single.eventId, a);
      expect((await target.select(target.events).get()).length, 2);
      final zipped = ZipDecoder().decodeBytes(await result.zip.readAsBytes());
      expect(
        zipped.files.map((f) => f.name),
        contains('markdown/stories/${id.toLowerCase()}.md'),
      );
    } finally {
      await target.close();
    }
  });

  test('T09 未命名、自訂調序、空段落與追加回顧的 ZIP 閱讀版及還原一致', () async {
    final content = EventContentRepository(h.context());
    final single = await content.save(
      EventDraft(
        title: 'Single acceptance',
        time: YearTime(2003),
        sections: [DraftSection(content: 'single_body_marker')],
      ),
    );
    final id = await content.save(
      EventDraft(
        title: 'Sections acceptance',
        time: YearTime(2004),
        sections: [
          DraftSection(title: 'Start marker', content: 'start_body_marker'),
          DraftSection(title: '想對你說的話', content: 'message_body_marker'),
          DraftSection(title: 'empty_section_marker', content: '  '),
        ],
      ),
    );
    final draft = (await content.load(id))!.toDraft();
    final moved = draft.sections.removeAt(1);
    draft.sections.insert(0, moved);
    await content.save(draft);
    await content.appendReflection(id, 'old_reflection_marker');
    await content.appendReflection(id, 'new_reflection_marker');
    final before = (await content.load(id))!;
    final exported = await export();
    final verified = await codec.verify(
      exported.zip,
      Directory(p.join(root.path, 't09-verify')),
      freeBytes: 1 << 30,
      cancellation: ImportCancellation(),
    );
    final documents = verified.directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'));
    final singleMd = await documents
        .firstWhere((f) => f.path.contains(single.toLowerCase()))
        .readAsString();
    expect(singleMd, contains(CommonMarkWriter.text('single_body_marker')));
    expect(singleMd, isNot(contains('## narrative')));
    final md = await documents
        .firstWhere((f) => f.path.contains(id.toLowerCase()))
        .readAsString();
    expect(md.indexOf('想對你說的話'), lessThan(md.indexOf('Start marker')));
    expect(md, isNot(contains(CommonMarkWriter.text('empty_section_marker'))));
    expect(
      md.indexOf(CommonMarkWriter.text('old_reflection_marker')),
      lessThan(md.indexOf(CommonMarkWriter.text('new_reflection_marker'))),
    );
    final html = await File(p.join(verified.directory.path, 'index.html'))
        .readAsString();
    expect(html.indexOf('想對你說的話'), lessThan(html.indexOf('Start marker')));
    expect(html, isNot(contains('empty_section_marker')));
    final target = AppDatabase(NativeDatabase.memory());
    try {
      final ctx = RepositoryContext(
        target,
        subjectId: h.profile.subjectId,
        actingAuthorId: h.profile.selfAuthorId,
      );
      final restore = ArchiveRestore(
        ArchiveRepository(
          ctx,
          AttachmentRepository(
            ctx,
            await Directory(p.join(root.path, 't09-media')).create(),
            platform,
          ),
          Directory(p.join(root.path, 't09-backups')),
          codec,
        ),
      );
      final plan = await restore.inspect(
        exported.zip,
        cancellation: ImportCancellation(),
      );
      await restore.apply(
        plan,
        {},
        cancellation: ImportCancellation(),
        validateSubjects: (_, _) async {},
      );
      final after = (await EventContentRepository(ctx).load(id))!;
      expect(after.sections, before.sections);
      expect(after.reflections, before.reflections);
      expect(after.reflections.map((r) => r.contentMd), [
        'old_reflection_marker',
        'new_reflection_marker',
      ]);
    } finally {
      await target.close();
    }
  });

  test('v1 封存的手動篇章缺少規則欄位仍可預覽並保留引用', () async {
    final a = await h.events().create(
      EventInput(title: '舊事件', time: YearTime(2003)),
    );
    final id = await StoryRepository(h.context())
        .save(title: '舊篇章', eventIds: [a]);
    final result = await export();
    final verified = await codec.verify(
      result.zip,
      Directory(p.join(root.path, 'v1-source')),
      freeBytes: 1 << 30,
      cancellation: ImportCancellation(),
    );
    final data = File(p.join(verified.directory.path, 'data/stories.json'));
    final rows = (jsonDecode(await data.readAsString()) as List)
        .map(
          (row) => Map<String, dynamic>.from(row as Map)..remove('rules_json'),
        )
        .toList();
    await data.writeAsString(jsonEncode(rows));
    final schemaFile = File(
      p.join(verified.directory.path, 'schema/stories.schema.json'),
    );
    final schema = jsonDecode(await schemaFile.readAsString()) as Map;
    (schema['items']['required'] as List).remove('rules_json');
    (schema['items']['properties'] as Map).remove('rules_json');
    await schemaFile.writeAsString(jsonEncode(schema));
    final manifest = verified.manifest
      ..['format_version'] = '1.0'
      ..['schema_version'] = 1;
    final files = <String, File>{};
    for (final entity
        in verified.directory.listSync(recursive: true).whereType<File>()) {
      files[p
              .relative(entity.path, from: verified.directory.path)
              .replaceAll('\\', '/')] =
          entity;
    }
    final hashes = <String, String>{};
    for (final entry in manifest['files'] as List) {
      final path = entry['path'] as String;
      entry['byte_size'] = await files[path]!.length();
      entry['sha256'] = await ArchiveZip.fileHash(files[path]!);
      hashes[path] = entry['sha256'] as String;
    }
    await files['manifest.json']!.writeAsString(jsonEncode(manifest));
    hashes['manifest.json'] = await ArchiveZip.fileHash(
      files['manifest.json']!,
    );
    await files['SHA256SUMS.txt']!.writeAsString(ArchiveIntegrity.sums(hashes));
    final v1 = File(p.join(root.path, 'legacy.zip'));
    await codec.write(v1, files, cancellation: ImportCancellation());
    final restore = ArchiveRestore(repository);
    final plan = await restore.inspect(v1, cancellation: ImportCancellation());
    expect(plan.data['stories']!.single['rules_json'], isNull);
    expect(plan.data['story_events']!.single['story_id'], id);
    await restore.apply(plan, {
      for (final c in plan.conflicts) c.key: ArchiveConflictChoice.useArchive,
    }, cancellation: ImportCancellation());
    expect(
      (await StoryRepository(h.context()).load(id))!.entries.single.eventId,
      a,
    );
  });

  test('永久刪除參照快照隨正式 ZIP 跨資料庫還原且保留最後區間', () async {
    final source = await h.events().create(
      EventInput(title: '原畢業標題', time: YearTime(2003), privacy: 'private'),
    );
    final dependent = await h.events().create(
      EventInput(
        title: '畢業之後',
        time: RelativeTime(source, RelativeRelation.after),
      ),
    );
    await h.events().softDelete(source);
    await h.events().purge(source);
    final before = (await h.events().find(dependent))!;
    final result = await export();
    final target = AppDatabase(NativeDatabase.memory());
    try {
      final ctx = RepositoryContext(
        target,
        subjectId: h.profile.subjectId,
        actingAuthorId: h.profile.selfAuthorId,
      );
      final targetMedia = AttachmentRepository(
        ctx,
        await Directory(p.join(root.path, 'snapshot-media')).create(),
        platform,
      );
      final restore = ArchiveRestore(
        ArchiveRepository(
          ctx,
          targetMedia,
          Directory(p.join(root.path, 'snapshot-backups')),
          codec,
        ),
      );
      final plan = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      await restore.apply(
        plan,
        {},
        cancellation: ImportCancellation(),
        validateSubjects: (_, _) async {},
      );
      final row = await target.select(target.events).getSingle();
      expect(row.timePayload, before.timePayload);
      expect(row.sortStart, before.sortStart);
      expect(row.sortEnd, before.sortEnd);
      expect(
        (decodeTime(row.timePayload) as RelativeTime).deletedReference,
        const DeletedTimeReference('原畢業標題', private: true),
      );
    } finally {
      await target.close();
    }
  });

  for (final choice in ArchiveConflictChoice.values) {
    test('同名不同 ID 逐筆決策 $choice，引用重用本機 ID 且重複匯入穩定', () async {
      final eventId = await EventContentRepository(h.context()).save(
        EventDraft(title: '原事件', place: '臺北', people: ['ＡＢＣ'], tags: ['相聚']),
      );
      final sourcePlace = (await h.db.select(h.db.places).get()).single.id;
      final sourcePerson = (await h.db.select(h.db.people).get()).single.id;
      final sourceTag = (await h.db.select(h.db.tags).get()).single.id;
      final theme = await StoryRepository(h.context()).save(
        title: '相聚主題',
        rule: ThemeRule(mode: TagMatchMode.all, include: [sourceTag]),
      );
      final result = await export();
      final place = h.context().newId();
      final person = h.context().newId();
      final tag = h.context().newId();
      await h.db.transaction(() async {
        await h.db.customStatement('PRAGMA defer_foreign_keys = ON');
        await h.db.customStatement(
          "UPDATE places SET place_id = ?, name = '台 北', latitude = 25, longitude = 121",
          [place],
        );
        await h.db.customStatement(
          "UPDATE people SET person_id = ?, display_name = 'abc'",
          [person],
        );
        await h.db.customStatement('UPDATE tags SET tag_id = ?', [tag]);
        await h.db.customStatement('UPDATE events SET place_id = ?', [place]);
        await h.db.customStatement('UPDATE event_people SET person_id = ?', [
          person,
        ]);
        await h.db.customStatement('UPDATE event_tags SET tag_id = ?', [tag]);
        await h.db.customStatement(
          'UPDATE stories SET rules_json = ? WHERE story_id = ?',
          [
            ThemeRule(mode: TagMatchMode.all, include: [tag]).encode(),
            theme,
          ],
        );
      });
      final restore = ArchiveRestore(repository);
      for (var run = 0; run < 2; run++) {
        final plan = await restore.inspect(
          result.zip,
          cancellation: ImportCancellation(),
        );
        expect(plan.conflicts.map((c) => c.sourceId).toSet(), {
          sourcePlace,
          sourcePerson,
          sourceTag,
        });
        expect(plan.data['events']!.single['place_id'], place);
        expect(plan.data['event_people']!.single['person_id'], person);
        expect(plan.data['event_tags']!.single['tag_id'], tag);
        expect(plan.conflicts.map((c) => c.table).toSet(), {
          'places',
          'people',
          'tags',
        });
        await restore.apply(plan, {
          for (final conflict in plan.conflicts) conflict.key: choice,
        }, cancellation: ImportCancellation());
        final places = await h.db.select(h.db.places).get();
        expect(places.single.id, place);
        expect(
          places.single.name,
          choice == ArchiveConflictChoice.keepLocal ? '台 北' : '臺北',
        );
        expect(
          places.single.latitude,
          choice == ArchiveConflictChoice.keepLocal ? 25 : null,
        );
        final people = await h.db.select(h.db.people).get();
        expect(people.single.id, person);
        expect(
          people.single.displayName,
          choice == ArchiveConflictChoice.keepLocal ? 'abc' : 'ＡＢＣ',
        );
        expect((await h.db.select(h.db.tags).get()).single.id, tag);
        final themeContent = (await StoryRepository(h.context()).load(theme))!;
        expect(
          ThemeRule.decode(themeContent.summary.story.rulesJson!).include,
          {tag},
        );
        expect(themeContent.entries.single.eventId, eventId);
        expect((await h.events().find(eventId))!.placeId, place);
        expect(
          await h.db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      }
    });
  }

  test('同名引用衝突未選完時不寫入資料且清理暫存', () async {
    await EventContentRepository(h.context())
        .save(EventDraft(title: '事件', tags: ['旅行']));
    final result = await export();
    final localId = h.context().newId();
    await h.db.transaction(() async {
      await h.db.customStatement('PRAGMA defer_foreign_keys = ON');
      await h.db.customStatement('UPDATE tags SET tag_id = ?', [localId]);
      await h.db.customStatement('UPDATE event_tags SET tag_id = ?', [localId]);
    });
    final before = jsonEncode(await repository.snapshot());
    final restore = ArchiveRestore(repository);
    final plan = await restore.inspect(
      result.zip,
      cancellation: ImportCancellation(),
    );
    expect(plan.conflicts, hasLength(1));
    await expectLater(
      restore.apply(plan, {}, cancellation: ImportCancellation()),
      throwsA(isA<ArchiveIntegrityException>()),
    );
    expect(jsonEncode(await repository.snapshot()), before);
    expect(await plan.verified.directory.exists(), isFalse);
  });

  test('新事件以混合選擇合併同名資料，晚期失敗完整復原', () async {
    final event = await EventContentRepository(h.context()).save(
      EventDraft(title: '封存事件', place: '台北', people: ['Amy'], tags: ['旅行']),
    );
    final result = await export();
    final localEvent = h.context().newId();
    final localPlace = h.context().newId();
    final localPerson = h.context().newId();
    final localTag = h.context().newId();
    await h.db.transaction(() async {
      await h.db.customStatement('PRAGMA defer_foreign_keys = ON');
      await h.db.customStatement(
        "UPDATE places SET place_id = ?, latitude = 25, longitude = 121",
        [localPlace],
      );
      await h.db.customStatement(
        "UPDATE people SET person_id = ?, display_name = 'AMY'",
        [localPerson],
      );
      await h.db.customStatement('UPDATE tags SET tag_id = ?', [localTag]);
      await h.db.customStatement(
        'UPDATE events SET event_id = ?, place_id = ?',
        [localEvent, localPlace],
      );
      await h.db.customStatement('UPDATE event_sections SET event_id = ?', [
        localEvent,
      ]);
      await h.db.customStatement(
        'UPDATE event_people SET event_id = ?, person_id = ?',
        [localEvent, localPerson],
      );
      await h.db.customStatement(
        'UPDATE event_tags SET event_id = ?, tag_id = ?',
        [localEvent, localTag],
      );
    });
    final restore = ArchiveRestore(repository);
    final before = jsonEncode(await repository.snapshot());
    for (final fail in [true, false]) {
      final plan = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      // 段落身分既存，保留本機；人物採用封存，地點與標籤保留本機。
      final choices = {
        for (final conflict in plan.conflicts)
          conflict.key: conflict.table == 'people'
              ? ArchiveConflictChoice.useArchive
              : ArchiveConflictChoice.keepLocal,
      };
      if (fail) {
        plan.data['events']!.single['place_id'] = 'missing-place';
        await expectLater(
          restore.apply(plan, choices, cancellation: ImportCancellation()),
          throwsA(isA<ArchiveIntegrityException>()),
        );
        expect(jsonEncode(await repository.snapshot()), before);
      } else {
        final report = await restore.apply(
          plan,
          choices,
          cancellation: ImportCancellation(),
        );
        expect(report.inserted['events'], 1);
        expect((await h.events().find(event))!.placeId, localPlace);
        expect(
          (await h.db.select(h.db.people).get()).single.displayName,
          'Amy',
        );
        expect((await h.db.select(h.db.places).get()).single.latitude, 25);
        expect(
          (await h.db.select(h.db.eventPeople).get())
              .map((row) => row.personId)
              .toSet(),
          {localPerson},
        );
        expect(
          (await h.db.select(h.db.eventTags).get())
              .map((row) => row.tagId)
              .toSet(),
          {localTag},
        );
        expect(
          await h.db.customSelect('PRAGMA foreign_key_check').get(),
          isEmpty,
        );
      }
      expect(await plan.verified.directory.exists(), isFalse);
    }
  });

  test('相同 ID 與相同名稱指向不同本機標籤時拒絕猜測且不改資料', () async {
    await EventContentRepository(h.context())
        .save(EventDraft(title: '事件', tags: ['旅行', '相聚']));
    final result = await export();
    final tags = await h.db.select(h.db.tags).get();
    await h.db.customStatement(
      "UPDATE tags SET label = '暫存' WHERE tag_id = ?",
      [tags[0].id],
    );
    await h.db.customStatement('UPDATE tags SET label = ? WHERE tag_id = ?', [
      tags[0].label,
      tags[1].id,
    ]);
    await h.db.customStatement('UPDATE tags SET label = ? WHERE tag_id = ?', [
      tags[1].label,
      tags[0].id,
    ]);
    final before = jsonEncode(await repository.snapshot());
    await expectLater(
      ArchiveRestore(repository)
          .inspect(result.zip, cancellation: ImportCancellation()),
      throwsA(isA<ArchiveIntegrityException>()),
    );
    expect(jsonEncode(await repository.snapshot()), before);
    expect(
      repository.outputDirectory.listSync().whereType<Directory>(),
      isEmpty,
    );
  });

  Future<void> withInitialTarget(
    Future<void> Function(ArchiveRestore restore, ArchiveRepository target) run,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final profile = await ProfileRepository(db).ensureDefaultProfile();
      final ctx = RepositoryContext(
        db,
        subjectId: profile.subjectId,
        actingAuthorId: profile.selfAuthorId,
      );
      final target = ArchiveRepository(
        ctx,
        AttachmentRepository(
          ctx,
          await Directory(p.join(root.path, 'initial-media')).create(),
          platform,
        ),
        Directory(p.join(root.path, 'initial-backups')),
        codec,
      );
      await run(ArchiveRestore(target), target);
    } finally {
      await db.close();
    }
  }

  test('排除私密事件：JSON、閱讀版、快照、共用媒體與正式還原不洩露私密內容', () async {
    final content = EventContentRepository(h.context());
    final private = await content.save(
      EventDraft(
        title: 'PRIVATE_TITLE_MARKER',
        privacy: 'private',
        time: YearTime(2001),
        sections: [DraftSection(content: 'PRIVATE_BODY_MARKER')],
      ),
    );
    await content.appendReflection(private, 'PRIVATE_REFLECTION_MARKER');
    final public = await content.save(
      EventDraft(
        title: 'public entry',
        time: RelativeTime(private, RelativeRelation.after),
        relatedIds: [private],
      ),
    );
    final purged = await h.events().create(
      EventInput(
        title: 'PRIVATE_SNAPSHOT_MARKER',
        privacy: 'private',
        time: YearTime(2002),
      ),
    );
    final reference = await h.events().create(
      EventInput(
        title: 'snapshot ref',
        time: RelativeTime(purged, RelativeRelation.after),
      ),
    );
    await h.events().softDelete(purged);
    await h.events().purge(purged);
    final story = await StoryRepository(h.context())
        .save(title: 'legacy', eventIds: [private, public]);
    final shared = File(p.join(root.path, 'shared-private.mp4'))
      ..writeAsBytesSync([11, 22, 33]);
    final exclusive = File(p.join(root.path, 'exclusive-private.mp4'))
      ..writeAsBytesSync([44, 55]);
    final warehouse = File(p.join(root.path, 'warehouse.mp4'))
      ..writeAsBytesSync([66, 77]);
    await media.importBatch(
      await media.prepare([
        AttachmentSource(shared.path, 'PRIVATE_FILENAME_MARKER.mp4'),
        AttachmentSource(exclusive.path, 'PRIVATE_EXCLUSIVE_MARKER.mp4'),
        AttachmentSource(warehouse.path, 'warehouse.mp4'),
      ]),
      eventId: private,
    );
    final unused = (await h.db.select(h.db.attachments).get()).singleWhere(
      (a) => a.originalFilename == 'warehouse.mp4',
    );
    await media.removeReference(unused.id);
    await media.importBatch(
      await media.prepare([AttachmentSource(shared.path, 'public.mp4')]),
      eventId: public,
    );
    // 典藏後追加的追憶亦隨所屬私密事件排除。
    await ProfileRepository(h.db).activateLifeArchive(
      h.profile.subjectId,
      byAuthorId: h.profile.selfAuthorId,
    );
    await EventContentRepository(h.context(actingAuthorId: h.familyAuthorId))
        .appendReflection(private, 'PRIVATE_FAMILY_MARKER');
    final before = await repository.snapshot();
    final plan = await repository.prepare(excludePrivateEvents: true);
    expect(plan.scope.type, 'custom');
    expect(plan.data['events']!.map((e) => e['event_id']), [public, reference]);
    expect(plan.data['reflections'], isEmpty);
    expect(plan.data['event_links'], isEmpty);
    expect(plan.data['story_events'], [
      {'story_id': story, 'event_id': public, 'position': 1},
    ]);
    expect(plan.data['attachments'], hasLength(1));
    expect(plan.media, hasLength(2)); // 共用與未引用倉庫副本。
    expect(plan.privacyFilter!.excludedEvents, 1);
    expect(plan.privacyFilter!.excludedMedia, 1);
    expect(plan.privacyFilter!.excludedSnapshots, 1);
    final result = await repository.export(
      plan,
      reading,
      readme: '# Archive\n',
      appVersion: '1.0.0',
    );
    final verified = await codec.verify(
      result.zip,
      Directory(p.join(root.path, 'private-verified')),
      freeBytes: 1 << 30,
      cancellation: ImportCancellation(),
    );
    expect(verified.manifest['format_version'], '1.2');
    expect(
      (verified.manifest['scope'] as Map)['private_events'],
      plan.privacyFilter!.manifest,
    );
    for (final file
        in verified.directory.listSync(recursive: true).whereType<File>()) {
      if (file.path.endsWith('.mp4')) continue;
      expect(
        await file.readAsString(),
        isNot(contains('PRIVATE_')),
        reason: file.path,
      );
    }
    await withInitialTarget((restore, target) async {
      final incoming = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      final report = await restore.apply(
        incoming,
        {},
        cancellation: ImportCancellation(),
      );
      expect(report.excluded, 2);
      expect(report.attachmentCount, 1);
      expect(
        await target.db.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      final restored = await target.snapshot();
      for (final event in restored['events']!) {
        final original = before['events']!.singleWhere(
          (e) => e['event_id'] == event['event_id'],
        );
        for (final field in [
          'layer',
          'author_id',
          'created_at',
          'updated_at',
          'sort_start',
          'sort_end',
        ]) {
          expect(event[field], original[field], reason: field);
        }
      }
      expect(restored['reflections'], isEmpty);
      expect(jsonEncode(restored), isNot(contains('PRIVATE_')));
    });
    expect(await repository.snapshot(), before);
    expect(await exclusive.exists(), isTrue);
    final noMedia = await repository.prepare(
      excludePrivateEvents: true,
      includeMedia: false,
    );
    expect(noMedia.media, isEmpty);
    expect(noMedia.excludedMedia, hasLength(2));
  });

  test('個別排除共用副本：自訂 manifest、閱讀連結與另一資料庫還原皆一致', () async {
    final event = await EventContentRepository(h.context())
        .save(EventDraft(title: '有共用附件'));
    final shared = File(p.join(root.path, 'shared.mp4'))
      ..writeAsBytesSync([1, 2, 3]);
    final kept = File(p.join(root.path, 'kept.mp4'))
      ..writeAsBytesSync([4, 5, 6, 7]);
    await media.importBatch(
      await media.prepare([
        AttachmentSource(shared.path, '敏感副本.mp4'),
        AttachmentSource(shared.path, '另一個共用名稱.mp4'),
        AttachmentSource(kept.path, '保留影片.mp4'),
      ]),
      eventId: event,
    );
    final before = jsonEncode(await repository.snapshot());
    final options = await repository.mediaOptions();
    expect(options, hasLength(2));
    final omitted = options.singleWhere((option) => option.references == 2);
    expect(omitted.names, ['另一個共用名稱.mp4', '敏感副本.mp4']);
    final plan = await repository.prepare(excludedBlobIds: {omitted.blobId});
    expect(plan.scope.type, 'custom');
    expect(plan.media, hasLength(1));
    expect(
      plan.requiredBytes,
      lessThan((await repository.prepare()).requiredBytes),
    );
    final result = await repository.export(
      plan,
      reading,
      readme: '# Archive\n',
      appVersion: '1.0.0',
    );
    expect(result.zip.path, endsWith('_custom.zip'));
    final verified = await codec.verify(
      result.zip,
      Directory(p.join(root.path, 'custom-check')),
      freeBytes: 1 << 30,
      cancellation: ImportCancellation(),
    );
    final excludedPath = plan.excludedMedia.keys.single;
    expect(verified.manifest['scope'], {
      'type': 'custom',
      'excluded': [
        {'path': excludedPath, 'reason': 'user_excluded'},
      ],
    });
    expect(
      await File(p.join(verified.directory.path, excludedPath)).exists(),
      isFalse,
    );
    expect(
      (verified.manifest['files'] as List).where(
        (file) => (file as Map)['path'] == excludedPath,
      ),
      isEmpty,
    );
    final html = await File(p.join(verified.directory.path, 'index.html'))
        .readAsString();
    expect(html, contains('敏感副本.mp4'));
    expect(html, contains('unavailable'));
    expect(html, isNot(contains('href="$excludedPath"')));
    expect(html, isNot(contains('src="$excludedPath"')));
    await withInitialTarget((restore, target) async {
      final incoming = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      final report = await restore.apply(
        incoming,
        {},
        cancellation: ImportCancellation(),
      );
      expect(report.excluded, 1);
      expect(report.attachmentCount, 3);
      expect(report.mediaBytes, 4);
      expect(await target.db.select(target.db.attachments).get(), hasLength(3));
      final blobs = await target.db.select(target.db.blobs).get();
      expect(
        blobs.where((blob) => blob.verifyStatus == 'excluded'),
        hasLength(1),
      );
      expect(
        blobs.where((blob) => blob.verifyStatus == 'verified'),
        hasLength(1),
      );
      expect(await target.attachments.directory.list().toList(), hasLength(1));
      expect(
        await target.db.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    });
    expect(jsonEncode(await repository.snapshot()), before);
    expect(await shared.readAsBytes(), [1, 2, 3]);
    expect(await kept.readAsBytes(), [4, 5, 6, 7]);
  });

  test('明確排除遺失副本仍可匯出，未知選擇則拒絕且不產生備份', () async {
    final event = await EventContentRepository(h.context())
        .save(EventDraft(title: '副本已遺失'));
    final source = File(p.join(root.path, 'missing.mp4'))
      ..writeAsBytesSync([8, 9]);
    await media.importBatch(
      await media.prepare([AttachmentSource(source.path, 'missing.mp4')]),
      eventId: event,
    );
    final blob = (await h.db.select(h.db.blobs).get()).single;
    await File(blob.path).delete();
    final before = jsonEncode(await repository.snapshot());
    await expectLater(
      repository.prepare(),
      throwsA(isA<ArchiveIntegrityException>()),
    );
    await expectLater(
      repository.prepare(excludedBlobIds: {'unknown'}),
      throwsA(isA<ArchiveIntegrityException>()),
    );
    expect(await repository.outputDirectory.list().toList(), isEmpty);
    final result = await repository.export(
      await repository.prepare(excludedBlobIds: {blob.id}),
      reading,
      readme: '# Archive\n',
      appVersion: '1.0.0',
    );
    expect(await result.zip.exists(), isTrue);
    expect(jsonEncode(await repository.snapshot()), before);
    expect(await source.readAsBytes(), [8, 9]);
  });

  test('沒有私密權限時不可列出副本名稱或借用已準備計畫匯出', () async {
    await EventContentRepository(h.context())
        .save(EventDraft(title: '私密事件', privacy: 'private'));
    final plan = await repository.prepare();
    final locked = ArchiveRepository(
      RepositoryContext(
        h.db,
        subjectId: h.profile.subjectId,
        actingAuthorId: h.profile.selfAuthorId,
        canReadPrivate: false,
      ),
      media,
      Directory(p.join(root.path, 'locked-backups')),
      codec,
    );
    await expectLater(
      locked.mediaOptions(),
      throwsA(isA<PermissionDeniedException>()),
    );
    await expectLater(
      locked.export(plan, reading, readme: '# Archive\n', appVersion: '1.0.0'),
      throwsA(isA<PermissionDeniedException>()),
    );
    expect(await locked.outputDirectory.exists(), isFalse);
  });

  test('跨主角只取代尚未填寫的初始主角，重開後使用還原的主角與本人作者', () async {
    await EventContentRepository(h.context()).save(EventDraft(title: '還原事件'));
    final result = await export();
    await withInitialTarget((restore, target) async {
      final plan = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      expect(plan.conflicts, isEmpty);
      final report = await restore.apply(
        plan,
        {},
        cancellation: ImportCancellation(),
      );
      expect(report.inserted['events'], 1);
      expect(
        await target.db.select(target.db.subjects).get(),
        await h.db.select(h.db.subjects).get(),
      );
      expect(
        await target.db.select(target.db.authors).get(),
        await h.db.select(h.db.authors).get(),
      );
      final profile = await ProfileRepository(target.db).ensureDefaultProfile();
      expect(profile.subjectId, h.profile.subjectId);
      expect(profile.selfAuthorId, h.profile.selfAuthorId);
      expect(
        await target.db.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    });
  });

  test('跨主角遇到本機姓名、生日、事件或額外作者時拒絕且不改原資料', () async {
    final result = await export();
    for (final change in ['name', 'birth', 'event', 'deleted', 'author']) {
      await withInitialTarget((restore, target) async {
        if (change == 'name') {
          await target.db.customStatement(
            "UPDATE subjects SET display_name = '已填姓名'",
          );
        } else if (change == 'birth') {
          await target.db.customStatement(
            "UPDATE subjects SET birth_date = ?",
            [jsonEncode(YearTime(1990).toJson())],
          );
        } else if (change == 'author') {
          await ProfileRepository(target.db).addAuthor('家人', role: 'family');
        } else {
          final content = EventContentRepository(target.ctx);
          final id = await content.save(EventDraft(title: '本機紀錄'));
          if (change == 'deleted') {
            await target.db.customStatement(
              'UPDATE events SET deleted_at = ?',
              [DateTime.utc(2026).toIso8601String()],
            );
          }
          expect(id, isNotEmpty);
        }
        final before = jsonEncode(await target.snapshot());
        await expectLater(
          restore.inspect(result.zip, cancellation: ImportCancellation()),
          throwsA(isA<ArchiveSubjectException>()),
        );
        expect(jsonEncode(await target.snapshot()), before, reason: change);
        expect(await target.outputDirectory.list().toList(), isEmpty);
      });
    }
  });

  test('取代初始主角後的晚期外鍵失敗會復原原主角與作者', () async {
    final id = await EventContentRepository(h.context())
        .save(EventDraft(title: '將失敗'));
    final source = File(p.join(root.path, 'late-failure.mp4'));
    await source.writeAsBytes([1, 2, 3]);
    await media.importBatch(
      await media.prepare([AttachmentSource(source.path, 'late-failure.mp4')]),
      eventId: id,
    );
    final result = await export();
    await withInitialTarget((restore, target) async {
      final before = jsonEncode(await target.snapshot());
      final plan = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      plan.data['events']!.single['place_id'] = 'missing-place';
      await expectLater(
        restore.apply(plan, {}, cancellation: ImportCancellation()),
        throwsA(isA<ArchiveIntegrityException>()),
      );
      expect(jsonEncode(await target.snapshot()), before);
      expect(await plan.verified.directory.exists(), isFalse);
      expect(await target.attachments.directory.list().toList(), isEmpty);
      expect(await source.readAsBytes(), [1, 2, 3]);
      expect(
        await target.db.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    });
  });

  test('檢視後本機新增內容時拒絕還原，不能以自訂驗證回呼繞過主角政策', () async {
    final result = await export();
    await withInitialTarget((restore, target) async {
      final plan = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      await EventContentRepository(target.ctx).save(EventDraft(title: '剛新增'));
      final before = jsonEncode(await target.snapshot());
      await expectLater(
        restore.apply(
          plan,
          {},
          cancellation: ImportCancellation(),
          validateSubjects: (_, _) async {},
        ),
        throwsA(isA<ArchiveIntegrityException>()),
      );
      expect(jsonEncode(await target.snapshot()), before);
      expect(await plan.verified.directory.exists(), isFalse);
    });
  });

  test('還原媒體串流複製中途取消時復原資料並清理副本', () async {
    final id = await EventContentRepository(h.context())
        .save(EventDraft(title: '中途取消'));
    final source = File(p.join(root.path, 'cancel-copy.mp4'));
    await source.writeAsBytes(List.generate(2 * 1024 * 1024, (i) => i % 251));
    await media.importBatch(
      await media.prepare([AttachmentSource(source.path, 'cancel-copy.mp4')]),
      eventId: id,
    );
    final result = await export();
    await withInitialTarget((restore, target) async {
      final before = jsonEncode(await target.snapshot());
      final plan = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      final cancellation = CancelDuringRestoreCopy(
        target.attachments.directory,
      );
      await expectLater(
        restore.apply(plan, {}, cancellation: cancellation),
        throwsA(isA<ImportCancelled>()),
      );
      expect(cancellation.cancelled, isTrue);
      expect(jsonEncode(await target.snapshot()), before);
      expect(await target.attachments.directory.list().toList(), isEmpty);
      expect(await plan.verified.directory.exists(), isFalse);
      expect(await source.length(), 2 * 1024 * 1024);
    });
  });

  test('不能先還原一般模式設定再覆蓋原本受典藏保護的原始紀錄', () async {
    final id = await EventContentRepository(h.context())
        .save(EventDraft(title: '舊版'));
    final result = await export();
    await h.events().update(id, const EventChanges(title: Value('不可覆蓋')));
    await h.activateArchive();
    final before = jsonEncode(await repository.snapshot());
    final restore = ArchiveRestore(repository);
    final plan = await restore.inspect(
      result.zip,
      cancellation: ImportCancellation(),
    );
    await expectLater(
      restore.apply(plan, {
        for (final conflict in plan.conflicts)
          conflict.key: ArchiveConflictChoice.useArchive,
      }, cancellation: ImportCancellation()),
      throwsA(isA<PermissionDeniedException>()),
    );
    expect(jsonEncode(await repository.snapshot()), before);
  });

  test('100 事件與共用媒體封存，另一個空資料庫還原筆數／層級／作者／時間／關聯', () async {
    final content = EventContentRepository(h.context());
    final ids = <String>[];
    for (var i = 0; i < 100; i++) {
      ids.add(
        await content.save(
          EventDraft(
            title: '# event * [$i]',
            time: HalfYearTime(2003, i.isEven ? 1 : 2),
            sections: [
              DraftSection(content: 'line one\nline two'),
              DraftSection(title: 'empty', content: ' '),
            ],
          ),
        ),
      );
    }
    await h.relations().link(ids[0], ids[1]);
    final original = File(p.join(root.path, 'original.mp4'));
    await original.writeAsBytes([1, 2, 3, 4]);
    final plan = await media.prepare([
      AttachmentSource(original.path, 'original.mp4'),
    ]);
    await media.importBatch(plan, eventId: ids[0]);
    await media.importBatch(plan, eventId: ids[1]);
    final result = await export();
    expect(await original.readAsBytes(), [1, 2, 3, 4]);
    expect(result.counts['events'], 100);
    expect(await ArchiveZip.fileHash(result.zip), result.hash);
    expect(await result.sidecar.readAsString(), startsWith(result.hash));
    final target = AppDatabase(NativeDatabase.memory());
    try {
      final ctx = RepositoryContext(
        target,
        subjectId: h.profile.subjectId,
        actingAuthorId: h.profile.selfAuthorId,
      );
      final targetMedia = AttachmentRepository(
        ctx,
        await Directory(p.join(root.path, 'target-media')).create(),
        platform,
      );
      final restore = ArchiveRestore(
        ArchiveRepository(
          ctx,
          targetMedia,
          Directory(p.join(root.path, 'new-target-backups')),
          codec,
        ),
      );
      final imported = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      expect(imported.conflicts, isEmpty);
      final report = await restore.apply(
        imported,
        {},
        cancellation: ImportCancellation(),
        validateSubjects: (_, _) async {},
      );
      expect(report.inserted['events'], 100);
      expect(report.attachmentCount, 2);
      expect(report.mediaBytes, 4);
      expect(
        await target.select(target.events).get(),
        await h.db.select(h.db.events).get(),
      );
      expect((await target.select(target.attachments).get()).length, 2);
      expect((await target.select(target.blobs).get()).length, 1);
      expect((await target.select(target.eventLinks).get()).length, 1);
      expect(
        await target.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      final file = File((await target.select(target.blobs).getSingle()).path);
      await original.delete();
      expect(await file.readAsBytes(), [1, 2, 3, 4]);
      final repeated = await restore.inspect(
        result.zip,
        cancellation: ImportCancellation(),
      );
      final repeatedReport = await restore.apply(repeated, {
        for (final conflict in repeated.conflicts)
          conflict.key: ArchiveConflictChoice.keepLocal,
      }, cancellation: ImportCancellation());
      expect(
        repeatedReport.inserted.values.every((count) => count == 0),
        isTrue,
      );
      expect(
        repeatedReport.skipped,
        repeated.data.values.fold<int>(0, (total, rows) => total + rows.length),
      );
    } finally {
      await target.close();
    }
  });

  test('正式 ZIP 的每份資料都有獨立 Schema，所有 Schema 皆納入完整性清單', () async {
    await EventContentRepository(h.context())
        .save(EventDraft(title: '可獨立驗證的資料'));
    final result = await export();
    final verified = await codec.verify(
      result.zip,
      Directory(p.join(root.path, 'schema-verify')),
      freeBytes: 1 << 30,
      cancellation: ImportCancellation(),
    );
    final inventory = (verified.manifest['files'] as List)
        .map((entry) => (entry as Map)['path'])
        .toSet();
    final aggregate = jsonDecode(
      await File(p.join(verified.directory.path, 'schema', 'data.schema.json'))
          .readAsString(),
    ) as Map;
    for (final table in repository.tables) {
      final name = table.actualTableName;
      expect((aggregate['properties'] as Map)[name], {
        r'$ref': '$name.schema.json',
      });
      expect(inventory, contains('schema/$name.schema.json'));
      final schema = jsonDecode(
        await File(
          p.join(verified.directory.path, 'schema', '$name.schema.json'),
        ).readAsString(),
      ) as Map;
      expect(schema['type'], 'array');
      expect(
        (schema['items'] as Map)['required'],
        table.$columns.map((column) => column.name).toList(),
      );
      expect(
        await File(p.join(verified.directory.path, 'data', '$name.json'))
            .exists(),
        isTrue,
      );
    }
    expect(
      inventory,
      containsAll([
        'schema/data.schema.json',
        'schema/time_value.schema.json',
        'schema/manifest.schema.json',
      ]),
    );
    final manifestSchema = jsonDecode(
      await File(
        p.join(verified.directory.path, 'schema', 'manifest.schema.json'),
      ).readAsString(),
    ) as Map;
    expect(
      (manifestSchema['required'] as List).toSet(),
      verified.manifest.keys.toSet(),
    );
  });

  test('遭竄改 manifest、路徑逃逸、符號連結與容量不足均不改資料庫', () async {
    await EventContentRepository(h.context()).save(EventDraft(title: 'event'));
    final result = await export();
    final before = jsonEncode(await repository.snapshot());
    final decoded = ZipDecoder().decodeBytes(await result.zip.readAsBytes());
    decoded.add(ArchiveFile.string('manifest.json', '{}'));
    final corrupt = File(p.join(root.path, 'corrupt.zip'));
    await corrupt.writeAsBytes(ZipEncoder().encode(decoded));
    final restore = ArchiveRestore(repository);
    await expectLater(
      restore.inspect(corrupt, cancellation: ImportCancellation()),
      throwsA(isA<ArchiveIntegrityException>()),
    );
    for (final entry in [
      ArchiveFile.string('../escape.txt', 'bad'),
      ArchiveFile.string('link', 'data/events.json')
        ..symbolicLink = 'data/events.json'
        ..mode = 0xa1ff,
    ]) {
      final malicious = File(p.join(root.path, 'malicious.zip'));
      await malicious.writeAsBytes(ZipEncoder().encode(Archive()..add(entry)));
      await expectLater(
        restore.inspect(malicious, cancellation: ImportCancellation()),
        throwsA(isA<ArchiveIntegrityException>()),
      );
    }
    platform.free = 1;
    await expectLater(
      restore.inspect(result.zip, cancellation: ImportCancellation()),
      throwsA(isA<ImportSpaceException>()),
    );
    expect(jsonEncode(await repository.snapshot()), before);
    expect(
      await File(p.join(root.parent.path, 'escape.txt')).exists(),
      isFalse,
    );
  });

  test('附件損毀或取消匯出不留下正式 ZIP，原資料與原件不變', () async {
    final id = await EventContentRepository(h.context())
        .save(EventDraft(title: 'event'));
    final original = File(p.join(root.path, 'original.mp4'));
    await original.writeAsBytes([7, 8, 9]);
    await media.importBatch(
      await media.prepare([AttachmentSource(original.path, 'original.mp4')]),
      eventId: id,
    );
    final plan = await repository.prepare();
    await plan.media.values.single.writeAsBytes([0]);
    await expectLater(
      repository.export(plan, reading, readme: '# Archive\n', appVersion: '1'),
      throwsA(isA<ArchiveIntegrityException>()),
    );
    expect(
      (await repository.outputDirectory.list().toList())
          .whereType<File>()
          .where((f) => f.path.endsWith('.zip')),
      isEmpty,
    );
    expect(await original.readAsBytes(), [7, 8, 9]);
    final token = ImportCancellation()..cancelled = true;
    await expectLater(
      repository.export(
        plan,
        reading,
        readme: '# Archive\n',
        appVersion: '1',
        cancellation: token,
      ),
      throwsA(isA<ImportCancelled>()),
    );
    expect((await h.db.select(h.db.events).get()).length, 1);
  });
}
