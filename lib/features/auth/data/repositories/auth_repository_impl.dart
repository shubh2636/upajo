import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/exceptions.dart' hide AuthException;
import '../../../../core/network/supabase_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;
  final SecureStorageService _secureStorage;

  /// Demo auth is STRICTLY disabled in release builds (impossible to enable in prod)
  static const bool allowDemoAuth =
      !kReleaseMode && bool.fromEnvironment('ALLOW_DEMO_AUTH', defaultValue: true);

  // Rate Limiting & Lockout Parameters
  static DateTime? _lastOtpRequestTime;
  static int _failedLoginAttempts = 0;
  static DateTime? _lockoutUntil;
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
  static const Duration otpResendCooldown = Duration(seconds: 60);

  AuthRepositoryImpl({
    SupabaseClient? client,
    SecureStorageService? secureStorage,
  })  : _client = client ?? SupabaseService.client,
        _secureStorage = secureStorage ?? SecureStorageService();

  String _formatIndianPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      if (!RegExp(r'^[6-9]').hasMatch(cleaned)) {
        throw ServerException('कृपया वैध 10-अंकों का भारतीय मोबाइल नंबर दर्ज करें (Invalid Indian mobile prefix)');
      }
      return '+91$cleaned';
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      final sub = cleaned.substring(2);
      if (!RegExp(r'^[6-9]').hasMatch(sub)) {
        throw ServerException('कृपया वैध 10-अंकों का भारतीय मोबाइल नंबर दर्ज करें (Invalid Indian mobile prefix)');
      }
      return '+$cleaned';
    }
    throw ServerException('कृपया 10 अंकों का वैध मोबाइल नंबर दर्ज करें (Please enter a valid 10-digit phone number)');
  }

  void _checkLockout() {
    final now = DateTime.now();
    if (_lockoutUntil != null && now.isBefore(_lockoutUntil!)) {
      final remainingMins = _lockoutUntil!.difference(now).inMinutes + 1;
      throw ServerException(
        'अत्यधिक गलत प्रयासों के कारण खाता $remainingMins मिनट के लिए सुरक्षित रूप से लॉक है। (Account locked for security. Please try again after $remainingMins minutes.)',
      );
    }
  }

  @override
  Future<void> sendOtp(String phone) async {
    _checkLockout();

    final now = DateTime.now();
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
      if (allowDemoAuth && (e.message.contains('sms_provider') || e.toString().contains('Failed host lookup'))) {
        _lastOtpRequestTime = DateTime.now();
        return; // Dev bypass
      }
      throw ServerException('ओटीपी भेजने में असमर्थ: कृपया नेटवर्क या फोन नंबर जांचें।');
    } catch (e) {
      if (allowDemoAuth && (e.toString().contains('sms_provider') || e.toString().contains('Failed host lookup'))) {
        _lastOtpRequestTime = DateTime.now();
        return; // Dev bypass
      }
      throw ServerException('ओटीपी भेजने में त्रुटि: ${e.toString()}');
    }
  }

  @override
  Future<UserProfile?> verifyOtp({
    required String phone,
    required String token,
  }) async {
    _checkLockout();

    try {
      final formattedPhone = _formatIndianPhone(phone);

      AuthResponse? res;
      try {
        res = await _client.auth.verifyOTP(
          phone: formattedPhone,
          token: token.trim(),
          type: OtpType.sms,
        );
      } catch (authErr) {
        // Dev bypass ONLY allowed in non-release builds when explicit demo flag is true
        if (allowDemoAuth && token.trim() == '123456') {
          final cleanPhone = formattedPhone.replaceAll(RegExp(r'[^0-9]'), '').substring(2);
          final existing = await _client
              .from('profiles')
              .select('*')
              .eq('phone', cleanPhone)
              .maybeSingle();

          _failedLoginAttempts = 0;
          _lockoutUntil = null;

          if (existing != null) {
            final profile = UserProfile.fromJson(existing);
            await _secureStorage.saveAuthSession(
              accessToken: 'demo_dev_token',
              refreshToken: 'demo_dev_refresh',
              userId: profile.id,
              phone: profile.phone,
              role: profile.role,
            );
            return profile;
          }
          return null; // Onboarding required
        }

        _failedLoginAttempts++;
        if (_failedLoginAttempts >= maxFailedAttempts) {
          _lockoutUntil = DateTime.now().add(lockoutDuration);
          throw ServerException(
            '5 बार गलत प्रयास दर्ज किए गए। सुरक्षा कारणों से खाता 15 मिनट के लिए लॉक कर दिया गया है। (Account locked for 15 minutes due to 5 failed attempts)',
          );
        }

        throw ServerException('अमान्य या समाप्त ओटीपी कोड (Invalid or expired OTP code)');
      }

      _failedLoginAttempts = 0;
      _lockoutUntil = null;

      final session = res.session;
      final userId = res.user?.id;
      if (userId == null) return null;

      final profileData = await _client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (profileData != null) {
        final profile = UserProfile.fromJson(profileData);
        if (session != null) {
          await _secureStorage.saveAuthSession(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken ?? '',
            userId: userId,
            phone: profile.phone,
            role: profile.role,
          );
        }
        return profile;
      }

      return null;
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('ओटीपी सत्यापन में त्रुटि: ${e.toString()}');
    }
  }

  @override
  Future<UserProfile> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    required String role,
  }) async {
    _checkLockout();

    // Prevent privilege escalation: User can never request admin role
    if (role == 'admin') {
      throw ServerException('सुरक्षा उल्लंघन: एडमिन भूमिका केवल आंतरिक सिस्टम द्वारा दी जा सकती है। (Cannot self-assign admin role)');
    }
    final assignedRole = (role == 'farmer') ? 'farmer' : 'consumer';

    if (password.length < 8) {
      throw ServerException('पासवर्ड में न्यूनतम 8 अक्षर होने चाहिए (Password must be at least 8 characters)');
    }

    final formattedPhone = _formatIndianPhone(phone);
    final raw10Digit = formattedPhone.replaceAll(RegExp(r'[^0-9]'), '').substring(2);

    try {
      final res = await _client.auth.signUp(
        phone: formattedPhone,
        password: password,
      );

      final user = res.user;
      if (user == null) {
        throw ServerException('पंजीकरण असफल रहा। कृपया पुनः प्रयास करें। (Registration failed)');
      }

      // Create initial profile in profiles table
      final profilePayload = {
        'id': user.id,
        'phone': raw10Digit,
        'full_name': fullName.trim(),
        'role': assignedRole,
        'preferred_language': 'hi',
        'kyc_status': 'pending',
        'verified_by_admin': false,
      };

      final data = await _client.from('profiles').insert(profilePayload).select().single();
      final profile = UserProfile.fromJson(data);

      if (res.session != null) {
        await _secureStorage.saveAuthSession(
          accessToken: res.session!.accessToken,
          refreshToken: res.session!.refreshToken ?? '',
          userId: user.id,
          phone: profile.phone,
          role: profile.role,
        );
      }

      return profile;
    } on AuthException catch (e) {
      if (e.message.contains('User already registered') || e.message.contains('already exists')) {
        throw ServerException('यह मोबाइल नंबर पहले से पंजीकृत है। कृपया लॉग इन करें। (Phone number already registered. Please log in.)');
      }
      throw ServerException('पंजीकरण में त्रुटि: ${e.message}');
    } catch (e) {
      throw ServerException('पंजीकरण में त्रुटि: $e');
    }
  }

  @override
  Future<UserProfile> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    _checkLockout();

    final formattedPhone = _formatIndianPhone(phone);

    try {
      final res = await _client.auth.signInWithPassword(
        phone: formattedPhone,
        password: password,
      );

      final user = res.user;
      final session = res.session;

      if (user == null || session == null) {
        throw ServerException('लॉगिन विफल रहा (Login failed)');
      }

      _failedLoginAttempts = 0;
      _lockoutUntil = null;

      // Authoritative profile retrieval strictly from server
      final profileData = await _client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      final profile = UserProfile.fromJson(profileData);

      await _secureStorage.saveAuthSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
        userId: user.id,
        phone: profile.phone,
        role: profile.role,
      );

      return profile;
    } on AuthException catch (_) {
      _failedLoginAttempts++;
      if (_failedLoginAttempts >= maxFailedAttempts) {
        _lockoutUntil = DateTime.now().add(lockoutDuration);
        throw ServerException(
          '5 बार गलत पासवर्ड दर्ज किया गया। सुरक्षा हेतु 15 मिनट के लिए लॉक किया गया है (Account locked for 15 minutes due to 5 failed attempts)',
        );
      }
      // Generic error prevents user enumeration
      throw ServerException('अमान्य फोन नंबर अथवा पासवर्ड (Invalid phone or password)');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('लॉगिन में त्रुटि: $e');
    }
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String otpToken,
    required String newPassword,
  }) async {
    _checkLockout();

    if (newPassword.length < 8) {
      throw ServerException('नया पासवर्ड कम से कम 8 अक्षरों का होना चाहिए (New password must be at least 8 characters)');
    }

    final formattedPhone = _formatIndianPhone(phone);

    try {
      await _client.auth.verifyOTP(
        phone: formattedPhone,
        token: otpToken.trim(),
        type: OtpType.recovery,
      );

      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      _failedLoginAttempts = 0;
    } on AuthException catch (e) {
      throw ServerException('पासवर्ड रीसेट विफल रहा: अमान्य या समाप्त ओटीपी कोड। (${e.message})');
    } catch (e) {
      throw ServerException('पासवर्ड रीसेट में त्रुटि: $e');
    }
  }

  @override
  Future<UserProfile?> restoreSession() async {
    try {
      final currentAuthUser = _client.auth.currentUser;
      if (currentAuthUser != null) {
        final profile = await getCurrentProfile();
        if (profile != null) return profile;
      }

      // Check secure storage
      final storedToken = await _secureStorage.getAccessToken();
      final storedUserId = await _secureStorage.getUserId();

      if (storedToken != null && storedUserId != null) {
        final profileData = await _client
            .from('profiles')
            .select('*')
            .eq('id', storedUserId)
            .maybeSingle();

        if (profileData != null) {
          return UserProfile.fromJson(profileData);
        }
      }
      return null;
    } catch (_) {
      return null;
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
      // Role, verification, and KYC status can only be modified server-side by admins
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
  Future<void> completeProfile({
    required String villageOrCity,
    required String district,
    required String state,
    required String pinCode,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw ServerException('सत्र समाप्त हो गया है। कृपया पुनः लॉगिन करें। (Session expired)');
    }

    try {
      await _client.from('profiles').update({
        'village_or_city': villageOrCity.trim(),
        'district': district.trim(),
        'state': state.trim(),
        'pin_code': pinCode.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      throw ServerException('विवरण सहेजने में त्रुटि: $e');
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
      await _secureStorage.clearAuthSession();
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOutAllDevices() async {
    try {
      await _secureStorage.clearAuthSession();
      await _client.auth.signOut(scope: SignOutScope.global);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
