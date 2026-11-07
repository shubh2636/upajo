import '../models/crop_input_params.dart';
import '../models/crop_recommendation.dart';
import '../models/weather_data.dart';

abstract class CropAdvisorRepository {
  /// Obtains rule-based / ML crop recommendations
  Future<CropRecommendation> getRecommendation(CropInputParams params);

  /// Fetches live Open-Meteo weather and calculates farming alerts
  Future<WeatherData> getLiveWeatherAndAlerts({
    required double latitude,
    required double longitude,
  });

  /// Saves the active crop plan and schedules calendar tasks in Supabase
  Future<void> saveCropPlanAndTasks({
    required String farmerId,
    required CropRecommendation recommendation,
    required DateTime sowingDate,
    required double landAreaAcres,
    required String soilType,
    required String waterSource,
  });

  /// Fetches active tasks for a farmer
  Future<List<CropCalendarTask>> getFarmerActiveTasks(String farmerId);

  /// Toggles task completion state
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted);
}
