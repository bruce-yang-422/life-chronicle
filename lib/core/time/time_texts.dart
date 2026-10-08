/// 時間顯示格式所需的文字來源（企劃書 4.7）。
///
/// 核心邏輯不寫死任何語言，由 `lib/l10n/` 依目前語系實作。
/// 數字型的日期格式（如 2003-09-15）與語言無關，由 [TimeFormat] 直接產生。
abstract interface class TimeTexts {
  // 完整格式（詳情頁）

  /// 例：「2003 年第 3 季」「Q3 2003」。
  String quarterFull(int year, int quarter);

  /// 例：「2003 年上半年」「H1 2003」。
  String halfYearFull(int year, {required bool firstHalf});

  /// 例：「2003 年」「2003」。
  String yearFull(int year);

  /// 例：「約 2003 年」「c. 2003」。
  String approxYear(int year);

  /// 起訖皆為年份的範圍，例：「2002～2004 年」「2002–2004」。
  String rangeYearsFull(int startYear, int endYear);

  /// 一般範圍，起訖已格式化，例：「2002-09～2004 年」。
  String range(String start, String end);

  /// 例：「大學畢業後」「After 大學畢業」。
  String relativeAfter(String title);

  String relativeBefore(String title);

  String relativeDuring(String title);

  /// 相對事件的參照事件已刪除時，代替標題的文字。
  String deletedReference();

  /// 例：「約 20 歲」「About age 20」。
  String ageEstimate(int age);

  /// 例：「時間未定」「Date unknown」。
  String unknown();

  // 列表格式（時間軸首頁，已依年份分組）

  /// 例：「12/28」。
  String listDay(int month, int day);

  /// 例：「12 月」「Dec」。
  String listMonth(int month);

  /// 例：「第 4 季」「Q4」。
  String listQuarter(int quarter);

  /// 例：「下半年」「H2」。
  String listHalfYear({required bool firstHalf});

  /// 只知年份時的列表文字，例：「月份未定」「Month unknown」。
  String listYearOnly();

  /// 起訖皆為年份的範圍，例：「2002～2004」。
  String rangeYearsList(int startYear, int endYear);
}
