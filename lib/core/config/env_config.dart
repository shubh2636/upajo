import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration provider for the Upajo mobile application.
/// 
/// Values are read with the following precedence:
/// 1. Compile-time `--dart-define` flags (production & CI/CD recommended)
/// 2. Local gitignored `.env` file (local development convenience)
/// 
/// Strictly validates backend credentials at startup. If either SUPABASE_URL or
/// SUPABASE_ANON_KEY is missing or contains placeholder values (e.g. "your-project"),
/// the app displays a full-screen "Backend not configured" message rather than
/// crashing or allowing broken signups.
class EnvConfig {
  EnvConfig._();

  // Read via --dart-define in ONE place only
  static const String _dartDefSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _dartDefSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _dartDefApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: String.fromEnvironment('ML_SERVICE_URL'),
  );
  static const String _dartDefRazorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
  static const String _dartDefOpenMeteo = String.fromEnvironment('OPEN_METEO_BASE_URL');
  static const String _dartDefMapTile = String.fromEnvironment('MAP_TILE_URL');

  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';
  static String _apiBaseUrl = '';
  static String _razorpayKeyId = '';
  static String _openMeteoBaseUrl = '';
  static String _mapTileUrl = '';
  static bool _isInitialized = false;
  static String? _configErrorReason;

  /// Initializes environment configuration.
  static Future<void> initialize({bool failLoudly = false}) async {
    // 1. Attempt loading from gitignored .env file if available
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env is optional when using --dart-define
    }

    _supabaseUrl = _dartDefSupabaseUrl.isNotEmpty
        ? _dartDefSupabaseUrl.trim()
        : (dotenv.env['SUPABASE_URL'] ?? '').trim();

    _supabaseAnonKey = _dartDefSupabaseAnonKey.isNotEmpty
        ? _dartDefSupabaseAnonKey.trim()
        : (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();

    _apiBaseUrl = _dartDefApiBaseUrl.isNotEmpty
        ? _dartDefApiBaseUrl.trim()
        : (dotenv.env['API_BASE_URL'] ?? dotenv.env['ML_SERVICE_URL'] ?? 'http://10.0.2.2:8000').trim();

    _razorpayKeyId = _dartDefRazorpayKeyId.isNotEmpty
        ? _dartDefRazorpayKeyId.trim()
        : (dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_placeholder').trim();

    _openMeteoBaseUrl = _dartDefOpenMeteo.isNotEmpty
        ? _dartDefOpenMeteo.trim()
        : (dotenv.env['OPEN_METEO_BASE_URL'] ?? 'https://api.open-meteo.com/v1/forecast').trim();

    _mapTileUrl = _dartDefMapTile.isNotEmpty
        ? _dartDefMapTile.trim()
        : (dotenv.env['MAP_TILE_URL'] ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png').trim();

    _isInitialized = true;
    _evaluateConfig();

    if (failLoudly && _configErrorReason != null) {
      debugPrint(_configErrorReason);
      throw StateError(_configErrorReason!);
    }
  }

  /// Internal evaluator that populates _configErrorReason
  static void _evaluateConfig() {
    final errors = <String>[];

    // SUPABASE_URL validation
    if (_supabaseUrl.isEmpty) {
      errors.add('SUPABASE_URL is required but was not provided.');
    } else if (_supabaseUrl.contains('your-project') || _supabaseUrl.contains('placeholder')) {
      errors.add('SUPABASE_URL contains placeholder "$_supabaseUrl". Set your real Supabase project URL.');
    } else if (!Uri.tryParse(_supabaseUrl)!.hasScheme) {
      errors.add('SUPABASE_URL "$_supabaseUrl" is invalid. It must include http:// or https://');
    }

    // SUPABASE_ANON_KEY validation
    if (_supabaseAnonKey.isEmpty) {
      errors.add('SUPABASE_ANON_KEY is required but was not provided.');
    } else if (_supabaseAnonKey.contains('your-') || _supabaseAnonKey.contains('placeholder')) {
      errors.add('SUPABASE_ANON_KEY contains placeholder dummy string. Set your real Supabase publishable anon key.');
    } else if (_supabaseAnonKey.toLowerCase().contains('service_role')) {
      errors.add('CRITICAL SECURITY VIOLATION: Never use service_role key in the Flutter app! Use public anon key only.');
    }

    if (errors.isNotEmpty) {
      _configErrorReason = errors.join('\n');
    } else {
      _configErrorReason = null;
    }
  }

  /// Returns true only when both URL and anon key are valid and not placeholders.
  static bool get isBackendConfigured {
    if (!_isInitialized) _lazyInit();
    return _configErrorReason == null;
  }

  /// Detailed human-readable error reason if backend is not configured.
  static String? get configErrorReason {
    if (!_isInitialized) _lazyInit();
    return _configErrorReason;
  }

  static String get supabaseUrl {
    if (!_isInitialized) _lazyInit();
    return _supabaseUrl;
  }

  static String get supabaseAnonKey {
    if (!_isInitialized) _lazyInit();
    return _supabaseAnonKey;
  }

  static String get apiBaseUrl {
    if (!_isInitialized) _lazyInit();
    return _apiBaseUrl;
  }

  static String get mlServiceUrl => apiBaseUrl;

  static String get razorpayKeyId {
    if (!_isInitialized) _lazyInit();
    return _razorpayKeyId;
  }

  static String get openMeteoBaseUrl {
    if (!_isInitialized) _lazyInit();
    return _openMeteoBaseUrl;
  }

  static String get mapTileUrl {
    if (!_isInitialized) _lazyInit();
    return _mapTileUrl;
  }

  static void _lazyInit() {
    _supabaseUrl = _dartDefSupabaseUrl.isNotEmpty ? _dartDefSupabaseUrl.trim() : '';
    _supabaseAnonKey = _dartDefSupabaseAnonKey.isNotEmpty ? _dartDefSupabaseAnonKey.trim() : '';
    _apiBaseUrl = _dartDefApiBaseUrl.isNotEmpty ? _dartDefApiBaseUrl.trim() : 'http://10.0.2.2:8000';
    _razorpayKeyId = _dartDefRazorpayKeyId.isNotEmpty ? _dartDefRazorpayKeyId.trim() : 'rzp_test_placeholder';
    _openMeteoBaseUrl = _dartDefOpenMeteo.isNotEmpty ? _dartDefOpenMeteo.trim() : 'https://api.open-meteo.com/v1/forecast';
    _mapTileUrl = _dartDefMapTile.isNotEmpty ? _dartDefMapTile.trim() : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    _isInitialized = true;
    _evaluateConfig();
  }
}
