import '../models/delivery_tracking_model.dart';

abstract class LogisticsRepository {
  /// Fetches live tracking record for an order
  Future<DeliveryTrackingModel> getOrderTracking(String orderId);

  /// Dispatches delivery through selected mode (self / partner)
  Future<DeliveryTrackingModel> dispatchDelivery({
    required String orderId,
    required String mode,
    required String pickupAddress,
    required String dropAddress,
    required double packageWeightKg,
    required String recipientName,
    required String recipientPhone,
  });

  /// Updates driver position or delivery milestone
  Future<void> updateDeliveryStatus({
    required String trackingId,
    required String status,
    double? lat,
    double? lng,
  });
}
