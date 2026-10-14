import 'package:drift/drift.dart';

import '../../core/time/calendar_date.dart';
import '../../core/time/sort_range.dart';
import '../../core/time/time_value.dart';
import '../../core/time/timeline_sort.dart';
import '../db/app_database.dart';
import 'event_repository.dart';
import 'repository_context.dart';

/// 年份索引只傳回筆數，不將所有事件載入記憶體。
class TimelineYearCount {
  const TimelineYearCount(this.year, this.count);
  final int? year;
  final int count;
}

/// 一個年份及其相對時間所需的參照標題。
class TimelineYearData {
  const TimelineYearData(
    this.items,
    this.referenceTitles, [
    this.previews = const {},
    this.deletedReferenceIds = const {},
  ]);
  final List<TimelineItem<Event>> items;
  final Map<String, String> referenceTitles;
  final Map<String, TimelinePreview> previews;
  final Set<String> deletedReferenceIds;
}

class TimelinePreview {
  const TimelinePreview({
    this.summary = '',
    this.attachmentCount = 0,
    this.imagePath,
    this.imageLabel,
  });
  final String summary;
  final int attachmentCount;
  final String? imagePath;
  final String? imageLabel;
}

/// 每個欄位選一個條件；不同欄位必須同時符合。
class TimelineFilter {
  const TimelineFilter({
    this.category,
    this.lifePeriodId,
    this.tagId,
    this.personId,
    this.placeId,
    this.layer,
  });
  final String? category;
  final String? lifePeriodId;
  final String? tagId;
  final String? personId;
  final String? placeId;
  final String? layer;
  bool get isActive => [
    category,
    lifePeriodId,
    tagId,
    personId,
    placeId,
    layer,
  ].any((value) => value != null);
}

class TimelineFilterOption {
  const TimelineFilterOption(this.id, this.label);
  final String id;
  final String label;
}

class TimelineFilterOptions {
  const TimelineFilterOptions({
    required this.categories,
    required this.lifePeriods,
    required this.tags,
    required this.people,
    required this.places,
  });
  final List<TimelineFilterOption> categories;
  final List<TimelineFilterOption> lifePeriods;
  final List<TimelineFilterOption> tags;
  final List<TimelineFilterOption> people;
  final List<TimelineFilterOption> places;
}

/// 時間軸專用的唯讀查詢；事件排序仍由唯一的 [TimelineSort] 負責。
class TimelineRepository {
  TimelineRepository(this.ctx);
  final RepositoryContext ctx;
  AppDatabase get db => ctx.db;

  (String, List<Variable>) _conditions(TimelineFilter filter) {
    final clauses = <String>['subject_id = ?', 'deleted_at IS NULL'];
    final variables = <Variable>[Variable.withString(ctx.subjectId)];
    if (filter.isActive && !ctx.canReadPrivate) {
      clauses.add("privacy != 'private'");
    }
    void add(String clause, String? value) {
      if (value == null) return;
      clauses.add(clause);
      variables.add(Variable.withString(value));
    }

    add('category = ?', filter.category);
    add('place_id = ?', filter.placeId);
    add('layer = ?', filter.layer);
    add(
      'EXISTS (SELECT 1 FROM event_life_periods r '
      'WHERE r.event_id = events.event_id AND r.life_period_id = ?)',
      filter.lifePeriodId,
    );
    add(
      'EXISTS (SELECT 1 FROM event_tags r '
      'WHERE r.event_id = events.event_id AND r.tag_id = ?)',
      filter.tagId,
    );
    add(
      'EXISTS (SELECT 1 FROM event_people r '
      'WHERE r.event_id = events.event_id AND r.person_id = ?)',
      filter.personId,
    );
    return (clauses.join(' AND '), variables);
  }

  Stream<List<TimelineYearCount>> watchYears({
    TimelineFilter filter = const TimelineFilter(),
  }) {
    final (where, variables) = _conditions(filter);
    return db
        .customSelect(
          'SELECT CAST(substr(sort_start, 1, 4) AS INTEGER) AS year, '
          'count(*) AS amount FROM events '
          'WHERE $where GROUP BY year',
          variables: variables,
          readsFrom: {
            db.events,
            db.eventLifePeriods,
            db.eventTags,
            db.eventPeople,
          },
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              TimelineYearCount(
                row.readNullable<int>('year'),
                row.read<int>('amount'),
              ),
          ],
        );
  }

  Future<TimelineFilterOptions> filterOptions() async {
    Future<List<TimelineFilterOption>> options(String sql) => db
        .customSelect(sql, variables: [Variable.withString(ctx.subjectId)])
        .get()
        .then(
          (rows) => [
            for (final row in rows)
              TimelineFilterOption(
                row.read<String>('id'),
                row.read<String>('label'),
              ),
          ],
        );
    final active =
        'subject_id = ? AND deleted_at IS NULL '
        "${ctx.canReadPrivate ? '' : "AND privacy != 'private'"}";
    return TimelineFilterOptions(
      categories: await options(
        'SELECT DISTINCT category AS id, category AS label '
        'FROM events WHERE $active AND category IS NOT NULL',
      ),
      lifePeriods: await options(
        'SELECT life_period_id AS id, coalesce(organization, role, type) AS label '
        'FROM life_periods WHERE subject_id = ?',
      ),
      tags: await options(
        'SELECT DISTINCT t.tag_id AS id, t.label FROM tags t '
        'JOIN event_tags r ON r.tag_id = t.tag_id JOIN events e ON e.event_id = r.event_id '
        'WHERE e.$active',
      ),
      people: await options(
        'SELECT DISTINCT p.person_id AS id, p.display_name AS label FROM people p '
        'JOIN event_people r ON r.person_id = p.person_id JOIN events e ON e.event_id = r.event_id '
        'WHERE e.$active',
      ),
      places: await options(
        'SELECT DISTINCT p.place_id AS id, coalesce(p.name, '
        "CAST(p.latitude AS TEXT) || ', ' || CAST(p.longitude AS TEXT)) AS label "
        'FROM places p JOIN events e ON e.place_id = p.place_id WHERE e.$active',
      ),
    );
  }

  /// 範圍條件使用 sort_start 索引；跨年事件仍歸於起點年份。
  Stream<TimelineYearData> watchYear(
    int? year, {
    TimelineFilter filter = const TimelineFilter(),
    bool includePreviews = true,
  }) {
    if (year != null && (year < 1 || year > 9999)) {
      throw ArgumentError.value(year, 'year');
    }
    final condition = year == null
        ? 'sort_start IS NULL'
        : 'sort_start >= ? AND sort_start < ?';
    final (where, filterVariables) = _conditions(filter);
    final variables = <Variable>[
      ...filterVariables,
      if (year != null) ...[
        Variable.withString('${year.toString().padLeft(4, '0')}-01-01'),
        Variable.withString(
          year == 9999
              ? '9999-12-32'
              : '${(year + 1).toString().padLeft(4, '0')}-01-01',
        ),
      ],
    ];
    return db
        .customSelect(
          'SELECT * FROM events WHERE $where AND $condition',
          variables: variables,
          // 年外參照與主角生日變動也必須重新換算。
          readsFrom: {
            db.events,
            db.subjects,
            if (includePreviews) ...[
              db.eventSections,
              db.attachments,
              db.blobs,
            ],
            db.eventLifePeriods,
            db.eventTags,
            db.eventPeople,
          },
        )
        .watch()
        .asyncMap((rows) async {
          final events = rows.map((row) => db.events.map(row.data)).toList();
          final byId = {for (final event in events) event.id: event};
          final times = {
            for (final event in events) event.id: decodeTime(event.timePayload),
          };
          var pending = times.values
              .whereType<RelativeTime>()
              .map((time) => time.eventId)
              .toSet();
          final visited = byId.keys.toSet();
          while (pending.isNotEmpty) {
            final ids = pending.difference(visited);
            if (ids.isEmpty) break;
            visited.addAll(ids);
            // 分批避免 SQLite 綁定參數上限；只讀取必要的參照鏈。
            final idList = ids.toList();
            pending = {};
            for (var offset = 0; offset < idList.length; offset += 400) {
              final batch = idList.skip(offset).take(400);
              final references =
                  await (db.select(db.events)..where(
                        (event) =>
                            event.subjectId.equals(ctx.subjectId) &
                            event.id.isIn(batch),
                      ))
                      .get();
              for (final event in references) {
                byId[event.id] = event;
                final time = decodeTime(event.timePayload);
                times[event.id] = time;
                if (time is RelativeTime) pending.add(time.eventId);
              }
            }
          }
          // 只有年齡推估（包括年外參照鏈）需要主角生日。
          TimeValue? birth;
          if (times.values.any((time) => time is AgeEstimateTime)) {
            final subject =
                await (db.select(db.subjects)
                      ..where((subject) => subject.id.equals(ctx.subjectId)))
                    .getSingle();
            birth = subject.birthDate == null
                ? null
                : decodeTime(subject.birthDate!);
          }
          final context = DbSortContext(
            times,
            birth is CalendarTime ? birth : null,
          );
          final previews = <String, TimelinePreview>{};
          // 精簡清單不顯示摘要或附件，不查詢也不監聽這些資料。
          for (
            var offset = 0;
            includePreviews && offset < events.length;
            offset += 400
          ) {
            final ids = events
                .skip(offset)
                .take(400)
                .map((event) => event.id)
                .toList();
            final marks = List.filled(ids.length, '?').join(',');
            final previewRows = await db
                .customSelect(
                  'SELECT e.event_id AS id, '
                  '(SELECT substr(s.content_md, 1, 280) FROM event_sections s '
                  'WHERE s.event_id = e.event_id AND trim(s.content_md) != \'\' '
                  'ORDER BY s.position, s.event_section_id LIMIT 1) AS summary, '
                  '(SELECT count(*) FROM attachments a WHERE a.event_id = e.event_id) AS amount, '
                  '(SELECT b.path FROM attachments a JOIN blobs b ON b.blob_id = a.blob_id '
                  'WHERE a.event_id = e.event_id AND b.media_type LIKE \'image/%\' '
                  'ORDER BY a.attachment_id LIMIT 1) AS image_path, '
                  '(SELECT a.original_filename FROM attachments a JOIN blobs b ON b.blob_id = a.blob_id '
                  'WHERE a.event_id = e.event_id AND b.media_type LIKE \'image/%\' '
                  'ORDER BY a.attachment_id LIMIT 1) AS image_label '
                  'FROM events e WHERE e.event_id IN ($marks)',
                  variables: ids.map(Variable.withString).toList(),
                )
                .get();
            for (final row in previewRows) {
              previews[row.read<String>('id')] = TimelinePreview(
                summary: row.readNullable<String>('summary') ?? '',
                attachmentCount: row.read<int>('amount'),
                imagePath: row.readNullable<String>('image_path'),
                imageLabel: row.readNullable<String>('image_label'),
              );
            }
          }
          return TimelineYearData(
            [
              for (final event in events)
                TimelineItem(
                  id: event.id,
                  time: times[event.id]!,
                  resolution: SortRangeResolver.resolve(
                    times[event.id]!,
                    context,
                    selfId: event.id,
                    previous: event.sortStart == null || event.sortEnd == null
                        ? null
                        : SortResolved(
                            SortRange(
                              CalendarDate.parse(event.sortStart!),
                              CalendarDate.parse(event.sortEnd!),
                            ),
                            TimeCertainty.exact,
                          ),
                  ),
                  manualOrder: event.manualOrder,
                  recordedAt: event.createdAt,
                  data: event,
                ),
            ],
            {for (final event in byId.values) event.id: event.title},
            previews,
            {
              for (final event in byId.values)
                if (event.deletedAt != null) event.id,
            },
          );
        });
  }
}
