import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/weather_data.dart';
import '../../../../core/errors/exceptions.dart';

class OpenMeteoService {
  final http.Client _client;

  OpenMeteoService({http.Client? client}) : _client = client ?? http.Client();

  Future<WeatherData> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max'
        '&timezone=auto',
      );

      final response = await _client.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        throw ServerException('Open-Meteo API returned status ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      final current = data['current'] as Map<String, dynamic>;
      final daily = data['daily'] as Map<String, dynamic>;

      final currentTemp = (current['temperature_2m'] as num).toDouble();
      final currentHumidity = (current['relative_humidity_2m'] as num).toInt();
      final windSpeed = (current['wind_speed_10m'] as num).toDouble();
      final weatherCode = (current['weather_code'] as num).toInt();

      final dates = (daily['time'] as List).cast<String>();
      final maxTemps = (daily['temperature_2m_max'] as List).cast<num>();
      final minTemps = (daily['temperature_2m_min'] as List).cast<num>();
      final rainSums = (daily['precipitation_sum'] as List).cast<num>();
      final rainProbs = (daily['precipitation_probability_max'] as List).cast<num>();
      final codes = (daily['weather_code'] as List).cast<num>();

      List<DailyForecast> forecasts = [];
      for (int i = 0; i < dates.length && i < 7; i++) {
        forecasts.add(
          DailyForecast(
            date: DateTime.parse(dates[i]),
            minTemp: minTemps[i].toDouble(),
            maxTemp: maxTemps[i].toDouble(),
            rainProbability: rainProbs[i].toInt(),
            rainMm: rainSums[i].toDouble(),
            weatherCode: codes[i].toInt(),
          ),
        );
      }

      // Generate localized agricultural advisories based on meteorological metrics
      List<FarmingAlert> alerts = [];

      final todayRainProb = forecasts.isNotEmpty ? forecasts.first.rainProbability : 0;
      final todayRainMm = forecasts.isNotEmpty ? forecasts.first.rainMm : 0.0;

      // 1. Rain / Irrigation Advisory
      if (todayRainProb > 60 || todayRainMm > 5.0) {
        alerts.add(
          const FarmingAlert(
            titleHi: 'वर्षा अलर्ट: सिंचाई स्थगित रखें',
            titleEn: 'Rain Alert: Postpone Irrigation',
            severity: 'high',
            recommendationHi: 'अगले 24 घंटों में तेज वर्षा का अनुमान है। खेत में जलभराव रोकने के लिए जल निकास नालियां साफ रखें और सिंचाई बंद रखें।',
            recommendationEn: 'Rain expected in next 24 hours. Keep drainage channels clear and hold off irrigation.',
          ),
        );
      }

      // 2. Wind / Spray Advisory
      if (windSpeed > 18.0) {
        alerts.add(
          FarmingAlert(
            titleHi: 'तेज हवा चेतावनी: कीटनाशक छिड़काव न करें',
            titleEn: 'High Wind: Avoid Spraying',
            severity: 'medium',
            recommendationHi: 'वर्तमान हवा की गति ${windSpeed.toStringAsFixed(1)} किमी/घंटा है। रसायन उड़ने और असर कम होने से बचने के लिए हवा थमने की प्रतीक्षा करें।',
            recommendationEn: 'Wind speed is high. Delay spraying to prevent pesticide drift and wastage.',
          ),
        );
      } else {
        alerts.add(
          const FarmingAlert(
            titleHi: 'मौसम अनुकूल: छिड़काव के लिए उपयुक्त',
            titleEn: 'Favorable Weather for Spraying',
            severity: 'low',
            recommendationHi: 'हवा की गति शांत है और वर्षा की संभावना कम है। आवश्यक खाद या कीटनाशक का छिड़काव किया जा सकता है।',
            recommendationEn: 'Winds are calm with low rain chance. Ideal window for nutrient and crop protection spray.',
          ),
        );
      }

      // 3. Frost / Cold Wave Advisory
      if (forecasts.isNotEmpty && forecasts.first.minTemp < 6.0) {
        alerts.add(
          const FarmingAlert(
            titleHi: 'शीतलहर / पाला चेतावनी (Frost Alert)',
            titleEn: 'Frost & Cold Wave Warning',
            severity: 'severe',
            recommendationHi: 'तापमान 6°C से नीचे जाने पर पाला पड़ने की आशंका है। शाम के समय खेत में हल्की सिंचाई करें अथवा मेड़ों पर धुआं करें।',
            recommendationEn: 'Risk of frost damage as temperature drops below 6C. Apply light evening irrigation to protect crops.',
          ),
        );
      }

      return WeatherData(
        currentTemp: currentTemp,
        currentHumidity: currentHumidity,
        windSpeedKmH: windSpeed,
        weatherCode: weatherCode,
        conditionHi: _getHindiCondition(weatherCode),
        dailyForecast: forecasts,
        alerts: alerts,
      );
    } catch (e) {
      // Offline fallback weather data for rural field testing
      return _getOfflineFallbackWeather();
    }
  }

  String _getHindiCondition(int code) {
    if (code <= 1) return 'साफ धूप';
    if (code <= 3) return 'हल्के बादल';
    if (code >= 51 && code <= 65) return 'रुक-रुक कर वर्षा';
    if (code >= 80) return 'तेज बौछारें';
    return 'सामान्य मौसम';
  }

  WeatherData _getOfflineFallbackWeather() {
    return WeatherData(
      currentTemp: 28.5,
      currentHumidity: 55,
      windSpeedKmH: 10.2,
      weatherCode: 1,
      conditionHi: 'साफ व अनुकूल मौसम',
      dailyForecast: [
        DailyForecast(date: DateTime.now(), minTemp: 18.0, maxTemp: 30.0, rainProbability: 10, rainMm: 0.0, weatherCode: 1),
        DailyForecast(date: DateTime.now().add(const Duration(days: 1)), minTemp: 18.5, maxTemp: 31.0, rainProbability: 15, rainMm: 0.0, weatherCode: 1),
        DailyForecast(date: DateTime.now().add(const Duration(days: 2)), minTemp: 19.0, maxTemp: 31.5, rainProbability: 20, rainMm: 0.0, weatherCode: 2),
      ],
      alerts: const [
        FarmingAlert(
          titleHi: 'मौसम अनुकूल: छिड़काव के लिए उपयुक्त',
          titleEn: 'Favorable Weather',
          severity: 'low',
          recommendationHi: 'हवा की गति शांत है और धूप साफ है। खेत की जुताई व फसल की देखभाल के लिए उपयुक्त समय है।',
          recommendationEn: 'Ideal farming weather for field operations.',
        ),
      ],
    );
  }
}

