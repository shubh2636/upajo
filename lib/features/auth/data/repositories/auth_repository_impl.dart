import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/errors/exceptions.dart' hide AuthException;
import '../../../../core/network/supabase_client.dart';
import '../../../../core/storage/secure_storage_service.dart';

/// Authentication repository implementation for Upajo (उपजो).
/// 
/// AUTHENTICATION MODEL & COMPLIANCE:
/// - Pure Mobile Number + Password (with optional email) backed by Supabase Auth.
/// - When phone is supplied without email, a deterministic synthetic email is generated:
///   `<10digit>@phone.upajo.invalid` (with automatic fallback to `<10digit>@phone.upajo.com`
///   if hosted DNS enforcement rejects RFC 2606 .invalid domains).
/// - SMS OTP is strictly disabled (no SMS provider / DLT exists).
/// - NOTICE: Phone numbers are NOT SMS-verified. Password reset via SMS is unavailable
///   until an approved transactional SMS provider is integrated.
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _client;
  final SecureStorageService _secureStorage;

  // Rate Limiting & Lockout Parameters
  static int _failedLoginAttempts = 0;
  static DateTime? _lockoutUntil;
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);

  AuthRepositoryImpl({
    SupabaseClient? client,
    SecureStorageService? secureStorage,
  })  : _client = client ?? SupabaseService.client,
        _secureStorage = secureStorage ?? SecureStorageService();

  /// Cleans and formats an Indian mobile number to strict 10 digits.
  String _clean10DigitPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length == 10) {
      if (!RegExp(r'^[6-9]').hasMatch(cleaned)) {
        throw const ServerException('कृपया वैध 10-अंकों का भारतीय मोबाइल नंबर दर्ज करें (Invalid Indian mobile prefix)');
      }
      return cleaned;
    } else if (cleaned.length == 12 && cleaned.startsWith('91')) {
      final sub = cleaned.substring(2);
      if (!RegExp(r'^[6-9]').hasMatch(sub)) {
        throw const ServerException('कृपया वैध 10-अंकों का भारतीय मोबाइल नंबर दर्ज करें (Invalid Indian mobile prefix)');
      }
      return sub;
    }
    throw const ServerException('कृपया 10 अंकों का वैध मोबाइल नंबर दर्ज करें (Please enter a valid 10-digit phone number)');
  }

  /// Maps an identifier (mobile number or email) to the internal Supabase Auth email.
  /// No external lookup is performed to prevent user enumeration attacks.
  String _mapIdentifierToEmail(String identifier, {bool useFallback = false}) {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) {
      return trimmed.toLowerCase();
    }
    final cleanPhone = _clean10DigitPhone(trimmed);
    return useFallback
        ? '$cleanPhone@phone.upajo.com'
        : '$cleanPhone@phone.upajo.invalid';
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
  Future<UserProfile> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
  }) async {
    _checkLockout();

    // Prevent privilege escalation: User can never self-assign admin role
    if (role == 'admin') {
      throw const ServerException('सुरक्षा उल्लंघन: एडमिन भूमिका केवल आंतरिक सिस्टम द्वारा दी जा सकती है। (Cannot self-assign admin role)');
    }
    final assignedRole = (role == 'farmer') ? 'farmer' : 'consumer';

    if (password.length < 8) {
      throw const ServerException('पासवर्ड में न्यूनतम 8 अक्षर होने चाहिए (Password must be at least 8 characters)');
    }

    final cleanPhone = _clean10DigitPhone(phone);

    // Determine registration email
    String authEmail;
    bool hasUserEmail = false;
    if (email != null && email.trim().isNotEmpty && email.contains('@')) {
      authEmail = email.trim().toLowerCase();
      hasUserEmail = true;
    } else {
      authEmail = _mapIdentifierToEmail(cleanPhone);
    }

    try {
      AuthResponse res;
      try {
        res = await _client.auth.signUp(
          email: authEmail,
          password: password,
          data: {
            'phone': cleanPhone,
            'full_name': fullName.trim(),
            'role': assignedRole,
          },
        );
      } catch (authErr) {
        // If hosted Supabase GoTrue rejects .invalid TLD with email_address_invalid, retry with fallback domain
        if (!hasUserEmail && authErr.toString().contains('email_address_invalid')) {
          authEmail = _mapIdentifierToEmail(cleanPhone, useFallback: true);
          res = await _client.auth.signUp(
            email: authEmail,
            password: password,
            data: {
              'phone': cleanPhone,
              'full_name': fullName.trim(),
              'role': assignedRole,
            },
          );
        } else {
          rethrow;
        }
      }

      final user = res.user;
      if (user == null) {
        throw const ServerException('पंजीकरण असफल रहा। कृपया पुनः प्रयास करें। (Registration failed)');
      }

      // Check if session was returned; if not, autoconfirm email is off in Supabase
      if (res.session == null) {
        // Try direct sign in immediately in case autoconfirm was processed by trigger
        try {
          final loginRes = await _client.auth.signInWithPassword(
            email: authEmail,
            password: password,
          );
          if (loginRes.session != null) {
            res = loginRes;
          }
        } catch (_) {
          throw const ServerException(
            'खाता बन गया है परंतु पुष्टि प्रतीक्षित है। कृपया Supabase Dashboard > Authentication > Providers > Email में "Confirm email" को OFF करें।',
          );
        }
      }

      // Ensure profile row exists (created either by Postgres trigger or explicit upsert)
      final profilePayload = {
        'id': user.id,
        'phone': cleanPhone,
        'full_name': fullName.trim(),
        'role': assignedRole,
        'preferred_language': 'hi',
        'kyc_status': assignedRole == 'farmer' ? 'pending' : 'verified',
        'verified_by_admin': assignedRole != 'farmer',
      };

      try {
        await _client.from('profiles').upsert(profilePayload);
      } catch (upsertErr) {
        debugPrint('Profile auto-trigger active or upsert notice: $upsertErr');
      }

      if (assignedRole == 'farmer') {
        try {
          await _client.from('farmer_profiles').upsert({
            'farmer_id': user.id,
            'farm_name': '${fullName.trim()} Farm',
            'total_acres': 0.0,
          });
        } catch (_) {}
      }

      final session = res.session;
      if (session != null) {
        await _secureStorage.saveAuthSession(
          accessToken: session.accessToken,
          refreshToken: session.refreshToken ?? '',
          userId: user.id,
          phone: cleanPhone,
          role: assignedRole,
        );
      }

      return UserProfile(
        id: user.id,
        phone: cleanPhone,
        fullName: fullName.trim(),
        role: assignedRole,
        preferredLanguage: 'hi',
        kycStatus: assignedRole == 'farmer' ? 'pending' : 'verified',
        verifiedByAdmin: assignedRole != 'farmer',
        villageOrCity: '',
        district: '',
        state: '',
        createdAt: DateTime.now(),
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered')) {
        throw const ServerException('यह मोबाइल नंबर/ईमेल पहले से पंजीकृत है। कृपया लॉगिन करें। (Account already exists)');
      }
      throw ServerException(e.message);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('पंजीकरण में त्रुटि: $e');
    }
  }

  @override
  Future<UserProfile> signInWithPassword({
    required String identifier,
    required String password,
  }) async {
    _checkLockout();

    final isEmail = identifier.contains('@');
    final primaryEmail = _mapIdentifierToEmail(identifier, useFallback: false);
    final fallbackEmail = isEmail ? primaryEmail : _mapIdentifierToEmail(identifier, useFallback: true);

    try {
      AuthResponse res;
      try {
        res = await _client.auth.signInWithPassword(
          email: primaryEmail,
          password: password,
        );
      } catch (err) {
        // If not a direct email and primary synthetic address failed, try fallback domain
        if (!isEmail) {
          try {
            res = await _client.auth.signInWithPassword(
              email: fallbackEmail,
              password: password,
            );
          } catch (_) {
            throw err;
          }
        } else {
          rethrow;
        }
      }

      final user = res.user;
      final session = res.session;

      if (user == null || session == null) {
        throw const ServerException('लॉगिन विफल रहा (Login failed)');
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
        throw const ServerException(
          '5 बार गलत पासवर्ड दर्ज किया गया। सुरक्षा हेतु 15 मिनट के लिए लॉक किया गया है (Account locked for 15 minutes due to 5 failed attempts)',
        );
      }
      // Generic error prevents user enumeration
      throw const ServerException('गलत मोबाइल नंबर/ईमेल या पासवर्ड (Invalid mobile number/email or password)');
    } catch (e) {
      if (e is ServerException) rethrow;
      throw const ServerException('गलत मोबाइल नंबर/ईमेल या पासवर्ड (Invalid mobile number/email or password)');
    }
  }

  @override
  Future<void> sendOtp(String phone) async {
    if (!AppConstants.enableOtpAuth) {
      throw const ServerException(
        'SMS OTP प्रमाणीकरण वर्तमान में अक्षम है। कृपया मोबाइल नंबर और पासवर्ड का उपयोग करें। (SMS OTP is disabled. Use mobile number and password.)',
      );
    }
    _checkLockout();
    final clean = _clean10DigitPhone(phone);
    await _client.auth.signInWithOtp(phone: '+91$clean');
  }

  @override
  Future<UserProfile?> verifyOtp({
    required String phone,
    required String token,
  }) async {
    if (!AppConstants.enableOtpAuth) {
      throw const ServerException(
        'SMS OTP प्रमाणीकरण अक्षम है। (SMS OTP is disabled)',
      );
    }
    _checkLockout();
    final clean = _clean10DigitPhone(phone);

    final res = await _client.auth.verifyOTP(
      phone: '+91$clean',
      token: token.trim(),
      type: OtpType.sms,
    );

    final user = res.user;
    final session = res.session;
    if (user == null || session == null) {
      throw const ServerException('अमान्य या समाप्त ओटीपी कोड (Invalid or expired OTP)');
    }

    final profileData = await _client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    if (profileData == null) return null;

    final profile = UserProfile.fromJson(profileData);
    await _secureStorage.saveAuthSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
      userId: user.id,
      phone: profile.phone,
      role: profile.role,
    );

    return profile;
  }

  @override
  Future<void> resetPasswordWithOtp({
    required String phone,
    required String otpToken,
    required String newPassword,
  }) async {
    throw const ServerException(
      'SMS द्वारा पासवर्ड रीसेट सेवा उपलब्ध नहीं है (कोई SMS गेटवे सक्रिय नहीं है)। कृपया ग्राहक सहायता से संपर्क करें। (SMS password reset unavailable without SMS provider.)',
    );
  }

  @override
  Future<UserProfile?> restoreSession() async {
    try {
      final currentAuthUser = _client.auth.currentUser;
      if (currentAuthUser != null) {
        final profile = await getCurrentProfile();
        if (profile != null) return profile;
      }

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
      throw const ServerException('सत्र समाप्त हो गया है। कृपया पुनः लॉगिन करें। (Session expired)');
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
