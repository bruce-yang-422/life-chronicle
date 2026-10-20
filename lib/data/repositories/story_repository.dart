import 'package:drift/drift.dart';

import '../../core/policy/layer_policy.dart';
import '../../core/stories/theme_rule.dart';
import '../../core/time/timeline_sort.dart';
import '../db/app_database.dart';
import 'event_repository.dart';
import 'repository_context.dart';

class StorySummary {
  const StorySummary(this.story, this.eventCount, this.canModify);
  final Story story;
  final int eventCount;
  final bool canModify;
}

class StoryEntry {
  const StoryEntry(this.eventId, this.event);
  final String eventId;
  // 未驗證的私密事件不向畫面提供標題、時間或其他內容。
  final Event? event;
}

class StoryContent {
  const StoryContent(this.summary, this.entries);
  final StorySummary summary;
  final List<StoryEntry> entries;
}

/// 篇章僅儲存事件引用與順序，不複製或修改事件本體（§4.2、§10）。
class StoryRepository {
  StoryRepository(this.ctx);
  final RepositoryContext ctx;
  AppDatabase get db => ctx.db;

  Stream<void> _changes() => db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          db.stories,
          db.storyEvents,
          db.events,
          db.archiveSettings,
          db.tags,
          db.eventTags,
          db.subjects,
        },
      )
      .watch()
      .map((_) {});

  Future<Story?> _find(String id) =>
      (db.select(db.stories)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<List<StoryEvent>> _references(String id) =>
      (db.select(db.storyEvents)
            ..where((r) => r.storyId.equals(id))
            ..orderBy([(r) => OrderingTerm.asc(r.position)]))
          .get();

  Stream<List<StorySummary>> watch() => _changes().asyncMap((_) async {
    final stories =
        await (db.select(db.stories)..orderBy([
              (s) => OrderingTerm.desc(s.createdAt),
              (s) => OrderingTerm.desc(s.id),
            ]))
            .get();
    return [for (final story in stories) (await load(story.id))!.summary];
  });

  Stream<List<Tag>> watchTags() =>
      (db.select(db.tags)..orderBy([(t) => OrderingTerm.asc(t.label)])).watch();

  Stream<StoryContent?> watchContent(
    String id, {
    SortDirection direction = SortDirection.newestFirst,
  }) => _changes().asyncMap((_) => load(id, direction: direction));

  Future<StoryContent?> load(
    String id, {
    SortDirection direction = SortDirection.newestFirst,
  }) async {
    final story = await _find(id);
    if (story == null) return null;
    final entries = <StoryEntry>[];
    if (story.rulesJson != null) {
      final rule = ThemeRule.decode(story.rulesJson!);
      final tags = <String, Set<String>>{};
      for (final link in await db.select(db.eventTags).get()) {
        (tags[link.eventId] ??= {}).add(link.tagId);
      }
      final items = await EventRepository(ctx).watchTimeline().first;
      entries.addAll(
        TimelineSort.sort(
          items.where(
            (item) =>
                item.data.privacy != 'private' &&
                rule.matches(tags[item.id] ?? {}),
          ),
          direction,
        ).map((item) => StoryEntry(item.id, item.data)),
      );
    } else {
      final references = await _references(id);
      for (final reference in references) {
        final event =
            await (db.select(db.events)..where(
                  (e) =>
                      e.id.equals(reference.eventId) &
                      e.subjectId.equals(ctx.subjectId),
                ))
                .getSingleOrNull();
        entries.add(
          StoryEntry(
            reference.eventId,
            event?.privacy == 'private' && !ctx.canReadPrivate ? null : event,
          ),
        );
      }
    }
    return StoryContent(
      StorySummary(
        story,
        entries.length,
        LayerPolicy.canModify(
          layerFromCode(story.layer),
          await ctx.archiveState(),
        ),
      ),
      entries,
    );
  }

  Future<String> save({
    String? id,
    required String title,
    List<String> eventIds = const [],
    ThemeRule? rule,
  }) => db.transaction(() async {
    if (title.trim().isEmpty || eventIds.toSet().length != eventIds.length) {
      throw ArgumentError('篇章需要名稱，且同一事件不能重複加入');
    }
    final existing = id == null ? null : await _find(id);
    if (id != null && existing == null) {
      throw const EventStateException('篇章不存在');
    }
    if (existing != null) await ctx.ensureCanModify(existing.layer);
    if (rule != null) {
      if (eventIds.isNotEmpty) throw ArgumentError('智慧主題不接受手動引用');
      final ids = (await db.select(db.tags).get()).map((t) => t.id).toSet();
      if (!ids.containsAll({...rule.include, ...rule.exclude})) {
        throw ArgumentError('主題使用的標籤已不存在');
      }
    }
    final previous = existing == null
        ? <String>{}
        : (await _references(existing.id)).map((r) => r.eventId).toSet();
    for (final eventId in eventIds) {
      final event =
          await (db.select(db.events)..where(
                (e) => e.id.equals(eventId) & e.subjectId.equals(ctx.subjectId),
              ))
              .getSingleOrNull();
      if (event == null ||
          (event.deletedAt != null && !previous.contains(eventId))) {
        throw const EventStateException('事件不存在或已刪除，無法加入篇章');
      }
      if (!previous.contains(eventId)) ctx.ensureCanReadPrivate(event.privacy);
    }
    final storyId = id ?? ctx.newId();
    if (existing == null) {
      final stamp = await ctx.stampForNew();
      await db
          .into(db.stories)
          .insert(
            StoriesCompanion.insert(
              id: storyId,
              title: title.trim(),
              rulesJson: Value(rule?.encode()),
              layer: stamp.layerCode,
              authorId: stamp.authorId,
              createdAt: stamp.createdAt,
              archiveSessionId: Value(stamp.archiveSessionId),
            ),
          );
    } else {
      await (db.update(db.stories)..where((s) => s.id.equals(storyId))).write(
        StoriesCompanion(
          title: Value(title.trim()),
          rulesJson: Value(rule?.encode()),
        ),
      );
    }
    await (db.delete(
      db.storyEvents,
    )..where((r) => r.storyId.equals(storyId))).go();
    for (var i = 0; i < eventIds.length; i++) {
      await db
          .into(db.storyEvents)
          .insert(
            StoryEventsCompanion.insert(
              storyId: storyId,
              eventId: eventIds[i],
              position: i,
            ),
          );
    }
    await ctx.recordChange(
      storyId,
      existing == null ? ChangeOperation.create : ChangeOperation.update,
    );
    return storyId;
  });

  Future<void> delete(String id) => db.transaction(() async {
    final story = await _find(id);
    if (story == null) throw const EventStateException('篇章不存在');
    await ctx.ensureCanModify(story.layer);
    await (db.delete(db.storyEvents)..where((r) => r.storyId.equals(id))).go();
    await (db.delete(db.stories)..where((s) => s.id.equals(id))).go();
    await ctx.recordChange(id, ChangeOperation.delete);
  });
}
