import '../../core/text/name_key.dart';
import '../db/app_database.dart';
import 'place_repository.dart';
import 'repository_context.dart';

/// 參與人物（企劃書 4.1）：與「作者」不同，是事件中出現的人。
///
/// 人物為共用的參考資料，不屬於任何層級；事件與人物的對照才有層級。
class PersonRepository {
  PersonRepository(this.ctx);

  final RepositoryContext ctx;

  AppDatabase get db => ctx.db;

  /// 依名稱取得人物；寫法差異視為同一人，不存在才建立。
  Future<String> findOrCreate(String name) async {
    final display = NameKey.displayName(name);
    final key = NameKey.of(name);
    if (display == null || key == null) {
      throw ArgumentError.value(name, 'name', '人物名稱不可空白');
    }
    final existing = await (db.select(
      db.people,
    )..where((p) => p.nameKey.equals(key))).getSingleOrNull();
    if (existing != null) return existing.id;
    final id = ctx.newId();
    await db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            id: id,
            displayName: display,
            nameKey: key,
            createdAt: ctx.now(),
          ),
        );
    return id;
  }

  /// 輸入人物時的建議。
  Future<List<Person>> suggest(String query, {int limit = 8}) async {
    final key = NameKey.of(query);
    if (key == null) return const [];
    final all = await db.select(db.people).get();
    return rankByNameKey(
      all,
      key,
      (p) => p.nameKey,
      (p) => p.displayName,
      limit: limit,
    );
  }
}
