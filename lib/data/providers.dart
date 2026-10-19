import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'platform/security_platform.dart';
import 'platform/location_platform.dart';
import 'repositories/security_service.dart';
import '../core/time/timeline_sort.dart';
import 'db/app_database.dart';
import 'repositories/event_relations_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/person_repository.dart';
import 'repositories/place_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/repository_context.dart';
import 'repositories/timeline_repository.dart';
import 'repositories/timeline_preferences_store.dart';
import 'repositories/event_content_repository.dart';
import 'repositories/event_draft_store.dart';
import 'repositories/search_repository.dart';
import 'repositories/attachment_repository.dart';

import 'dart:io';

import 'package:path/path.dart' as p;

import 'repositories/archive_repository.dart';
import 'repositories/archive_zip.dart';

final securityStorageProvider = Provider<SecurityStorage>(
  (ref) => DeviceSecurityStorage(),
);
final locationPlatformProvider = Provider<LocationPlatform>(
  (ref) => DeviceLocationPlatform(),
);
final securityPlatformProvider = Provider<SecurityPlatform>(
  (ref) => DeviceSecurityPlatform(),
);
final securityProvider = ChangeNotifierProvider<SecurityService>(
  (ref) => SecurityService(
    ref.watch(securityStorageProvider),
    ref.watch(securityPlatformProvider),
    ref.watch(appDatabaseProvider),
  )..load(),
);

final archiveRepositoryProvider = FutureProvider<ArchiveRepository>((
  ref,
) async {
  final attachments = await ref.watch(attachmentRepositoryProvider.future);
  return ArchiveRepository(
    await ref.watch(repositoryContextProvider.future),
    attachments,
    Directory(p.join(attachments.directory.parent.path, 'backups')),
    const ArchiveZip(),
  );
});

/// 平板主從畫面的選取；縮小視窗時仍保留同一事件。
class SelectedEventController extends Notifier<({String id, String? title})?> {
  @override
  ({String id, String? title})? build() => null;
  void select(String id, String? title) => state = (id: id, title: title);
  void clear() => state = null;
}

final selectedEventProvider =
    NotifierProvider<SelectedEventController, ({String id, String? title})?>(
      SelectedEventController.new,
    );

final timelinePreferencesStoreProvider =
    FutureProvider<TimelinePreferencesStore>(
      (ref) => FileTimelinePreferencesStore.open(),
    );

class TimelineDirectionController extends Notifier<SortDirection> {
  @override
  SortDirection build() => SortDirection.newestFirst;
  void set(SortDirection direction) => state = direction;
}

final timelineDirectionProvider =
    NotifierProvider<TimelineDirectionController, SortDirection>(
      TimelineDirectionController.new,
    );

/// 資料庫連線。測試時以記憶體資料庫覆寫。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

/// 主角與本人作者；首次開啟時自動建立。
final profileProvider = FutureProvider<Profile>(
  (ref) =>
      ProfileRepository(ref.watch(appDatabaseProvider)).ensureDefaultProfile(),
);

/// 各 repository 共用的執行環境；第一階段操作者為主角本人。
final repositoryContextProvider = FutureProvider<RepositoryContext>((
  ref,
) async {
  final profile = await ref.watch(profileProvider.future);
  final security = ref.watch(securityProvider);
  return RepositoryContext(
    ref.watch(appDatabaseProvider),
    subjectId: profile.subjectId,
    actingAuthorId: security.family
        ? security.familyAuthorId!
        : profile.selfAuthorId,
    canReadPrivate: security.canReadPrivate,
  );
});

final eventRepositoryProvider = FutureProvider<EventRepository>(
  (ref) async =>
      EventRepository(await ref.watch(repositoryContextProvider.future)),
);
final eventReferencesProvider = StreamProvider<List<Event>>((ref) async* {
  yield* (await ref.watch(eventRepositoryProvider.future)).watchReferences();
});

final eventDraftStoreProvider = FutureProvider<EventDraftStore>(
  (ref) => FileEventDraftStore.open(),
);
final attachmentRepositoryProvider = FutureProvider<AttachmentRepository>(
  (ref) async => AttachmentRepository.open(
    await ref.watch(repositoryContextProvider.future),
  ),
);
final eventAttachmentsProvider = StreamProvider.autoDispose
    .family<List<StoredAttachment>, String>((ref, id) async* {
      final repository = await ref.watch(attachmentRepositoryProvider.future);
      yield* repository.watch(id);
    });
final eventContentRepositoryProvider = FutureProvider<EventContentRepository>(
  (ref) async =>
      EventContentRepository(await ref.watch(repositoryContextProvider.future)),
);
final deletedEventContentProvider = StreamProvider.autoDispose
    .family<EventContent?, String>((ref, id) async* {
      final repository = await ref.watch(eventContentRepositoryProvider.future);
      yield* repository.watch(
        id,
        includeDeleted: true,
        direction: ref.watch(timelineDirectionProvider),
      );
    });
final eventContentProvider = StreamProvider.autoDispose
    .family<EventContent?, String>((ref, id) async* {
      final repository = await ref.watch(eventContentRepositoryProvider.future);
      yield* repository.watch(
        id,
        direction: ref.watch(timelineDirectionProvider),
      );
    });
final searchRepositoryProvider = FutureProvider<SearchRepository>(
  (ref) async =>
      SearchRepository(await ref.watch(repositoryContextProvider.future)),
);
final searchResultsProvider = StreamProvider.autoDispose
    .family<List<TimelineItem<Event>>, ({String query, int? from, int? to})>((
      ref,
      request,
    ) async* {
      final repository = await ref.watch(searchRepositoryProvider.future);
      final direction = ref.watch(timelineDirectionProvider);
      yield* repository.watch(
        request.query,
        fromYear: request.from,
        toYear: request.to,
        direction: direction,
      );
    });

final placeRepositoryProvider = FutureProvider<PlaceRepository>(
  (ref) async =>
      PlaceRepository(await ref.watch(repositoryContextProvider.future)),
);

final personRepositoryProvider = FutureProvider<PersonRepository>(
  (ref) async =>
      PersonRepository(await ref.watch(repositoryContextProvider.future)),
);

final eventRelationsRepositoryProvider =
    FutureProvider<EventRelationsRepository>(
      (ref) async => EventRelationsRepository(
        await ref.watch(repositoryContextProvider.future),
      ),
    );

/// 時間軸事件（未排序）；資料變更時自動更新。排序與分組交由 [TimelineSort]。
final timelineItemsProvider = StreamProvider<List<TimelineItem<Event>>>((
  ref,
) async* {
  final repository = await ref.watch(eventRepositoryProvider.future);
  yield* repository.watchTimeline();
});

final timelineRepositoryProvider = FutureProvider<TimelineRepository>(
  (ref) async =>
      TimelineRepository(await ref.watch(repositoryContextProvider.future)),
);

final timelineYearsProvider = StreamProvider<List<TimelineYearCount>>((
  ref,
) async* {
  final filter = ref.watch(timelineFilterProvider);
  final repository = await ref.watch(timelineRepositoryProvider.future);
  yield* repository.watchYears(filter: filter);
});

final timelineAllYearsProvider = StreamProvider<List<TimelineYearCount>>((
  ref,
) async* {
  final repository = await ref.watch(timelineRepositoryProvider.future);
  yield* repository.watchYears();
});

class TimelineFilterController extends Notifier<TimelineFilter> {
  @override
  TimelineFilter build() => const TimelineFilter();
  void apply(TimelineFilter filter) => state = filter;
}

final timelineFilterProvider =
    NotifierProvider<TimelineFilterController, TimelineFilter>(
      TimelineFilterController.new,
    );

final timelineFilterOptionsProvider =
    FutureProvider.autoDispose<TimelineFilterOptions>((ref) async {
      final repository = await ref.watch(timelineRepositoryProvider.future);
      return repository.filterOptions();
    });

/// 離開畫面後釋放該年份的事件與資料庫監聽。
final timelineYearProvider = StreamProvider.autoDispose
    .family<TimelineYearData, ({int? year, bool previews})>((
      ref,
      query,
    ) async* {
      final filter = ref.watch(timelineFilterProvider);
      final repository = await ref.watch(timelineRepositoryProvider.future);
      yield* repository.watchYear(
        query.year,
        filter: filter,
        includePreviews: query.previews,
      );
    });
