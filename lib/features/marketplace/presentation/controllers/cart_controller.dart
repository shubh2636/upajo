import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/cart_item.dart';
import '../../domain/models/product_model.dart';
import '../../domain/models/order_model.dart';
import '../../domain/repositories/marketplace_repository.dart';
import 'marketplace_controller.dart';

class CartState {
  final List<CartItem> items;
  final String deliveryMode; // 'pickup' or 'self_delivery'
  final bool isPlacingOrder;
  final String? errorMessage;

  const CartState({
    this.items = const [],
    this.deliveryMode = 'pickup',
    this.isPlacingOrder = false,
    this.errorMessage,
  });

  double get subtotal => items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get deliveryFee => (deliveryMode == 'pickup' || items.isEmpty) ? 0.0 : 150.0;
  double get total => subtotal + deliveryFee;
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  String? get currentFarmerId => items.isNotEmpty ? items.first.product.farmerId : null;

  CartState copyWith({
    List<CartItem>? items,
    String? deliveryMode,
    bool? isPlacingOrder,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      errorMessage: errorMessage,
    );
  }
}

class CartController extends StateNotifier<CartState> {
  final MarketplaceRepository _repository;

  CartController(this._repository) : super(const CartState());

  void setDeliveryMode(String mode) {
    state = state.copyWith(deliveryMode: mode);
  }

  bool addToCart(ProductModel product, int packSizeKg, [int quantity = 1]) {
    // Single-farmer basket rule to simplify farmgate direct logistics
    if (state.items.isNotEmpty && state.items.first.product.farmerId != product.farmerId) {
      return false; // Different farmer indicator
    }

    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id && item.packSizeKg == packSizeKg,
    );

    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state.items);
      final current = updated[existingIndex];
      updated[existingIndex] = current.copyWith(quantity: current.quantity + quantity);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [
          ...state.items,
          CartItem(product: product, packSizeKg: packSizeKg, quantity: quantity),
        ],
      );
    }
    return true;
  }

  void updateQuantity(String productId, int packSizeKg, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromCart(productId, packSizeKg);
      return;
    }

    final updated = state.items.map((item) {
      if (item.product.id == productId && item.packSizeKg == packSizeKg) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updated);
  }

  void removeFromCart(String productId, int packSizeKg) {
    final updated = state.items.where(
      (item) => !(item.product.id == productId && item.packSizeKg == packSizeKg),
    ).toList();
    state = state.copyWith(items: updated);
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }

  Future<OrderModel?> placeOrder({
    required String consumerId,
    required Map<String, dynamic> deliveryAddress,
  }) async {
    if (state.items.isEmpty) return null;
    final farmerId = state.items.first.product.farmerId;

    state = state.copyWith(isPlacingOrder: true, errorMessage: null);

    try {
      final order = await _repository.createOrder(
        consumerId: consumerId,
        farmerId: farmerId,
        deliveryMode: state.deliveryMode,
        deliveryAddress: deliveryAddress,
        subtotalAmount: state.subtotal,
        deliveryFee: state.deliveryFee,
        totalAmount: state.total,
        items: state.items,
      );

      clearCart();
      state = state.copyWith(isPlacingOrder: false);
      return order;
    } catch (e) {
      state = state.copyWith(isPlacingOrder: false, errorMessage: e.toString());
      return null;
    }
  }
}

final cartControllerProvider = StateNotifierProvider<CartController, CartState>((ref) {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return CartController(repo);
});

