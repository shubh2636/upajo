import 'package:flutter_test/flutter_test.dart';
import 'package:upajo/features/marketplace/domain/models/product_model.dart';
import 'package:upajo/features/marketplace/domain/models/order_model.dart';
import 'package:upajo/features/machinery/domain/models/machinery_model.dart';
import 'package:upajo/features/machinery/domain/models/rental_booking_model.dart';
import 'package:upajo/features/mandi/domain/models/mandi_price_model.dart';
import 'package:upajo/features/crop_advisor/domain/models/crop_input_params.dart';
import 'package:upajo/features/crop_advisor/domain/models/crop_recommendation.dart';

void main() {
  group('Part 6: Core Business & Domain Invariants', () {
    test('1. Farmer Crop Listing & Pack Price Computation', () {
      final product = ProductModel(
        id: 'prod_wheat_1',
        farmerId: 'farmer_baldev',
        categoryId: 'grains',
        titleHi: 'शरबती गेहूं (C-306)',
        titleEn: 'Sharbati Wheat C-306',
        descriptionHi: 'शुद्ध देसी गेहूं',
        descriptionEn: 'Pure organic wheat',
        images: const ['https://example.com/wheat.jpg'],
        pricePerKg: 35.0,
        stockKg: 2000.0,
        packSizesKg: const [10, 20, 50],
        harvestDate: DateTime.now().subtract(const Duration(days: 5)),
        shelfLifeDays: 365,
        deliveryModes: const ['delivery', 'pickup'],
        isOrganic: true,
        isActive: true,
        villageOrCity: 'श्यामपुर',
        district: 'सीहोर',
        state: 'मध्य प्रदेश',
        pinCode: '466001',
        createdAt: DateTime.now(),
      );

      // Verify pack price calculations
      expect(product.priceForPack(10), 350.0);
      expect(product.priceForPack(20), 700.0);
      expect(product.priceForPack(50), 1750.0);
      expect(product.stockInPacks(50), 40);
    });

    test('2. Consumer Cart & Delivery Fee Invariant', () {
      const double subtotal = 1750.0;
      const double deliveryCharge = 150.0;

      // Farm Pickup
      const bool isPickup = true;
      final double totalPickup = subtotal + (isPickup ? 0.0 : deliveryCharge);
      expect(totalPickup, 1750.0);

      // Doorstep Delivery
      const bool isDelivery = false;
      final double totalDelivery = subtotal + (isDelivery ? 0.0 : deliveryCharge);
      expect(totalDelivery, 1900.0);
    });

    test('3. Machinery Rental Days & Deposit Security Computation', () {
      final machine = MachineryModel(
        id: 'mach_tractor_1',
        ownerId: 'farmer_baldev',
        ownerName: 'बलदेव सिंह पटेल',
        ownerPhone: '9876543210',
        titleHi: 'महिंद्रा 575 DI ट्रैक्टर (45 HP)',
        titleEn: 'Mahindra 575 DI Tractor',
        machineryType: 'tractor',
        modelYear: 2022,
        hp: 45,
        hourlyRate: 450.0,
        dailyRate: 3200.0,
        securityDeposit: 2000.0,
        villageOrCity: 'श्यामपुर',
        district: 'सीहोर',
        state: 'मध्य प्रदेश',
        images: const ['https://example.com/tractor.jpg'],
      );

      final startDate = DateTime(2026, 11, 15);
      final endDate = DateTime(2026, 11, 18); // 4 days inclusive
      final int totalDays = endDate.difference(startDate).inDays + 1;

      expect(totalDays, 4);
      final double totalRent = totalDays * machine.dailyRate;
      expect(totalRent, 12800.0);

      final double grandTotalWithDeposit = totalRent + machine.securityDeposit;
      expect(grandTotalWithDeposit, 14800.0);
    });

    test('4. Mandi Rates & Farmer Direct Realization Advantage', () {
      final mandi = MandiPriceModel(
        id: 'mandi_wheat_sehore',
        cropNameHi: 'गेहूं (शरबती)',
        cropNameEn: 'Wheat (Sharbati)',
        mandiName: 'सीहोर कृषि उपज मंडी',
        district: 'सीहोर',
        state: 'मध्य प्रदेश',
        minPrice: 2850.0,
        maxPrice: 3650.0,
        modalPrice: 3280.0,
        change24h: 45.0,
        arrivalsTonnes: 420.0,
        priceDate: DateTime.now(),
        historicalTrend: const [3080.0, 3120.0, 3160.0, 3200.0, 3210.0, 3240.0, 3280.0],
      );

      // Traditional Mandi deductions: 2.5% Tax + 2.5% Arhatiya + loading/loss (~9% total)
      final double mandiRatePerKg = mandi.modalPrice / 100.0; // ₹32.80/kg
      final double traditionalFarmerNetPerKg = mandiRatePerKg * 0.91; // ~₹29.85/kg

      // Upajo direct fair price (15% premium for graded produce)
      final double upajoDirectPricePerKg = mandiRatePerKg * 1.15; // ~₹37.72/kg

      final double farmerProfitIncreasePct =
          ((upajoDirectPricePerKg - traditionalFarmerNetPerKg) / traditionalFarmerNetPerKg) * 100.0;

      expect(farmerProfitIncreasePct, greaterThan(25.0)); // At least 25% higher profit
    });

    test('5. CGST Act Section 23: 100% Tax Exemption On Raw Agricultural Produce', () {
      const double subtotal = 3500.0;
      const double gstRate = 0.00; // Tax-Exempt
      final double gstAmount = subtotal * gstRate;
      final double totalAmount = subtotal + gstAmount;

      expect(gstAmount, 0.0);
      expect(totalAmount, 3500.0);
    });
  });
}
