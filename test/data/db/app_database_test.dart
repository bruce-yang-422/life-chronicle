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
        'places',
        'people',
        'event_people',
        'event_links',
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

  group('地點（企劃書 4.1）', () {
    PlacesCompanion place(
      String id, {
      String? name,
      String? key,
      double? lat,
      double? lng,
      double? radius,
    }) => PlacesCompanion.insert(
      id: id,
      name: Value(name),
      nameKey: Value(key),
      latitude: Value(lat),
      longitude: Value(lng),
      radiusM: Value(radius),
      createdAt: _now,
    );

    test('可只有名稱、只有座標，或兩者皆有', () async {
      await db.into(db.places).insert(place('p1', name: '臺北市', key: '台北市'));
      await db
          .into(db.places)
          .insert(place('p2', lat: 25.17, lng: 121.56, radius: 500));
      await db
          .into(db.places)
          .insert(
            place('p3', name: '陽明山', key: '陽明山', lat: 25.16, lng: 121.55),
          );
      expect(await db.select(db.places).get(), hasLength(3));
    });

    test('名稱與座標都沒有時拒絕', () async {
      expect(
        () => db.into(db.places).insert(place('p1')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('正規化名稱不可重複', () async {
      await db.into(db.places).insert(place('p1', name: '臺北市', key: '台北市'));
      expect(
        () => db.into(db.places).insert(place('p2', name: '台北市', key: '台北市')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('經緯度必須成對且在有效範圍；半徑必須為正數且搭配座標', () async {
      for (final bad in [
        place('a', name: 'x', key: 'x', lat: 25),
        place('b', name: 'y', key: 'y', lat: 91, lng: 121),
        place('c', name: 'z', key: 'z', lat: 25, lng: 181),
        place('d', name: 'w', key: 'w', lat: 25, lng: 121, radius: 0),
        place('e', name: 'v', key: 'v', radius: 100),
      ]) {
        expect(
          () => db.into(db.places).insert(bad),
          throwsA(isA<SqliteException>()),
          reason: bad.id.value,
        );
      }
    });

    test('事件可指向地點', () async {
      await db.into(db.places).insert(place('p1', name: '臺北市', key: '台北市'));
      await db
          .into(db.events)
          .insert(event('e1').copyWith(placeId: const Value('p1')));
      final row = await db.select(db.events).getSingle();
      expect(row.placeId, 'p1');
    });
  });

  group('參與人物與關聯事件', () {
    test('人物正規化名稱不可重複；事件與人物多對多', () async {
      await db
          .into(db.people)
          .insert(
            PeopleCompanion.insert(
              id: 'mom',
              displayName: '媽媽',
              nameKey: '媽媽',
              createdAt: _now,
            ),
          );
      expect(
        () => db
            .into(db.people)
            .insert(
              PeopleCompanion.insert(
                id: 'mom2',
                displayName: '媽媽',
                nameKey: '媽媽',
                createdAt: _now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
      await db.into(db.events).insert(event('e1'));
      await db.into(db.events).insert(event('e2'));
      for (final id in ['e1', 'e2']) {
        await db
            .into(db.eventPeople)
            .insert(
              EventPeopleCompanion.insert(
                eventId: id,
                personId: 'mom',
                layer: Layer.original,
                authorId: 'self',
                createdAt: _now,
              ),
            );
      }
      expect(await db.select(db.eventPeople).get(), hasLength(2));
    });

    EventLinksCompanion link(String a, String b) => EventLinksCompanion.insert(
      eventAId: a,
      eventBId: b,
      layer: Layer.original,
      authorId: 'self',
      createdAt: _now,
    );

    test('一個事件可關聯多個事件', () async {
      for (final id in ['e1', 'e2', 'e3', 'e4']) {
        await db.into(db.events).insert(event(id));
      }
      await db.into(db.eventLinks).insert(link('e1', 'e2'));
      await db.into(db.eventLinks).insert(link('e1', 'e3'));
      await db.into(db.eventLinks).insert(link('e1', 'e4'));
      expect(await db.select(db.eventLinks).get(), hasLength(3));
    });

    test('每對只存一列：不可反向重複、不可自我關聯', () async {
      await db.into(db.events).insert(event('e1'));
      await db.into(db.events).insert(event('e2'));
      expect(
        () => db.into(db.eventLinks).insert(link('e2', 'e1')),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => db.into(db.eventLinks).insert(link('e1', 'e1')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('關聯事件與人物對照同樣套用層級觸發器', () async {
      await db.into(db.events).insert(event('e1'));
      await db.into(db.events).insert(event('e2'));
      await db.into(db.eventLinks).insert(link('e1', 'e2'));
      expect(
        () => db.customStatement("UPDATE event_links SET layer = 'original'"),
        throwsSqlite('層級建立後不可變更'),
      );
    });
  });

  group('隱私與軟刪除', () {
    test('隱私預設為一般，只接受 normal 與 private', () async {
      await db.into(db.events).insert(event('e1'));
      expect((await db.select(db.events).getSingle()).privacy, Privacy.normal);
      expect(
        () => db.customStatement("UPDATE events SET privacy = 'secret'"),
        throwsA(isA<SqliteException>()),
      );
    });

    test('軟刪除與復原只改 deleted_at，不受層級觸發器影響', () async {
      await db.into(db.events).insert(event('e1'));
      final byId = db.update(db.events)..where((e) => e.id.equals('e1'));
      await byId.write(EventsCompanion(deletedAt: Value(_now)));
      expect((await db.select(db.events).getSingle()).deletedAt, _now);
      await byId.write(const EventsCompanion(deletedAt: Value(null)));
      expect((await db.select(db.events).getSingle()).deletedAt, isNull);
    });

    test('未軟刪除的事件不可標記為永久刪除', () async {
      await db.into(db.events).insert(event('e1'));
      expect(
        () => (db.update(db.events)..where((e) => e.id.equals('e1'))).write(
          EventsCompanion(purgedAt: Value(_now)),
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('附件拍攝座標必須成對', () async {
      final row = await db
          .customSelect(
            "SELECT sql FROM sqlite_master WHERE name = 'attachments'",
          )
          .getSingle();
      expect(
        row.read<String>('sql'),
        contains('(captured_latitude IS NULL) = (captured_longitude IS NULL)'),
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
