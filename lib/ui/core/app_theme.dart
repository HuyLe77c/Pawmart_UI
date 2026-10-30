import 'package:flutter/material.dart';

abstract final class PawmartColors {
  static const cream = Color(0xFFF7F6F1);
  static const green = Color(0xFF176B50);
  static const greenDark = Color(0xFF104936);
  static const greenPale = Color(0xFFE8F3EC);
  static const ink = Color(0xFF1D3028);
  static const muted = Color(0xFF68776D);
  static const line = Color(0xFFDFE7DF);
  static const amber = Color(0xFFC2763B);
  static const amberPale = Color(0xFFFFF0DF);
  static const surface = Colors.white;
  static const error = Color(0xFFB43F3F);
}

abstract final class PawmartTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: PawmartColors.green,
      primary: PawmartColors.green,
      secondary: PawmartColors.amber,
      surface: PawmartColors.surface,
      error: PawmartColors.error,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: PawmartColors.cream,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.12,
          color: PawmartColors.ink,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
          height: 1.16,
          color: PawmartColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.45,
          height: 1.2,
          color: PawmartColors.ink,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: PawmartColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: PawmartColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.45,
          color: PawmartColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.45,
          color: PawmartColors.ink,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: PawmartColors.muted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: PawmartColors.surface,
        foregroundColor: PawmartColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: PawmartColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: PawmartColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: PawmartColors.line),
        ),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: PawmartColors.green,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: PawmartColors.cream,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: PawmartColors.greenPale,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? PawmartColors.greenDark
                : PawmartColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 23,
            color: states.contains(WidgetState.selected)
                ? PawmartColors.greenDark
                : PawmartColors.muted,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(color: PawmartColors.line),
      chipTheme: ChipThemeData(
        backgroundColor: PawmartColors.greenPale,
        selectedColor: PawmartColors.green,
        labelStyle: const TextStyle(
          color: PawmartColors.ink,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: PawmartColors.green),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PawmartColors.ink,
          side: const BorderSide(color: PawmartColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          minimumSize: const Size(48, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: PawmartColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: PawmartColors.green, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: PawmartColors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: PawmartColors.ink,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
    );
  }
}
