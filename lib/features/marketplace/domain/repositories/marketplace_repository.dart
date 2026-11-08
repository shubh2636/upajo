import 'dart:io';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';

abstract class MarketplaceRepository {
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? district,
    bool? isOrganic,
    String? query,
  });

  Future<ProductModel?> getProductById(String id);

  Future<List<ProductModel>> getFarmerProducts(String farmerId);

  Future<String> uploadProductImage(File imageFile);

  Future<ProductModel> addProduct(ProductModel product);

  Future<ProductModel> updateProduct(ProductModel product);

  Future<void> deleteProduct(String productId);

  Future<OrderModel> createOrder({
    required String consumerId,
    required String farmerId,
    required String deliveryMode,
    required Map<String, dynamic> deliveryAddress,
    required double subtotalAmount,
    required double deliveryFee,
    required double totalAmount,
    required List<CartItem> items,
  });

  Future<List<OrderModel>> getConsumerOrders(String consumerId);

  Future<List<OrderModel>> getFarmerOrders(String farmerId);

  Future<void> updateOrderStatus(String orderId, String newStatus);

  Future<void> submitRating({
    required String orderId,
    required String productId,
    required String consumerId,
    required String farmerId,
    required int rating,
    String? comment,
  });

  Future<List<OrderModel>> getAllOrdersAdmin();

  Future<void> setFarmerKycStatus({
    required String farmerId,
    required String status,
    required bool verifiedByAdmin,
  });

  Future<Map<String, dynamic>> createRazorpayOrder({required String orderId});

  Future<bool> verifyRazorpayPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  });
}

