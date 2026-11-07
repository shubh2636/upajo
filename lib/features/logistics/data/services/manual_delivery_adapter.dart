import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../domain/models/delivery_tracking_model.dart';
import '../../domain/services/delivery_partner_adapter.dart';

class ManualSelfDeliveryAdapter implements DeliveryPartnerAdapter {
  static const _uuid = Uuid();

  @override
  String get partnerName => 'self';

  @override
  Future<DeliveryTrackingModel> createShipment({
    required String orderId,
    required String pickupAddress,
    required String dropAddress,
    required double packageWeightKg,
    required String recipientName,
    required String recipientPhone,
  }) async {
    final trackingNo = 'UPJ-SELF-${Random().nextInt(90000) + 10000}';
    return DeliveryTrackingModel(
      id: _uuid.v4(),
      orderId: orderId,
      deliveryPartner: partnerName,
      trackingNumber: trackingNo,
      driverName: 'किसान द्वारा सीधी डिलीवरी (Self Delivery)',
      driverPhone: '9826012345',
      vehicleNumber: 'MP 04 TR 7890',
      status: 'in_transit',
      liveLatitude: 23.2200,
      liveLongitude: 77.2100,
      pickupLatitude: 23.2032,
      pickupLongitude: 77.0844,
      dropLatitude: 23.2599,
      dropLongitude: 77.4126,
      pickupAddress: pickupAddress,
      dropAddress: dropAddress,
      estimatedDeliveryAt: DateTime.now().add(const Duration(minutes: 35)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<DeliveryTrackingModel> getLiveTracking(String trackingNumber) async {
    // Simulates realistic continuous vehicle motion along Sehore -> Bhopal highway corridor
    final randomOffset = (Random().nextDouble() - 0.5) * 0.005;
    return DeliveryTrackingModel(
      id: 'active_tracking',
      orderId: 'order_current',
      deliveryPartner: partnerName,
      trackingNumber: trackingNumber,
      driverName: 'राजेश पटेल (किसान साथी)',
      driverPhone: '9826012345',
      vehicleNumber: 'MP 04 TR 7890',
      status: 'in_transit',
      liveLatitude: 23.2350 + randomOffset,
      liveLongitude: 77.2500 + randomOffset,
      pickupLatitude: 23.2032,
      pickupLongitude: 77.0844,
      dropLatitude: 23.2599,
      dropLongitude: 77.4126,
      pickupAddress: 'खेत क्र. 4, ग्राम श्यामपुर, सीहोर',
      dropAddress: 'मकान नं 42, अरेरा कॉलोनी, भोपाल',
      estimatedDeliveryAt: DateTime.now().add(const Duration(minutes: 25)),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<bool> cancelShipment(String trackingNumber) async {
    return true;
  }
}
