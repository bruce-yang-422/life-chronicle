import 'package:drift/drift.dart';

import '../db/app_database.dart';
import 'event_repository.dart';
import 'repository_context.dart';

/// 事件的參與人物與關聯事件（企劃書 4.1）。
///
/// 對照資料有層級：生命典藏期間新增的人物或關聯屬於後續追憶層，
/// 不會改動原始生命紀錄。
class EventRelationsRepository {
  EventRelationsRepository(this.ctx);

  final RepositoryContext ctx;

  AppDatabase get db => ctx.db;

  // ---- 參與人物 ----

  Future<void> addPerson(String eventId, String personId) =>
      db.transaction(() async {
        final existing =
            await (db.select(db.eventPeople)..where(
                  (r) =>
                      r.eventId.equals(eventId) & r.personId.equals(personId),
                ))
                .getSingleOrNull();
        if (existing != null) return;
        final stamp = await ctx.stampForNew();
        await db
            .into(db.eventPeople)
            .insert(
              EventPeopleCompanion.insert(
                eventId: eventId,
                personId: personId,
                layer: stamp.layerCode,
                authorId: stamp.authorId,
                createdAt: stamp.createdAt,
                archiveSessionId: Value(stamp.archiveSessionId),
              ),
            );
      });

  Future<void> removePerson(String eventId, String personId) => db.transaction(
    () async {
      final query = db.select(db.eventPeople)
        ..where((r) => r.eventId.equals(eventId) & r.personId.equals(personId));
      final row = await query.getSingleOrNull();
      if (row == null) return;
      await ctx.ensureCanModify(row.layer);
      await (db.delete(db.eventPeople)..where(
            (r) => r.eventId.equals(eventId) & r.personId.equals(personId),
          ))
          .go();
    },
  );

  Future<List<Person>> peopleOf(String eventId) {
    final query = db.select(db.people).join([
      innerJoin(
        db.eventPeople,
        db.eventPeople.personId.equalsExp(db.people.id),
      ),
    ])..where(db.eventPeople.eventId.equals(eventId));
    return query.map((r) => r.readTable(db.people)).get();
  }

  // ---- 關聯事件（無方向，每對只存一列） ----

  static (String, String) _ordered(String a, String b) =>
      a.compareTo(b) < 0 ? (a, b) : (b, a);

  /// 建立兩事件的關聯；已存在時不重複建立。
  Future<void> link(String eventId, String otherId) => db.transaction(() async {
    if (eventId == otherId) {
      throw ArgumentError('事件不可與自己關聯');
    }
    for (final id in [eventId, otherId]) {
      final row = await (db.select(
        db.events,
      )..where((e) => e.id.equals(id))).getSingleOrNull();
      if (row == null || row.deletedAt != null) {
        throw EventStateException('無法關聯不存在或已刪除的事件：$id');
      }
    }
    final (a, b) = _ordered(eventId, otherId);
    final existing = await _findLink(a, b);
    if (existing != null) return;
    final stamp = await ctx.stampForNew();
    await db
        .into(db.eventLinks)
        .insert(
          EventLinksCompanion.insert(
            eventAId: a,
            eventBId: b,
            layer: stamp.layerCode,
            authorId: stamp.authorId,
            createdAt: stamp.createdAt,
            archiveSessionId: Value(stamp.archiveSessionId),
          ),
        );
  });

  /// 一次關聯多個事件（企劃書 4.1：輸入時可一次勾選多個）。
  Future<void> linkAll(String eventId, Iterable<String> otherIds) async {
    for (final other in otherIds) {
      await link(eventId, other);
    }
  }

  Future<void> unlink(String eventId, String otherId) =>
      db.transaction(() async {
        final (a, b) = _ordered(eventId, otherId);
        final row = await _findLink(a, b);
        if (row == null) return;
        await ctx.ensureCanModify(row.layer);
        await (db.delete(
          db.eventLinks,
        )..where((l) => l.eventAId.equals(a) & l.eventBId.equals(b))).go();
      });

  /// 與某事件關聯的所有事件（從任一端查看都看得到），排除已刪除事件。
  Future<List<Event>> related(String eventId) async {
    final links =
        await (db.select(db.eventLinks)..where(
              (l) => l.eventAId.equals(eventId) | l.eventBId.equals(eventId),
            ))
            .get();
    final ids = [
      for (final l in links) l.eventAId == eventId ? l.eventBId : l.eventAId,
    ];
    if (ids.isEmpty) return const [];
    return (db.select(db.events)
          ..where((e) => e.id.isIn(ids) & e.deletedAt.isNull())
          ..orderBy([(e) => OrderingTerm.asc(e.id)]))
        .get();
  }

  Future<EventLink?> _findLink(String a, String b) =>
      (db.select(db.eventLinks)
            ..where((l) => l.eventAId.equals(a) & l.eventBId.equals(b)))
          .getSingleOrNull();
}
