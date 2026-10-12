import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final timelinePreferencesStoreProvider =
    FutureProvider<TimelinePreferencesStore>(
      (ref) => FileTimelinePreferencesStore.open(),
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
  return RepositoryContext(
    ref.watch(appDatabaseProvider),
    subjectId: profile.subjectId,
    actingAuthorId: profile.selfAuthorId,
  );
});

final eventRepositoryProvider = FutureProvider<EventRepository>(
  (ref) async =>
      EventRepository(await ref.watch(repositoryContextProvider.future)),
);

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
    .family<TimelineYearData, int?>((ref, year) async* {
      final filter = ref.watch(timelineFilterProvider);
      final repository = await ref.watch(timelineRepositoryProvider.future);
      yield* repository.watchYear(year, filter: filter);
    });
