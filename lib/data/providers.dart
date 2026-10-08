import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/time/timeline_sort.dart';
import 'db/app_database.dart';
import 'repositories/event_relations_repository.dart';
import 'repositories/event_repository.dart';
import 'repositories/person_repository.dart';
import 'repositories/place_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/repository_context.dart';

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
