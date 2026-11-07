import '../models/farmer_analytics_model.dart';

abstract class AnalyticsRepository {
  /// Aggregates sales metrics, crop distribution, seasonal trends, and top buyers
  Future<FarmerAnalyticsModel> getFarmerAnalytics(String farmerId);
}
