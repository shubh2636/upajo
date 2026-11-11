import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'Upajo';
  static const String appNameHi = 'उपजो';
  static const String appPackageId = 'com.upajo.app';
  static const String appVersion = '1.0.0';

  /// Feature Flag: SMS OTP Authentication
  /// Kept strictly disabled across all flavors because no transactional SMS/DLT provider is active.
  /// All signup and login flows strictly use Mobile Number + Password.
  static const bool enableOtpAuth = false;

  // Localization
  static const Locale localeHindi = Locale('hi');
  static const Locale localeEnglish = Locale('en');
  static const Locale localeHinglish = Locale.fromSubtags(languageCode: 'hi', scriptCode: 'Latn');

  static const Locale defaultLocale = localeHindi;
  static const List<Locale> supportedLocales = [
    localeHindi,
    localeEnglish,
    localeHinglish,
  ];
  static const String translationsPath = 'assets/translations';

  // Pack sizes for direct farmer selling (10kg, 20kg, 50kg)
  static const List<int> standardPackSizesKg = [10, 20, 50];

  // Delivery Modes
  static const String deliveryModePickup = 'pickup';
  static const String deliveryModeSelf = 'self_delivery';
  static const String deliveryModePartner = 'partner';

  // Image Upload Limits
  static const int maxImageSizeKb = 500; // Village 2G/3G optimization
  static const int maxImageWidthOrHeight = 1280;

  // Touch Target Accessibility
  static const double minTouchTargetDp = 48.0;
  static const double minTouchTargetLargeDp = 56.0;

  // Local Storage Cache Keys
  static const String keyUserRole = 'upajo_user_role';
  static const String keyAuthToken = 'upajo_auth_token';
  static const String keySelectedLocale = 'upajo_selected_locale';
}

