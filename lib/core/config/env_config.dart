import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Centralized configuration provider for the Upajo mobile application.
/// 
/// Values are read with the following precedence:
/// 1. Compile-time `--dart-define` flags (production & CI/CD recommended)
/// 2. Local gitignored `.env` file (local development convenience)
/// 
/// FAILS LOUDLY at startup if required endpoints or keys are missing or still
/// contain placeholder values (e.g. "your-project").
class EnvConfig {
  EnvConfig._();

  static String _supabaseUrl = '';
  static String _supabaseAnonKey = '';
  static String _apiBaseUrl = '';
  static String _razorpayKeyId = '';
  static String _openMeteoBaseUrl = '';
  static String _mapTileUrl = '';
  static bool _isInitialized = false;

  /// Initializes environment configuration and enforces strict production invariants.
  static Future<void> initialize({bool failLoudly = true}) async {
    // 1. Attempt loading from gitignored .env file if available
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env is optional when using --dart-define
    }

    // 2. Read with compile-time --dart-define taking highest precedence
    const dartDefSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const dartDefSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const dartDefApiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: String.fromEnvironment('ML_SERVICE_URL'),
    );
    const dartDefRazorpayKeyId = String.fromEnvironment('RAZORPAY_KEY_ID');
    const dartDefOpenMeteo = String.fromEnvironment('OPEN_METEO_BASE_URL');
    const dartDefMapTile = String.fromEnvironment('MAP_TILE_URL');

    _supabaseUrl = dartDefSupabaseUrl.isNotEmpty
        ? dartDefSupabaseUrl.trim()
        : (dotenv.env['SUPABASE_URL'] ?? '').trim();

    _supabaseAnonKey = dartDefSupabaseAnonKey.isNotEmpty
        ? dartDefSupabaseAnonKey.trim()
        : (dotenv.env['SUPABASE_ANON_KEY'] ?? '').trim();

    _apiBaseUrl = dartDefApiBaseUrl.isNotEmpty
        ? dartDefApiBaseUrl.trim()
        : (dotenv.env['API_BASE_URL'] ?? dotenv.env['ML_SERVICE_URL'] ?? 'http://10.0.2.2:8000').trim();

    _razorpayKeyId = dartDefRazorpayKeyId.isNotEmpty
        ? dartDefRazorpayKeyId.trim()
        : (dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_placeholder').trim();

    _openMeteoBaseUrl = dartDefOpenMeteo.isNotEmpty
        ? dartDefOpenMeteo.trim()
        : (dotenv.env['OPEN_METEO_BASE_URL'] ?? 'https://api.open-meteo.com/v1/forecast').trim();

    _mapTileUrl = dartDefMapTile.isNotEmpty
        ? dartDefMapTile.trim()
        : (dotenv.env['MAP_TILE_URL'] ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png').trim();

    _isInitialized = true;

    if (failLoudly) {
      validateConfig();
    }
  }

  /// Validates configuration and fails loudly if required variables are missing,
  /// malformed, or set to placeholder dummy strings.
  static void validateConfig() {
    final errors = <String>[];

    // SUPABASE_URL validation
    if (_supabaseUrl.isEmpty) {
      errors.add('SUPABASE_URL is required but was not provided.');
    } else if (_supabaseUrl.contains('your-project') || _supabaseUrl.contains('placeholder')) {
      errors.add('SUPABASE_URL still contains placeholder "$_supabaseUrl". Set your real Supabase project URL.');
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

    // API_BASE_URL validation
    if (_apiBaseUrl.isEmpty) {
      errors.add('API_BASE_URL is required but was not provided.');
    } else if (_apiBaseUrl.contains('your-') || _apiBaseUrl.contains('placeholder')) {
      errors.add('API_BASE_URL contains placeholder dummy string. Set real FastAPI URL (e.g. http://10.0.2.2:8000).');
    }

    if (errors.isNotEmpty) {
      final banner = '\n'
          '======================================================================\n'
          '❌ FATAL CONFIGURATION ERROR - APP STARTUP ABORTED\n'
          '======================================================================\n'
          '${errors.map((e) => '  [!] $e').join('\n')}\n\n'
          'Please provide your real configuration using one of these two methods:\n\n'
          'Method 1: Compile-time --dart-define flags (Recommended):\n'
          '  flutter run --flavor dev \\\n'
          '    --dart-define=SUPABASE_URL=https://<YOUR-PROJECT-REF>.supabase.co \\\n'
          '    --dart-define=SUPABASE_ANON_KEY=<YOUR-SUPABASE-ANON-KEY> \\\n'
          '    --dart-define=API_BASE_URL=http://10.0.2.2:8000\n\n'
          'Method 2: Gitignored .env file in project root:\n'
          '  SUPABASE_URL=https://<YOUR-PROJECT-REF>.supabase.co\n'
          '  SUPABASE_ANON_KEY=<YOUR-SUPABASE-ANON-KEY>\n'
          '  API_BASE_URL=http://10.0.2.2:8000\n'
          '======================================================================\n';
      debugPrint(banner);
      throw StateError(banner);
    }
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
    _supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    _supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    _apiBaseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:8000');
    _razorpayKeyId = const String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'rzp_test_placeholder');
    _openMeteoBaseUrl = const String.fromEnvironment('OPEN_METEO_BASE_URL', defaultValue: 'https://api.open-meteo.com/v1/forecast');
    _mapTileUrl = const String.fromEnvironment('MAP_TILE_URL', defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');
    _isInitialized = true;
  }
}


