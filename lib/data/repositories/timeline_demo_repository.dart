import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../../core/time/sort_range.dart';
import '../../core/time/time_value.dart';
import '../db/app_database.dart';
import 'event_repository.dart';
import 'repository_context.dart';

/// 僅供 debug 版使用；追加資料，不刪除任何既有生命紀錄。
class TimelineDemoRepository {
  TimelineDemoRepository(this.ctx);
  final RepositoryContext ctx;

  Future<void> generate(
    int count, {
    required String Function(int) title,
    required String category,
  }) async {
    if (!kDebugMode) throw StateError('假資料工具只在 debug 版本可用');
    if (count != 1000 && count != 5000) {
      throw ArgumentError.value(count, 'count');
    }
    await ctx.db.transaction(() async {
      final stamp = await ctx.stampForNew();
      final firstYear = DateTime.now().year - 49;
      final times = <String, TimeValue>{};
      final ids = <String>[];
      for (var i = 0; i < count; i++) {
        final id = ctx.newId();
        ids.add(id);
        final year = firstYear + i % 50;
        times[id] = switch ((i ~/ 50) % 10) {
          0 => DayTime(year, i % 12 + 1, i % 28 + 1),
          1 => MonthTime(year, i % 12 + 1),
          2 => QuarterTime(year, i % 4 + 1),
          3 => HalfYearTime(year, i % 2 + 1),
          4 => YearTime(year),
          5 => ApproxYearTime(year),
          6 => RangeTime(YearTime(year), YearTime(year + 2)),
          7 => RelativeTime(ids[i - 50], RelativeRelation.after),
          8 => AgeEstimateTime(i % 80),
          _ => const UnknownTime(),
        };
      }
      final subject = await (ctx.db.select(
        ctx.db.subjects,
      )..where((row) => row.id.equals(ctx.subjectId))).getSingle();
      final birth = subject.birthDate == null
          ? null
          : decodeTime(subject.birthDate!);
      final context = DbSortContext(
        times,
        birth is CalendarTime ? birth : null,
      );
      final now = ctx.now();
      final rows = <EventsCompanion>[];
      final changes = <ChangeHistoryCompanion>[];
      for (var i = 0; i < ids.length; i++) {
        final id = ids[i];
        final time = times[id]!;
        final resolution = SortRangeResolver.resolve(time, context, selfId: id);
        final range = resolution is SortResolved ? resolution.range : null;
        rows.add(
          EventsCompanion.insert(
            id: id,
            subjectId: ctx.subjectId,
            title: title(i + 1),
            category: Value(category),
            timePayload: encodeTime(time),
            sortStart: Value(range?.start.toIso()),
            sortEnd: Value(range?.end.toIso()),
            layer: stamp.layerCode,
            authorId: stamp.authorId,
            archiveSessionId: Value(stamp.archiveSessionId),
            createdAt: now.add(Duration(microseconds: i)),
            updatedAt: now,
          ),
        );
        changes.add(
          ChangeHistoryCompanion.insert(
            entityId: id,
            operation: ChangeOperation.create,
            authorId: ctx.actingAuthorId,
            timestamp: now,
          ),
        );
      }
      await ctx.db.batch((batch) {
        batch.insertAll(ctx.db.events, rows);
        batch.insertAll(ctx.db.changeHistory, changes);
      });
    });
  }
}
