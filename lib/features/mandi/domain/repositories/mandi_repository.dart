import '../models/mandi_price_model.dart';

abstract class MandiRepository {
  /// Fetches real-time APMC Mandi rates with Agmarknet fallback
  Future<List<MandiPriceModel>> getMandiPrices({String? crop, String? state});

  /// Fetches active price alerts for the farmer
  Future<List<PriceAlertModel>> getPriceAlerts(String farmerId);

  /// Sets up a push/in-app alert when mandi rate crosses target threshold
  Future<void> createPriceAlert(PriceAlertModel alert);

  /// Removes an active alert
  Future<void> deletePriceAlert(String alertId);
}

