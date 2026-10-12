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
    final dark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFF9CCAC4) : const Color(0xFF326D71),
          onPrimary: dark ? const Color(0xFF163B3C) : Colors.white,
          surface: dark ? const Color(0xFF172223) : const Color(0xFFF5F7F6),
          surfaceContainerLow: dark ? const Color(0xFF202D2E) : Colors.white,
          surfaceContainer: dark
              ? const Color(0xFF253435)
              : const Color(0xFFEAF0EF),
          onSurface: dark ? const Color(0xFFE1EBE9) : const Color(0xFF1E3038),
          onSurfaceVariant: dark
              ? const Color(0xFFAFBFBD)
              : const Color(0xFF75828B),
          outlineVariant: dark
              ? const Color(0xFF384A4B)
              : const Color(0xFFE0E7E5),
        );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamilyFallback: const [
        'Noto Sans TC',
        'PingFang TC',
        'Microsoft JhengHei',
      ],
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: colorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.5,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      iconTheme: IconThemeData(size: 22, color: colorScheme.onSurfaceVariant),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: const CircleBorder(),
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary,
        labelStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
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
        height: 76,
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
