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
  /// **'主題瀏覽'**
  String get navStories;

  /// 主導航：資料與備份（同時用於底部導覽列，譯文需簡短以免換行）
  ///
  /// In zh, this message translates to:
  /// **'資料與備份'**
  String get navBackup;

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

  /// 相對參照不存在且沒有可讀快照時代替標題，可能已刪除或未匯出
  ///
  /// In zh, this message translates to:
  /// **'（參照事件未提供）'**
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

  /// No description provided for @editorName.
  ///
  /// In zh, this message translates to:
  /// **'事件名稱'**
  String get editorName;

  /// No description provided for @editorWhen.
  ///
  /// In zh, this message translates to:
  /// **'何時發生'**
  String get editorWhen;

  /// No description provided for @editorNarrative.
  ///
  /// In zh, this message translates to:
  /// **'記述'**
  String get editorNarrative;

  /// No description provided for @editorAttachments.
  ///
  /// In zh, this message translates to:
  /// **'加入附件'**
  String get editorAttachments;

  /// No description provided for @editorAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'進階編輯'**
  String get editorAdvanced;

  /// No description provided for @editorSave.
  ///
  /// In zh, this message translates to:
  /// **'儲存事件'**
  String get editorSave;

  /// No description provided for @editorEdit.
  ///
  /// In zh, this message translates to:
  /// **'編輯事件'**
  String get editorEdit;

  /// No description provided for @editorRequired.
  ///
  /// In zh, this message translates to:
  /// **'請輸入事件名稱'**
  String get editorRequired;

  /// No description provided for @editorError.
  ///
  /// In zh, this message translates to:
  /// **'無法儲存，草稿已保留。請重試。'**
  String get editorError;

  /// No description provided for @editorDraftError.
  ///
  /// In zh, this message translates to:
  /// **'草稿無法讀取或保存，請重試。'**
  String get editorDraftError;

  /// No description provided for @editorRestored.
  ///
  /// In zh, this message translates to:
  /// **'已恢復尚未儲存的草稿'**
  String get editorRestored;

  /// No description provided for @editorDiscard.
  ///
  /// In zh, this message translates to:
  /// **'捨棄草稿'**
  String get editorDiscard;

  /// No description provided for @editorDiscardConfirm.
  ///
  /// In zh, this message translates to:
  /// **'捨棄尚未儲存的內容？'**
  String get editorDiscardConfirm;

  /// No description provided for @editorCategory.
  ///
  /// In zh, this message translates to:
  /// **'類別'**
  String get editorCategory;

  /// No description provided for @editorPlace.
  ///
  /// In zh, this message translates to:
  /// **'地點'**
  String get editorPlace;

  /// No description provided for @editorPeople.
  ///
  /// In zh, this message translates to:
  /// **'參與人物'**
  String get editorPeople;

  /// No description provided for @editorAddPerson.
  ///
  /// In zh, this message translates to:
  /// **'加入人物'**
  String get editorAddPerson;

  /// No description provided for @editorTags.
  ///
  /// In zh, this message translates to:
  /// **'標籤（以逗號分隔）'**
  String get editorTags;

  /// No description provided for @editorPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'隱私層級'**
  String get editorPrivacy;

  /// No description provided for @editorNormal.
  ///
  /// In zh, this message translates to:
  /// **'一般'**
  String get editorNormal;

  /// No description provided for @editorPrivate.
  ///
  /// In zh, this message translates to:
  /// **'私密'**
  String get editorPrivate;

  /// No description provided for @editorRelated.
  ///
  /// In zh, this message translates to:
  /// **'關聯事件'**
  String get editorRelated;

  /// No description provided for @editorAddSection.
  ///
  /// In zh, this message translates to:
  /// **'新增段落'**
  String get editorAddSection;

  /// No description provided for @editorSectionTitle.
  ///
  /// In zh, this message translates to:
  /// **'段落標題（選填）'**
  String get editorSectionTitle;

  /// No description provided for @editorRemoveSection.
  ///
  /// In zh, this message translates to:
  /// **'刪除段落'**
  String get editorRemoveSection;

  /// No description provided for @editorMoveUp.
  ///
  /// In zh, this message translates to:
  /// **'上移'**
  String get editorMoveUp;

  /// No description provided for @editorMoveDown.
  ///
  /// In zh, this message translates to:
  /// **'下移'**
  String get editorMoveDown;

  /// No description provided for @editorCustomSection.
  ///
  /// In zh, this message translates to:
  /// **'自訂標題'**
  String get editorCustomSection;

  /// No description provided for @sectionCause.
  ///
  /// In zh, this message translates to:
  /// **'起因'**
  String get sectionCause;

  /// No description provided for @sectionProcess.
  ///
  /// In zh, this message translates to:
  /// **'經過'**
  String get sectionProcess;

  /// No description provided for @sectionResult.
  ///
  /// In zh, this message translates to:
  /// **'結果'**
  String get sectionResult;

  /// No description provided for @sectionFeeling.
  ///
  /// In zh, this message translates to:
  /// **'當時感受'**
  String get sectionFeeling;

  /// No description provided for @sectionDifficulty.
  ///
  /// In zh, this message translates to:
  /// **'困難'**
  String get sectionDifficulty;

  /// No description provided for @sectionInsight.
  ///
  /// In zh, this message translates to:
  /// **'領悟'**
  String get sectionInsight;

  /// No description provided for @sectionPeople.
  ///
  /// In zh, this message translates to:
  /// **'相關人物'**
  String get sectionPeople;

  /// No description provided for @sectionScene.
  ///
  /// In zh, this message translates to:
  /// **'場景與畫面'**
  String get sectionScene;

  /// No description provided for @sectionWords.
  ///
  /// In zh, this message translates to:
  /// **'印象深刻的話'**
  String get sectionWords;

  /// No description provided for @pickerPrecision.
  ///
  /// In zh, this message translates to:
  /// **'時間精確度'**
  String get pickerPrecision;

  /// No description provided for @pickerYear.
  ///
  /// In zh, this message translates to:
  /// **'年份'**
  String get pickerYear;

  /// No description provided for @pickerHalf.
  ///
  /// In zh, this message translates to:
  /// **'半年'**
  String get pickerHalf;

  /// No description provided for @pickerQuarter.
  ///
  /// In zh, this message translates to:
  /// **'季度'**
  String get pickerQuarter;

  /// No description provided for @pickerMonth.
  ///
  /// In zh, this message translates to:
  /// **'月份'**
  String get pickerMonth;

  /// No description provided for @pickerDay.
  ///
  /// In zh, this message translates to:
  /// **'日期'**
  String get pickerDay;

  /// No description provided for @pickerApprox.
  ///
  /// In zh, this message translates to:
  /// **'約略年份'**
  String get pickerApprox;

  /// No description provided for @pickerRange.
  ///
  /// In zh, this message translates to:
  /// **'時間範圍'**
  String get pickerRange;

  /// No description provided for @pickerRelative.
  ///
  /// In zh, this message translates to:
  /// **'相對事件'**
  String get pickerRelative;

  /// No description provided for @pickerAge.
  ///
  /// In zh, this message translates to:
  /// **'年齡推估'**
  String get pickerAge;

  /// No description provided for @pickerUnknown.
  ///
  /// In zh, this message translates to:
  /// **'時間未定'**
  String get pickerUnknown;

  /// No description provided for @pickerStart.
  ///
  /// In zh, this message translates to:
  /// **'起點'**
  String get pickerStart;

  /// No description provided for @pickerEnd.
  ///
  /// In zh, this message translates to:
  /// **'終點'**
  String get pickerEnd;

  /// No description provided for @pickerBefore.
  ///
  /// In zh, this message translates to:
  /// **'之前'**
  String get pickerBefore;

  /// No description provided for @pickerAfter.
  ///
  /// In zh, this message translates to:
  /// **'之後'**
  String get pickerAfter;

  /// No description provided for @pickerDuring.
  ///
  /// In zh, this message translates to:
  /// **'期間'**
  String get pickerDuring;

  /// No description provided for @pickerInvalid.
  ///
  /// In zh, this message translates to:
  /// **'請檢查時間輸入及起訖順序'**
  String get pickerInvalid;

  /// No description provided for @pickerApply.
  ///
  /// In zh, this message translates to:
  /// **'套用時間'**
  String get pickerApply;

  /// No description provided for @detailMissing.
  ///
  /// In zh, this message translates to:
  /// **'事件不存在或已刪除'**
  String get detailMissing;

  /// No description provided for @detailRecorded.
  ///
  /// In zh, this message translates to:
  /// **'建立紀錄'**
  String get detailRecorded;

  /// No description provided for @detailReflections.
  ///
  /// In zh, this message translates to:
  /// **'日後回顧'**
  String get detailReflections;

  /// No description provided for @detailAddReflection.
  ///
  /// In zh, this message translates to:
  /// **'新增回顧'**
  String get detailAddReflection;

  /// No description provided for @detailSaveReflection.
  ///
  /// In zh, this message translates to:
  /// **'儲存回顧'**
  String get detailSaveReflection;

  /// No description provided for @detailAuthorSelf.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get detailAuthorSelf;

  /// No description provided for @detailReflectionYear.
  ///
  /// In zh, this message translates to:
  /// **'{year} 年追記'**
  String detailReflectionYear(String year);

  /// No description provided for @detailMedia.
  ///
  /// In zh, this message translates to:
  /// **'附件'**
  String get detailMedia;

  /// No description provided for @detailOpen.
  ///
  /// In zh, this message translates to:
  /// **'開啟附件'**
  String get detailOpen;

  /// No description provided for @detailRemoveAttachment.
  ///
  /// In zh, this message translates to:
  /// **'移除附件關聯'**
  String get detailRemoveAttachment;

  /// No description provided for @detailRemembrance.
  ///
  /// In zh, this message translates to:
  /// **'後續追憶'**
  String get detailRemembrance;

  /// No description provided for @attachmentPlan.
  ///
  /// In zh, this message translates to:
  /// **'完整複製匯入'**
  String get attachmentPlan;

  /// No description provided for @attachmentPlanBody.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 個檔案\n原檔總大小：{size}\n預估新增容量：{added}\n可用空間：{free}\n相同副本：{duplicates} 個\n原檔會保留。任一檔案失敗，整批取消，可重新匯入。'**
  String attachmentPlanBody(
    int count,
    String size,
    String added,
    String free,
    int duplicates,
  );

  /// No description provided for @attachmentImport.
  ///
  /// In zh, this message translates to:
  /// **'匯入附件'**
  String get attachmentImport;

  /// No description provided for @attachmentError.
  ///
  /// In zh, this message translates to:
  /// **'匯入失敗，整批未保存，原檔保留。請重試。'**
  String get attachmentError;

  /// No description provided for @attachmentNoSpace.
  ///
  /// In zh, this message translates to:
  /// **'可用空間不足，未匯入任何附件'**
  String get attachmentNoSpace;

  /// No description provided for @attachmentCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消匯入'**
  String get attachmentCancel;

  /// No description provided for @attachmentProgress.
  ///
  /// In zh, this message translates to:
  /// **'已處理 {done}／{total} 位元組'**
  String attachmentProgress(int done, int total);

  /// No description provided for @attachmentUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'附件無法開啟，請確認檔案完整或選擇支援的 APP'**
  String get attachmentUnavailable;

  /// No description provided for @attachmentWarehouse.
  ///
  /// In zh, this message translates to:
  /// **'附件倉庫'**
  String get attachmentWarehouse;

  /// No description provided for @attachmentUnreferenced.
  ///
  /// In zh, this message translates to:
  /// **'待清理副本'**
  String get attachmentUnreferenced;

  /// No description provided for @attachmentClean.
  ///
  /// In zh, this message translates to:
  /// **'永久清理副本'**
  String get attachmentClean;

  /// No description provided for @attachmentCleanConfirm.
  ///
  /// In zh, this message translates to:
  /// **'只清理沒有引用的 APP 副本，原檔不會刪除。共 {size}，要永久清理？'**
  String attachmentCleanConfirm(String size);

  /// No description provided for @attachmentEmpty.
  ///
  /// In zh, this message translates to:
  /// **'沒有待清理的副本'**
  String get attachmentEmpty;

  /// No description provided for @searchQuery.
  ///
  /// In zh, this message translates to:
  /// **'搜尋標題、記述、人物、地點、標籤或附件'**
  String get searchQuery;

  /// No description provided for @searchFrom.
  ///
  /// In zh, this message translates to:
  /// **'起始年份（選填）'**
  String get searchFrom;

  /// No description provided for @searchTo.
  ///
  /// In zh, this message translates to:
  /// **'結束年份（選填）'**
  String get searchTo;

  /// No description provided for @searchAction.
  ///
  /// In zh, this message translates to:
  /// **'搜尋'**
  String get searchAction;

  /// No description provided for @searchNoResults.
  ///
  /// In zh, this message translates to:
  /// **'沒有符合的事件'**
  String get searchNoResults;

  /// No description provided for @searchInvalid.
  ///
  /// In zh, this message translates to:
  /// **'年份須為 1～9999，起始年份不可晚於結束年份'**
  String get searchInvalid;

  /// No description provided for @searchPrivate.
  ///
  /// In zh, this message translates to:
  /// **'私密事件'**
  String get searchPrivate;

  /// No description provided for @detailPlaceLabel.
  ///
  /// In zh, this message translates to:
  /// **'地點：{place}'**
  String detailPlaceLabel(String place);

  /// No description provided for @editorTimeValue.
  ///
  /// In zh, this message translates to:
  /// **'何時發生: {time}'**
  String editorTimeValue(String time);

  /// No description provided for @detailSelectEvent.
  ///
  /// In zh, this message translates to:
  /// **'選取事件以閱讀紀事本末'**
  String get detailSelectEvent;

  /// No description provided for @recycleTitle.
  ///
  /// In zh, this message translates to:
  /// **'最近刪除'**
  String get recycleTitle;

  /// No description provided for @recycleEmpty.
  ///
  /// In zh, this message translates to:
  /// **'沒有已刪除的事件'**
  String get recycleEmpty;

  /// No description provided for @recycleRestore.
  ///
  /// In zh, this message translates to:
  /// **'復原事件'**
  String get recycleRestore;

  /// No description provided for @recyclePurge.
  ///
  /// In zh, this message translates to:
  /// **'永久刪除'**
  String get recyclePurge;

  /// No description provided for @recyclePurgeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'永久刪除事件內容與附件關聯，無法復原。附件原件不受影響；獨立副本可在附件倉庫清理。'**
  String get recyclePurgeConfirm;

  /// No description provided for @recyclePreserve.
  ///
  /// In zh, this message translates to:
  /// **'將保留標題，追憶內容不受影響。'**
  String get recyclePreserve;

  /// No description provided for @recycleDelete.
  ///
  /// In zh, this message translates to:
  /// **'移到最近刪除'**
  String get recycleDelete;

  /// No description provided for @recycleUndo.
  ///
  /// In zh, this message translates to:
  /// **'復原'**
  String get recycleUndo;

  /// No description provided for @recycleView.
  ///
  /// In zh, this message translates to:
  /// **'查看保留內容'**
  String get recycleView;

  /// No description provided for @recycleDeletedTitle.
  ///
  /// In zh, this message translates to:
  /// **'原事件「{title}」已刪除'**
  String recycleDeletedTitle(String title);

  /// No description provided for @backupExport.
  ///
  /// In zh, this message translates to:
  /// **'匯出 ZIP 備份'**
  String get backupExport;

  /// No description provided for @backupImport.
  ///
  /// In zh, this message translates to:
  /// **'匯入與還原 ZIP'**
  String get backupImport;

  /// No description provided for @backupVerify.
  ///
  /// In zh, this message translates to:
  /// **'驗證既有備份'**
  String get backupVerify;

  /// No description provided for @backupMedia.
  ///
  /// In zh, this message translates to:
  /// **'包含影音原始副本'**
  String get backupMedia;

  /// No description provided for @backupScope.
  ///
  /// In zh, this message translates to:
  /// **'選擇備份範圍'**
  String get backupScope;

  /// No description provided for @backupPlan.
  ///
  /// In zh, this message translates to:
  /// **'預估需要：{required}\n可用空間：{free}\n事件：{count} 筆\n完成後可透過系統分享另存。'**
  String backupPlan(String required, String free, String count);

  /// No description provided for @backupProgress.
  ///
  /// In zh, this message translates to:
  /// **'正在處理及驗證封存'**
  String get backupProgress;

  /// No description provided for @backupShare.
  ///
  /// In zh, this message translates to:
  /// **'分享或另存 ZIP 與校驗旁檔'**
  String get backupShare;

  /// No description provided for @backupSuccess.
  ///
  /// In zh, this message translates to:
  /// **'備份完成，已重新開啟 ZIP 並逐檔驗證。'**
  String get backupSuccess;

  /// No description provided for @backupVerified.
  ///
  /// In zh, this message translates to:
  /// **'全部檔案驗證通過'**
  String get backupVerified;

  /// No description provided for @backupFailure.
  ///
  /// In zh, this message translates to:
  /// **'封存處理失敗，原有資料未改動。請檢查容量、格式或檔案完整性。'**
  String get backupFailure;

  /// No description provided for @backupLast.
  ///
  /// In zh, this message translates to:
  /// **'最近一次完成並驗證的備份'**
  String get backupLast;

  /// No description provided for @backupConflict.
  ///
  /// In zh, this message translates to:
  /// **'逐筆處理相同 ID 的差異'**
  String get backupConflict;

  /// No description provided for @backupKeep.
  ///
  /// In zh, this message translates to:
  /// **'保留目前資料'**
  String get backupKeep;

  /// No description provided for @backupUseArchive.
  ///
  /// In zh, this message translates to:
  /// **'使用封存內容'**
  String get backupUseArchive;

  /// No description provided for @backupRestoreConfirm.
  ///
  /// In zh, this message translates to:
  /// **'還原已驗證的封存內容？相同 ID 的資料依你的逐筆選擇處理。不含影音的項目會標示為不可用。'**
  String get backupRestoreConfirm;

  /// No description provided for @backupRestoreDone.
  ///
  /// In zh, this message translates to:
  /// **'還原核對報告'**
  String get backupRestoreDone;

  /// No description provided for @backupReport.
  ///
  /// In zh, this message translates to:
  /// **'新增：{inserted}\n替換：{replaced}\n略過：{skipped}\n刻意排除影音：{excluded}\n忽略額外檔案：{extras}'**
  String backupReport(
    String inserted,
    String replaced,
    String skipped,
    String excluded,
    String extras,
  );

  /// No description provided for @backupNewFormat.
  ///
  /// In zh, this message translates to:
  /// **'部分新格式資料無法辨識，僅還原已知欄位。'**
  String get backupNewFormat;

  /// No description provided for @backupReadme.
  ///
  /// In zh, this message translates to:
  /// **'# 人生編年史封存\n\n解壓縮全部檔案後，以瀏覽器開啟 index.html，或閱讀 markdown/timeline.md。媒體為原始副本，位於 media/。\n\ndata/ 內 JSON 是唯一權威資料，Markdown 與 HTML 是閱讀版本；修改閱讀版本不會被匯入。各資料表檔案的欄位規格見 schema/data.schema.json。時間 payload 保存原始精確度，sort_start 與 sort_end 只供排序。\n\n所有時間戳記含時區。SHA256SUMS.txt 記錄除自身外全部檔案的 SHA-256；ZIP 外旁檔可驗證整包。\n\n請將 ZIP 與旁檔另存至其他裝置；移除 APP 可能連同私有目錄中的備份一起刪除。\n'**
  String get backupReadme;

  /// No description provided for @archiveTimeLabel.
  ///
  /// In zh, this message translates to:
  /// **'時間'**
  String get archiveTimeLabel;

  /// No description provided for @archiveLayerLabel.
  ///
  /// In zh, this message translates to:
  /// **'紀錄層'**
  String get archiveLayerLabel;

  /// No description provided for @archiveAuthorLabel.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get archiveAuthorLabel;

  /// No description provided for @securityTitle.
  ///
  /// In zh, this message translates to:
  /// **'安全性'**
  String get securityTitle;

  /// No description provided for @securityUnlock.
  ///
  /// In zh, this message translates to:
  /// **'解鎖'**
  String get securityUnlock;

  /// No description provided for @securityPassword.
  ///
  /// In zh, this message translates to:
  /// **'APP 密碼或遺族密碼'**
  String get securityPassword;

  /// No description provided for @securityAppPassword.
  ///
  /// In zh, this message translates to:
  /// **'APP 密碼（至少六位英數字）'**
  String get securityAppPassword;

  /// No description provided for @securityNative.
  ///
  /// In zh, this message translates to:
  /// **'使用手機原生解鎖'**
  String get securityNative;

  /// No description provided for @securityReason.
  ///
  /// In zh, this message translates to:
  /// **'驗證身分以開啟人生編年史'**
  String get securityReason;

  /// No description provided for @securityPrivateEvent.
  ///
  /// In zh, this message translates to:
  /// **'私密事件'**
  String get securityPrivateEvent;

  /// No description provided for @securityPrivateUnlock.
  ///
  /// In zh, this message translates to:
  /// **'驗證以查看私密內容'**
  String get securityPrivateUnlock;

  /// No description provided for @securityFailed.
  ///
  /// In zh, this message translates to:
  /// **'驗證未完成，請檢查密碼或改用其他方式。'**
  String get securityFailed;

  /// No description provided for @securityPaused.
  ///
  /// In zh, this message translates to:
  /// **'連續輸錯，請等待 {seconds} 秒後再試。'**
  String securityPaused(String seconds);

  /// No description provided for @securityAppLock.
  ///
  /// In zh, this message translates to:
  /// **'APP 開啟鎖定'**
  String get securityAppLock;

  /// No description provided for @securityProtectPrivate.
  ///
  /// In zh, this message translates to:
  /// **'私密事件保護'**
  String get securityProtectPrivate;

  /// No description provided for @securityPasswordOnly.
  ///
  /// In zh, this message translates to:
  /// **'私密事件指定輸入 APP 密碼'**
  String get securityPasswordOnly;

  /// No description provided for @securityHidePreview.
  ///
  /// In zh, this message translates to:
  /// **'隱藏最近使用的 APP 預覽'**
  String get securityHidePreview;

  /// No description provided for @securityFamilyPrivate.
  ///
  /// In zh, this message translates to:
  /// **'允許遺族密碼開啟私密事件'**
  String get securityFamilyPrivate;

  /// No description provided for @securityTimeout.
  ///
  /// In zh, this message translates to:
  /// **'自動鎖定時間'**
  String get securityTimeout;

  /// No description provided for @securityImmediate.
  ///
  /// In zh, this message translates to:
  /// **'立即'**
  String get securityImmediate;

  /// No description provided for @securityMinute.
  ///
  /// In zh, this message translates to:
  /// **'1 分鐘'**
  String get securityMinute;

  /// No description provided for @securityFiveMinutes.
  ///
  /// In zh, this message translates to:
  /// **'5 分鐘'**
  String get securityFiveMinutes;

  /// No description provided for @securitySetup.
  ///
  /// In zh, this message translates to:
  /// **'設定 APP 密碼與備援代碼'**
  String get securitySetup;

  /// No description provided for @securityConsequences.
  ///
  /// In zh, this message translates to:
  /// **'忘記密碼時，先以手機原生解鎖重設；仍無法驗證時才使用復原碼。若兩者都無法使用，APP 無法找回密碼。復原碼供本人重設密碼，遺族密碼供家人開啟 APP；兩者用途不同。請保留外部 ZIP 備份，APP 鎖定不會保護已匯出的檔案。'**
  String get securityConsequences;

  /// No description provided for @securityRecovery.
  ///
  /// In zh, this message translates to:
  /// **'復原碼'**
  String get securityRecovery;

  /// No description provided for @securityFamily.
  ///
  /// In zh, this message translates to:
  /// **'遺族密碼'**
  String get securityFamily;

  /// No description provided for @securityCopyConfirm.
  ///
  /// In zh, this message translates to:
  /// **'我已抄寫並安全保存顯示的代碼'**
  String get securityCopyConfirm;

  /// No description provided for @securitySave.
  ///
  /// In zh, this message translates to:
  /// **'儲存安全性設定'**
  String get securitySave;

  /// No description provided for @securityForgot.
  ///
  /// In zh, this message translates to:
  /// **'忘記 APP 密碼'**
  String get securityForgot;

  /// No description provided for @securityReset.
  ///
  /// In zh, this message translates to:
  /// **'重設 APP 密碼'**
  String get securityReset;

  /// No description provided for @securityRegenerateRecovery.
  ///
  /// In zh, this message translates to:
  /// **'重新產生復原碼（舊碼將失效）'**
  String get securityRegenerateRecovery;

  /// No description provided for @securityRegenerateFamily.
  ///
  /// In zh, this message translates to:
  /// **'重新產生遺族密碼（舊碼將失效）'**
  String get securityRegenerateFamily;

  /// No description provided for @securityFamilyDenied.
  ///
  /// In zh, this message translates to:
  /// **'遺族模式無法查看或變更安全性設定；私密內容依本人設定提供。'**
  String get securityFamilyDenied;

  /// No description provided for @securityFamilyName.
  ///
  /// In zh, this message translates to:
  /// **'家屬'**
  String get securityFamilyName;

  /// No description provided for @securityLockNow.
  ///
  /// In zh, this message translates to:
  /// **'立即鎖定'**
  String get securityLockNow;

  /// No description provided for @securityStorageError.
  ///
  /// In zh, this message translates to:
  /// **'無法讀取安全性設定。請重試；完成驗證前不顯示內容。'**
  String get securityStorageError;

  /// No description provided for @locationCurrent.
  ///
  /// In zh, this message translates to:
  /// **'使用目前位置'**
  String get locationCurrent;

  /// No description provided for @locationMapPick.
  ///
  /// In zh, this message translates to:
  /// **'在地圖釘選位置'**
  String get locationMapPick;

  /// No description provided for @locationRadius.
  ///
  /// In zh, this message translates to:
  /// **'範圍半徑（公尺，可留空）'**
  String get locationRadius;

  /// No description provided for @locationInvalid.
  ///
  /// In zh, this message translates to:
  /// **'請輸入有效座標與大於零的範圍半徑'**
  String get locationInvalid;

  /// No description provided for @locationUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'無法取得位置或開啟地圖。可繼續使用文字地點。'**
  String get locationUnavailable;

  /// No description provided for @locationCoordinates.
  ///
  /// In zh, this message translates to:
  /// **'緯度：{latitude}　經度：{longitude}'**
  String locationCoordinates(String latitude, String longitude);

  /// No description provided for @locationDragPin.
  ///
  /// In zh, this message translates to:
  /// **'拖曳釘選點調整位置，或點擊地圖選點'**
  String get locationDragPin;

  /// No description provided for @locationOffline.
  ///
  /// In zh, this message translates to:
  /// **'地圖圖資需要網路。目前仍可用文字地點或目前位置儲存。'**
  String get locationOffline;

  /// No description provided for @locationOpenMap.
  ///
  /// In zh, this message translates to:
  /// **'以手機地圖 APP 開啟'**
  String get locationOpenMap;

  /// No description provided for @locationSave.
  ///
  /// In zh, this message translates to:
  /// **'使用這個位置'**
  String get locationSave;

  /// No description provided for @locationOsmAttribution.
  ///
  /// In zh, this message translates to:
  /// **'© OpenStreetMap 貢獻者'**
  String get locationOsmAttribution;

  /// No description provided for @locationOsmCopyright.
  ///
  /// In zh, this message translates to:
  /// **'OpenStreetMap 著作權資訊'**
  String get locationOsmCopyright;

  /// No description provided for @locationPhotoSuggestion.
  ///
  /// In zh, this message translates to:
  /// **'照片含拍攝座標，是否用作事件地點？'**
  String get locationPhotoSuggestion;

  /// No description provided for @locationUsePhoto.
  ///
  /// In zh, this message translates to:
  /// **'使用照片拍攝位置'**
  String get locationUsePhoto;

  /// No description provided for @locationAwaitGps.
  ///
  /// In zh, this message translates to:
  /// **'正在取得 GPS 位置，可繼續填寫其他欄位'**
  String get locationAwaitGps;

  /// No description provided for @mdBold.
  ///
  /// In zh, this message translates to:
  /// **'粗體'**
  String get mdBold;

  /// No description provided for @mdItalic.
  ///
  /// In zh, this message translates to:
  /// **'斜體'**
  String get mdItalic;

  /// No description provided for @mdPreview.
  ///
  /// In zh, this message translates to:
  /// **'預覽'**
  String get mdPreview;

  /// No description provided for @mdEdit.
  ///
  /// In zh, this message translates to:
  /// **'編輯原文'**
  String get mdEdit;

  /// No description provided for @mdEmptyPreview.
  ///
  /// In zh, this message translates to:
  /// **'先輸入記述，再查看預覽。'**
  String get mdEmptyPreview;

  /// No description provided for @mdHint.
  ///
  /// In zh, this message translates to:
  /// **'支援 Markdown：粗體、表格、清單、引用與程式碼；emoji 請使用手機鍵盤。'**
  String get mdHint;

  /// No description provided for @mdAttachmentImage.
  ///
  /// In zh, this message translates to:
  /// **'圖片請使用附件加入'**
  String get mdAttachmentImage;

  /// No description provided for @mdLinkCopied.
  ///
  /// In zh, this message translates to:
  /// **'已複製連結'**
  String get mdLinkCopied;

  /// No description provided for @mdTable.
  ///
  /// In zh, this message translates to:
  /// **'插入表格'**
  String get mdTable;

  /// No description provided for @mdTableTemplate.
  ///
  /// In zh, this message translates to:
  /// **'| 欄位一 | 欄位二 |\n| --- | --- |\n| 內容 | 內容 |'**
  String get mdTableTemplate;

  /// No description provided for @displaySettings.
  ///
  /// In zh, this message translates to:
  /// **'設定'**
  String get displaySettings;

  /// No description provided for @timeZoneSetting.
  ///
  /// In zh, this message translates to:
  /// **'時間顯示與時區'**
  String get timeZoneSetting;

  /// No description provided for @timeZoneHelp.
  ///
  /// In zh, this message translates to:
  /// **'選擇建立紀錄、回顧、附件與刪除時間的顯示時區。事件發生日期與模糊時間不會改變。'**
  String get timeZoneHelp;

  /// No description provided for @timestampPattern.
  ///
  /// In zh, this message translates to:
  /// **'y 年 M 月 d 日 ah:mm'**
  String get timestampPattern;

  /// No description provided for @zoneSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟隨手機時區'**
  String get zoneSystem;

  /// No description provided for @zoneTaipei.
  ///
  /// In zh, this message translates to:
  /// **'台北'**
  String get zoneTaipei;

  /// No description provided for @zoneTokyo.
  ///
  /// In zh, this message translates to:
  /// **'東京'**
  String get zoneTokyo;

  /// No description provided for @zoneShanghai.
  ///
  /// In zh, this message translates to:
  /// **'上海'**
  String get zoneShanghai;

  /// No description provided for @zoneHongKong.
  ///
  /// In zh, this message translates to:
  /// **'香港'**
  String get zoneHongKong;

  /// No description provided for @zoneSingapore.
  ///
  /// In zh, this message translates to:
  /// **'新加坡'**
  String get zoneSingapore;

  /// No description provided for @zoneSydney.
  ///
  /// In zh, this message translates to:
  /// **'雪梨'**
  String get zoneSydney;

  /// No description provided for @zoneLondon.
  ///
  /// In zh, this message translates to:
  /// **'倫敦'**
  String get zoneLondon;

  /// No description provided for @zoneParis.
  ///
  /// In zh, this message translates to:
  /// **'巴黎'**
  String get zoneParis;

  /// No description provided for @zoneNewYork.
  ///
  /// In zh, this message translates to:
  /// **'紐約'**
  String get zoneNewYork;

  /// No description provided for @zoneLosAngeles.
  ///
  /// In zh, this message translates to:
  /// **'洛杉磯'**
  String get zoneLosAngeles;

  /// No description provided for @zoneUtc.
  ///
  /// In zh, this message translates to:
  /// **'世界標準時間（UTC）'**
  String get zoneUtc;

  /// No description provided for @mdHeading.
  ///
  /// In zh, this message translates to:
  /// **'標題層級'**
  String get mdHeading;

  /// No description provided for @mdHeadingLevel.
  ///
  /// In zh, this message translates to:
  /// **'{level} 級標題'**
  String mdHeadingLevel(int level);

  /// No description provided for @mdBullets.
  ///
  /// In zh, this message translates to:
  /// **'項目符號清單'**
  String get mdBullets;

  /// No description provided for @mdNumbers.
  ///
  /// In zh, this message translates to:
  /// **'編號清單'**
  String get mdNumbers;

  /// No description provided for @mdIndent.
  ///
  /// In zh, this message translates to:
  /// **'增加縮排（巢狀清單）'**
  String get mdIndent;

  /// No description provided for @mdOutdent.
  ///
  /// In zh, this message translates to:
  /// **'減少縮排'**
  String get mdOutdent;

  /// No description provided for @mdCode.
  ///
  /// In zh, this message translates to:
  /// **'行內程式碼'**
  String get mdCode;

  /// No description provided for @mdLink.
  ///
  /// In zh, this message translates to:
  /// **'插入連結'**
  String get mdLink;

  /// No description provided for @mdLinkText.
  ///
  /// In zh, this message translates to:
  /// **'連結文字'**
  String get mdLinkText;

  /// No description provided for @mdLinkUrl.
  ///
  /// In zh, this message translates to:
  /// **'網址（https://）'**
  String get mdLinkUrl;

  /// No description provided for @mdLinkInvalid.
  ///
  /// In zh, this message translates to:
  /// **'請填寫連結文字及有效的 http 或 https 網址。'**
  String get mdLinkInvalid;

  /// No description provided for @mdInsert.
  ///
  /// In zh, this message translates to:
  /// **'插入'**
  String get mdInsert;

  /// No description provided for @pickerChooseYear.
  ///
  /// In zh, this message translates to:
  /// **'選擇年份'**
  String get pickerChooseYear;

  /// No description provided for @pickerChooseDate.
  ///
  /// In zh, this message translates to:
  /// **'選擇日期'**
  String get pickerChooseDate;

  /// No description provided for @elapsedToday.
  ///
  /// In zh, this message translates to:
  /// **'今天'**
  String get elapsedToday;

  /// No description provided for @elapsedThisMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get elapsedThisMonth;

  /// No description provided for @elapsedThisYear.
  ///
  /// In zh, this message translates to:
  /// **'今年'**
  String get elapsedThisYear;

  /// No description provided for @elapsedIncludesToday.
  ///
  /// In zh, this message translates to:
  /// **'期間包含今天'**
  String get elapsedIncludesToday;

  /// No description provided for @elapsedUnknown.
  ///
  /// In zh, this message translates to:
  /// **'距今時間未定'**
  String get elapsedUnknown;

  /// No description provided for @elapsedRange.
  ///
  /// In zh, this message translates to:
  /// **'{start}～{end}'**
  String elapsedRange(int start, int end);

  /// No description provided for @elapsedApprox.
  ///
  /// In zh, this message translates to:
  /// **'約{text}'**
  String elapsedApprox(String text);

  /// No description provided for @elapsedDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天前'**
  String elapsedDaysAgo(String count);

  /// No description provided for @elapsedMonthsAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 個月前'**
  String elapsedMonthsAgo(String count);

  /// No description provided for @elapsedYearsAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 年前'**
  String elapsedYearsAgo(String count);

  /// No description provided for @elapsedDaysFuture.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天後'**
  String elapsedDaysFuture(String count);

  /// No description provided for @elapsedMonthsFuture.
  ///
  /// In zh, this message translates to:
  /// **'{count} 個月後'**
  String elapsedMonthsFuture(String count);

  /// No description provided for @elapsedYearsFuture.
  ///
  /// In zh, this message translates to:
  /// **'{count} 年後'**
  String elapsedYearsFuture(String count);

  /// No description provided for @restoreIntro.
  ///
  /// In zh, this message translates to:
  /// **'選取 ZIP 後會先驗證並列出差異。確認還原前不會修改原有資料。'**
  String get restoreIntro;

  /// No description provided for @restoreSelect.
  ///
  /// In zh, this message translates to:
  /// **'選取 ZIP 備份'**
  String get restoreSelect;

  /// No description provided for @restorePreview.
  ///
  /// In zh, this message translates to:
  /// **'還原預覽'**
  String get restorePreview;

  /// No description provided for @restoreApply.
  ///
  /// In zh, this message translates to:
  /// **'確認還原'**
  String get restoreApply;

  /// No description provided for @restoreChooseAll.
  ///
  /// In zh, this message translates to:
  /// **'有差異的項目須逐筆選擇，未選完不能還原。'**
  String get restoreChooseAll;

  /// No description provided for @restoreDifferentSubject.
  ///
  /// In zh, this message translates to:
  /// **'此備份屬於不同主角。已有資料的生命檔案不能合併其他主角；請在尚未填寫資料的空白 APP 還原。原有資料未改動。'**
  String get restoreDifferentSubject;

  /// No description provided for @restoreInvalidSubject.
  ///
  /// In zh, this message translates to:
  /// **'備份的主角、本人作者或典藏設定不符合單一主角格式，無法還原。'**
  String get restoreInvalidSubject;

  /// No description provided for @restoreChanged.
  ///
  /// In zh, this message translates to:
  /// **'預覽後原有資料已變更。請重新選取備份、核對差異後再還原。'**
  String get restoreChanged;

  /// No description provided for @restoreCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消還原，原有資料未改動。'**
  String get restoreCancelled;

  /// No description provided for @restoreExcluded.
  ///
  /// In zh, this message translates to:
  /// **'此備份刻意排除部分影音，還原後這些附件可能無法開啟。'**
  String get restoreExcluded;

  /// No description provided for @restoreExtraFiles.
  ///
  /// In zh, this message translates to:
  /// **'下列額外檔案會忽略，不會匯入：'**
  String get restoreExtraFiles;

  /// No description provided for @restoreEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未填寫'**
  String get restoreEmpty;

  /// No description provided for @restoreYes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get restoreYes;

  /// No description provided for @restoreNo.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get restoreNo;

  /// No description provided for @restoreLocalValue.
  ///
  /// In zh, this message translates to:
  /// **'目前：{value}'**
  String restoreLocalValue(String value);

  /// No description provided for @restoreArchiveValue.
  ///
  /// In zh, this message translates to:
  /// **'備份：{value}'**
  String restoreArchiveValue(String value);

  /// No description provided for @restoreCount.
  ///
  /// In zh, this message translates to:
  /// **'{name}：{count} 筆'**
  String restoreCount(String name, int count);

  /// No description provided for @restoreConflictNumber.
  ///
  /// In zh, this message translates to:
  /// **'差異 {count} · {name}'**
  String restoreConflictNumber(String name, int count);

  /// No description provided for @restoreTable.
  ///
  /// In zh, this message translates to:
  /// **'{table, select, subjects{主角} authors{作者} archive_sessions{典藏期間} archive_settings{典藏設定} places{地點} people{人物} tags{標籤} events{事件} event_sections{記述段落} life_periods{人生階段} event_life_periods{人生階段連結} reflections{回顧} stories{篇章} story_events{篇章事件連結} blobs{影音副本} attachments{附件} event_tags{事件標籤} event_people{事件人物連結} event_links{關聯事件} change_history{修訂紀錄} other{其他資料}}'**
  String restoreTable(String table);

  /// No description provided for @restoreField.
  ///
  /// In zh, this message translates to:
  /// **'{field, select, display_name{名稱} birth_date{生日} death_date{逝世日期} title{標題} content_md{內容} time_payload{發生時間} category{類別} privacy{隱私} created_at{建立時間} updated_at{更新時間} recorded_at{記錄時間} deleted_at{刪除時間} purged_at{永久刪除時間} layer{紀錄層} author_id{作者} event_id{事件} subject_id{主角} place_id{地點} person_id{人物} tag_id{標籤} life_period_id{人生階段} story_id{篇章} blob_id{影音副本} event_a_id{關聯事件} event_b_id{關聯事件} archive_session_id{典藏期間} current_session_id{目前典藏期間} role{角色／用途} is_subject_self{本人作者} mode{典藏狀態} activated_at{啟用時間} deactivated_at{結束時間} activated_by{啟用作者} deactivated_by{結束作者} sort_start{排序區間起點} sort_end{排序區間終點} manual_order{手動排序} position{排列位置} suggestion_key{段落建議類型} type{類型} start_time{開始時間} end_time{結束時間} organization{組織} provenance{來源說明} sha256{檔案校驗值} byte_size{檔案大小} media_type{媒體類型} path{副本位置} verify_status{校驗狀態} original_filename{原始檔名} captured_at{拍攝時間} captured_latitude{拍攝緯度} captured_longitude{拍攝經度} imported_at{匯入時間} storage_mode{保存方式} name{名稱} name_key{名稱比對值} latitude{緯度} longitude{經度} radius_m{範圍半徑（公尺）} label{標籤} operation{操作} timestamp{記錄時間} entity_id{修訂對象} other{其他欄位}}'**
  String restoreField(String field);

  /// No description provided for @restoreMediaTotals.
  ///
  /// In zh, this message translates to:
  /// **'還原後附件：{count} 個；可用影音副本總容量：{size}（共用副本只計一次）'**
  String restoreMediaTotals(int count, String size);

  /// No description provided for @archiveCoordinates.
  ///
  /// In zh, this message translates to:
  /// **'座標（緯度、經度）'**
  String get archiveCoordinates;

  /// No description provided for @archiveRadius.
  ///
  /// In zh, this message translates to:
  /// **'範圍半徑（公尺）'**
  String get archiveRadius;

  /// No description provided for @archiveCaptured.
  ///
  /// In zh, this message translates to:
  /// **'拍攝時間'**
  String get archiveCaptured;

  /// No description provided for @archiveImported.
  ///
  /// In zh, this message translates to:
  /// **'匯入時間'**
  String get archiveImported;

  /// No description provided for @archiveFilename.
  ///
  /// In zh, this message translates to:
  /// **'原始檔名'**
  String get archiveFilename;

  /// No description provided for @archiveExcludedMedia.
  ///
  /// In zh, this message translates to:
  /// **'此副本未包含於備份中，無法從本封存開啟'**
  String get archiveExcludedMedia;

  /// No description provided for @archiveDeletedReference.
  ///
  /// In zh, this message translates to:
  /// **'原事件已刪除'**
  String get archiveDeletedReference;

  /// No description provided for @archivePeople.
  ///
  /// In zh, this message translates to:
  /// **'參與人物'**
  String get archivePeople;

  /// No description provided for @archiveTags.
  ///
  /// In zh, this message translates to:
  /// **'標籤'**
  String get archiveTags;

  /// No description provided for @archivePeriods.
  ///
  /// In zh, this message translates to:
  /// **'人生階段'**
  String get archivePeriods;

  /// No description provided for @restoreReuseId.
  ///
  /// In zh, this message translates to:
  /// **'同名資料將重用本機 ID。封存 ID：{sourceId}；本機 ID：{localId}。請選擇保留的內容；匯入引用會連到本機資料。'**
  String restoreReuseId(String sourceId, String localId);

  /// No description provided for @backupMediaNotice.
  ///
  /// In zh, this message translates to:
  /// **'取消勾選可排除個別影音副本。附件名稱等紀錄資料仍會保留；共用同一副本的附件會一起排除。'**
  String get backupMediaNotice;

  /// No description provided for @backupMediaSelection.
  ///
  /// In zh, this message translates to:
  /// **'選擇要包含的副本'**
  String get backupMediaSelection;

  /// No description provided for @backupNoMedia.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有影音副本。'**
  String get backupNoMedia;

  /// No description provided for @backupMediaDetails.
  ///
  /// In zh, this message translates to:
  /// **'{size} · {count} 個附件共用'**
  String backupMediaDetails(String size, int count);

  /// No description provided for @backupScopeSummary.
  ///
  /// In zh, this message translates to:
  /// **'範圍：{scope}；排除 {count} 個副本'**
  String backupScopeSummary(String scope, int count);

  /// No description provided for @backupScopeFull.
  ///
  /// In zh, this message translates to:
  /// **'完整備份'**
  String get backupScopeFull;

  /// No description provided for @backupScopeNoMedia.
  ///
  /// In zh, this message translates to:
  /// **'不含影音'**
  String get backupScopeNoMedia;

  /// No description provided for @backupScopeCustom.
  ///
  /// In zh, this message translates to:
  /// **'自訂匯出範圍'**
  String get backupScopeCustom;

  /// No description provided for @editorGroupBasics.
  ///
  /// In zh, this message translates to:
  /// **'事件資訊'**
  String get editorGroupBasics;

  /// No description provided for @editorGroupPeople.
  ///
  /// In zh, this message translates to:
  /// **'人物與標籤'**
  String get editorGroupPeople;

  /// No description provided for @editorGroupOptions.
  ///
  /// In zh, this message translates to:
  /// **'隱私與關聯'**
  String get editorGroupOptions;

  /// No description provided for @editorGroupNarrative.
  ///
  /// In zh, this message translates to:
  /// **'記述與附件'**
  String get editorGroupNarrative;

  /// No description provided for @storiesCreate.
  ///
  /// In zh, this message translates to:
  /// **'新增智慧主題'**
  String get storiesCreate;

  /// No description provided for @storiesEdit.
  ///
  /// In zh, this message translates to:
  /// **'編輯主題'**
  String get storiesEdit;

  /// No description provided for @storiesTitle.
  ///
  /// In zh, this message translates to:
  /// **'主題名稱'**
  String get storiesTitle;

  /// No description provided for @storiesEmpty.
  ///
  /// In zh, this message translates to:
  /// **'設定標籤組合，自動瀏覽相關事件。'**
  String get storiesEmpty;

  /// No description provided for @storiesEmptyEvents.
  ///
  /// In zh, this message translates to:
  /// **'目前沒有符合條件的事件。新增或調整事件標籤後，這裡會自動更新。'**
  String get storiesEmptyEvents;

  /// No description provided for @storiesEvents.
  ///
  /// In zh, this message translates to:
  /// **'符合條件的事件'**
  String get storiesEvents;

  /// No description provided for @storiesAddEvents.
  ///
  /// In zh, this message translates to:
  /// **'選擇事件'**
  String get storiesAddEvents;

  /// No description provided for @storiesRemoveEvent.
  ///
  /// In zh, this message translates to:
  /// **'移出篇章'**
  String get storiesRemoveEvent;

  /// No description provided for @storiesSave.
  ///
  /// In zh, this message translates to:
  /// **'儲存主題'**
  String get storiesSave;

  /// No description provided for @storiesDelete.
  ///
  /// In zh, this message translates to:
  /// **'刪除主題'**
  String get storiesDelete;

  /// No description provided for @storiesDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'刪除此主題？事件、標籤及附件都會保留。'**
  String get storiesDeleteConfirm;

  /// No description provided for @storiesError.
  ///
  /// In zh, this message translates to:
  /// **'無法儲存主題。請確認標籤仍存在，或目前是否允許修改。'**
  String get storiesError;

  /// No description provided for @storiesMissing.
  ///
  /// In zh, this message translates to:
  /// **'此主題已不存在。'**
  String get storiesMissing;

  /// No description provided for @storiesReadOnly.
  ///
  /// In zh, this message translates to:
  /// **'生命典藏期間，原始生命紀錄的主題設定唯讀。'**
  String get storiesReadOnly;

  /// No description provided for @storiesDeletedEvent.
  ///
  /// In zh, this message translates to:
  /// **'事件已移到最近刪除'**
  String get storiesDeletedEvent;

  /// No description provided for @storiesCount.
  ///
  /// In zh, this message translates to:
  /// **'符合 {count} 個事件'**
  String storiesCount(int count);

  /// No description provided for @themesMode.
  ///
  /// In zh, this message translates to:
  /// **'納入條件'**
  String get themesMode;

  /// No description provided for @themesAll.
  ///
  /// In zh, this message translates to:
  /// **'全部符合（AND）'**
  String get themesAll;

  /// No description provided for @themesAny.
  ///
  /// In zh, this message translates to:
  /// **'任一符合（OR）'**
  String get themesAny;

  /// No description provided for @themesInclude.
  ///
  /// In zh, this message translates to:
  /// **'納入標籤（至少一個）'**
  String get themesInclude;

  /// No description provided for @themesExclude.
  ///
  /// In zh, this message translates to:
  /// **'排除標籤（選填）'**
  String get themesExclude;

  /// No description provided for @themesAutoUpdate.
  ///
  /// In zh, this message translates to:
  /// **'符合標籤條件的事件會自動更新。排除條件優先生效；私密及最近刪除事件不納入。'**
  String get themesAutoUpdate;

  /// No description provided for @themesChooseTag.
  ///
  /// In zh, this message translates to:
  /// **'請至少選一個納入標籤。'**
  String get themesChooseTag;

  /// No description provided for @themesMissingTag.
  ///
  /// In zh, this message translates to:
  /// **'已移除的標籤'**
  String get themesMissingTag;

  /// No description provided for @themesSearchTags.
  ///
  /// In zh, this message translates to:
  /// **'搜尋標籤'**
  String get themesSearchTags;

  /// No description provided for @themesNoTags.
  ///
  /// In zh, this message translates to:
  /// **'先在事件加入標籤，再建立智慧主題。'**
  String get themesNoTags;

  /// No description provided for @themesLegacy.
  ///
  /// In zh, this message translates to:
  /// **'這是舊版手動篇章。設定標籤條件並儲存後，會改為智慧主題；原事件保留。'**
  String get themesLegacy;

  /// No description provided for @backupSplit.
  ///
  /// In zh, this message translates to:
  /// **'分包方式'**
  String get backupSplit;

  /// No description provided for @backupNoSplit.
  ///
  /// In zh, this message translates to:
  /// **'單一 ZIP（支援 ZIP64）'**
  String get backupNoSplit;

  /// No description provided for @backupPartLimit.
  ///
  /// In zh, this message translates to:
  /// **'每包最多 {size}'**
  String backupPartLimit(String size);

  /// No description provided for @backupSplitNotice.
  ///
  /// In zh, this message translates to:
  /// **'每個分包可獨立解壓。還原時請一次選取全部 ZIP；閱讀時請解壓到同一資料夾。單一附件不會切碎，超過上限時請調高上限或取消分包。'**
  String get backupSplitNotice;

  /// No description provided for @backupPartTooSmall.
  ///
  /// In zh, this message translates to:
  /// **'單一附件或第一包的文字資料超過分包上限。請調高每包上限、排除過大的附件，或改用單一 ZIP。'**
  String get backupPartTooSmall;

  /// No description provided for @backupMissingParts.
  ///
  /// In zh, this message translates to:
  /// **'分包不完整，尚缺：\n{names}\n請一次選取同一備份的全部 ZIP。原有資料未變更。'**
  String backupMissingParts(String names);

  /// No description provided for @backupPartCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 個 ZIP 分包；分享包含全部分包、校驗旁檔與大小／雜湊索引。'**
  String backupPartCount(int count);

  /// No description provided for @backupSplitReadme.
  ///
  /// In zh, this message translates to:
  /// **'\n## 分包使用方式\n\n若此備份包含多個 ZIP，每包都可獨立解壓；第一包包含全部文字、JSON 與 manifest，其餘包包含媒體。請保留全部 ZIP 與各自的 .sha256 旁檔；.parts.json 索引另記錄各包檔名、位元組大小與 SHA-256。離線閱讀時將各包解壓到同一資料夾，各包的 SHA256SUMS.txt 請分別驗證。APP 還原或驗證時一次選取全部 ZIP，順序不限；缺包時不會寫入資料。\n'**
  String get backupSplitReadme;

  /// No description provided for @backupExcludePrivate.
  ///
  /// In zh, this message translates to:
  /// **'排除私密事件'**
  String get backupExcludePrivate;

  /// No description provided for @backupExcludePrivateNotice.
  ///
  /// In zh, this message translates to:
  /// **'不匯出私密事件、記述、追憶、標題快照及專屬附件。共用附件、獨立人物／地點／標籤與未引用的倉庫副本仍依原選擇保留；不會修改手機資料。'**
  String get backupExcludePrivateNotice;

  /// No description provided for @backupPrivateMediaExcluded.
  ///
  /// In zh, this message translates to:
  /// **'僅供私密事件使用，會自動排除'**
  String get backupPrivateMediaExcluded;

  /// No description provided for @backupPrivateExcluded.
  ///
  /// In zh, this message translates to:
  /// **'已刻意排除 {events} 筆私密事件及 {media} 份專屬媒體副本；不會還原這些內容。'**
  String backupPrivateExcluded(int events, int media);

  /// No description provided for @editorBodyLabel.
  ///
  /// In zh, this message translates to:
  /// **'內文'**
  String get editorBodyLabel;

  /// No description provided for @editorBodyHint.
  ///
  /// In zh, this message translates to:
  /// **'從這裡開始寫下發生的事、當時的感受或想留下的話……'**
  String get editorBodyHint;

  /// No description provided for @editorSectionHint.
  ///
  /// In zh, this message translates to:
  /// **'例如：第一次見面的那一天（可以留空）'**
  String get editorSectionHint;

  /// No description provided for @editorDragSection.
  ///
  /// In zh, this message translates to:
  /// **'拖曳調整段落順序'**
  String get editorDragSection;

  /// No description provided for @editorDragSectionNumber.
  ///
  /// In zh, this message translates to:
  /// **'拖曳第 {number} 段以調整順序'**
  String editorDragSectionNumber(int number);
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
