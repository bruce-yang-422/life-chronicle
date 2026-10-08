import 'package:flutter/material.dart';

/// 間距單位（企劃書 4.4：8dp 間距網格）。
abstract final class AppSpacing {
  static const double unit = 8;
  static const double xs = unit / 2;
  static const double sm = unit;
  static const double md = unit * 2;
  static const double lg = unit * 3;
  static const double xl = unit * 4;
}

/// 圓角尺寸。
abstract final class AppRadius {
  static const double card = 16;
  static const double control = 12;
}

/// 全 APP 主題（企劃書 4.4）：一組主色加中性色、統一圓角卡片，淺色與深色兩套。
abstract final class AppTheme {
  /// 主色：沉靜的墨綠色，呼應「值得珍藏」的氛圍。
  static const Color seedColor = Color(0xFF2F6B66);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      // 觸控目標至少 48dp（企劃書 4.3）
      materialTapTargetSize: MaterialTapTargetSize.padded,
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: colorScheme.secondaryContainer,
      ),
    );
  }
}
