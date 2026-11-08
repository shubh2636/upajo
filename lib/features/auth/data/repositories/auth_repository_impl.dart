import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/exceptions.dart' hide AuthException;
import '../../../../core/network/supabase_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;

  /// Demo auth is STRICTLY disabled in release builds (impossible to enable in prod)
  static const bool allowDemoAuth =
      !kReleaseMode && bool.fromEnvironment('ALLOW_DEMO_AUTH', defaultValue: true);

  // Rate Limiting & Lockout Parameters
  static DateTime? _lastOtpRequestTime;
  static int _failedOtpAttempts = 0;
  static DateTime? _lockoutUntil;
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration otpResendCooldown = Duration(seconds: 60);

  AuthRepositoryImpl({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  String _formatIndianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      return '+91$cleaned';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      return '+$cleaned';
    }
    return phone.startsWith('+') ? phone : '+$phone';
  }

  @override
  Future<void> sendOtp(String phone) async {
    final now = DateTime.now();

    // Check brute-force lockout
    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      final remainingMins = _lockoutUntil!.difference(now).inMinutes + 1;
      throw ServerException(
        'सुरक्षा कारणों से ओटीपी अनुरोध लॉक है। कृपया $remainingMins मिनट बाद पुनः प्रयास करें। (Account temporarily locked. Please wait $remainingMins minutes.)',
      );
    }

    // Check resend cooldown
    if (_lastOtpRequestTime != null && now.difference(_lastOtpRequestTime!) < otpResendCooldown) {
      final waitSecs = otpResendCooldown.inSeconds - now.difference(_lastOtpRequestTime!).inSeconds;
      throw ServerException(
        'कृपया नया ओटीपी मांगने से पहले $waitSecs सेकंड प्रतीक्षा करें (Please wait $waitSecs seconds before resending OTP)',
      );
    }

    try {
      final formattedPhone = _formatIndianPhone(phone);
      await _client.auth.signInWithOtp(
        phone: formattedPhone,
        channel: OtpChannel.sms,
      );
      _lastOtpRequestTime = DateTime.now();
    } on AuthException catch (e) {
      if (allowDemoAuth && (e.message.contains('sms_provider') || e.message.contains('Failed host lookup') || e.toString().contains('Failed host lookup'))) {
        _lastOtpRequestTime = DateTime.now();
        return; // Dev / offline test fallback
      }
      rethrow;
    } catch (e) {
      // In local dev without active SMS gateway balance, allow graceful fallback
      if (allowDemoAuth && (e.toString().contains('sms_provider') || e.toString().contains('Failed host lookup'))) {
        _lastOtpRequestTime = DateTime.now();
        return; // Dev bypass
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserProfile?> verifyOtp({
    required String phone,
    required String token,
  }) async {
    final now = DateTime.now();

    // Check brute-force lockout
    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      final remainingMins = _lockoutUntil!.difference(now).inMinutes + 1;
      throw ServerException(
        'गलत प्रयासों के कारण खाता $remainingMins मिनट के लिए लॉक है (Too many failed attempts. Locked for $remainingMins minutes)',
      );
    }

    try {
      final formattedPhone = _formatIndianPhone(phone);

      // Verify OTP with Supabase
      AuthResponse? res;
      try {
        res = await _client.auth.verifyOTP(
          phone: formattedPhone,
          token: token,
          type: OtpType.sms,
        );
      } catch (authErr) {
        // Dev bypass ONLY available in debug/development builds; impossible in release mode
        if (allowDemoAuth && token == '123456') {
          final existing = await _client
              .from('profiles')
              .select('*')
              .eq('phone', phone.replaceAll(RegExp(r'[^0-9]'), ''))
              .maybeSingle();

          _failedOtpAttempts = 0;
          _lockoutUntil = null;

          if (existing != null) {
            return UserProfile.fromJson(existing);
          }
          return null; // Triggers onboarding
        }

        // Increment failed attempts and trigger lockout if limit reached
        _failedOtpAttempts++;
        if (_failedOtpAttempts >= maxFailedAttempts) {
          _lockoutUntil = DateTime.now().add(lockoutDuration);
          throw ServerException(
            '5 बार गलत ओटीपी दर्ज किया गया। सुरक्षा हेतु 15 मिनट के लिए लॉक किया गया है (5 failed attempts. Account locked for 15 minutes)',
          );
        }

        throw ServerException('अमान्य ओटीपी कोड (Invalid OTP)');
      }

      // Successful verification: reset counters
      _failedOtpAttempts = 0;
      _lockoutUntil = null;

      final userId = res.user?.id;
      if (userId == null) return null;

      // Check if profile exists
      final profileData = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null) {
        return UserProfile.fromJson(profileData);
      }

      return null; // Needs onboarding
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserProfile?> getCurrentProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final data = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserProfile> createOrUpdateProfile(UserProfile profile) async {
    try {
      final currentAuthId = _client.auth.currentUser?.id ?? profile.id;
      final payload = profile.toJson();
      payload['id'] = currentAuthId;

      // SECURITY: Strip privileged fields from client update payloads
      // Role and admin verification can only be modified server-side by admins
      payload.remove('role');
      payload.remove('verified_by_admin');
      payload.remove('kyc_status');

      final data = await _client
          .from('profiles')
          .upsert(payload)
          .select()
          .single();

      return UserProfile.fromJson(data);
    } catch (e) {
      throw ServerException('प्रोफ़ाइल सहेजने में त्रुटि: $e');
    }
  }

  @override
  Future<void> createFarmerProfile({
    required String farmerId,
    required String farmName,
    required double totalAcres,
    String? upiVpa,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankHolderName,
  }) async {
    try {
      await _client.from('farmer_profiles').upsert({
        'farmer_id': farmerId,
        'farm_name': farmName,
        'total_acres': totalAcres,
        'upi_vpa': upiVpa,
        'bank_account_number': bankAccountNumber,
        'bank_ifsc': bankIfsc,
        'bank_account_holder_name': bankHolderName,
      });
    } catch (e) {
      throw ServerException('किसान विवरण सहेजने में त्रुटि: $e');
    }
  }

  @override
  Future<void> updateFcmToken(String token) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
    } catch (_) {
      // Non-blocking
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.global);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

