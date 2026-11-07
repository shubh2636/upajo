import '../models/delivery_tracking_model.dart';

abstract class DeliveryPartnerAdapter {
  String get partnerName; // 'self', 'porter', 'shiprocket', 'borzo'

  /// Dispatches or schedules shipment
  Future<DeliveryTrackingModel> createShipment({
    required String orderId,
    required String pickupAddress,
    required String dropAddress,
    required double packageWeightKg,
    required String recipientName,
    required String recipientPhone,
  });

  /// Fetches live GPS coordinates and transit status
  Future<DeliveryTrackingModel> getLiveTracking(String trackingNumber);

  /// Cancels active shipment
  Future<bool> cancelShipment(String trackingNumber);
}

