import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phone);

  Future<UserProfile?> verifyOtp({
    required String phone,
    required String token,
  });

  Future<UserProfile?> getCurrentProfile();

  Future<UserProfile> createOrUpdateProfile(UserProfile profile);

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
}

