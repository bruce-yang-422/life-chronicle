import 'package:drift/drift.dart';

import '../../core/text/name_key.dart';
import '../db/app_database.dart';
import 'repository_context.dart';

/// 依正規化名稱排序建議：完全相同 > 開頭相同 > 包含；同級依名稱。
List<T> rankByNameKey<T>(
  Iterable<T> items,
  String queryKey,
  String Function(T) keyOf,
  String Function(T) labelOf, {
  required int limit,
}) {
  int rank(T item) {
    final key = keyOf(item);
    if (key == queryKey) return 0;
    if (key.startsWith(queryKey)) return 1;
    return 2;
  }

  final matches = items.where((i) => keyOf(i).contains(queryKey)).toList()
    ..sort((a, b) {
      final c = rank(a).compareTo(rank(b));
      return c != 0 ? c : labelOf(a).compareTo(labelOf(b));
    });
  return matches.take(limit).toList();
}

/// 地點：文字名稱與 GPS 錨點（企劃書 4.1）。
///
/// 地點為共用的參考資料，不屬於任何層級；事件透過 `place_id` 指向地點。
class PlaceRepository {
  PlaceRepository(this.ctx);

  final RepositoryContext ctx;

  AppDatabase get db => ctx.db;

  Future<Place?> find(String id) =>
      (db.select(db.places)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Place?> findByName(String name) async {
    final key = NameKey.of(name);
    if (key == null) return null;
    return (db.select(
      db.places,
    )..where((p) => p.nameKey.equals(key))).getSingleOrNull();
  }

  /// 依名稱取得地點；寫法差異（台／臺、全形、空白）視為同一地點，不存在才建立。
  Future<String> findOrCreateByName(String name) async {
    final display = NameKey.displayName(name);
    final key = NameKey.of(name);
    if (display == null || key == null) {
      throw ArgumentError.value(name, 'name', '地點名稱不可空白');
    }
    final existing = await findByName(name);
    if (existing != null) return existing.id;
    final id = ctx.newId();
    await db
        .into(db.places)
        .insert(
          PlacesCompanion.insert(
            id: id,
            name: Value(display),
            nameKey: Value(key),
            createdAt: ctx.now(),
          ),
        );
    return id;
  }

  /// 輸入地點時的建議：列出名稱包含輸入文字的既有地點。
  Future<List<Place>> suggest(String query, {int limit = 8}) async {
    final key = NameKey.of(query);
    if (key == null) return const [];
    final named = await (db.select(
      db.places,
    )..where((p) => p.nameKey.isNotNull())).get();
    return rankByNameKey(
      named,
      key,
      (p) => p.nameKey!,
      (p) => p.name!,
      limit: limit,
    );
  }

  /// 建立 GPS 錨點地點；名稱可省略（例如沒有地址的區域）。
  ///
  /// 指定名稱且該地點已存在時，改為補上或更新其座標。
  Future<String> createAnchor({
    required double latitude,
    required double longitude,
    double? radiusM,
    String? name,
  }) async {
    _checkCoordinates(latitude, longitude, radiusM);
    if (name != null && NameKey.of(name) != null) {
      final id = await findOrCreateByName(name);
      await setAnchor(
        id,
        latitude: latitude,
        longitude: longitude,
        radiusM: radiusM,
      );
      return id;
    }
    final id = ctx.newId();
    await db
        .into(db.places)
        .insert(
          PlacesCompanion.insert(
            id: id,
            latitude: Value(latitude),
            longitude: Value(longitude),
            radiusM: Value(radiusM),
            createdAt: ctx.now(),
          ),
        );
    return id;
  }

  /// 設定或更新地點的錨點（例如日後有網路時再於地圖上補上釘選點）。
  Future<void> setAnchor(
    String placeId, {
    required double latitude,
    required double longitude,
    double? radiusM,
  }) async {
    _checkCoordinates(latitude, longitude, radiusM);
    await (db.update(db.places)..where((p) => p.id.equals(placeId))).write(
      PlacesCompanion(
        latitude: Value(latitude),
        longitude: Value(longitude),
        radiusM: Value(radiusM),
      ),
    );
  }

  static void _checkCoordinates(double lat, double lng, double? radius) {
    if (lat < -90 || lat > 90) {
      throw ArgumentError.value(lat, 'latitude', '緯度須介於 -90 與 90');
    }
    if (lng < -180 || lng > 180) {
      throw ArgumentError.value(lng, 'longitude', '經度須介於 -180 與 180');
    }
    if (radius != null && radius <= 0) {
      throw ArgumentError.value(radius, 'radiusM', '範圍半徑須大於 0');
    }
  }
}
