import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

class AuthState {
  final UserProfile? userProfile;
  final bool isLoading;
  final String? errorMessage;
  final String? pendingPhone;
  final String selectedRole; // 'farmer' or 'consumer'

  const AuthState({
    this.userProfile,
    this.isLoading = false,
    this.errorMessage,
    this.pendingPhone,
    this.selectedRole = 'farmer',
  });

  AuthState copyWith({
    UserProfile? userProfile,
    bool? isLoading,
    String? errorMessage,
    String? pendingPhone,
    String? selectedRole,
  }) {
    return AuthState(
      userProfile: userProfile ?? this.userProfile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pendingPhone: pendingPhone ?? this.pendingPhone,
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState()) {
    checkCurrentSession();
  }

  Future<void> checkCurrentSession() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.getCurrentProfile();
      state = state.copyWith(userProfile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSelectedRole(String role) {
    // Only 'farmer' or 'consumer' can be selected by end users.
    // 'admin' role cannot be assigned through user role selection.
    if (role == 'farmer' || role == 'consumer') {
      state = state.copyWith(selectedRole: role);
    }
  }

  Future<bool> sendOtp(String phone) async {
    state = state.copyWith(isLoading: true, errorMessage: null, pendingPhone: phone);
    try {
      await _repository.sendOtp(phone);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool?> verifyOtp(String token) async {
    final phone = state.pendingPhone;
    if (phone == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.verifyOtp(phone: phone, token: token);
      if (profile != null) {
        state = state.copyWith(userProfile: profile, isLoading: false);
        return true; // Existing profile
      } else {
        state = state.copyWith(isLoading: false);
        return null; // Needs onboarding
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> completeOnboarding({
    required String fullName,
    required String villageOrCity,
    required String district,
    required String stateName,
    required String pinCode,
    String? addressLine,
    String? farmName,
    double totalAcres = 0.0,
  }) async {
    final phone = state.pendingPhone ?? state.userProfile?.phone ?? '';
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final newProfile = UserProfile(
        id: state.userProfile?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
        role: state.selectedRole,
        phone: phone.replaceAll(RegExp(r'[^0-9]'), ''),
        fullName: fullName,
        villageOrCity: villageOrCity,
        district: district,
        state: stateName,
        pinCode: pinCode,
        addressLine: addressLine,
        kycStatus: state.selectedRole == 'farmer' ? 'pending' : 'verified',
        verifiedByAdmin: state.selectedRole != 'farmer',
        createdAt: DateTime.now(),
      );

      final saved = await _repository.createOrUpdateProfile(newProfile);

      if (state.selectedRole == 'farmer') {
        await _repository.createFarmerProfile(
          farmerId: saved.id,
          farmName: farmName ?? '$fullName का खेत',
          totalAcres: totalAcres,
        );
      }

      state = state.copyWith(userProfile: saved, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

