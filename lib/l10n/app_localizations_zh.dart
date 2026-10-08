// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

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
}
