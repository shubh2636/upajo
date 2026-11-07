import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/crop_input_params.dart';
import '../../domain/models/crop_recommendation.dart';
import '../../domain/models/weather_data.dart';
import '../../domain/repositories/crop_advisor_repository.dart';
import '../../data/repositories/crop_advisor_repository_impl.dart';

final cropAdvisorRepositoryProvider = Provider<CropAdvisorRepository>((ref) {
  return CropAdvisorRepositoryImpl();
});

class CropAdvisorState {
  final bool isLoading;
  final bool isWeatherLoading;
  final String? errorMessage;
  final WeatherData? weatherData;
  final CropRecommendation? recommendation;
  final List<CropCalendarTask> activeTasks;
  final String selectedSoilType;
  final String selectedSeason;
  final String selectedWaterSource;
  final double landAreaAcres;
  final String district;
  final String stateName;
  final bool isPlanSaved;

  const CropAdvisorState({
    this.isLoading = false,
    this.isWeatherLoading = false,
    this.errorMessage,
    this.weatherData,
    this.recommendation,
    this.activeTasks = const [],
    this.selectedSoilType = 'black_soil',
    this.selectedSeason = 'rabi',
    this.selectedWaterSource = 'tube_well',
    this.landAreaAcres = 2.0,
    this.district = 'सीहोर',
    this.stateName = 'मध्य प्रदेश',
    this.isPlanSaved = false,
  });

  CropAdvisorState copyWith({
    bool? isLoading,
    bool? isWeatherLoading,
    String? errorMessage,
    WeatherData? weatherData,
    CropRecommendation? recommendation,
    List<CropCalendarTask>? activeTasks,
    String? selectedSoilType,
    String? selectedSeason,
    String? selectedWaterSource,
    double? landAreaAcres,
    String? district,
    String? stateName,
    bool? isPlanSaved,
  }) {
    return CropAdvisorState(
      isLoading: isLoading ?? this.isLoading,
      isWeatherLoading: isWeatherLoading ?? this.isWeatherLoading,
      errorMessage: errorMessage,
      weatherData: weatherData ?? this.weatherData,
      recommendation: recommendation ?? this.recommendation,
      activeTasks: activeTasks ?? this.activeTasks,
      selectedSoilType: selectedSoilType ?? this.selectedSoilType,
      selectedSeason: selectedSeason ?? this.selectedSeason,
      selectedWaterSource: selectedWaterSource ?? this.selectedWaterSource,
      landAreaAcres: landAreaAcres ?? this.landAreaAcres,
      district: district ?? this.district,
      stateName: stateName ?? this.stateName,
      isPlanSaved: isPlanSaved ?? this.isPlanSaved,
    );
  }
}

class CropAdvisorController extends StateNotifier<CropAdvisorState> {
  final CropAdvisorRepository _repository;

  CropAdvisorController(this._repository) : super(const CropAdvisorState()) {
    init();
  }

  Future<void> init({double lat = 23.2032, double lon = 77.0844}) async {
    await fetchWeather(lat: lat, lon: lon);
  }

  Future<void> fetchWeather({required double lat, required double lon}) async {
    state = state.copyWith(isWeatherLoading: true, errorMessage: null);
    try {
      final weather = await _repository.getLiveWeatherAndAlerts(
        latitude: lat,
        longitude: lon,
      );
      state = state.copyWith(weatherData: weather, isWeatherLoading: false);
    } catch (e) {
      state = state.copyWith(
        isWeatherLoading: false,
        errorMessage: 'मौसम डेटा प्राप्त नहीं हो सका: $e',
      );
    }
  }

  void setSoilType(String soil) {
    state = state.copyWith(selectedSoilType: soil);
  }

  void setSeason(String season) {
    state = state.copyWith(selectedSeason: season);
  }

  void setWaterSource(String source) {
    state = state.copyWith(selectedWaterSource: source);
  }

  void setLandArea(double acres) {
    if (acres > 0) {
      state = state.copyWith(landAreaAcres: acres);
    }
  }

  Future<void> getRecommendation() async {
    state = state.copyWith(isLoading: true, errorMessage: null, isPlanSaved: false);
    try {
      final params = CropInputParams(
        soilType: state.selectedSoilType,
        landAreaAcres: state.landAreaAcres,
        season: state.selectedSeason,
        waterSource: state.selectedWaterSource,
        district: state.district,
        state: state.stateName,
      );

      final rec = await _repository.getRecommendation(params);
      state = state.copyWith(
        recommendation: rec,
        activeTasks: rec.calendarSchedule,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'फसल सिफारिश में त्रुटि: $e',
      );
    }
  }

  Future<void> saveCurrentPlan({
    required String farmerId,
    required DateTime sowingDate,
  }) async {
    if (state.recommendation == null) return;
    state = state.copyWith(isLoading: true);
    try {
      await _repository.saveCropPlanAndTasks(
        farmerId: farmerId,
        recommendation: state.recommendation!,
        sowingDate: sowingDate,
        landAreaAcres: state.landAreaAcres,
        soilType: state.selectedSoilType,
        waterSource: state.selectedWaterSource,
      );
      state = state.copyWith(isLoading: false, isPlanSaved: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'योजना सहेजने में त्रुटि: $e',
      );
    }
  }

  Future<void> loadFarmerTasks(String farmerId) async {
    state = state.copyWith(isLoading: true);
    try {
      final tasks = await _repository.getFarmerActiveTasks(farmerId);
      state = state.copyWith(activeTasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'कैलेंडर कार्य लोड नहीं हो सके: $e',
      );
    }
  }

  Future<void> toggleTask(String taskId, bool isCompleted) async {
    final updated = state.activeTasks.map((t) {
      if (t.id == taskId) {
        return t.copyWith(isCompleted: isCompleted);
      }
      return t;
    }).toList();

    state = state.copyWith(activeTasks: updated);
    await _repository.toggleTaskCompletion(taskId, isCompleted);
  }
}

final cropAdvisorControllerProvider =
    StateNotifierProvider<CropAdvisorController, CropAdvisorState>((ref) {
  final repo = ref.watch(cropAdvisorRepositoryProvider);
  return CropAdvisorController(repo);
});

