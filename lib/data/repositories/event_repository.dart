import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/time/calendar_date.dart';
import '../../core/time/sort_range.dart';
import '../../core/time/time_value.dart';
import '../../core/time/timeline_sort.dart';
import '../db/app_database.dart';
import '../db/tables.dart';
import 'repository_context.dart';

/// 新增事件的輸入。層級由資料存取層決定，呼叫端不得指定。
class EventInput {
  const EventInput({
    required this.title,
    required this.time,
    this.category,
    this.placeId,
    this.privacy = Privacy.normal,
    this.manualOrder = 0,
  });

  final String title;
  final TimeValue time;
  final String? category;
  final String? placeId;
  final String privacy;
  final int manualOrder;
}

/// 修改事件的欄位；未提供的欄位維持不變。不含 `layer`（不可變更）。
class EventChanges {
  const EventChanges({
    this.title = const Value.absent(),
    this.time = const Value.absent(),
    this.category = const Value.absent(),
    this.placeId = const Value.absent(),
    this.privacy = const Value.absent(),
    this.manualOrder = const Value.absent(),
  });

  final Value<String> title;
  final Value<TimeValue> time;
  final Value<String?> category;
  final Value<String?> placeId;
  final Value<String> privacy;
  final Value<int> manualOrder;
}

/// 相對事件形成循環參照（企劃書 5.1：不得形成循環參照）。
class CircularTimeReferenceException implements Exception {
  const CircularTimeReferenceException(this.chain);

  final List<String> chain;

  @override
  String toString() => 'CircularTimeReferenceException(${chain.join(' → ')})';
}

/// 事件狀態不允許此操作（例如復原未刪除的事件）。
class EventStateException implements Exception {
  const EventStateException(this.message);

  final String message;

  @override
  String toString() => 'EventStateException($message)';
}

/// 由資料庫內容提供排序換算所需的外部資訊。
class DbSortContext implements SortContext {
  DbSortContext(this._times, this._birth);

  final Map<String, TimeValue> _times;
  final CalendarTime? _birth;

  @override
  TimeValue? timeOfEvent(String eventId) => _times[eventId];

  @override
  CalendarTime? subjectBirth() => _birth;
}

TimeValue decodeTime(String payload) =>
    TimeValue.fromJson(jsonDecode(payload) as Map<String, Object?>);

String encodeTime(TimeValue time) => jsonEncode(time.toJson());

/// 人生節點的資料存取（企劃書 4.1、第 5 節、9.3）。
class EventRepository {
  EventRepository(this.ctx);

  final RepositoryContext ctx;

  AppDatabase get db => ctx.db;

  // ---- 查詢 ----

  Future<Event?> find(String id) =>
      (db.select(db.events)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<Event> _get(String id) async {
    final row = await find(id);
    if (row == null) throw EventStateException('事件不存在：$id');
    return row;
  }

  /// 時間軸資料：排除已刪除事件，回傳可直接交給 [TimelineSort] 的項目。
  ///
  /// 相對事件參照已刪除（未永久移除）的事件時，仍沿用其時間排序。
  Stream<List<TimelineItem<Event>>> watchTimeline() {
    final query = db.select(db.events)
      ..where((e) => e.subjectId.equals(ctx.subjectId));
    return query.watch().asyncMap((rows) async {
      final sortContext = DbSortContext({
        for (final r in rows) r.id: decodeTime(r.timePayload),
      }, await _birth());
      return [
        for (final r in rows)
          if (r.deletedAt == null) _toItem(r, sortContext),
      ];
    });
  }

  TimelineItem<Event> _toItem(Event row, DbSortContext sortContext) {
    final time = sortContext.timeOfEvent(row.id)!;
    return TimelineItem(
      id: row.id,
      time: time,
      resolution: SortRangeResolver.resolve(
        time,
        sortContext,
        selfId: row.id,
        previous: _storedRange(row),
      ),
      manualOrder: row.manualOrder,
      recordedAt: row.createdAt,
      data: row,
    );
  }

  /// 「最近刪除」：已軟刪除、尚未永久刪除的事件。
  Future<List<Event>> listRecentlyDeleted() =>
      (db.select(db.events)
            ..where(
              (e) =>
                  e.subjectId.equals(ctx.subjectId) &
                  e.deletedAt.isNotNull() &
                  e.purgedAt.isNull(),
            )
            ..orderBy([(e) => OrderingTerm.desc(e.deletedAt)]))
          .get();

  // ---- 新增與修改 ----

  Future<String> create(EventInput input) => db.transaction(() async {
    final stamp = await ctx.stampForNew();
    final id = ctx.newId();
    final sortContext = await _loadSortContext(override: {id: input.time});
    final range = _resolveForWrite(id, input.time, sortContext, null);
    final now = ctx.now();
    await db
        .into(db.events)
        .insert(
          EventsCompanion.insert(
            id: id,
            subjectId: ctx.subjectId,
            title: input.title.trim(),
            category: Value(input.category),
            timePayload: encodeTime(input.time),
            sortStart: Value(range?.start.toIso()),
            sortEnd: Value(range?.end.toIso()),
            manualOrder: Value(input.manualOrder),
            placeId: Value(input.placeId),
            privacy: Value(input.privacy),
            updatedAt: now,
            layer: stamp.layerCode,
            authorId: stamp.authorId,
            createdAt: stamp.createdAt,
            archiveSessionId: Value(stamp.archiveSessionId),
          ),
        );
    await ctx.recordChange(id, ChangeOperation.create);
    return id;
  });

  Future<void> update(String id, EventChanges changes) =>
      db.transaction(() async {
        final row = await _get(id);
        await ctx.ensureCanModify(row.layer);
        var companion = EventsCompanion(
          title: changes.title.present
              ? Value(changes.title.value.trim())
              : const Value.absent(),
          category: changes.category,
          placeId: changes.placeId,
          privacy: changes.privacy,
          manualOrder: changes.manualOrder,
          updatedAt: Value(ctx.now()),
        );
        DbSortContext? sortContext;
        if (changes.time.present) {
          final time = changes.time.value;
          sortContext = await _loadSortContext(override: {id: time});
          final range = _resolveForWrite(
            id,
            time,
            sortContext,
            _storedRange(row),
          );
          companion = companion.copyWith(
            timePayload: Value(encodeTime(time)),
            sortStart: Value(range?.start.toIso()),
            sortEnd: Value(range?.end.toIso()),
          );
        }
        await (db.update(
          db.events,
        )..where((e) => e.id.equals(id))).write(companion);
        if (sortContext != null) {
          await _recomputeDependents(id, sortContext);
        }
        await ctx.recordChange(id, ChangeOperation.update);
      });

  /// 換算排序區間；形成循環參照時拒絕寫入。
  SortRange? _resolveForWrite(
    String id,
    TimeValue time,
    DbSortContext sortContext,
    SortResolved? previous,
  ) {
    final result = SortRangeResolver.resolve(
      time,
      sortContext,
      selfId: id,
      previous: previous,
    );
    return switch (result) {
      SortResolved(:final range) => range,
      SortReferenceMissing(:final lastKnown) => lastKnown?.range,
      SortUnsortable() => null,
      SortCircularReference(:final chain) =>
        throw CircularTimeReferenceException(chain),
    };
  }

  /// 參照事件的時間改變時，重算所有（直接或間接）參照它的相對事件（企劃書 5.1）。
  ///
  /// `sort_start`／`sort_end` 是衍生欄位，重算不視為修改內容，不受層級權限限制。
  Future<void> _recomputeDependents(
    String changedId,
    DbSortContext sortContext,
  ) async {
    final queue = [changedId];
    final visited = <String>{changedId};
    while (queue.isNotEmpty) {
      final referencedId = queue.removeAt(0);
      final dependents = await db
          .customSelect(
            'SELECT * FROM events '
            "WHERE json_extract(time_payload, '\$.type') = 'relative' "
            "AND json_extract(time_payload, '\$.event_id') = ?",
            variables: [Variable.withString(referencedId)],
            readsFrom: {db.events},
          )
          .map((r) => db.events.map(r.data))
          .get();
      for (final dependent in dependents) {
        if (!visited.add(dependent.id)) continue;
        final range = _resolveForWrite(
          dependent.id,
          decodeTime(dependent.timePayload),
          sortContext,
          _storedRange(dependent),
        );
        await (db.update(
          db.events,
        )..where((e) => e.id.equals(dependent.id))).write(
          EventsCompanion(
            sortStart: Value(range?.start.toIso()),
            sortEnd: Value(range?.end.toIso()),
          ),
        );
        queue.add(dependent.id);
      }
    }
  }

  // ---- 軟刪除（企劃書 9.3） ----

  /// 刪除事件：只記錄刪除時間，移入「最近刪除」。
  Future<void> softDelete(String id) => db.transaction(() async {
    final row = await _get(id);
    if (row.deletedAt != null) return;
    await ctx.ensureCanModify(row.layer);
    await (db.update(db.events)..where((e) => e.id.equals(id))).write(
      EventsCompanion(deletedAt: Value(ctx.now())),
    );
    await ctx.recordChange(id, ChangeOperation.delete);
  });

  /// 從「最近刪除」復原。
  Future<void> restore(String id) => db.transaction(() async {
    final row = await _get(id);
    if (row.deletedAt == null) return;
    if (row.purgedAt != null) {
      throw const EventStateException('已永久刪除的事件無法復原');
    }
    await ctx.ensureCanModify(row.layer);
    await (db.update(db.events)..where((e) => e.id.equals(id))).write(
      const EventsCompanion(deletedAt: Value(null)),
    );
    await ctx.recordChange(id, ChangeOperation.restore);
  });

  /// 永久刪除：只能對已軟刪除的事件執行。
  ///
  /// 仍有後續追憶附掛時，只移除原始生命紀錄層內容並保留標題與時間，
  /// 讓追憶內容仍有可依附的對象；否則完整移除事件。
  Future<bool> purge(String id) => db.transaction(() async {
    final row = await _get(id);
    if (row.deletedAt == null) {
      throw const EventStateException('只能永久刪除已移入「最近刪除」的事件');
    }
    if (row.purgedAt != null) return true;
    await ctx.ensureCanModify(row.layer);

    final keepsTitle = await _hasRemembranceContent(id);
    await _deleteOriginalChildren(id);
    if (keepsTitle) {
      await (db.update(db.events)..where((e) => e.id.equals(id))).write(
        EventsCompanion(
          purgedAt: Value(ctx.now()),
          category: const Value(null),
          placeId: const Value(null),
        ),
      );
    } else {
      await (db.delete(db.events)..where((e) => e.id.equals(id))).go();
    }
    await ctx.recordChange(id, ChangeOperation.purge);
    return keepsTitle;
  });

  /// 事件底下是否有任何後續追憶層內容。
  Future<bool> _hasRemembranceContent(String eventId) async {
    const r = Layer.remembrance;
    final row = await db
        .customSelect(
          'SELECT ('
          'EXISTS (SELECT 1 FROM event_sections WHERE event_id = ?1 AND layer = ?2) OR '
          'EXISTS (SELECT 1 FROM attachments WHERE event_id = ?1 AND layer = ?2) OR '
          'EXISTS (SELECT 1 FROM reflections WHERE event_id = ?1 AND layer = ?2) OR '
          'EXISTS (SELECT 1 FROM event_tags WHERE event_id = ?1 AND layer = ?2) OR '
          'EXISTS (SELECT 1 FROM event_people WHERE event_id = ?1 AND layer = ?2) OR '
          'EXISTS (SELECT 1 FROM event_links '
          'WHERE (event_a_id = ?1 OR event_b_id = ?1) AND layer = ?2)'
          ') AS has_remembrance',
          variables: [Variable.withString(eventId), Variable.withString(r)],
        )
        .getSingle();
    return row.read<bool>('has_remembrance');
  }

  Future<void> _deleteOriginalChildren(String eventId) async {
    const o = Layer.original;
    for (final table in [
      'event_sections',
      'attachments',
      'reflections',
      'event_tags',
      'event_people',
    ]) {
      await db.customStatement(
        'DELETE FROM $table WHERE event_id = ? AND layer = ?',
        [eventId, o],
      );
    }
    await db.customStatement(
      'DELETE FROM event_links WHERE (event_a_id = ? OR event_b_id = ?) '
      'AND layer = ?',
      [eventId, eventId, o],
    );
    await db.customStatement('DELETE FROM story_events WHERE event_id = ?', [
      eventId,
    ]);
  }

  // ---- 共用 ----

  Future<DbSortContext> _loadSortContext({
    Map<String, TimeValue> override = const {},
  }) async {
    final rows = await (db.select(
      db.events,
    )..where((e) => e.subjectId.equals(ctx.subjectId))).get();
    return DbSortContext({
      for (final r in rows) r.id: decodeTime(r.timePayload),
      ...override,
    }, await _birth());
  }

  Future<CalendarTime?> _birth() async {
    final subject = await (db.select(
      db.subjects,
    )..where((s) => s.id.equals(ctx.subjectId))).getSingle();
    final payload = subject.birthDate;
    if (payload == null) return null;
    final time = decodeTime(payload);
    return time is CalendarTime ? time : null;
  }

  static SortResolved? _storedRange(Event row) {
    final start = row.sortStart, end = row.sortEnd;
    if (start == null || end == null) return null;
    return SortResolved(
      SortRange(CalendarDate.parse(start), CalendarDate.parse(end)),
      TimeCertainty.exact,
    );
  }
}
