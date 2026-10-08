import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/db/tables.dart';

final _now = DateTime.utc(2045, 3, 2);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.subjects)
        .insert(SubjectsCompanion.insert(id: 'subject', displayName: '王大明'));
    await db
        .into(db.authors)
        .insert(
          AuthorsCompanion.insert(
            id: 'self',
            displayName: '王大明',
            role: '本人',
            isSubjectSelf: const Value(true),
          ),
        );
    await db
        .into(db.authors)
        .insert(
          AuthorsCompanion.insert(
            id: 'daughter',
            displayName: '王小美',
            role: '女兒',
          ),
        );
    await db
        .into(db.archiveSessions)
        .insert(
          ArchiveSessionsCompanion.insert(
            id: 'session1',
            subjectId: 'subject',
            activatedAt: _now,
            activatedBy: 'daughter',
          ),
        );
  });

  tearDown(() => db.close());

  EventsCompanion event(
    String id, {
    String layer = Layer.original,
    String author = 'self',
    String? session,
  }) => EventsCompanion.insert(
    id: id,
    subjectId: 'subject',
    title: '進入大學',
    timePayload: '{"type":"year","year":2003}',
    sortStart: const Value('2003-01-01'),
    sortEnd: const Value('2003-12-31'),
    updatedAt: _now,
    layer: layer,
    authorId: author,
    createdAt: _now,
    archiveSessionId: Value(session),
  );

  Matcher throwsSqlite(String messagePart) => throwsA(
    isA<SqliteException>().having(
      (e) => e.message,
      'message',
      contains(messagePart),
    ),
  );

  test('資料庫可從空白建立並開啟，schema_version = 1', () async {
    expect(db.schemaVersion, 1);
    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();
    expect(
      names,
      containsAll([
        'subjects',
        'authors',
        'archive_settings',
        'archive_sessions',
        'events',
        'event_sections',
        'life_periods',
        'reflections',
        'stories',
        'story_events',
        'blobs',
        'attachments',
        'tags',
        'event_tags',
        'change_history',
        'search_index',
      ]),
    );
  });

  test('外鍵約束已啟用', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.first, 1);
    expect(
      () => db.into(db.events).insert(event('e1', author: 'nobody')),
      throwsA(isA<SqliteException>()),
    );
  });

  test('排序欄位建有索引', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND tbl_name = 'events'",
        )
        .get();
    final names = rows.map((r) => r.read<String>('name'));
    expect(names, containsAll(['events_sort_start', 'events_sort_end']));
  });

  group('層級不可變更（企劃書 9.2）', () {
    test('修改 layer 的 SQL 會失敗', () async {
      await db.into(db.events).insert(event('e1'));
      expect(
        () => db.customStatement(
          "UPDATE events SET layer = 'remembrance', "
          "archive_session_id = 'session1' WHERE id = 'e1'",
        ),
        throwsSqlite('層級建立後不可變更'),
      );
    });

    test('即使寫入相同的值也拒絕', () async {
      await db.into(db.events).insert(event('e1'));
      expect(
        () => db.customStatement(
          "UPDATE events SET layer = 'original' WHERE id = 'e1'",
        ),
        throwsSqlite('層級建立後不可變更'),
      );
    });

    test('不涉及 layer 的修改正常', () async {
      await db.into(db.events).insert(event('e1'));
      await (db.update(db.events)..where((e) => e.id.equals('e1'))).write(
        const EventsCompanion(title: Value('進入台大')),
      );
      final row = await (db.select(
        db.events,
      )..where((e) => e.id.equals('e1'))).getSingle();
      expect(row.title, '進入台大');
      expect(row.layer, Layer.original);
    });

    test('所有內容表都套用層級觸發器', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'trigger' "
            "AND name LIKE '%_layer_immutable'",
          )
          .get();
      expect(rows.map((r) => r.read<String>('name')).toSet(), {
        for (final t in layeredTables) '${t}_layer_immutable',
      });
    });
  });

  group('後續追憶層的作者', () {
    test('作者為主角本人時新增失敗', () async {
      expect(
        () => db
            .into(db.events)
            .insert(event('e1', layer: Layer.remembrance, session: 'session1')),
        throwsSqlite('作者不得為主角本人'),
      );
    });

    test('作者為家人時可新增', () async {
      await db
          .into(db.events)
          .insert(
            event(
              'e1',
              layer: Layer.remembrance,
              author: 'daughter',
              session: 'session1',
            ),
          );
      final row = await db.select(db.events).getSingle();
      expect(row.layer, Layer.remembrance);
    });

    test('將追憶內容的作者改為本人會失敗', () async {
      await db
          .into(db.events)
          .insert(
            event(
              'e1',
              layer: Layer.remembrance,
              author: 'daughter',
              session: 'session1',
            ),
          );
      expect(
        () => (db.update(db.events)..where((e) => e.id.equals('e1'))).write(
          const EventsCompanion(authorId: Value('self')),
        ),
        throwsSqlite('作者不得為主角本人'),
      );
    });

    test('已撰寫追憶的作者不可改標記為本人', () async {
      await db
          .into(db.events)
          .insert(
            event(
              'e1',
              layer: Layer.remembrance,
              author: 'daughter',
              session: 'session1',
            ),
          );
      expect(
        () => (db.update(db.authors)..where((a) => a.id.equals('daughter')))
            .write(const AuthorsCompanion(isSubjectSelf: Value(true))),
        throwsSqlite('不可標記為主角本人'),
      );
    });

    test('其他內容表（回顧）同樣受限', () async {
      await db.into(db.events).insert(event('e1'));
      expect(
        () => db
            .into(db.reflections)
            .insert(
              ReflectionsCompanion.insert(
                id: 'r1',
                eventId: 'e1',
                recordedAt: _now,
                contentMd: '回想',
                layer: Layer.remembrance,
                authorId: 'self',
                createdAt: _now,
                archiveSessionId: const Value('session1'),
              ),
            ),
        throwsSqlite('作者不得為主角本人'),
      );
    });
  });

  group('層級與典藏期間一致性', () {
    test('原始生命紀錄層不可帶典藏期間', () async {
      expect(
        () => db.into(db.events).insert(event('e1', session: 'session1')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('後續追憶層必須指向典藏期間', () async {
      expect(
        () => db
            .into(db.events)
            .insert(event('e1', layer: Layer.remembrance, author: 'daughter')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('不接受未定義的層級代號', () async {
      expect(
        () => db.into(db.events).insert(event('e1', layer: 'memorial')),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  test('典藏模式只接受 normal 與 life_archive', () async {
    await db
        .into(db.archiveSettings)
        .insert(ArchiveSettingsCompanion.insert(subjectId: 'subject'));
    final row = await db.select(db.archiveSettings).getSingle();
    expect(row.mode, ArchiveMode.normal);
    expect(
      () => db.customStatement(
        "UPDATE archive_settings SET mode = 'death' WHERE subject_id = 'subject'",
      ),
      throwsA(isA<SqliteException>()),
    );
  });

  test('全文索引（FTS5）可寫入與查詢', () async {
    await db.customStatement(
      "INSERT INTO search_index (entity_type, entity_id, content) "
      "VALUES ('event', 'e1', 'graduation ceremony taipei')",
    );
    final rows = await db
        .customSelect(
          "SELECT entity_id FROM search_index WHERE search_index MATCH 'taipei'",
        )
        .get();
    expect(rows.single.read<String>('entity_id'), 'e1');
  });
}
