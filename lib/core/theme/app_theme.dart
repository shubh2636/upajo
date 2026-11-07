import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static const double minTouchTarget = 48.0;
  static const double minTouchTargetLarge = 56.0;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary500,
      scaffoldBackgroundColor: AppColors.soil50,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary500,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primary100,
        onPrimaryContainer: AppColors.primary800,
        secondary: AppColors.wheat500,
        onSecondary: AppColors.soil900,
        secondaryContainer: AppColors.wheat100,
        onSecondaryContainer: AppColors.wheat800,
        error: AppColors.clay500,
        onError: Colors.white,
        surface: AppColors.soil50,
        onSurface: AppColors.soil800,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.soil800,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w800,
          color: AppColors.soil800,
        ),
        iconTheme: IconThemeData(
          color: AppColors.soil800,
          size: 26.0,
        ),
      ),

      // Card Theme with Bento Corners
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: AppColors.soil200, width: 1.0),
        ),
      ),

      // Elevated Button Theme (Min 48dp Touch Target)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary500,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(minTouchTargetLarge),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          textStyle: AppTypography.buttonLarge,
          elevation: 1,
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.soil800,
          minimumSize: const Size.fromHeight(minTouchTarget),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          side: const BorderSide(color: AppColors.soil200, width: 2.0),
          textStyle: AppTypography.buttonMedium.copyWith(color: AppColors.soil800),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        constraints: const BoxConstraints(minHeight: minTouchTargetLarge),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.soil200, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.soil200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.primary500, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.clay500, width: 1.5),
        ),
        labelStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600, color: AppColors.soil700),
        hintStyle: const TextStyle(fontSize: 15.0, color: AppColors.soil400),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary500,
        unselectedItemColor: AppColors.soil500,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary400,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary400,
        onPrimary: AppColors.soil900,
        primaryContainer: AppColors.primary800,
        onPrimaryContainer: AppColors.primary100,
        secondary: AppColors.wheat400,
        onSecondary: AppColors.soil900,
        error: AppColors.clay400,
        surface: AppColors.darkSurface,
        onSurface: AppColors.soil100,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.soil100,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: const BorderSide(color: AppColors.darkBorder, width: 1.0),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.5),
        ),
      ),
    );
  }
}

