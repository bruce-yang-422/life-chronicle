import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'home_shell.dart';
import 'theme.dart';

/// 繁體中文（臺灣）。需指定 Hant 字體腳本，Material 元件才會使用繁體中文。
const zhHantLocale = Locale.fromSubtags(
  languageCode: 'zh',
  scriptCode: 'Hant',
  countryCode: 'TW',
);

/// 英文。
const enLocale = Locale('en');

/// 第一階段支援的語系（企劃書 4.7）。
const appSupportedLocales = [zhHantLocale, enLocale];

/// 依系統偏好語言決定 APP 語系（企劃書 4.7）。
///
/// 依序檢查系統偏好語言：中文（任何字體）→ 繁體中文；英文 → 英文。
/// 都不符合時使用英文。第二階段加入簡體中文、日文、韓文時於此擴充。
Locale resolveAppLocale(List<Locale>? preferred) {
  for (final locale in preferred ?? const <Locale>[]) {
    switch (locale.languageCode) {
      case 'zh':
        return zhHantLocale;
      case 'en':
        return enLocale;
    }
  }
  return enLocale;
}

class LifeChronicleApp extends StatelessWidget {
  const LifeChronicleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // 淺色／深色跟隨系統設定（企劃書 4.4）
      themeMode: ThemeMode.system,
      supportedLocales: appSupportedLocales,
      localeListResolutionCallback: (preferred, _) =>
          resolveAppLocale(preferred),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}
