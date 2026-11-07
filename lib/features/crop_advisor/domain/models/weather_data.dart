class DailyForecast {
  final DateTime date;
  final double minTemp;
  final double maxTemp;
  final int rainProbability;
  final double rainMm;
  final int weatherCode;

  const DailyForecast({
    required this.date,
    required this.minTemp,
    required this.maxTemp,
    required this.rainProbability,
    required this.rainMm,
    required this.weatherCode,
  });

  String get weatherDescription {
    if (rainMm > 5.0 || rainProbability > 70) return 'वर्षा की संभावना (Rain)';
    if (weatherCode <= 1) return 'साफ धूप (Sunny)';
    if (weatherCode <= 3) return 'हल्के बादल (Partly Cloudy)';
    if (weatherCode >= 51 && weatherCode <= 65) return 'बूंदाबांदी (Showers)';
    return 'सामान्य मौसम';
  }
}

class FarmingAlert {
  final String titleHi;
  final String titleEn;
  final String severity; // 'low', 'medium', 'high', 'severe'
  final String recommendationHi;
  final String recommendationEn;

  const FarmingAlert({
    required this.titleHi,
    required this.titleEn,
    required this.severity,
    required this.recommendationHi,
    required this.recommendationEn,
  });
}

class WeatherData {
  final double currentTemp;
  final int currentHumidity;
  final double windSpeedKmH;
  final int weatherCode;
  final String conditionHi;
  final List<DailyForecast> dailyForecast;
  final List<FarmingAlert> alerts;

  const WeatherData({
    required this.currentTemp,
    required this.currentHumidity,
    required this.windSpeedKmH,
    required this.weatherCode,
    required this.conditionHi,
    required this.dailyForecast,
    required this.alerts,
  });

  bool get shouldSprayPesticide {
    // If high wind (>20 km/h) or high rain probability (>50%), spray is NOT recommended
    if (windSpeedKmH > 20.0) return false;
    if (dailyForecast.isNotEmpty && dailyForecast.first.rainProbability > 50) return false;
    return true;
  }
}
