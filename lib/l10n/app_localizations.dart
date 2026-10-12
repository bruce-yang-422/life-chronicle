import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @timelineUnavailableFilter.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有可選用的對應資料'**
  String get timelineUnavailableFilter;

  /// APP 名稱
  ///
  /// In zh, this message translates to:
  /// **'人生編年史'**
  String get appTitle;

  /// 主導航：人生時間軸
  ///
  /// In zh, this message translates to:
  /// **'人生時間軸'**
  String get navTimeline;

  /// 主導航：搜尋與視圖（同時用於底部導覽列，譯文需簡短以免換行）
  ///
  /// In zh, this message translates to:
  /// **'搜尋與視圖'**
  String get navSearch;

  /// 主導航：新增節點
  ///
  /// In zh, this message translates to:
  /// **'新增節點'**
  String get navNewEvent;

  /// 主導航：故事篇章
  ///
  /// In zh, this message translates to:
  /// **'故事篇章'**
  String get navStories;

  /// 主導航：資料與備份（同時用於底部導覽列，譯文需簡短以免換行）
  ///
  /// In zh, this message translates to:
  /// **'資料與備份'**
  String get navBackup;

  /// 尚未實作功能的佔位文字
  ///
  /// In zh, this message translates to:
  /// **'此功能開發中'**
  String get placeholderComingSoon;

  /// 完整格式：季度
  ///
  /// In zh, this message translates to:
  /// **'{year} 年第 {quarter} 季'**
  String timeQuarterFull(String year, String quarter);

  /// 完整格式：半年；half 為 first 或 second
  ///
  /// In zh, this message translates to:
  /// **'{year} 年{half, select, first{上半年} other{下半年}}'**
  String timeHalfYearFull(String year, String half);

  /// 完整格式：年份
  ///
  /// In zh, this message translates to:
  /// **'{year} 年'**
  String timeYearFull(String year);

  /// 約略年份
  ///
  /// In zh, this message translates to:
  /// **'約 {year} 年'**
  String timeApproxYear(String year);

  /// 完整格式：起訖皆為年份的範圍
  ///
  /// In zh, this message translates to:
  /// **'{start}～{end} 年'**
  String timeRangeYearsFull(String start, String end);

  /// 列表格式：起訖皆為年份的範圍
  ///
  /// In zh, this message translates to:
  /// **'{start}～{end}'**
  String timeRangeYearsList(String start, String end);

  /// 一般時間範圍，起訖已格式化
  ///
  /// In zh, this message translates to:
  /// **'{start}～{end}'**
  String timeRange(String start, String end);

  /// 相對事件：之後
  ///
  /// In zh, this message translates to:
  /// **'{title}後'**
  String timeRelativeAfter(String title);

  /// 相對事件：之前
  ///
  /// In zh, this message translates to:
  /// **'{title}前'**
  String timeRelativeBefore(String title);

  /// 相對事件：期間
  ///
  /// In zh, this message translates to:
  /// **'{title}期間'**
  String timeRelativeDuring(String title);

  /// 相對事件的參照事件已刪除時代替標題
  ///
  /// In zh, this message translates to:
  /// **'（參照事件已刪除）'**
  String get timeDeletedReference;

  /// 年齡推估
  ///
  /// In zh, this message translates to:
  /// **'約 {age} 歲'**
  String timeAgeEstimate(String age);

  /// 完全未知的時間
  ///
  /// In zh, this message translates to:
  /// **'時間未定'**
  String get timeUnknown;

  /// 列表格式：精確日期（月、日已補零）
  ///
  /// In zh, this message translates to:
  /// **'{month}/{day}'**
  String timeListDay(String month, String day);

  /// 列表格式：年月
  ///
  /// In zh, this message translates to:
  /// **'{month} 月'**
  String timeListMonth(String month);

  /// 列表格式：季度
  ///
  /// In zh, this message translates to:
  /// **'第 {quarter} 季'**
  String timeListQuarter(String quarter);

  /// 列表格式：半年；half 為 first 或 second
  ///
  /// In zh, this message translates to:
  /// **'{half, select, first{上半年} other{下半年}}'**
  String timeListHalfYear(String half);

  /// 列表格式：只知年份
  ///
  /// In zh, this message translates to:
  /// **'月份未定'**
  String get timeListYearOnly;

  /// No description provided for @timelineOldestFirst.
  ///
  /// In zh, this message translates to:
  /// **'舊→新'**
  String get timelineOldestFirst;

  /// No description provided for @timelineThisYear.
  ///
  /// In zh, this message translates to:
  /// **'回到今年'**
  String get timelineThisYear;

  /// No description provided for @timelineCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 筆'**
  String timelineCount(int count);

  /// No description provided for @timelineNewestFirst.
  ///
  /// In zh, this message translates to:
  /// **'新→舊'**
  String get timelineNewestFirst;

  /// No description provided for @timelineChooseYear.
  ///
  /// In zh, this message translates to:
  /// **'選擇年份'**
  String get timelineChooseYear;

  /// No description provided for @timelineYearCount.
  ///
  /// In zh, this message translates to:
  /// **'{year}・{count} 筆'**
  String timelineYearCount(int count, String year);

  /// No description provided for @timelineEmpty.
  ///
  /// In zh, this message translates to:
  /// **'還沒有生命紀錄，請從「新增節點」開始。'**
  String get timelineEmpty;

  /// No description provided for @timelineRetry.
  ///
  /// In zh, this message translates to:
  /// **'重試'**
  String get timelineRetry;

  /// No description provided for @timelineLoadError.
  ///
  /// In zh, this message translates to:
  /// **'無法載入時間軸，請重試。'**
  String get timelineLoadError;

  /// No description provided for @timelineAll.
  ///
  /// In zh, this message translates to:
  /// **'不限'**
  String get timelineAll;

  /// No description provided for @timelineOriginal.
  ///
  /// In zh, this message translates to:
  /// **'原始生命紀錄'**
  String get timelineOriginal;

  /// No description provided for @timelineMatches.
  ///
  /// In zh, this message translates to:
  /// **'符合 {matched}／{total} 筆'**
  String timelineMatches(int matched, int total);

  /// No description provided for @timelineFilter.
  ///
  /// In zh, this message translates to:
  /// **'篩選'**
  String get timelineFilter;

  /// No description provided for @timelineApply.
  ///
  /// In zh, this message translates to:
  /// **'套用'**
  String get timelineApply;

  /// No description provided for @timelinePlace.
  ///
  /// In zh, this message translates to:
  /// **'地點'**
  String get timelinePlace;

  /// No description provided for @timelineCategory.
  ///
  /// In zh, this message translates to:
  /// **'類別'**
  String get timelineCategory;

  /// No description provided for @timelinePerson.
  ///
  /// In zh, this message translates to:
  /// **'人物'**
  String get timelinePerson;

  /// No description provided for @timelineLayer.
  ///
  /// In zh, this message translates to:
  /// **'紀錄層'**
  String get timelineLayer;

  /// No description provided for @timelineRemembrance.
  ///
  /// In zh, this message translates to:
  /// **'後續追憶'**
  String get timelineRemembrance;

  /// No description provided for @timelineTag.
  ///
  /// In zh, this message translates to:
  /// **'標籤'**
  String get timelineTag;

  /// No description provided for @timelineLifePeriod.
  ///
  /// In zh, this message translates to:
  /// **'人生階段'**
  String get timelineLifePeriod;

  /// No description provided for @timelineClear.
  ///
  /// In zh, this message translates to:
  /// **'清除篩選'**
  String get timelineClear;

  /// No description provided for @timelineDemo.
  ///
  /// In zh, this message translates to:
  /// **'開發用假資料'**
  String get timelineDemo;

  /// No description provided for @timelineCompact.
  ///
  /// In zh, this message translates to:
  /// **'精簡清單'**
  String get timelineCompact;

  /// No description provided for @timelineAttachments.
  ///
  /// In zh, this message translates to:
  /// **'{count} 個附件'**
  String timelineAttachments(int count);

  /// No description provided for @timelineEnterYear.
  ///
  /// In zh, this message translates to:
  /// **'輸入年份'**
  String get timelineEnterYear;

  /// No description provided for @timelineCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get timelineCancel;

  /// No description provided for @timelineGenerate.
  ///
  /// In zh, this message translates to:
  /// **'產生'**
  String get timelineGenerate;

  /// No description provided for @timelineDemoTitle.
  ///
  /// In zh, this message translates to:
  /// **'測試紀錄 {number}'**
  String timelineDemoTitle(int number);

  /// No description provided for @timelineDemoCount.
  ///
  /// In zh, this message translates to:
  /// **'追加 {count} 筆假資料'**
  String timelineDemoCount(int count);

  /// No description provided for @timelinePreferencesError.
  ///
  /// In zh, this message translates to:
  /// **'無法讀取或保存顯示偏好，請檢查裝置儲存空間。'**
  String get timelinePreferencesError;

  /// No description provided for @timelineCards.
  ///
  /// In zh, this message translates to:
  /// **'圖文卡片'**
  String get timelineCards;

  /// No description provided for @timelineDemoConfirm.
  ///
  /// In zh, this message translates to:
  /// **'將追加 {count} 筆假資料至目前資料庫，不會刪除既有紀錄。建議僅在測試裝置使用。'**
  String timelineDemoConfirm(int count);

  /// No description provided for @timelineDemoCategory.
  ///
  /// In zh, this message translates to:
  /// **'測試資料'**
  String get timelineDemoCategory;

  /// 正式英文名稱，來源為企劃書標題：人生編年史 Life Chronicle
  ///
  /// In zh, this message translates to:
  /// **'Life Chronicle'**
  String get timelineBrandEnglish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
