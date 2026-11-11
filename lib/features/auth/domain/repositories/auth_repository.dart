import '../models/user_profile.dart';

/// Authentication repository interface for Upajo.
/// 
/// IMPORTANT NOTICE:
/// Phone numbers are NOT verified via SMS OTP because no SMS provider is active.
/// Password reset via SMS is unavailable until an SMS gateway (DLT) is configured.
abstract class AuthRepository {
  /// Sign up with phone/email and password.
  /// If [email] is omitted, a synthetic email format (<10digit>@phone.upajo.invalid / fallback)
  /// is generated so that the mobile number serves as the Supabase Auth login identifier.
  Future<UserProfile> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
  });

  /// Log in with either 10-digit mobile number OR email + password.
  /// Mobile number is mapped directly to the internal email format on the client
  /// with zero external user lookup to prevent user enumeration attacks.
  Future<UserProfile> signInWithPassword({
    required String identifier,
    required String password,
  });

  /// Feature-flagged OTP operations (disabled by default until SMS provider is added)
  Future<void> sendOtp(String phone);

  Future<UserProfile?> verifyOtp({
    required String phone,
    required String token,
  });

  Future<void> resetPasswordWithOtp({
    required String phone,
    required String otpToken,
    required String newPassword,
  });

  Future<UserProfile?> getCurrentProfile();

  Future<UserProfile?> restoreSession();

  Future<UserProfile> createOrUpdateProfile(UserProfile profile);

  Future<void> completeProfile({
    required String villageOrCity,
    required String district,
    required String state,
    required String pinCode,
  });

  Future<void> createFarmerProfile({
    required String farmerId,
    required String farmName,
    required double totalAcres,
    String? upiVpa,
    String? bankAccountNumber,
    String? bankIfsc,
    String? bankHolderName,
  });

  Future<void> updateFcmToken(String token);

  Future<void> signOut();

  Future<void> signOutAllDevices();
}
