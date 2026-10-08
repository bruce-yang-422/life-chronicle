import 'calendar_date.dart';
import 'time_value.dart';

/// 排序區間：最早可能日期～最晚可能日期（企劃書 5.1 步驟一）。
///
/// 只供系統排序使用，永遠不顯示給使用者。
class SortRange {
  SortRange(this.start, this.end) {
    if (start.isAfter(end)) {
      throw ArgumentError('排序區間的起點不可晚於終點：$start～$end');
    }
  }

  final CalendarDate start;
  final CalendarDate end;

  @override
  bool operator ==(Object other) =>
      other is SortRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start～$end';
}

/// 時間的確定程度（企劃書 5.1 規則 3：確定者在前）。
enum TimeCertainty { exact, approximate }

/// 無法排序的原因。
enum UnsortableReason {
  /// 時間未定。
  unknownTime,

  /// 年齡推估缺少主角生日，視同時間未定並提示補填。
  missingBirthDate,
}

/// 排序區間換算結果。
sealed class SortResolution {
  const SortResolution();
}

/// 成功換算出排序區間。
final class SortResolved extends SortResolution {
  const SortResolved(this.range, this.certainty);

  final SortRange range;
  final TimeCertainty certainty;

  @override
  bool operator ==(Object other) =>
      other is SortResolved &&
      other.range == range &&
      other.certainty == certainty;

  @override
  int get hashCode => Object.hash(range, certainty);

  @override
  String toString() => 'SortResolved($range, ${certainty.name})';
}

/// 不參與時間排序，歸入時間軸最後的「時間未定」區。
final class SortUnsortable extends SortResolution {
  const SortUnsortable(this.reason);

  final UnsortableReason reason;

  @override
  bool operator ==(Object other) =>
      other is SortUnsortable && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'SortUnsortable(${reason.name})';
}

/// 相對事件所參照的事件已不存在。
///
/// 依企劃書 5.1：保留最後一次換算的區間（[lastKnown]）並標示「參照事件已刪除」，
/// 提示使用者重新指定。沒有先前區間時視同時間未定。
final class SortReferenceMissing extends SortResolution {
  const SortReferenceMissing(this.missingEventId, this.lastKnown);

  final String missingEventId;
  final SortResolved? lastKnown;

  @override
  bool operator ==(Object other) =>
      other is SortReferenceMissing &&
      other.missingEventId == missingEventId &&
      other.lastKnown == lastKnown;

  @override
  int get hashCode => Object.hash(missingEventId, lastKnown);

  @override
  String toString() => 'SortReferenceMissing($missingEventId, $lastKnown)';
}

/// 相對事件形成循環參照（企劃書 5.1：不得形成循環參照）。
final class SortCircularReference extends SortResolution {
  const SortCircularReference(this.chain);

  /// 形成循環的事件 ID 鏈，最後一個與其中某個重複。
  final List<String> chain;

  @override
  bool operator ==(Object other) =>
      other is SortCircularReference && _listEquals(other.chain, chain);

  @override
  int get hashCode => Object.hashAll(chain);

  @override
  String toString() => 'SortCircularReference(${chain.join(' → ')})';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// 換算時所需的外部資訊，由資料層注入（核心邏輯不直接查資料庫）。
abstract interface class SortContext {
  /// 取得事件的時間值；事件不存在時回傳 null。
  TimeValue? timeOfEvent(String eventId);

  /// 主角生日（精確日期、年月或年份）；未填寫時回傳 null。
  CalendarTime? subjectBirth();
}

/// 將時間值換算為排序區間（企劃書 5.1 步驟一）。
abstract final class SortRangeResolver {
  /// 換算 [value] 的排序區間。
  ///
  /// [selfId] 為此時間所屬事件的 ID，用於偵測循環參照；
  /// [previous] 為此事件上一次換算的結果，參照事件消失時保留使用。
  static SortResolution resolve(
    TimeValue value,
    SortContext context, {
    String? selfId,
    SortResolved? previous,
  }) => _resolve(value, context, [?selfId], previous);

  static SortResolution _resolve(
    TimeValue value,
    SortContext context,
    List<String> chain,
    SortResolved? previous,
  ) {
    return switch (value) {
      CalendarTime c => SortResolved(
        SortRange(c.startDate, c.endDate),
        TimeCertainty.exact,
      ),
      ApproxYearTime(:final year) => SortResolved(
        SortRange(
          CalendarDate.firstOfYear(year),
          CalendarDate.lastOfYear(year),
        ),
        TimeCertainty.approximate,
      ),
      RangeTime(:final start, :final end) => SortResolved(
        SortRange(start.startDate, end.endDate),
        TimeCertainty.exact,
      ),
      RelativeTime(:final eventId) => _resolveRelative(
        eventId,
        context,
        chain,
        previous,
      ),
      AgeEstimateTime(:final age) => _resolveAge(age, context),
      UnknownTime() => const SortUnsortable(UnsortableReason.unknownTime),
    };
  }

  /// 相對事件繼承參照事件的區間；「之後／之前」的緊鄰位置由排序比較器處理。
  static SortResolution _resolveRelative(
    String eventId,
    SortContext context,
    List<String> chain,
    SortResolved? previous,
  ) {
    if (chain.contains(eventId)) {
      return SortCircularReference([...chain, eventId]);
    }
    final referenced = context.timeOfEvent(eventId);
    if (referenced == null) {
      return SortReferenceMissing(eventId, previous);
    }
    return _resolve(referenced, context, [...chain, eventId], previous);
  }

  /// 年齡推估：主角生日＋N 歲 ～ 生日＋(N+1) 歲前一日。
  ///
  /// 生日只知年月或年份時，以最早與最晚可能生日放寬區間。
  /// 年齡推估本身是約略值，標記為推估。
  static SortResolution _resolveAge(int age, SortContext context) {
    final birth = context.subjectBirth();
    if (birth == null) {
      return const SortUnsortable(UnsortableReason.missingBirthDate);
    }
    final start = birth.startDate.addYears(age);
    final end = birth.endDate.addYears(age + 1).addDays(-1);
    return SortResolved(SortRange(start, end), TimeCertainty.approximate);
  }
}
