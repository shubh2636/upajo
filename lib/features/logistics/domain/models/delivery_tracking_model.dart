class DeliveryTrackingModel {
  final String id;
  final String orderId;
  final String deliveryPartner; // 'self', 'porter', 'shiprocket', 'borzo'
  final String trackingNumber;
  final String driverName;
  final String driverPhone;
  final String vehicleNumber;
  final String status; // 'assigned', 'picked_up', 'in_transit', 'delivered', 'cancelled'
  final double liveLatitude;
  final double liveLongitude;
  final double pickupLatitude;
  final double pickupLongitude;
  final double dropLatitude;
  final double dropLongitude;
  final String pickupAddress;
  final String dropAddress;
  final DateTime? estimatedDeliveryAt;
  final DateTime? actualDeliveryAt;
  final DateTime updatedAt;

  const DeliveryTrackingModel({
    required this.id,
    required this.orderId,
    this.deliveryPartner = 'self',
    required this.trackingNumber,
    required this.driverName,
    required this.driverPhone,
    this.vehicleNumber = 'MP 04 AB 1234',
    required this.status,
    required this.liveLatitude,
    required this.liveLongitude,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropLatitude,
    required this.dropLongitude,
    required this.pickupAddress,
    required this.dropAddress,
    this.estimatedDeliveryAt,
    this.actualDeliveryAt,
    required this.updatedAt,
  });

  factory DeliveryTrackingModel.fromJson(Map<String, dynamic> json) {
    return DeliveryTrackingModel(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String? ?? '',
      deliveryPartner: json['delivery_partner'] as String? ?? 'self',
      trackingNumber: json['tracking_number'] as String? ?? 'UPJ-LOG-8921',
      driverName: json['driver_name'] as String? ?? 'राजेश यादव (किसान साथी)',
      driverPhone: json['driver_phone'] as String? ?? '9826198765',
      vehicleNumber: json['vehicle_number'] as String? ?? 'MP 04 EA 5678',
      status: json['status'] as String? ?? 'in_transit',
      liveLatitude: (json['live_lat'] as num?)?.toDouble() ?? 23.2350,
      liveLongitude: (json['live_lng'] as num?)?.toDouble() ?? 77.1050,
      pickupLatitude: (json['pickup_lat'] as num?)?.toDouble() ?? 23.2032,
      pickupLongitude: (json['pickup_lng'] as num?)?.toDouble() ?? 77.0844,
      dropLatitude: (json['drop_lat'] as num?)?.toDouble() ?? 23.2599,
      dropLongitude: (json['drop_lng'] as num?)?.toDouble() ?? 77.4126,
      pickupAddress: json['pickup_address'] as String? ?? 'खेत क्र. 4, ग्राम श्यामपुर, सीहोर',
      dropAddress: json['drop_address'] as String? ?? 'मकान नं 42, अरेरा कॉलोनी, भोपाल',
      estimatedDeliveryAt: json['estimated_delivery_at'] != null
          ? DateTime.parse(json['estimated_delivery_at'] as String)
          : DateTime.now().add(const Duration(minutes: 45)),
      actualDeliveryAt: json['actual_delivery_at'] != null
          ? DateTime.parse(json['actual_delivery_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'order_id': orderId,
      'delivery_partner': deliveryPartner,
      'tracking_number': trackingNumber,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'status': status,
      'live_lat': liveLatitude,
      'live_lng': liveLongitude,
      'estimated_delivery_at': estimatedDeliveryAt?.toIso8601String(),
      'actual_delivery_at': actualDeliveryAt?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
