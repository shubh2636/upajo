import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env_config.dart';
import 'secure_local_storage.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    final url = EnvConfig.supabaseUrl;
    final anonKey = EnvConfig.supabaseAnonKey;

    if (anonKey.toLowerCase().contains('service_role')) {
      throw StateError('CRITICAL SECURITY VIOLATION: Never initialize Supabase client with the service_role key!');
    }

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureLocalStorage(),
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
      ),
    );
  }

  static bool get isAuthenticated => client.auth.currentUser != null;

  static String? get currentUserId => client.auth.currentUser?.id;
}

