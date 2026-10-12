// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get timelineUnavailableFilter => '目前沒有可選用的對應資料';

  @override
  String get appTitle => '人生編年史';

  @override
  String get navTimeline => '人生時間軸';

  @override
  String get navSearch => '搜尋與視圖';

  @override
  String get navNewEvent => '新增節點';

  @override
  String get navStories => '故事篇章';

  @override
  String get navBackup => '資料與備份';

  @override
  String get placeholderComingSoon => '此功能開發中';

  @override
  String timeQuarterFull(String year, String quarter) {
    return '$year 年第 $quarter 季';
  }

  @override
  String timeHalfYearFull(String year, String half) {
    String _temp0 = intl.Intl.selectLogic(half, {
      'first': '上半年',
      'other': '下半年',
    });
    return '$year 年$_temp0';
  }

  @override
  String timeYearFull(String year) {
    return '$year 年';
  }

  @override
  String timeApproxYear(String year) {
    return '約 $year 年';
  }

  @override
  String timeRangeYearsFull(String start, String end) {
    return '$start～$end 年';
  }

  @override
  String timeRangeYearsList(String start, String end) {
    return '$start～$end';
  }

  @override
  String timeRange(String start, String end) {
    return '$start～$end';
  }

  @override
  String timeRelativeAfter(String title) {
    return '$title後';
  }

  @override
  String timeRelativeBefore(String title) {
    return '$title前';
  }

  @override
  String timeRelativeDuring(String title) {
    return '$title期間';
  }

  @override
  String get timeDeletedReference => '（參照事件已刪除）';

  @override
  String timeAgeEstimate(String age) {
    return '約 $age 歲';
  }

  @override
  String get timeUnknown => '時間未定';

  @override
  String timeListDay(String month, String day) {
    return '$month/$day';
  }

  @override
  String timeListMonth(String month) {
    return '$month 月';
  }

  @override
  String timeListQuarter(String quarter) {
    return '第 $quarter 季';
  }

  @override
  String timeListHalfYear(String half) {
    String _temp0 = intl.Intl.selectLogic(half, {
      'first': '上半年',
      'other': '下半年',
    });
    return '$_temp0';
  }

  @override
  String get timeListYearOnly => '月份未定';

  @override
  String get timelineOldestFirst => '舊→新';

  @override
  String get timelineThisYear => '回到今年';

  @override
  String timelineCount(int count) {
    return '$count 筆';
  }

  @override
  String get timelineNewestFirst => '新→舊';

  @override
  String get timelineChooseYear => '選擇年份';

  @override
  String timelineYearCount(int count, String year) {
    return '$year・$count 筆';
  }

  @override
  String get timelineEmpty => '還沒有生命紀錄，請從「新增節點」開始。';

  @override
  String get timelineRetry => '重試';

  @override
  String get timelineLoadError => '無法載入時間軸，請重試。';

  @override
  String get timelineAll => '不限';

  @override
  String get timelineOriginal => '原始生命紀錄';

  @override
  String timelineMatches(int matched, int total) {
    return '符合 $matched／$total 筆';
  }

  @override
  String get timelineFilter => '篩選';

  @override
  String get timelineApply => '套用';

  @override
  String get timelinePlace => '地點';

  @override
  String get timelineCategory => '類別';

  @override
  String get timelinePerson => '人物';

  @override
  String get timelineLayer => '紀錄層';

  @override
  String get timelineRemembrance => '後續追憶';

  @override
  String get timelineTag => '標籤';

  @override
  String get timelineLifePeriod => '人生階段';

  @override
  String get timelineClear => '清除篩選';

  @override
  String get timelineDemo => '開發用假資料';

  @override
  String get timelineCompact => '精簡清單';

  @override
  String timelineAttachments(int count) {
    return '$count 個附件';
  }

  @override
  String get timelineEnterYear => '輸入年份';

  @override
  String get timelineCancel => '取消';

  @override
  String get timelineGenerate => '產生';

  @override
  String timelineDemoTitle(int number) {
    return '測試紀錄 $number';
  }

  @override
  String timelineDemoCount(int count) {
    return '追加 $count 筆假資料';
  }

  @override
  String get timelinePreferencesError => '無法讀取或保存顯示偏好，請檢查裝置儲存空間。';

  @override
  String get timelineCards => '圖文卡片';

  @override
  String timelineDemoConfirm(int count) {
    return '將追加 $count 筆假資料至目前資料庫，不會刪除既有紀錄。建議僅在測試裝置使用。';
  }

  @override
  String get timelineDemoCategory => '測試資料';

  @override
  String get timelineBrandEnglish => 'Life Chronicle';
}
