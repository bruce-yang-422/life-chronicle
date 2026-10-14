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

  @override
  String get editorName => '事件名稱';

  @override
  String get editorWhen => '何時發生';

  @override
  String get editorNarrative => '記述';

  @override
  String get editorAttachments => '加入附件';

  @override
  String get editorAdvanced => '進階編輯';

  @override
  String get editorSave => '儲存事件';

  @override
  String get editorEdit => '編輯事件';

  @override
  String get editorRequired => '請輸入事件名稱';

  @override
  String get editorError => '無法儲存，草稿已保留。請重試。';

  @override
  String get editorDraftError => '草稿無法讀取或保存，請重試。';

  @override
  String get editorRestored => '已恢復尚未儲存的草稿';

  @override
  String get editorDiscard => '捨棄草稿';

  @override
  String get editorDiscardConfirm => '捨棄尚未儲存的內容？';

  @override
  String get editorCategory => '類別';

  @override
  String get editorPlace => '地點';

  @override
  String get editorPeople => '參與人物';

  @override
  String get editorAddPerson => '加入人物';

  @override
  String get editorTags => '標籤（以逗號分隔）';

  @override
  String get editorPrivacy => '隱私層級';

  @override
  String get editorNormal => '一般';

  @override
  String get editorPrivate => '私密';

  @override
  String get editorRelated => '關聯事件';

  @override
  String get editorAddSection => '新增段落';

  @override
  String get editorSectionTitle => '段落標題（選填）';

  @override
  String get editorRemoveSection => '刪除段落';

  @override
  String get editorMoveUp => '上移';

  @override
  String get editorMoveDown => '下移';

  @override
  String get editorCustomSection => '自訂標題';

  @override
  String get sectionCause => '起因';

  @override
  String get sectionProcess => '經過';

  @override
  String get sectionResult => '結果';

  @override
  String get sectionFeeling => '當時感受';

  @override
  String get sectionDifficulty => '困難';

  @override
  String get sectionInsight => '領悟';

  @override
  String get sectionPeople => '相關人物';

  @override
  String get sectionScene => '場景與畫面';

  @override
  String get sectionWords => '印象深刻的話';

  @override
  String get pickerPrecision => '時間精確度';

  @override
  String get pickerYear => '年份';

  @override
  String get pickerHalf => '半年';

  @override
  String get pickerQuarter => '季度';

  @override
  String get pickerMonth => '月份';

  @override
  String get pickerDay => '日期';

  @override
  String get pickerApprox => '約略年份';

  @override
  String get pickerRange => '時間範圍';

  @override
  String get pickerRelative => '相對事件';

  @override
  String get pickerAge => '年齡推估';

  @override
  String get pickerUnknown => '時間未定';

  @override
  String get pickerStart => '起點';

  @override
  String get pickerEnd => '終點';

  @override
  String get pickerBefore => '之前';

  @override
  String get pickerAfter => '之後';

  @override
  String get pickerDuring => '期間';

  @override
  String get pickerInvalid => '請檢查時間輸入及起訖順序';

  @override
  String get pickerApply => '套用時間';

  @override
  String get detailMissing => '事件不存在或已刪除';

  @override
  String get detailRecorded => '建立紀錄';

  @override
  String get detailReflections => '日後回顧';

  @override
  String get detailAddReflection => '新增回顧';

  @override
  String get detailSaveReflection => '儲存回顧';

  @override
  String get detailAuthorSelf => '我';

  @override
  String detailReflectionYear(String year) {
    return '$year 年追記';
  }

  @override
  String get detailMedia => '附件';

  @override
  String get detailOpen => '開啟附件';

  @override
  String get detailRemoveAttachment => '移除附件關聯';

  @override
  String get detailRemembrance => '後續追憶';

  @override
  String get attachmentPlan => '完整複製匯入';

  @override
  String attachmentPlanBody(
    int count,
    String size,
    String added,
    String free,
    int duplicates,
  ) {
    return '共 $count 個檔案\n原檔總大小：$size\n預估新增容量：$added\n可用空間：$free\n相同副本：$duplicates 個\n原檔會保留。任一檔案失敗，整批取消，可重新匯入。';
  }

  @override
  String get attachmentImport => '匯入附件';

  @override
  String get attachmentError => '匯入失敗，整批未保存，原檔保留。請重試。';

  @override
  String get attachmentNoSpace => '可用空間不足，未匯入任何附件';

  @override
  String get attachmentCancel => '取消匯入';

  @override
  String attachmentProgress(int done, int total) {
    return '已處理 $done／$total 位元組';
  }

  @override
  String get attachmentUnavailable => '附件無法開啟，請確認檔案完整或選擇支援的 APP';

  @override
  String get attachmentWarehouse => '附件倉庫';

  @override
  String get attachmentUnreferenced => '待清理副本';

  @override
  String get attachmentClean => '永久清理副本';

  @override
  String attachmentCleanConfirm(String size) {
    return '只清理沒有引用的 APP 副本，原檔不會刪除。共 $size，要永久清理？';
  }

  @override
  String get attachmentEmpty => '沒有待清理的副本';

  @override
  String get searchQuery => '搜尋標題、記述、人物、地點、標籤或附件';

  @override
  String get searchFrom => '起始年份（選填）';

  @override
  String get searchTo => '結束年份（選填）';

  @override
  String get searchAction => '搜尋';

  @override
  String get searchNoResults => '沒有符合的事件';

  @override
  String get searchInvalid => '年份須為 1～9999，起始年份不可晚於結束年份';

  @override
  String get searchPrivate => '私密事件';

  @override
  String detailPlaceLabel(String place) {
    return '地點：$place';
  }

  @override
  String editorTimeValue(String time) {
    return '何時發生: $time';
  }

  @override
  String get detailSelectEvent => '選取事件以閱讀紀事本末';

  @override
  String get recycleTitle => '最近刪除';

  @override
  String get recycleEmpty => '沒有已刪除的事件';

  @override
  String get recycleRestore => '復原事件';

  @override
  String get recyclePurge => '永久刪除';

  @override
  String get recyclePurgeConfirm => '永久刪除事件內容與附件關聯，無法復原。附件原件不受影響；獨立副本可在附件倉庫清理。';

  @override
  String get recyclePreserve => '將保留標題，追憶內容不受影響。';

  @override
  String get recycleDelete => '移到最近刪除';

  @override
  String get recycleUndo => '復原';

  @override
  String get recycleView => '查看保留內容';

  @override
  String recycleDeletedTitle(String title) {
    return '原事件「$title」已刪除';
  }

  @override
  String get backupExport => '匯出 ZIP 備份';

  @override
  String get backupImport => '匯入與還原 ZIP';

  @override
  String get backupVerify => '驗證既有備份';

  @override
  String get backupMedia => '包含影音原始副本';

  @override
  String get backupScope => '選擇備份範圍';

  @override
  String backupPlan(String required, String free, String count) {
    return '預估需要：$required\n可用空間：$free\n事件：$count 筆\n完成後可透過系統分享另存。';
  }

  @override
  String get backupProgress => '正在處理及驗證封存';

  @override
  String get backupShare => '分享或另存 ZIP 與校驗旁檔';

  @override
  String get backupSuccess => '備份完成，已重新開啟 ZIP 並逐檔驗證。';

  @override
  String get backupVerified => '全部檔案驗證通過';

  @override
  String get backupFailure => '封存處理失敗，原有資料未改動。請檢查容量、格式或檔案完整性。';

  @override
  String get backupLast => '最近一次完成並驗證的備份';

  @override
  String get backupConflict => '逐筆處理相同 ID 的差異';

  @override
  String get backupKeep => '保留目前資料';

  @override
  String get backupUseArchive => '使用封存內容';

  @override
  String get backupRestoreConfirm =>
      '還原已驗證的封存內容？相同 ID 的資料依你的逐筆選擇處理。不含影音的項目會標示為不可用。';

  @override
  String get backupRestoreDone => '還原核對報告';

  @override
  String backupReport(
    String inserted,
    String replaced,
    String skipped,
    String excluded,
    String extras,
  ) {
    return '新增：$inserted\n替換：$replaced\n略過：$skipped\n刻意排除影音：$excluded\n忽略額外檔案：$extras';
  }

  @override
  String get backupNewFormat => '部分新格式資料無法辨識，僅還原已知欄位。';

  @override
  String get backupReadme =>
      '# 人生編年史封存\n\n解壓縮全部檔案後，以瀏覽器開啟 index.html，或閱讀 markdown/timeline.md。媒體為原始副本，位於 media/。\n\ndata/ 內 JSON 是唯一權威資料，Markdown 與 HTML 是閱讀版本；修改閱讀版本不會被匯入。各資料表檔案的欄位規格見 schema/data.schema.json。時間 payload 保存原始精確度，sort_start 與 sort_end 只供排序。\n\n所有時間戳記含時區。SHA256SUMS.txt 記錄除自身外全部檔案的 SHA-256；ZIP 外旁檔可驗證整包。\n\n請將 ZIP 與旁檔另存至其他裝置；移除 APP 可能連同私有目錄中的備份一起刪除。\n';

  @override
  String get archiveTimeLabel => '時間';

  @override
  String get archiveLayerLabel => '紀錄層';

  @override
  String get archiveAuthorLabel => '作者';

  @override
  String get securityTitle => '安全性';

  @override
  String get securityUnlock => '解鎖';

  @override
  String get securityPassword => 'APP 密碼或遺族密碼';

  @override
  String get securityAppPassword => 'APP 密碼（至少六位英數字）';

  @override
  String get securityNative => '使用手機原生解鎖';

  @override
  String get securityReason => '驗證身分以開啟人生編年史';

  @override
  String get securityPrivateEvent => '私密事件';

  @override
  String get securityPrivateUnlock => '驗證以查看私密內容';

  @override
  String get securityFailed => '驗證未完成，請檢查密碼或改用其他方式。';

  @override
  String securityPaused(String seconds) {
    return '連續輸錯，請等待 $seconds 秒後再試。';
  }

  @override
  String get securityAppLock => 'APP 開啟鎖定';

  @override
  String get securityProtectPrivate => '私密事件保護';

  @override
  String get securityPasswordOnly => '私密事件指定輸入 APP 密碼';

  @override
  String get securityHidePreview => '隱藏最近使用的 APP 預覽';

  @override
  String get securityFamilyPrivate => '允許遺族密碼開啟私密事件';

  @override
  String get securityTimeout => '自動鎖定時間';

  @override
  String get securityImmediate => '立即';

  @override
  String get securityMinute => '1 分鐘';

  @override
  String get securityFiveMinutes => '5 分鐘';

  @override
  String get securitySetup => '設定 APP 密碼與備援代碼';

  @override
  String get securityConsequences =>
      '忘記密碼時，先以手機原生解鎖重設；仍無法驗證時才使用復原碼。若兩者都無法使用，APP 無法找回密碼。復原碼供本人重設密碼，遺族密碼供家人開啟 APP；兩者用途不同。請保留外部 ZIP 備份，APP 鎖定不會保護已匯出的檔案。';

  @override
  String get securityRecovery => '復原碼';

  @override
  String get securityFamily => '遺族密碼';

  @override
  String get securityCopyConfirm => '我已抄寫並安全保存顯示的代碼';

  @override
  String get securitySave => '儲存安全性設定';

  @override
  String get securityForgot => '忘記 APP 密碼';

  @override
  String get securityReset => '重設 APP 密碼';

  @override
  String get securityRegenerateRecovery => '重新產生復原碼（舊碼將失效）';

  @override
  String get securityRegenerateFamily => '重新產生遺族密碼（舊碼將失效）';

  @override
  String get securityFamilyDenied => '遺族模式無法查看或變更安全性設定；私密內容依本人設定提供。';

  @override
  String get securityFamilyName => '家屬';

  @override
  String get securityLockNow => '立即鎖定';

  @override
  String get securityStorageError => '無法讀取安全性設定。請重試；完成驗證前不顯示內容。';

  @override
  String get locationCurrent => '使用目前位置';

  @override
  String get locationMapPick => '在地圖釘選位置';

  @override
  String get locationRadius => '範圍半徑（公尺，可留空）';

  @override
  String get locationInvalid => '請輸入有效座標與大於零的範圍半徑';

  @override
  String get locationUnavailable => '無法取得位置或開啟地圖。可繼續使用文字地點。';

  @override
  String locationCoordinates(String latitude, String longitude) {
    return '緯度：$latitude　經度：$longitude';
  }

  @override
  String get locationDragPin => '拖曳釘選點調整位置，或點擊地圖選點';

  @override
  String get locationOffline => '地圖圖資需要網路。目前仍可用文字地點或目前位置儲存。';

  @override
  String get locationOpenMap => '以手機地圖 APP 開啟';

  @override
  String get locationSave => '使用這個位置';

  @override
  String get locationOsmAttribution => '© OpenStreetMap 貢獻者';

  @override
  String get locationOsmCopyright => 'OpenStreetMap 著作權資訊';

  @override
  String get locationPhotoSuggestion => '照片含拍攝座標，是否用作事件地點？';

  @override
  String get locationUsePhoto => '使用照片拍攝位置';

  @override
  String get locationAwaitGps => '正在取得 GPS 位置，可繼續填寫其他欄位';

  @override
  String get mdBold => '粗體';

  @override
  String get mdItalic => '斜體';

  @override
  String get mdPreview => '預覽';

  @override
  String get mdEdit => '編輯原文';

  @override
  String get mdEmptyPreview => '先輸入記述，再查看預覽。';

  @override
  String get mdHint => '支援 Markdown：粗體、表格、清單、引用與程式碼；emoji 請使用手機鍵盤。';

  @override
  String get mdAttachmentImage => '圖片請使用附件加入';

  @override
  String get mdLinkCopied => '已複製連結';

  @override
  String get mdTable => '插入表格';

  @override
  String get mdTableTemplate => '| 欄位一 | 欄位二 |\n| --- | --- |\n| 內容 | 內容 |';

  @override
  String get displaySettings => '設定';

  @override
  String get timeZoneSetting => '時間顯示與時區';

  @override
  String get timeZoneHelp => '選擇建立紀錄、回顧、附件與刪除時間的顯示時區。事件發生日期與模糊時間不會改變。';

  @override
  String get timestampPattern => 'y 年 M 月 d 日 ah:mm';

  @override
  String get zoneSystem => '跟隨手機時區';

  @override
  String get zoneTaipei => '台北';

  @override
  String get zoneTokyo => '東京';

  @override
  String get zoneShanghai => '上海';

  @override
  String get zoneHongKong => '香港';

  @override
  String get zoneSingapore => '新加坡';

  @override
  String get zoneSydney => '雪梨';

  @override
  String get zoneLondon => '倫敦';

  @override
  String get zoneParis => '巴黎';

  @override
  String get zoneNewYork => '紐約';

  @override
  String get zoneLosAngeles => '洛杉磯';

  @override
  String get zoneUtc => '世界標準時間（UTC）';

  @override
  String get mdHeading => '標題層級';

  @override
  String mdHeadingLevel(int level) {
    return '$level 級標題';
  }

  @override
  String get mdBullets => '項目符號清單';

  @override
  String get mdNumbers => '編號清單';

  @override
  String get mdIndent => '增加縮排（巢狀清單）';

  @override
  String get mdOutdent => '減少縮排';

  @override
  String get mdCode => '行內程式碼';

  @override
  String get mdLink => '插入連結';

  @override
  String get mdLinkText => '連結文字';

  @override
  String get mdLinkUrl => '網址（https://）';

  @override
  String get mdLinkInvalid => '請填寫連結文字及有效的 http 或 https 網址。';

  @override
  String get mdInsert => '插入';

  @override
  String get pickerChooseYear => '選擇年份';

  @override
  String get pickerChooseDate => '選擇日期';

  @override
  String get elapsedToday => '今天';

  @override
  String get elapsedThisMonth => '本月';

  @override
  String get elapsedThisYear => '今年';

  @override
  String get elapsedIncludesToday => '期間包含今天';

  @override
  String get elapsedUnknown => '距今時間未定';

  @override
  String elapsedRange(int start, int end) {
    return '$start～$end';
  }

  @override
  String elapsedApprox(String text) {
    return '約$text';
  }

  @override
  String elapsedDaysAgo(String count) {
    return '$count 天前';
  }

  @override
  String elapsedMonthsAgo(String count) {
    return '$count 個月前';
  }

  @override
  String elapsedYearsAgo(String count) {
    return '$count 年前';
  }

  @override
  String elapsedDaysFuture(String count) {
    return '$count 天後';
  }

  @override
  String elapsedMonthsFuture(String count) {
    return '$count 個月後';
  }

  @override
  String elapsedYearsFuture(String count) {
    return '$count 年後';
  }
}
