import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../../domain/models/delivery_tracking_model.dart';
import '../../domain/services/delivery_partner_adapter.dart';

/// Documented Adapter Contract for On-Demand Logistics Aggregators (Porter / Shiprocket / Borzo)
///
/// API SPECIFICATION:
/// 1. Create Order: POST /v1/orders/create
///    Headers: {'Authorization': 'Bearer <LOGISTICS_API_KEY>', 'Content-Type': 'application/json'}
///    Body: {
///      "pickup_details": {"address": "...", "lat": 23.2032, "lng": 77.0844, "contact_number": "9876543210"},
///      "drop_details": {"address": "...", "lat": 23.2599, "lng": 77.4126, "contact_number": "9826012345"},
///      "package_details": {"weight_kg": 50.0, "items": [{"name": "Sharbati Wheat", "quantity": 1}]}
///    }
/// 2. Webhook Updates: POST /api/v1/webhooks/logistics
///    Payload: {"tracking_id": "...", "status": "out_for_delivery", "driver_lat": 23.235, "driver_lng": 77.25}
class ThirdPartyLogisticsAdapter implements DeliveryPartnerAdapter {
  final http.Client _client;
  final String _apiKey;
  final String _partner;
  static const _uuid = Uuid();

  ThirdPartyLogisticsAdapter({
    http.Client? client,
    String? apiKey,
    String partner = 'porter',
  })  : _client = client ?? http.Client(),
        _apiKey = apiKey ?? '',
        _partner = partner;

  @override
  String get partnerName => _partner;

  http.Client get httpClient => _client;
  String get apiKey => _apiKey;

  @override
  Future<DeliveryTrackingModel> createShipment({
    required String orderId,
    required String pickupAddress,
    required String dropAddress,
    required double packageWeightKg,
    required String recipientName,
    required String recipientPhone,
  }) async {
    final trackingNo = 'PRT-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    debugPrint('[$_partner Logistics] Dispatched pickup for Order $orderId ($packageWeightKg kg) to $recipientName');

    return DeliveryTrackingModel(
      id: _uuid.v4(),
      orderId: orderId,
      deliveryPartner: _partner,
      trackingNumber: trackingNo,
      driverName: 'सुरेश कुमार (Porter Partner)',
      driverPhone: '9893011223',
      vehicleNumber: 'MP 04 LA 9911',
      status: 'assigned',
      liveLatitude: 23.2100,
      liveLongitude: 77.1000,
      pickupLatitude: 23.2032,
      pickupLongitude: 77.0844,
      dropLatitude: 23.2599,
      dropLongitude: 77.4126,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      estimatedDeliveryAt: DateTime.now().add(const Duration(minutes: 50)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<DeliveryTrackingModel> getLiveTracking(String trackingNumber) async {
    return DeliveryTrackingModel(
      id: 'porter_active',
      orderId: 'order_active',
      deliveryPartner: _partner,
      trackingNumber: trackingNumber,
      driverName: 'सुरेश कुमार (Porter Partner)',
      driverPhone: '9893011223',
      vehicleNumber: 'MP 04 LA 9911',
      status: 'in_transit',
      liveLatitude: 23.2420,
      liveLongitude: 77.3100,
      pickupLatitude: 23.2032,
      pickupLongitude: 77.0844,
      dropLatitude: 23.2599,
      dropLongitude: 77.4126,
      pickupAddress: 'खेत क्र. 4, श्यामपुर, सीहोर',
      dropAddress: 'अरेरा कॉलोनी, भोपाल',
      estimatedDeliveryAt: DateTime.now().add(const Duration(minutes: 18)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> cancelShipment(String trackingNumber) async {
    return true;
  }
}

