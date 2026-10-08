import 'sort_range.dart';
import 'time_value.dart';

/// 時間軸排序方向（企劃書 4.6：由使用者切換）。
enum SortDirection {
  /// 舊到新：從出生讀起。
  oldestFirst,

  /// 新到舊：打開即看到最近的人生。
  newestFirst,
}

/// 參與排序的項目。
///
/// 由事件的時間值與換算結果建立；[data] 攜帶呼叫端需要的資料（如事件本身）。
class TimelineItem<T> {
  TimelineItem({
    required this.id,
    required this.time,
    required this.resolution,
    required this.recordedAt,
    this.manualOrder = 0,
    required this.data,
  });

  final String id;
  final TimeValue time;
  final SortResolution resolution;

  /// 使用者手動順序（企劃書 5.1 規則 4）：同一天的多件事可拖曳調整。
  final int manualOrder;

  /// 實際建立紀錄的時間（企劃書 5.1 規則 5）。
  final DateTime recordedAt;

  final T data;

  /// 用於排序的區間；無法排序時為 null（歸入「時間未定」區）。
  ///
  /// 參照事件已刪除時沿用最後一次換算的區間。
  SortResolved? get effective => switch (resolution) {
    SortResolved r => r,
    SortReferenceMissing(:final lastKnown) => lastKnown,
    SortUnsortable() || SortCircularReference() => null,
  };

  /// 時間軸分組年份：一律依 `sort_start` 所在年份；時間未定為 null。
  int? get groupYear => effective?.range.start.year;
}

/// 時間軸的一個年份分組。
class TimelineGroup<T> {
  const TimelineGroup(this.year, this.items);

  /// 年份；null 代表「時間未定」區。
  final int? year;
  final List<TimelineItem<T>> items;
}

/// 時間軸排序（企劃書 5.1）——**全專案唯一的排序實作**。
///
/// 畫面、匯出或其他功能需要依時間排序時，一律呼叫本類別，不得另寫排序邏輯。
abstract final class TimelineSort {
  /// 比較兩個項目（不含相對事件的緊鄰規則）。
  ///
  /// 舊到新：
  /// 1. `sort_start` 早者在前
  /// 2. 區間較長者在前（`sort_end` 晚者在前）
  /// 3. 確定者在前
  /// 4. `manual_order` 小者在前
  /// 5. `recorded_at` 早者在前，最後以 ID 排序
  ///
  /// 新到舊（對稱規則，非直接倒轉）：
  /// 1. `sort_end` 晚者在前
  /// 2. 區間較長者在前（`sort_start` 早者在前）
  /// 3. 確定者在前
  /// 4. `manual_order` 反向
  /// 5. `recorded_at` 晚者在前，最後以 ID 反向
  ///
  /// 時間未定的項目一律排在所有可排序項目之後，彼此間依規則 4、5。
  static int compare(TimelineItem a, TimelineItem b, SortDirection direction) {
    final ra = a.effective, rb = b.effective;
    if (ra == null || rb == null) {
      if (ra != null) return -1;
      if (rb != null) return 1;
      return _tieBreak(a, b, direction);
    }
    final newest = direction == SortDirection.newestFirst;
    int c;
    if (newest) {
      c = rb.range.end.compareTo(ra.range.end);
      if (c != 0) return c;
      c = ra.range.start.compareTo(rb.range.start);
      if (c != 0) return c;
    } else {
      c = ra.range.start.compareTo(rb.range.start);
      if (c != 0) return c;
      c = rb.range.end.compareTo(ra.range.end);
      if (c != 0) return c;
    }
    c = ra.certainty.index.compareTo(rb.certainty.index);
    if (c != 0) return c;
    return _tieBreak(a, b, direction);
  }

  /// 規則 4、5：手動順序、建立時間、ID。新到舊時全部反向。
  static int _tieBreak(
    TimelineItem a,
    TimelineItem b,
    SortDirection direction,
  ) {
    var c = a.manualOrder.compareTo(b.manualOrder);
    if (c == 0) c = a.recordedAt.compareTo(b.recordedAt);
    if (c == 0) c = a.id.compareTo(b.id);
    return direction == SortDirection.newestFirst ? -c : c;
  }

  /// 依方向排序，並將「之後／之前」的相對事件緊鄰其參照事件。
  ///
  /// 舊到新：「之後」緊接在參照事件下方，「之前」緊接在上方。
  /// 新到舊：「之後」顯示在參照事件上方，「之前」顯示在下方。
  /// 參照事件不在清單中（例如被篩選掉）時，依繼承的區間一般排序。
  static List<TimelineItem<T>> sort<T>(
    Iterable<TimelineItem<T>> items,
    SortDirection direction,
  ) {
    final list = items.toList();
    final byId = {for (final item in list) item.id: item};

    final afterChildren = <String, List<TimelineItem<T>>>{};
    final beforeChildren = <String, List<TimelineItem<T>>>{};
    final base = <TimelineItem<T>>[];

    for (final item in list) {
      final anchor = _anchorOf(item, byId);
      if (anchor == null) {
        base.add(item);
        continue;
      }
      final (anchorId, relation) = anchor;
      final target = relation == RelativeRelation.after
          ? afterChildren
          : beforeChildren;
      target.putIfAbsent(anchorId, () => []).add(item);
    }

    int cmp(TimelineItem a, TimelineItem b) => compare(a, b, direction);
    base.sort(cmp);
    for (final children in [
      ...afterChildren.values,
      ...beforeChildren.values,
    ]) {
      children.sort((a, b) => _tieBreak(a, b, SortDirection.oldestFirst));
    }

    final result = <TimelineItem<T>>[];
    final emitted = <String>{};
    final newest = direction == SortDirection.newestFirst;

    void emit(TimelineItem<T> item) {
      if (!emitted.add(item.id)) return;
      final after = afterChildren[item.id] ?? const [];
      final before = beforeChildren[item.id] ?? const [];
      if (newest) {
        after.reversed.forEach(emit);
        result.add(item);
        before.reversed.forEach(emit);
      } else {
        before.forEach(emit);
        result.add(item);
        after.forEach(emit);
      }
    }

    base.forEach(emit);
    // 防禦：理論上所有項目都已輸出（循環參照不會成為錨點）
    for (final item in list) {
      if (!emitted.contains(item.id)) {
        result.add(item);
        emitted.add(item.id);
      }
    }
    return result;
  }

  /// 項目若為「之後／之前」相對事件，且參照事件在清單中並可排序，回傳錨點。
  static (String, RelativeRelation)? _anchorOf<T>(
    TimelineItem<T> item,
    Map<String, TimelineItem<T>> byId,
  ) {
    final time = item.time;
    if (time is! RelativeTime || time.relation == RelativeRelation.during) {
      return null;
    }
    if (item.resolution is! SortResolved) return null;
    final anchor = byId[time.eventId];
    if (anchor == null || anchor.effective == null || anchor.id == item.id) {
      return null;
    }
    return (anchor.id, time.relation);
  }

  /// 排序並依年份分組。
  ///
  /// 一律依 `sort_start` 所在年份分組（兩種方向相同，切換方向時事件不換組）；
  /// 年份依方向排列，「時間未定」區固定在最後。
  static List<TimelineGroup<T>> group<T>(
    Iterable<TimelineItem<T>> items,
    SortDirection direction,
  ) {
    final buckets = <int?, List<TimelineItem<T>>>{};
    for (final item in sort(items, direction)) {
      buckets.putIfAbsent(item.groupYear, () => []).add(item);
    }
    final years = buckets.keys.whereType<int>().toList()..sort();
    final ordered = direction == SortDirection.newestFirst
        ? years.reversed
        : years;
    return [
      for (final year in ordered) TimelineGroup(year, buckets[year]!),
      if (buckets.containsKey(null)) TimelineGroup(null, buckets[null]!),
    ];
  }
}
