import 'package:flutter/material.dart';

/// ── Colors ───────────────────────────────────────────────────────────────────
abstract class AppColors {
  // Brand
  static const primary = Color(0xff1BA3A1);
  static const primaryDark = Color(0xff158280);

  // Semantic
  static const success = Color(0xff66BB6A);
  static const error = Color(0xffF44336);
  static const warning = Color(0xffFFA726);

  // Text
  static const textPrimary = Color(0xff101011);
  static const textSecondary = Color(0xff817D8A);

  // Surface — light
  static const surfaceLight = Color(0xffF2F2F3);
  static const cardLight = Colors.white;

  // Surface — dark
  static const surfaceDark = Color(0xFF1E1E1E);
  static const scaffoldDark = Color(0xFF121212);

  // Dividers
  static const dividerLight = Color(0x1F000000); // black12
  static const dividerDark = Color(0x1FFFFFFF);  // white12
}

/// ── Border radii ─────────────────────────────────────────────────────────────
abstract class AppRadius {
  static const double xs = 2;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;

  static BorderRadius get xs$ => BorderRadius.circular(xs);
  static BorderRadius get sm$ => BorderRadius.circular(sm);
  static BorderRadius get md$ => BorderRadius.circular(md);
  static BorderRadius get lg$ => BorderRadius.circular(lg);
  static BorderRadius get xl$ => BorderRadius.circular(xl);
}

/// ── Spacing ──────────────────────────────────────────────────────────────────
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// ── Typography ───────────────────────────────────────────────────────────────
abstract class AppText {
  static const labelXs = TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w400);
  static const labelSm = TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w400);
  static const body    = TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400);
  static const bodyMd  = TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w400);
  static const bodyLg  = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400);

  static const titleSm = TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600);
  static const titleMd = TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600);
  static const titleLg = TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600);

  static const amount  = TextStyle(fontFamily: 'Inter', fontSize: 19, fontWeight: FontWeight.w600);
  static const amountSm = TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700);

  static const secondary = TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}

/// ── Theme builders ───────────────────────────────────────────────────────────
abstract class AppTheme {
  static ThemeData get light => ThemeData(
    fontFamily: 'Inter',
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(color: Colors.white),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm$),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: AppRadius.sm$,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.sm$,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
      hintStyle: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm$),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.dividerLight, space: 1),
  );

  static ThemeData get dark => ThemeData(
    fontFamily: 'Inter',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: AppColors.scaffoldDark,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.scaffoldDark,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: const CardThemeData(color: AppColors.surfaceDark),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm$),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: AppRadius.sm$,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.sm$,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
      hintStyle: AppText.bodyMd.copyWith(color: AppColors.textSecondary),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sm$),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.dividerDark, space: 1),
  );
}
