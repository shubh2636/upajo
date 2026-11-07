import 'package:flutter/material.dart';

/// Authentic Indian Farmland Color Palette for Upajo (उपजो)
/// Inspired by rich fertile black soil, golden ripening wheat, lush green fields,
/// traditional terracotta clay pots (kulhad), and handmade khadi canvas.
class AppColors {
  AppColors._();

  // Primary: Leaf & Harvest Green (जीवन और हरियाली)
  static const Color primary50 = Color(0xFFF0FDF4);
  static const Color primary100 = Color(0xFFDCFCE7);
  static const Color primary200 = Color(0xFFBBF7D0);
  static const Color primary300 = Color(0xFF86EFAC);
  static const Color primary400 = Color(0xFF4ADE80);
  static const Color primary500 = Color(0xFF25603A); // Main Harvest Green CTA
  static const Color primary600 = Color(0xFF1B492C); // Deep Forest Canopy
  static const Color primary700 = Color(0xFF143721);
  static const Color primary800 = Color(0xFF0D2516);
  static const Color primary900 = Color(0xFF07140B);

  // Secondary: Golden Wheat & Mustard (पकी हुई सुनहरी गेहूं)
  static const Color wheat50 = Color(0xFFFEFCE8);
  static const Color wheat100 = Color(0xFFFEF9C3);
  static const Color wheat200 = Color(0xFFFEF08A);
  static const Color wheat300 = Color(0xFFFDE047);
  static const Color wheat400 = Color(0xFFFACC15);
  static const Color wheat500 = Color(0xFFD8972C); // Ripe Wheat Gold
  static const Color wheat600 = Color(0xFFB3781A);
  static const Color wheat700 = Color(0xFF8C5B0E);
  static const Color wheat800 = Color(0xFF663F05);
  static const Color wheat900 = Color(0xFF402502);

  // Accent: Terracotta & Kulhad Clay (देसी मिट्टी / कुल्हड़)
  static const Color clay50 = Color(0xFFFDF4F2);
  static const Color clay100 = Color(0xFFFCE7E4);
  static const Color clay200 = Color(0xFFF9D1CA);
  static const Color clay300 = Color(0xFFF3AEA2);
  static const Color clay400 = Color(0xFFE87D6B);
  static const Color clay500 = Color(0xFFBA4A38); // Terracotta Clay
  static const Color clay600 = Color(0xFF963626);
  static const Color clay700 = Color(0xFF732517);
  static const Color clay800 = Color(0xFF51170D);
  static const Color clay900 = Color(0xFF330C05);

  // Neutral / Background: Fertile Soil & Khadi Cream (काली मिट्टी व खादी)
  static const Color soil50 = Color(0xFFFAF7F0); // Khadi Cream Base
  static const Color soil100 = Color(0xFFF2ECE1); // Soft Sand Card
  static const Color soil200 = Color(0xFFE2D7C3); // Border Divider
  static const Color soil300 = Color(0xFFC7B79B);
  static const Color soil400 = Color(0xFF9E8D6E);
  static const Color soil500 = Color(0xFF6E5F44);
  static const Color soil600 = Color(0xFF524530);
  static const Color soil700 = Color(0xFF3B3020);
  static const Color soil800 = Color(0xFF2E1F14); // Dark Rich Loam (High-Contrast Text)
  static const Color soil900 = Color(0xFF180F08);

  // Dark Theme Surfaces
  static const Color darkBackground = Color(0xFF17130F);
  static const Color darkSurface = Color(0xFF221C16);
  static const Color darkCard = Color(0xFF2D251E);
  static const Color darkBorder = Color(0xFF3F352C);

  // Semantic Status Colors
  static const Color success = Color(0xFF25603A);
  static const Color success400 = Color(0xFF4ADE80);
  static const Color success500 = Color(0xFF25603A);
  static const Color success600 = Color(0xFF1B492C);
  static const Color warning = Color(0xFFD8972C);
  static const Color error = Color(0xFFBA4A38);
  static const Color error50 = clay50;
  static const Color error300 = clay300;
  static const Color error400 = clay400;
  static const Color error600 = Color(0xFF963626);
  static const Color error700 = clay700;
  static const Color info = Color(0xFF2E5E8A);

  // Terracotta aliases for clay
  static const Color terracotta50 = clay50;
  static const Color terracotta200 = clay200;
  static const Color terracotta500 = clay500;
  static const Color terracotta600 = clay600;
  static const Color terracotta800 = clay800;
}

