import 'product_model.dart';

class OrderItemModel {
  final String id;
  final String orderId;
  final String productId;
  final int packSizeKg;
  final int quantity;
  final double pricePerPack;
  final double totalPrice;
  final ProductModel? product;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.packSizeKg,
    required this.quantity,
    required this.pricePerPack,
    required this.totalPrice,
    this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      packSizeKg: (json['pack_size_kg'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      pricePerPack: (json['price_per_pack'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      product: json['product'] != null
          ? ProductModel.fromJson(json['product'] as Map<String, dynamic>)
          : null,
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber;
  final String consumerId;
  final String farmerId;
  final String deliveryMode; // 'pickup', 'self_delivery', 'partner'
  final Map<String, dynamic> deliveryAddress;
  final double subtotalAmount;
  final double deliveryFee;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  // Joined metadata
  final String? consumerName;
  final String? consumerPhone;
  final String? farmerName;
  final String? farmerPhone;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.consumerId,
    required this.farmerId,
    required this.deliveryMode,
    required this.deliveryAddress,
    required this.subtotalAmount,
    required this.deliveryFee,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.items = const [],
    this.consumerName,
    this.consumerPhone,
    this.farmerName,
    this.farmerPhone,
  });

  bool get isPickup => deliveryMode == 'pickup';
  bool get isDelivered => status == 'delivered';

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] ?? json['items'];
    List<OrderItemModel> itemsList = [];
    if (rawItems is List) {
      itemsList = rawItems
          .map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>))
          .toList();
    }

    final consumer = json['consumer'] as Map<String, dynamic>?;
    final farmer = json['farmer'] as Map<String, dynamic>?;

    return OrderModel(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      consumerId: json['consumer_id'] as String,
      farmerId: json['farmer_id'] as String,
      deliveryMode: json['delivery_mode'] as String? ?? 'pickup',
      deliveryAddress: json['delivery_address'] as Map<String, dynamic>? ?? {},
      subtotalAmount: (json['subtotal_amount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending_payment',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      items: itemsList,
      consumerName: consumer?['full_name'] as String?,
      consumerPhone: consumer?['phone'] as String?,
      farmerName: farmer?['full_name'] as String?,
      farmerPhone: farmer?['phone'] as String?,
    );
  }
}

