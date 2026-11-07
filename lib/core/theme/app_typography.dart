import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Display Typography for Titles & Hero Headings
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
    height: 1.25,
    color: AppColors.soil800,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 26.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.3,
    color: AppColors.soil800,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    height: 1.35,
    color: AppColors.soil800,
  );

  // Headlines for Bento Cards
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 19.0,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.soil800,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w700,
    height: 1.4,
    color: AppColors.soil800,
  );

  // Body Typography with High Contrast & Legibility for Rural Users
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.soil800,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AppColors.soil700,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.soil600,
  );

  // Large Button Labels (Min 48dp Touch Affordance)
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  // Numeric Values & Rupee Pricing
  static const TextStyle priceLarge = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w900,
    color: AppColors.primary500,
  );

  static const TextStyle priceMedium = TextStyle(
    fontSize: 19.0,
    fontWeight: FontWeight.w800,
    color: AppColors.primary500,
  );
}

