import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/order_model.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/supabase_client.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final SupabaseClient _client;

  MarketplaceRepositoryImpl({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  @override
  Future<List<ProductModel>> getProducts({
    String? categoryId,
    String? district,
    bool? isOrganic,
    String? query,
  }) async {
    try {
      var builder = _client
          .from('products')
          .select('*, farmer:profiles!products_farmer_id_fkey(*)')
          .eq('is_active', true);

      if (categoryId != null && categoryId.isNotEmpty) {
        builder = builder.eq('category_id', categoryId);
      }
      if (district != null && district.isNotEmpty) {
        builder = builder.ilike('district', '%$district%');
      }
      if (isOrganic != null) {
        builder = builder.eq('is_organic', isOrganic);
      }
      if (query != null && query.isNotEmpty) {
        builder = builder.or('title_hi.ilike.%$query%,title_en.ilike.%$query%');
      }

      final response = await builder.order('created_at', ascending: false);
      return (response as List)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('उपज लोड करने में त्रुटि: $e');
    }
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    try {
      final res = await _client
          .from('products')
          .select('*, farmer:profiles!products_farmer_id_fkey(*)')
          .eq('id', id)
          .maybeSingle();

      if (res == null) return null;
      return ProductModel.fromJson(res);
    } catch (e) {
      throw ServerException('उत्पाद लोड करने में त्रुटि: $e');
    }
  }

  @override
  Future<List<ProductModel>> getFarmerProducts(String farmerId) async {
    try {
      final res = await _client
          .from('products')
          .select('*')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('किसान उपज लोड करने में त्रुटि: $e');
    }
  }

  @override
  Future<String> uploadProductImage(File imageFile) async {
    try {
      // 1. Compress image before upload (saving 2G/3G mobile data)
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: 75,
        minWidth: 1024,
        minHeight: 1024,
      );

      final fileToUpload = File(compressedFile?.path ?? imageFile.path);
      final fileExt = fileToUpload.path.split('.').last;
      final fileName = '${const Uuid().v4()}.$fileExt';

      await _client.storage.from('product-images').upload(
            fileName,
            fileToUpload,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      return _client.storage.from('product-images').getPublicUrl(fileName);
    } catch (e) {
      // Fallback placeholder image for offline/local test
      return 'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?auto=format&fit=crop&w=800&q=80';
    }
  }

  @override
  Future<ProductModel> addProduct(ProductModel product) async {
    try {
      final payload = product.toJson();
      payload.remove('id'); // Auto-generated UUID
      final res = await _client.from('products').insert(payload).select().single();
      return ProductModel.fromJson(res);
    } catch (e) {
      throw ServerException('उपज जोड़ने में त्रुटि: $e');
    }
  }

  @override
  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final res = await _client
          .from('products')
          .update(product.toJson())
          .eq('id', product.id)
          .select()
          .single();
      return ProductModel.fromJson(res);
    } catch (e) {
      throw ServerException('उपज अपडेट करने में त्रुटि: $e');
    }
  }

  @override
  Future<OrderModel> createOrder({
    required String consumerId,
    required String farmerId,
    required String deliveryMode,
    required Map<String, dynamic> deliveryAddress,
    required double subtotalAmount,
    required double deliveryFee,
    required double totalAmount,
    required List<CartItem> items,
  }) async {
    try {
      final orderNumber = 'UP-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 10000}';

      // 1. Insert order
      final orderRes = await _client
          .from('orders')
          .insert({
            'order_number': orderNumber,
            'consumer_id': consumerId,
            'farmer_id': farmerId,
            'delivery_mode': deliveryMode,
            'delivery_address': deliveryAddress,
            'subtotal_amount': subtotalAmount,
            'delivery_fee': deliveryFee,
            'total_amount': totalAmount,
            'status': 'confirmed',
          })
          .select()
          .single();

      final orderId = orderRes['id'] as String;

      // 2. Insert order items
      final itemsPayload = items.map((item) {
        return {
          'order_id': orderId,
          'product_id': item.product.id,
          'pack_size_kg': item.packSizeKg,
          'quantity': item.quantity,
          'price_per_pack': item.pricePerPack,
          'total_price': item.totalPrice,
        };
      }).toList();

      await _client.from('order_items').insert(itemsPayload);

      return OrderModel.fromJson(orderRes);
    } catch (e) {
      throw ServerException('ऑर्डर बनाने में त्रुटि: $e');
    }
  }

  @override
  Future<List<OrderModel>> getConsumerOrders(String consumerId) async {
    try {
      final res = await _client
          .from('orders')
          .select('*, items:order_items(*, product:products(*)), farmer:profiles!orders_farmer_id_fkey(*)')
          .eq('consumer_id', consumerId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((i) => OrderModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('उपभोक्ता ऑर्डर लोड करने में त्रुटि: $e');
    }
  }

  @override
  Future<List<OrderModel>> getFarmerOrders(String farmerId) async {
    try {
      final res = await _client
          .from('orders')
          .select('*, items:order_items(*, product:products(*)), consumer:profiles!orders_consumer_id_fkey(*)')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);

      return (res as List)
          .map((i) => OrderModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('किसान ऑर्डर लोड करने में त्रुटि: $e');
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
    } catch (e) {
      throw ServerException('ऑर्डर स्थिति बदलने में त्रुटि: $e');
    }
  }

  @override
  Future<void> submitRating({
    required String orderId,
    required String productId,
    required String consumerId,
    required String farmerId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _client.from('ratings').insert({
        'order_id': orderId,
        'product_id': productId,
        'consumer_id': consumerId,
        'farmer_id': farmerId,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      throw ServerException('रेटिंग सहेजने में त्रुटि: $e');
    }
  }

  @override
  Future<List<OrderModel>> getAllOrdersAdmin() async {
    try {
      final res = await _client
          .from('orders')
          .select('*, farmer:profiles!orders_farmer_id_fkey(*), consumer:profiles!orders_consumer_id_fkey(*)')
          .order('created_at', ascending: false);

      return (res as List)
          .map((i) => OrderModel.fromJson(i as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException('समस्त ऑर्डर लोड करने में त्रुटि: $e');
    }
  }

  @override
  Future<void> setFarmerKycStatus({
    required String farmerId,
    required String status,
    required bool verifiedByAdmin,
  }) async {
    try {
      await _client.from('profiles').update({
        'kyc_status': status,
        'verified_by_admin': verifiedByAdmin,
      }).eq('id', farmerId);
    } catch (e) {
      throw ServerException('किसान सत्यापन में त्रुटि: $e');
    }
  }
}

