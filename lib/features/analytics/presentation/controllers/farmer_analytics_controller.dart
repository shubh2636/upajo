import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/farmer_analytics_model.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../data/repositories/analytics_repository_impl.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl();
});

class FarmerAnalyticsState {
  final bool isLoading;
  final FarmerAnalyticsModel? analytics;
  final String? errorMessage;

  const FarmerAnalyticsState({
    this.isLoading = false,
    this.analytics,
    this.errorMessage,
  });

  FarmerAnalyticsState copyWith({
    bool? isLoading,
    FarmerAnalyticsModel? analytics,
    String? errorMessage,
  }) {
    return FarmerAnalyticsState(
      isLoading: isLoading ?? this.isLoading,
      analytics: analytics ?? this.analytics,
      errorMessage: errorMessage,
    );
  }
}

class FarmerAnalyticsController extends StateNotifier<FarmerAnalyticsState> {
  final AnalyticsRepository _repository;

  FarmerAnalyticsController(this._repository) : super(const FarmerAnalyticsState());

  Future<void> loadAnalytics(String farmerId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repository.getFarmerAnalytics(farmerId);
      state = state.copyWith(analytics: data, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final farmerAnalyticsControllerProvider =
    StateNotifierProvider<FarmerAnalyticsController, FarmerAnalyticsState>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return FarmerAnalyticsController(repo);
});

