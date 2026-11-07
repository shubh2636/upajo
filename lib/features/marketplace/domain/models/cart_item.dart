import 'product_model.dart';

class CartItem {
  final ProductModel product;
  final int packSizeKg;
  final int quantity;

  const CartItem({
    required this.product,
    required this.packSizeKg,
    this.quantity = 1,
  });

  double get pricePerPack => product.pricePerKg * packSizeKg;
  double get totalPrice => pricePerPack * quantity;
  double get totalWeightKg => (packSizeKg * quantity).toDouble();

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      product: product,
      packSizeKg: packSizeKg,
      quantity: quantity ?? this.quantity,
    );
  }
}

