import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// 間距單位（企劃書 4.4：8dp 間距網格）。
abstract final class AppSpacing {
  static const double unit = 8;
  static const double xs = unit / 2;
  static const double sm = unit;
  static const double md = unit * 1.5;
  static const double lg = unit * 2;
  static const double xl = unit * 3;
}

/// 圓角尺寸。
abstract final class AppRadius {
  static const double card = 12;
  static const double control = 10;
}

/// 全 APP 主題（企劃書 4.4）：一組主色加中性色、統一圓角卡片，淺色與深色兩套。
abstract final class AppTheme {
  /// 主色：iOS 系統藍；中性色依淺色／深色切換。
  static const Color seedColor = Color(0xFF007AFF);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: brightness,
        ).copyWith(
          primary: dark ? const Color(0xFF0A84FF) : const Color(0xFF007AFF),
          onPrimary: dark ? const Color(0xFFFFFFFF) : Colors.white,
          surface: dark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
          surfaceContainerLow: dark ? const Color(0xFF1C1C1E) : Colors.white,
          surfaceContainer: dark
              ? const Color(0xFF2C2C2E)
              : const Color(0xFFE5E5EA),
          onSurface: dark ? const Color(0xFFF2F2F7) : const Color(0xFF1C1C1E),
          onSurfaceVariant: dark
              ? const Color(0xFFAEAEB2)
              : const Color(0xFF636366),
          outlineVariant: dark
              ? const Color(0xFF38383A)
              : const Color(0xFFC6C6C8),
        );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      platform: TargetPlatform.iOS,
      cupertinoOverrideTheme: CupertinoThemeData(
        brightness: brightness,
        primaryColor: colorScheme.primary,
        scaffoldBackgroundColor: colorScheme.surface,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 48,
        titleTextStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        systemOverlayStyle: dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 48),
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: TextStyle(color: colorScheme.primary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          backgroundColor: colorScheme.surfaceContainerLow,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: colorScheme.surfaceContainerLow,
        iconColor: colorScheme.primary,
        minVerticalPadding: 8,
        minTileHeight: 48,
        minLeadingWidth: 28,
        horizontalTitleGap: 12,
        subtitleTextStyle: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: colorScheme.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: .5),
        thickness: .5,
        space: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: .2),
        selectionHandleColor: colorScheme.primary,
      ),
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamilyFallback: const [
        'Noto Sans TC',
        'PingFang TC',
        'Microsoft JhengHei',
      ],
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          height: 1.18,
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
          color: colorScheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -.5,
          color: colorScheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: colorScheme.onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        displayLarge: TextStyle(fontSize: 48, color: colorScheme.onSurface),
        displayMedium: TextStyle(fontSize: 40, color: colorScheme.onSurface),
        displaySmall: TextStyle(fontSize: 32, color: colorScheme.onSurface),
        labelMedium: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        labelSmall: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: colorScheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: colorScheme.onSurfaceVariant,
        ),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      iconTheme: IconThemeData(size: 20, color: colorScheme.onSurfaceVariant),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          iconSize: 20,
          minimumSize: const Size(48, 48),
        ),
      ),
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
        sizeConstraints: const BoxConstraints.tightFor(width: 48, height: 48),
        shape: const CircleBorder(),
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primary.withValues(alpha: .10),
        labelStyle: TextStyle(color: colorScheme.primary, fontSize: 12),
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
        height: 56,
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
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
