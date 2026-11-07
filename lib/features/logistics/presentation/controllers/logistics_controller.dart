import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/delivery_tracking_model.dart';
import '../../domain/repositories/logistics_repository.dart';
import '../../data/repositories/logistics_repository_impl.dart';

final logisticsRepositoryProvider = Provider<LogisticsRepository>((ref) {
  return LogisticsRepositoryImpl();
});

class LogisticsState {
  final bool isLoading;
  final DeliveryTrackingModel? tracking;
  final String? errorMessage;

  const LogisticsState({
    this.isLoading = false,
    this.tracking,
    this.errorMessage,
  });

  LogisticsState copyWith({
    bool? isLoading,
    DeliveryTrackingModel? tracking,
    String? errorMessage,
  }) {
    return LogisticsState(
      isLoading: isLoading ?? this.isLoading,
      tracking: tracking ?? this.tracking,
      errorMessage: errorMessage,
    );
  }
}

class LogisticsController extends StateNotifier<LogisticsState> {
  final LogisticsRepository _repository;

  LogisticsController(this._repository) : super(const LogisticsState());

  Future<void> fetchTracking(String orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final tracking = await _repository.getOrderTracking(orderId);
      state = state.copyWith(tracking: tracking, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'ट्रैकिंग डेटा लोड नहीं हो सका: $e');
    }
  }

  Future<void> refreshLocation(String orderId) async {
    try {
      final updated = await _repository.getOrderTracking(orderId);
      state = state.copyWith(tracking: updated);
    } catch (_) {}
  }
}

final logisticsControllerProvider =
    StateNotifierProvider<LogisticsController, LogisticsState>((ref) {
  final repo = ref.watch(logisticsRepositoryProvider);
  return LogisticsController(repo);
});

