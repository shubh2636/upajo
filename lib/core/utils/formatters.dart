import 'dart:ui';
import 'package:intl/intl.dart';

/// Centralized, locale-aware formatting utility for Upajo.
/// Ensures currency, dates, quantities, and units respect the active locale.
class AppFormatters {
  AppFormatters._();

  /// Format Indian Rupee currency: e.g. ₹1,250 or ₹1,250.50
  static String currency(num amount, {Locale? locale, bool includeDecimals = false}) {
    final isHindi = locale?.languageCode == 'hi' && (locale?.scriptCode == null || locale?.scriptCode != 'Latn');
    final formatter = NumberFormat.currency(
      locale: isHindi ? 'hi_IN' : 'en_IN',
      symbol: '₹',
      decimalDigits: includeDecimals ? 2 : 0,
    );
    return formatter.format(amount);
  }

  /// Format weight with proper localized unit (kg vs किग्रा)
  static String weight(num kg, {Locale? locale}) {
    final isPureHindi = locale?.languageCode == 'hi' && (locale?.scriptCode == null || locale?.scriptCode != 'Latn');
    final unit = isPureHindi ? 'किग्रा' : 'kg';
    final formattedNumber = NumberFormat.decimalPattern(isPureHindi ? 'hi_IN' : 'en_IN').format(kg);
    return '$formattedNumber $unit';
  }

  /// Format land area with proper localized unit (acres vs एकड़)
  static String area(num acres, {Locale? locale}) {
    final isPureHindi = locale?.languageCode == 'hi' && (locale?.scriptCode == null || locale?.scriptCode != 'Latn');
    final unit = isPureHindi ? 'एकड़' : 'acres';
    final formattedNumber = NumberFormat.decimalPattern(isPureHindi ? 'hi_IN' : 'en_IN').format(acres);
    return '$formattedNumber $unit';
  }

  /// Format date using intl per locale
  static String date(DateTime date, {Locale? locale, String pattern = 'd MMM yyyy'}) {
    final isPureHindi = locale?.languageCode == 'hi' && (locale?.scriptCode == null || locale?.scriptCode != 'Latn');
    final localeStr = isPureHindi ? 'hi' : 'en';
    try {
      return DateFormat(pattern, localeStr).format(date);
    } catch (_) {
      return DateFormat(pattern, 'en').format(date);
    }
  }

  /// Format generic numbers with Indian numbering grouping (lakhs/crores)
  static String number(num value, {Locale? locale}) {
    final isPureHindi = locale?.languageCode == 'hi' && (locale?.scriptCode == null || locale?.scriptCode != 'Latn');
    return NumberFormat.decimalPattern(isPureHindi ? 'hi_IN' : 'en_IN').format(value);
  }
}
