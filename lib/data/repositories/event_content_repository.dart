import 'package:drift/drift.dart';

import '../../core/editor/event_draft.dart';
import '../../core/policy/layer_policy.dart';
import '../../core/time/timeline_sort.dart';
import '../db/app_database.dart';
import 'event_repository.dart';
import 'event_relations_repository.dart';
import 'person_repository.dart';
import 'place_repository.dart';
import 'repository_context.dart';

class EventContent {
  EventContent({
    required this.event,
    required this.sections,
    required this.reflections,
    required this.authors,
    required this.related,
    required this.people,
    required this.tags,
    this.place,
  });
  final Event event;
  final List<EventSection> sections;
  final List<Reflection> reflections;
  final Map<String, String> authors;
  final List<Event> related;
  final List<Person> people;
  final List<Tag> tags;
  final Place? place;
  EventDraft toDraft() => EventDraft(
    eventId: event.id,
    title: event.title,
    time: decodeTime(event.timePayload),
    category: event.category ?? '',
    place: place?.name ?? '',
    latitude: place?.latitude,
    longitude: place?.longitude,
    radiusM: place?.radiusM,
    privacy: event.privacy,
    sections: sections.isEmpty
        ? [DraftSection()]
        : [
            for (final section in sections)
              DraftSection(
                id: section.id,
                title: section.title ?? '',
                content: section.contentMd,
                suggestionKey: section.suggestionKey,
              ),
          ],
    people: people.map((person) => person.displayName).toList(),
    tags: tags.map((tag) => tag.label).toList(),
    relatedIds: related.map((event) => event.id).toList(),
  );
}

/// 編輯與詳情的唯一內容寫入入口：一筆事件及其段落／關聯以單一交易保存。
class EventContentRepository {
  EventContentRepository(this.ctx);
  final RepositoryContext ctx;
  AppDatabase get db => ctx.db;
  String reserveCreationId() => ctx.newId();
  Future<EventContent?> load(
    String id, {
    SortDirection direction = SortDirection.newestFirst,
    bool includeDeleted = false,
  }) async {
    final event = await EventRepository(ctx).find(id);
    if (event == null ||
        event.subjectId != ctx.subjectId ||
        (!includeDeleted && event.deletedAt != null)) {
      return null;
    }
    if (event.privacy == 'private' && !ctx.canReadPrivate) return null;
    final sections =
        await (db.select(db.eventSections)
              ..where((s) => s.eventId.equals(id))
              ..orderBy([
                (s) => OrderingTerm.asc(s.position),
                (s) => OrderingTerm.asc(s.id),
              ]))
            .get();
    final reflections =
        await (db.select(db.reflections)
              ..where((r) => r.eventId.equals(id))
              ..orderBy([
                (r) => OrderingTerm.asc(r.recordedAt),
                (r) => OrderingTerm.asc(r.id),
              ]))
            .get();
    final authors = await db.select(db.authors).get();
    final relations = EventRelationsRepository(ctx);
    final tags = await db
        .customSelect(
          'SELECT t.* FROM tags t JOIN event_tags r '
          'ON r.tag_id = t.tag_id WHERE r.event_id = ?',
          variables: [Variable.withString(id)],
        )
        .get();
    return EventContent(
      event: event,
      sections: sections,
      reflections: reflections,
      authors: {for (final author in authors) author.id: author.displayName},
      related: await relations.related(id, direction: direction),
      people: await relations.peopleOf(id),
      tags: tags.map((row) => db.tags.map(row.data)).toList(),
      place: event.placeId == null
          ? null
          : await PlaceRepository(ctx).find(event.placeId!),
    );
  }

  Stream<EventContent?> watch(
    String id, {
    SortDirection direction = SortDirection.newestFirst,
    bool includeDeleted = false,
  }) => db
      .customSelect(
        'SELECT event_id FROM events WHERE event_id = ?',
        variables: [Variable.withString(id)],
        readsFrom: {
          db.events,
          db.eventSections,
          db.reflections,
          db.authors,
          db.eventLinks,
          db.people,
          db.eventPeople,
          db.places,
          db.tags,
          db.eventTags,
        },
      )
      .watch()
      .asyncMap(
        (_) => load(id, direction: direction, includeDeleted: includeDeleted),
      );

  Future<String> save(EventDraft draft) => db.transaction(() async {
    if (draft.title.trim().isEmpty) throw ArgumentError('事件名稱不可空白');
    final events = EventRepository(ctx);
    if (draft.eventId == null && draft.creationId != null) {
      final committed = await events.find(draft.creationId!);
      if (committed != null) {
        if (committed.subjectId != ctx.subjectId ||
            committed.deletedAt != null) {
          throw const EventStateException('草稿對應的事件已刪除或不屬於此主角');
        }
        return committed.id;
      }
    }
    Event? existing;
    if (draft.eventId != null) {
      existing = await events.find(draft.eventId!);
      if (existing == null ||
          existing.subjectId != ctx.subjectId ||
          existing.deletedAt != null) {
        throw const EventStateException('事件不存在或已刪除');
      }
      ctx.ensureCanReadPrivate(existing.privacy);
    }
    final previousPlace = existing?.placeId == null
        ? null
        : await PlaceRepository(ctx).find(existing!.placeId!);
    final sameAnchor =
        previousPlace != null &&
        previousPlace.latitude == draft.latitude &&
        previousPlace.longitude == draft.longitude &&
        previousPlace.radiusM == draft.radiusM &&
        (previousPlace.name ?? '') == draft.place;
    final placeId = draft.latitude != null && draft.longitude != null
        ? sameAnchor
              ? previousPlace.id
              : await PlaceRepository(ctx).createAnchor(
                  latitude: draft.latitude!,
                  longitude: draft.longitude!,
                  radiusM: draft.radiusM,
                  name: draft.place,
                )
        : draft.place.trim().isEmpty
        ? null
        : await PlaceRepository(ctx).findOrCreateByName(draft.place);
    final id =
        existing?.id ??
        await events.create(
          EventInput(
            title: draft.title,
            time: draft.time,
            category: _optional(draft.category),
            placeId: placeId,
            privacy: draft.privacy,
          ),
          reservedId: draft.creationId,
        );
    if (existing != null) {
      final effectivePlace =
          draft.place.trim().isEmpty &&
              existing.placeId != null &&
              (await PlaceRepository(ctx).find(existing.placeId!))?.name == null
          ? existing.placeId
          : placeId;
      final headerChanged =
          existing.title != draft.title.trim() ||
          decodeTime(existing.timePayload) != draft.time ||
          existing.category != _optional(draft.category) ||
          existing.placeId != effectivePlace ||
          existing.privacy != draft.privacy;
      final canModifyParent = LayerPolicy.canModify(
        layerFromCode(existing.layer),
        await ctx.archiveState(),
      );
      // 原始事件唯讀時仍可追加後續追憶，但不重寫其標題、時間或修改時間。
      if (canModifyParent || headerChanged) {
        await events.update(
          id,
          EventChanges(
            title: Value(draft.title),
            time: decodeTime(existing.timePayload) == draft.time
                ? const Value.absent()
                : Value(draft.time),
            category: Value(_optional(draft.category)),
            // 純座標地點在未輸入文字時保留，GPS 編輯由 T17 處理。
            placeId: Value(effectivePlace),
            privacy: Value(draft.privacy),
          ),
        );
      }
    }
    final old = await (db.select(
      db.eventSections,
    )..where((s) => s.eventId.equals(id))).get();
    final retained = draft.sections
        .map((s) => s.id)
        .whereType<String>()
        .toSet();
    for (final section in old) {
      if (!retained.contains(section.id)) {
        await ctx.ensureCanModify(section.layer);
        await (db.delete(
          db.eventSections,
        )..where((s) => s.id.equals(section.id))).go();
        await ctx.recordChange(section.id, ChangeOperation.delete);
      }
    }
    for (var i = 0; i < draft.sections.length; i++) {
      final section = draft.sections[i];
      final prior = old.where((s) => s.id == section.id).firstOrNull;
      if (section.id != null && prior == null) {
        throw const EventStateException('段落不屬於此事件');
      }
      if (prior != null) {
        if (prior.title == _optional(section.title) &&
            prior.contentMd == section.content &&
            prior.position == i &&
            prior.suggestionKey == section.suggestionKey) {
          continue;
        }
        await ctx.ensureCanModify(prior.layer);
        await (db.update(
          db.eventSections,
        )..where((s) => s.id.equals(prior.id))).write(
          EventSectionsCompanion(
            title: Value(_optional(section.title)),
            contentMd: Value(section.content),
            position: Value(i),
            suggestionKey: Value(section.suggestionKey),
          ),
        );
        await ctx.recordChange(prior.id, ChangeOperation.update);
      } else if (section.content.trim().isNotEmpty ||
          section.title.trim().isNotEmpty) {
        final stamp = await ctx.stampForNew();
        final sectionId = ctx.newId();
        await db
            .into(db.eventSections)
            .insert(
              EventSectionsCompanion.insert(
                id: sectionId,
                eventId: id,
                title: Value(_optional(section.title)),
                position: i,
                contentMd: section.content,
                suggestionKey: Value(section.suggestionKey),
                layer: stamp.layerCode,
                authorId: stamp.authorId,
                createdAt: stamp.createdAt,
                archiveSessionId: Value(stamp.archiveSessionId),
              ),
            );
        await ctx.recordChange(sectionId, ChangeOperation.create);
      }
    }
    final relations = EventRelationsRepository(ctx);
    final wantedPeople = <String>{};
    for (final name in draft.people.where((name) => name.trim().isNotEmpty)) {
      final person = await PersonRepository(ctx).findOrCreate(name);
      wantedPeople.add(person);
      await relations.addPerson(id, person);
    }
    for (final person in await relations.peopleOf(id)) {
      if (!wantedPeople.contains(person.id)) {
        await relations.removePerson(id, person.id);
      }
    }
    final wantedLinks = draft.relatedIds.toSet();
    for (final related in await relations.related(id)) {
      if (!wantedLinks.contains(related.id)) {
        await relations.unlink(id, related.id);
      }
    }
    await relations.linkAll(id, wantedLinks);
    await _saveTags(id, draft.tags);
    return id;
  });

  Future<void> _saveTags(String eventId, List<String> labels) async {
    final wanted = <String>{};
    for (final label
        in labels.map((l) => l.trim()).where((l) => l.isNotEmpty).toSet()) {
      var tag = await (db.select(
        db.tags,
      )..where((t) => t.label.equals(label))).getSingleOrNull();
      if (tag == null) {
        final id = ctx.newId();
        // 標籤為共用參考資料；帶有層級的是事件與標籤的關聯。
        await db
            .into(db.tags)
            .insert(TagsCompanion.insert(id: id, label: label));
        tag = await (db.select(
          db.tags,
        )..where((t) => t.id.equals(id))).getSingle();
      }
      wanted.add(tag.id);
      final link =
          await (db.select(db.eventTags)..where(
                (r) => r.eventId.equals(eventId) & r.tagId.equals(tag!.id),
              ))
              .getSingleOrNull();
      if (link == null) {
        final stamp = await ctx.stampForNew();
        await db
            .into(db.eventTags)
            .insert(
              EventTagsCompanion.insert(
                eventId: eventId,
                tagId: tag.id,
                layer: stamp.layerCode,
                authorId: stamp.authorId,
                createdAt: stamp.createdAt,
                archiveSessionId: Value(stamp.archiveSessionId),
              ),
            );
        await ctx.recordChange(eventId, ChangeOperation.update);
      }
    }
    final old = await (db.select(
      db.eventTags,
    )..where((r) => r.eventId.equals(eventId))).get();
    for (final link in old) {
      if (!wanted.contains(link.tagId)) {
        await ctx.ensureCanModify(link.layer);
        await (db.delete(db.eventTags)..where(
              (r) => r.eventId.equals(eventId) & r.tagId.equals(link.tagId),
            ))
            .go();
        await ctx.recordChange(eventId, ChangeOperation.update);
      }
    }
  }

  /// 回顧只能追加；不提供覆寫既有回顧的 API。
  Future<String> appendReflection(String eventId, String text) =>
      db.transaction(() async {
        if (text.trim().isEmpty) throw ArgumentError('回顧內容不可空白');
        final event = await EventRepository(ctx).find(eventId);
        if (event == null ||
            event.subjectId != ctx.subjectId ||
            event.deletedAt != null) {
          throw const EventStateException('事件不存在或已刪除');
        }
        final stamp = await ctx.stampForNew();
        final id = ctx.newId();
        await db
            .into(db.reflections)
            .insert(
              ReflectionsCompanion.insert(
                id: id,
                eventId: eventId,
                recordedAt: ctx.now(),
                contentMd: text,
                layer: stamp.layerCode,
                authorId: stamp.authorId,
                createdAt: stamp.createdAt,
                archiveSessionId: Value(stamp.archiveSessionId),
              ),
            );
        await ctx.recordChange(id, ChangeOperation.create);
        return id;
      });
  String? _optional(String text) => text.trim().isEmpty ? null : text.trim();
}
