import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phone);

  Future<UserProfile?> verifyOtp({
    required String phone,
    required String token,
  });

  Future<UserProfile> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    required String role,
  });

  Future<UserProfile> signInWithPassword({
    required String phone,
    required String password,
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
