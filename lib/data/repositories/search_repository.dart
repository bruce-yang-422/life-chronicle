import 'package:drift/drift.dart';

import '../../core/text/search_tokens.dart';
import '../../core/time/timeline_sort.dart';
import '../../core/stories/theme_rule.dart';
import '../db/app_database.dart';
import 'event_repository.dart';
import 'repository_context.dart';

/// FTS5 搜尋所有事件內容；索引是可重建的衍生快取，不修改生命紀錄。
class SearchRepository {
  SearchRepository(this.ctx);
  final RepositoryContext ctx;
  Future<void> _indexWrites = Future.value();
  final _indexed = <String, String>{};
  bool _initialized = false;
  String get _entityType => 'event:${ctx.subjectId}';

  Stream<List<TimelineItem<Event>>> watch(
    String query, {
    int? fromYear,
    int? toYear,
    SortDirection direction = SortDirection.newestFirst,
  }) {
    if ((fromYear != null && (fromYear < 1 || fromYear > 9999)) ||
        (toYear != null && (toYear < 1 || toYear > 9999)) ||
        (fromYear != null && toYear != null && fromYear > toYear)) {
      throw ArgumentError('搜尋年份無效');
    }
    return ctx.db
        .customSelect(
          "SELECT e.event_id AS id, e.privacy AS privacy, e.title || char(10) || coalesce(e.category, '') || char(10) || "
          "coalesce(p.name, '') || char(10) || "
          "coalesce((SELECT group_concat(content_md, char(10)) FROM event_sections s WHERE s.event_id=e.event_id), '') || char(10) || "
          "coalesce((SELECT group_concat(content_md, char(10)) FROM reflections r WHERE r.event_id=e.event_id), '') || char(10) || "
          "coalesce((SELECT group_concat(p.display_name, char(10)) FROM people p JOIN event_people r ON p.person_id=r.person_id WHERE r.event_id=e.event_id), '') || char(10) || "
          "coalesce((SELECT group_concat(t.label, char(10)) FROM tags t JOIN event_tags r ON t.tag_id=r.tag_id WHERE r.event_id=e.event_id), '') || char(10) || "
          "coalesce((SELECT group_concat(original_filename, char(10)) FROM attachments a WHERE a.event_id=e.event_id), '') || char(10) || "
          "coalesce((SELECT group_concat(s.title, char(10)) FROM stories s JOIN story_events r ON s.story_id=r.story_id WHERE r.event_id=e.event_id), '') AS document "
          'FROM events e LEFT JOIN places p ON p.place_id=e.place_id '
          'WHERE e.subject_id=? AND e.deleted_at IS NULL '
          "${ctx.canReadPrivate ? '' : "AND e.privacy != 'private'"}",
          variables: [Variable.withString(ctx.subjectId)],
          readsFrom: {
            ctx.db.events,
            ctx.db.eventSections,
            ctx.db.reflections,
            ctx.db.places,
            ctx.db.people,
            ctx.db.eventPeople,
            ctx.db.tags,
            ctx.db.eventTags,
            ctx.db.attachments,
            ctx.db.stories,
            ctx.db.storyEvents,
            ctx.db.subjects,
          },
        )
        .watch()
        .asyncMap((rows) async {
          final rules = [
            for (final story in await ctx.db.select(ctx.db.stories).get())
              if (story.rulesJson != null)
                MapEntry(story.title, ThemeRule.decode(story.rulesJson!)),
          ];
          final tags = <String, Set<String>>{};
          if (rules.isNotEmpty) {
            for (final link in await ctx.db.select(ctx.db.eventTags).get()) {
              (tags[link.eventId] ??= {}).add(link.tagId);
            }
          }
          final documents = {
            for (final row in rows)
              row.read<String>('id'): SearchTokens.normalize(
                '${row.read<String>('document')}\n${row.read<String>('privacy') == 'private' ? '' : rules.where((e) => e.value.matches(tags[row.read<String>('id')] ?? {})).map((e) => e.key).join('\n')}',
              ),
          };
          final operation = _indexWrites.then((_) => _updateIndex(documents));
          _indexWrites = operation.catchError((Object error) {});
          await operation;
          final terms = SearchTokens.terms(query);
          Set<String> ids = documents.keys.toSet();
          if (terms.isNotEmpty) {
            final matches = await ctx.db
                .customSelect(
                  'SELECT entity_id FROM search_index WHERE entity_type=? AND search_index MATCH ?',
                  variables: [
                    Variable.withString(_entityType),
                    Variable.withString(SearchTokens.match(query)),
                  ],
                )
                .get();
            ids = matches
                .map((row) => row.read<String>('entity_id'))
                .where(
                  (id) =>
                      documents[id] != null &&
                      terms.every(documents[id]!.contains),
                )
                .toSet();
          }
          final items = await EventRepository(ctx).watchTimeline().first;
          return TimelineSort.sort(
            items.where((item) {
              if (!ids.contains(item.id)) return false;
              final range = item.effective?.range;
              if (fromYear != null &&
                  (range == null || range.end.year < fromYear)) {
                return false;
              }
              if (toYear != null &&
                  (range == null || range.start.year > toYear)) {
                return false;
              }
              return true;
            }),
            direction,
          );
        });
  }

  Future<void> _updateIndex(Map<String, String> documents) async {
    await ctx.db.transaction(() async {
      if (!_initialized) {
        await ctx.db.customStatement(
          'DELETE FROM search_index WHERE entity_type=?',
          [_entityType],
        );
      }
      final obsolete = _indexed.keys
          .where((id) => !documents.containsKey(id))
          .toList();
      for (final id in obsolete) {
        await ctx.db.customStatement(
          'DELETE FROM search_index WHERE entity_type=? AND entity_id=?',
          [_entityType, id],
        );
      }
      for (final entry in documents.entries) {
        if (_initialized && _indexed[entry.key] == entry.value) continue;
        await ctx.db.customStatement(
          'DELETE FROM search_index WHERE entity_type=? AND entity_id=?',
          [_entityType, entry.key],
        );
        await ctx.db.customStatement(
          'INSERT INTO search_index(entity_type, entity_id, content) VALUES(?,?,?)',
          [_entityType, entry.key, SearchTokens.of(entry.value).join(' ')],
        );
      }
    });
    _indexed
      ..clear()
      ..addAll(documents);
    _initialized = true;
  }
}
