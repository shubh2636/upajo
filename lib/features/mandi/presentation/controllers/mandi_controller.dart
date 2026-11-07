import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/mandi_price_model.dart';
import '../../domain/repositories/mandi_repository.dart';
import '../../data/repositories/mandi_repository_impl.dart';

final mandiRepositoryProvider = Provider<MandiRepository>((ref) {
  return MandiRepositoryImpl();
});

class MandiState {
  final bool isLoading;
  final List<MandiPriceModel> mandiList;
  final String selectedCrop;
  final MandiPriceModel? selectedMandiForChart;
  final List<PriceAlertModel> userAlerts;
  final String? errorMessage;

  const MandiState({
    this.isLoading = false,
    this.mandiList = const [],
    this.selectedCrop = 'all',
    this.selectedMandiForChart,
    this.userAlerts = const [],
    this.errorMessage,
  });

  MandiState copyWith({
    bool? isLoading,
    List<MandiPriceModel>? mandiList,
    String? selectedCrop,
    MandiPriceModel? selectedMandiForChart,
    List<PriceAlertModel>? userAlerts,
    String? errorMessage,
  }) {
    return MandiState(
      isLoading: isLoading ?? this.isLoading,
      mandiList: mandiList ?? this.mandiList,
      selectedCrop: selectedCrop ?? this.selectedCrop,
      selectedMandiForChart: selectedMandiForChart ?? this.selectedMandiForChart,
      userAlerts: userAlerts ?? this.userAlerts,
      errorMessage: errorMessage,
    );
  }
}

class MandiController extends StateNotifier<MandiState> {
  final MandiRepository _repository;
  static const _uuid = Uuid();

  MandiController(this._repository) : super(const MandiState()) {
    loadPrices();
  }

  Future<void> loadPrices({String? crop}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final c = crop ?? state.selectedCrop;
      final list = await _repository.getMandiPrices(crop: c);
      state = state.copyWith(
        mandiList: list,
        selectedCrop: c,
        selectedMandiForChart: list.isNotEmpty ? list.first : null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'मंडी भाव लोड नहीं हो सके: $e');
    }
  }

  void selectCrop(String crop) {
    state = state.copyWith(selectedCrop: crop);
    loadPrices(crop: crop);
  }

  void selectMandiForChart(MandiPriceModel item) {
    state = state.copyWith(selectedMandiForChart: item);
  }

  Future<void> createPriceAlert({
    required String farmerId,
    required String cropName,
    required double targetPrice,
    required String condition,
  }) async {
    final alert = PriceAlertModel(
      id: _uuid.v4(),
      farmerId: farmerId,
      cropName: cropName,
      targetPrice: targetPrice,
      condition: condition,
      createdAt: DateTime.now(),
    );
    await _repository.createPriceAlert(alert);
    state = state.copyWith(userAlerts: [...state.userAlerts, alert]);
  }

  Future<void> loadAlerts(String farmerId) async {
    final alerts = await _repository.getPriceAlerts(farmerId);
    state = state.copyWith(userAlerts: alerts);
  }
}

final mandiControllerProvider =
    StateNotifierProvider<MandiController, MandiState>((ref) {
  final repo = ref.watch(mandiRepositoryProvider);
  return MandiController(repo);
});

