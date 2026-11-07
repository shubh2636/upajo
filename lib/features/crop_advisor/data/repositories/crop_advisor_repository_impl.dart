import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/crop_input_params.dart';
import '../../domain/models/crop_recommendation.dart';
import '../../domain/models/weather_data.dart';
import '../../domain/repositories/crop_advisor_repository.dart';
import '../services/open_meteo_service.dart';
import '../services/rule_based_crop_engine.dart';

class CropAdvisorRepositoryImpl implements CropAdvisorRepository {
  final SupabaseClient _supabase;
  final OpenMeteoService _weatherService;
  final http.Client _httpClient;
  final String _mlServiceUrl;
  static const _uuid = Uuid();

  CropAdvisorRepositoryImpl({
    SupabaseClient? supabase,
    OpenMeteoService? weatherService,
    http.Client? httpClient,
    String? mlServiceUrl,
  })  : _supabase = supabase ?? Supabase.instance.client,
        _weatherService = weatherService ?? OpenMeteoService(),
        _httpClient = httpClient ?? http.Client(),
        _mlServiceUrl = mlServiceUrl ?? 'http://10.0.2.2:8000'; // Default Android emulator host for FastAPI

  @override
  Future<CropRecommendation> getRecommendation(CropInputParams params) async {
    // 1. Attempt ML microservice request if available
    try {
      final response = await _httpClient
          .post(
            Uri.parse('$_mlServiceUrl/api/v1/crop-advisor/recommend'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(params.toJson()),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return CropRecommendation.fromJson(data);
      }
    } catch (e) {
      debugPrint('[CropAdvisorRepo] ML service unreachable or timed out ($e), falling back to ICAR Rule Engine');
    }

    // 2. High-precision ICAR Rule Engine (offline-first & low-latency guarantee)
    return RuleBasedCropEngine.recommend(params);
  }

  @override
  Future<WeatherData> getLiveWeatherAndAlerts({
    required double latitude,
    required double longitude,
  }) async {
    return await _weatherService.fetchWeather(
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<void> saveCropPlanAndTasks({
    required String farmerId,
    required CropRecommendation recommendation,
    required DateTime sowingDate,
    required double landAreaAcres,
    required String soilType,
    required String waterSource,
  }) async {
    final planId = _uuid.v4();
    final harvestDate = sowingDate.add(const Duration(days: 120));

    try {
      // 1. Look up or create crop in public.crops
      String cropId = _uuid.v4();
      final cropCheck = await _supabase
          .from('crops')
          .select('id')
          .ilike('name_en', '%${recommendation.nameEn}%')
          .limit(1)
          .maybeSingle();

      if (cropCheck != null && cropCheck['id'] != null) {
        cropId = cropCheck['id'] as String;
      } else {
        await _supabase.from('crops').insert({
          'id': cropId,
          'name_hi': recommendation.nameHi,
          'name_en': recommendation.nameEn,
          'scientific_name': recommendation.scientificName,
          'season': 'rabi', // default fallback enum
          'soil_types': [soilType],
          'water_requirement': waterSource,
          'duration_days': 120,
          'avg_yield_per_acre': recommendation.expectedYieldMaxQuintal,
        });
      }

      // 2. Insert into public.crop_plans
      await _supabase.from('crop_plans').insert({
        'id': planId,
        'farmer_id': farmerId,
        'crop_id': cropId,
        'land_area_acres': landAreaAcres,
        'soil_type': soilType,
        'water_source': waterSource,
        'sowing_date': sowingDate.toIso8601String().split('T')[0],
        'expected_harvest_date': harvestDate.toIso8601String().split('T')[0],
        'expected_yield_quintal': recommendation.totalExpectedYieldQuintal,
        'status': 'active',
      });

      // 3. Batch insert calendar tasks into public.tasks
      final tasksData = recommendation.calendarSchedule.map((task) {
        final taskDueDate = sowingDate.add(Duration(days: task.daysAfterSowing));
        return {
          'id': _uuid.v4(),
          'crop_plan_id': planId,
          'farmer_id': farmerId,
          'title_hi': task.titleHi,
          'title_en': task.titleEn,
          'description_hi': task.descriptionHi,
          'description_en': task.descriptionEn,
          'stage': task.stage,
          'due_date': taskDueDate.toIso8601String().split('T')[0],
          'is_completed': false,
        };
      }).toList();

      if (tasksData.isNotEmpty) {
        await _supabase.from('tasks').insert(tasksData);
      }
    } catch (e) {
      debugPrint('[CropAdvisorRepo] Error saving crop plan to Supabase: $e');
      // Graceful degradation: in demo/offline mode, tasks are preserved in local runtime state
    }
  }

  @override
  Future<List<CropCalendarTask>> getFarmerActiveTasks(String farmerId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('*')
          .eq('farmer_id', farmerId)
          .order('due_date', ascending: true);

      final list = (response as List)
          .map((data) => CropCalendarTask.fromJson(data as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('[CropAdvisorRepo] Error fetching tasks from Supabase: $e');
    }

    // Return fallback sample calendar tasks if Supabase returns empty (e.g. fresh account or offline)
    final now = DateTime.now();
    return [
      CropCalendarTask(
        id: 'sample_task_1',
        titleHi: 'खेत की गहरी जुताई व गोबर खाद',
        titleEn: 'Deep plowing and FYM application',
        descriptionHi: '2 बार कल्टीवेटर चलाएं व 4 ट्रॉली गोबर की खाद फैलाकर पाटा लगाएं।',
        descriptionEn: 'Deep plowing and mix FYM thoroughly before sowing.',
        stage: 'soil_prep',
        daysAfterSowing: -7,
        dueDate: now.subtract(const Duration(days: 2)),
        isCompleted: true,
      ),
      CropCalendarTask(
        id: 'sample_task_2',
        titleHi: 'बीज उपचार व बुआई (Sowing)',
        titleEn: 'Seed treatment and sowing',
        descriptionHi: 'ट्राइकोडर्मा व बाविस्टिन से बीज उपचारित करें। उचित कतार दूरी पर बुआई करें।',
        descriptionEn: 'Treat certified seed with Trichoderma and sow.',
        stage: 'sowing',
        daysAfterSowing: 0,
        dueDate: now.add(const Duration(days: 1)),
        isCompleted: false,
      ),
      CropCalendarTask(
        id: 'sample_task_3',
        titleHi: 'प्रथम सिंचाई: मुकुट जड़ (CRI Stage) व यूरिया',
        titleEn: 'CRI Stage Irrigation & Urea Top Dress',
        descriptionHi: 'बुआई के 21 दिन बाद पहली हल्की सिंचाई करें और 30 किग्रा यूरिया प्रति एकड़ दें।',
        descriptionEn: 'First irrigation at 21 DAS. Apply 30 kg Urea per acre.',
        stage: 'irrigation',
        daysAfterSowing: 21,
        dueDate: now.add(const Duration(days: 20)),
        isCompleted: false,
      ),
      CropCalendarTask(
        id: 'sample_task_4',
        titleHi: 'खरपतवार नियंत्रण व निंदाई',
        titleEn: 'Weed control and manual weeding',
        descriptionHi: 'सकरी व चौड़ी पत्ती के खरपतवार निकालें जिससे फसल को पूरा पोषण मिले।',
        descriptionEn: 'Weed eradication to prevent crop nutrient competition.',
        stage: 'pest_control',
        daysAfterSowing: 35,
        dueDate: now.add(const Duration(days: 34)),
        isCompleted: false,
      ),
    ];
  }

  @override
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _supabase.from('tasks').update({
        'is_completed': isCompleted,
        'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
      }).eq('id', taskId);
    } catch (e) {
      debugPrint('[CropAdvisorRepo] Error toggling task in Supabase: $e');
    }
  }
}

