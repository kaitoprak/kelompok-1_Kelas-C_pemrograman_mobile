import 'package:flutter/material.dart';

abstract final class ShelfColors {
  static const sage = Color(0xFFB9D8C4);
  static const darkBackground = Color(0xFF111315);
  static const darkSurface = Color(0xFF191C1F);
  static const darkRaised = Color(0xFF22262A);
  static const lightBackground = Color(0xFFF5F5F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1E2521);
  static const muted = Color(0xFF929B96);
  static const book = Color(0xFFE2B36F);
  static const movie = Color(0xFFC4B7F0);
  static const series = Color(0xFF82C7BE);
  static const danger = Color(0xFFE78E8E);
}

abstract final class ShelfSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

abstract final class ShelfRadius {
  static const card = 20.0;
  static const control = 14.0;
  static const pill = 100.0;
}

ThemeData shelfTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final surface = isDark ? ShelfColors.darkSurface : ShelfColors.lightSurface;
  final background = isDark
      ? ShelfColors.darkBackground
      : ShelfColors.lightBackground;
  final onSurface = isDark ? const Color(0xFFF1F3F0) : ShelfColors.ink;
  final muted = isDark ? const Color(0xFFABB3AE) : const Color(0xFF68736D);
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF668A73),
        brightness: brightness,
        surface: surface,
      ).copyWith(
        primary: isDark ? ShelfColors.sage : const Color(0xFF3E7053),
        onPrimary: isDark ? const Color(0xFF16211A) : Colors.white,
        secondary: isDark ? const Color(0xFFE7C38F) : const Color(0xFF805D28),
        tertiary: isDark ? const Color(0xFFC8BDF3) : const Color(0xFF66599B),
        surface: surface,
        surfaceContainerLowest: background,
        surfaceContainerLow: isDark
            ? const Color(0xFF1D2023)
            : const Color(0xFFF0F1EB),
        surfaceContainer: isDark
            ? ShelfColors.darkRaised
            : const Color(0xFFE9EBE5),
        surfaceContainerHigh: isDark
            ? const Color(0xFF282D30)
            : const Color(0xFFE1E4DD),
        onSurface: onSurface,
        onSurfaceVariant: muted,
        outline: isDark ? const Color(0xFF343A3D) : const Color(0xFFD7DCD5),
        error: isDark ? ShelfColors.danger : const Color(0xFFB42332),
      );
  final text = ThemeData(brightness: brightness).textTheme
      .apply(bodyColor: onSurface, displayColor: onSurface);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    textTheme: text,
    dividerColor: scheme.outline.withValues(alpha: .55),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ShelfRadius.card),
        side: BorderSide(color: scheme.outline.withValues(alpha: .38)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: onSurface,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF202427) : const Color(0xFFF0F1EB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ShelfRadius.control),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ShelfRadius.control),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: .55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ShelfRadius.control),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ShelfRadius.control),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ShelfRadius.control),
        borderSide: BorderSide(color: scheme.error, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 70,
      backgroundColor: surface,
      indicatorColor: scheme.primary.withValues(alpha: isDark ? .17 : .12),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelSmall?.copyWith(
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShelfRadius.control),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ShelfRadius.control),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark
          ? const Color(0xFF303633)
          : const Color(0xFF29362E),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
