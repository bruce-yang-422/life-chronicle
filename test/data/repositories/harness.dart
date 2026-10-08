import 'package:drift/native.dart';
import 'package:life_chronicle/data/db/app_database.dart';
import 'package:life_chronicle/data/repositories/event_relations_repository.dart';
import 'package:life_chronicle/data/repositories/event_repository.dart';
import 'package:life_chronicle/data/repositories/person_repository.dart';
import 'package:life_chronicle/data/repositories/place_repository.dart';
import 'package:life_chronicle/data/repositories/profile_repository.dart';
import 'package:life_chronicle/data/repositories/repository_context.dart';

/// 測試用的資料層：記憶體資料庫、可調整的時鐘、主角與家人作者。
class Harness {
  Harness._(this.db, this.profile, this.familyAuthorId);

  static Future<Harness> create() async {
    final db = AppDatabase(NativeDatabase.memory());
    final profiles = ProfileRepository(db);
    final profile = await profiles.ensureDefaultProfile();
    final family = await profiles.addAuthor('王小美', role: AuthorRole.family);
    return Harness._(db, profile, family);
  }

  final AppDatabase db;
  final Profile profile;
  final String familyAuthorId;

  /// 目前時間；測試可直接修改。
  DateTime now = DateTime.utc(2026, 10, 8, 9);

  RepositoryContext context({String? actingAuthorId}) => RepositoryContext(
    db,
    subjectId: profile.subjectId,
    actingAuthorId: actingAuthorId ?? profile.selfAuthorId,
    clock: () => now,
  );

  EventRepository events({String? as}) =>
      EventRepository(context(actingAuthorId: as));

  EventRelationsRepository relations({String? as}) =>
      EventRelationsRepository(context(actingAuthorId: as));

  PlaceRepository get places => PlaceRepository(context());

  PersonRepository get people => PersonRepository(context());

  ProfileRepository get profiles => ProfileRepository(db, clock: () => now);

  Future<void> activateArchive() => profiles.activateLifeArchive(
    profile.subjectId,
    byAuthorId: familyAuthorId,
  );

  Future<void> deactivateArchive() => profiles.deactivateLifeArchive(
    profile.subjectId,
    byAuthorId: familyAuthorId,
  );

  Future<void> close() => db.close();
}
