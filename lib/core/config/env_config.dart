import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  EnvConfig._();

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {
      // Fallback if file not provided in test harness
    }
  }

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://placeholder.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'placeholder-anon-key';

  static String get razorpayKeyId =>
      dotenv.env['RAZORPAY_KEY_ID'] ?? 'rzp_test_placeholder';

  static String get mlServiceUrl =>
      dotenv.env['ML_SERVICE_URL'] ?? 'http://10.0.2.2:8000';

  static String get openMeteoBaseUrl =>
      dotenv.env['OPEN_METEO_BASE_URL'] ?? 'https://api.open-meteo.com/v1/forecast';
}

