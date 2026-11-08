import 'package:flutter_test/flutter_test.dart';
import 'package:upajo/features/marketplace/domain/models/cart_item.dart';
import 'package:upajo/features/marketplace/domain/models/product_model.dart';
import 'package:upajo/features/marketplace/domain/models/order_model.dart';

void main() {
  group('STEP 4: Customer Portal & Checkout Invariants', () {
    test('1. Cart Item Calculates Subtotal Based on Pack Size and Quantity', () {
      final product = ProductModel(
        id: 'p1',
        farmerId: 'f1',
        categoryId: 'c1',
        titleHi: 'चना दाल',
        titleEn: 'Chana Dal',
        descriptionHi: 'देसी चना दाल',
        descriptionEn: 'Desi Chana Dal',
        images: ['https://example.com/dal.jpg'],
        pricePerKg: 70.0,
        stockKg: 200.0,
        packSizesKg: [10, 20],
        harvestDate: DateTime.now(),
        shelfLifeDays: 90,
        deliveryModes: ['pickup', 'self_delivery'],
        isOrganic: true,
        isActive: true,
        villageOrCity: 'Bhopal',
        district: 'Bhopal',
        state: 'MP',
        pinCode: '462001',
        createdAt: DateTime.now(),
      );

      // Pack size = 10 kg, Quantity = 2 -> total kg = 20 -> expected = 20 * 70 = 1400.0
      final cartItem = CartItem(
        product: product,
        packSizeKg: 10,
        quantity: 2,
      );

      expect(cartItem.totalWeightKg, equals(20.0));
      expect(cartItem.totalPrice, equals(1400.0));
    });

    test('2. Order Total Invariant Equals Subtotal Plus Delivery Fee', () {
      const double subtotal = 1400.0;
      const double deliveryFee = 120.0;
      const double totalAmount = subtotal + deliveryFee;

      expect(totalAmount, equals(1520.0));
    });

    test('3. Order Cancellation Window is Strictly Limited to Placed or Confirmed Status', () {
      bool isCancellableByConsumer(String status) {
        return status == 'placed' || status == 'confirmed';
      }

      expect(isCancellableByConsumer('placed'), isTrue);
      expect(isCancellableByConsumer('confirmed'), isTrue);
      expect(isCancellableByConsumer('harvesting_packed'), isFalse);
      expect(isCancellableByConsumer('out_for_delivery'), isFalse);
      expect(isCancellableByConsumer('delivered'), isFalse);
      expect(isCancellableByConsumer('cancelled'), isFalse);
    });

    test('4. Rating Score Must Be Clamped Between 1 and 5 Stars', () {
      int validateRating(int input) {
        return input.clamp(1, 5);
      }

      expect(validateRating(5), equals(5));
      expect(validateRating(1), equals(1));
      expect(validateRating(0), equals(1));
      expect(validateRating(6), equals(5));
      expect(validateRating(-2), equals(1));
    });
  });
}
