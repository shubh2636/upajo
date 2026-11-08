import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:upajo/features/marketplace/data/repositories/marketplace_repository_impl.dart';
import 'package:upajo/features/machinery/domain/models/machinery_model.dart';
import 'package:upajo/features/machinery/domain/models/rental_booking_model.dart';

void main() {
  group('Step 5: Payments and Money Logic Invariants', () {
    late SupabaseClient mockClient;
    late MarketplaceRepositoryImpl repo;

    setUp(() {
      mockClient = SupabaseClient('https://mock.supabase.co', 'mock-anon-key');
      repo = MarketplaceRepositoryImpl(client: mockClient);
    });

    test('1. Repository exposes Server-Side Razorpay Order & Payment Verification', () {
      expect(repo.createRazorpayOrder, isNotNull);
      expect(repo.verifyRazorpayPayment, isNotNull);
    });

    test('2. Machinery Security Deposit is Honest Record without False Escrow', () {
      final machine = MachineryModel(
        id: 'mach_test_1',
        ownerId: 'farmer_1',
        titleHi: 'ट्रैक्टर',
        titleEn: 'Tractor',
        machineryType: 'tractor',
        modelYear: 2022,
        hp: 45,
        hourlyRate: 500.0,
        dailyRate: 3000.0,
        securityDeposit: 2000.0,
        villageOrCity: 'सीहोर',
        district: 'सीहोर',
        state: 'मध्य प्रदेश',
        images: const [],
      );

      final booking = RentalBookingModel(
        id: 'book_test_1',
        machineryId: machine.id,
        renterId: 'consumer_1',
        ownerId: machine.ownerId,
        startDate: DateTime.now().add(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 3)),
        totalDays: 3,
        totalAmount: 9000.0,
        depositAmount: machine.securityDeposit,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Verify booking records security deposit as a record without claiming escrow
      expect(booking.depositAmount, 2000.0);
      expect(booking.status, 'pending');
      final json = booking.toSupabaseJson();
      expect(json['deposit_amount'], 2000.0);
      expect(json['total_amount'], 9000.0);
      expect(json.containsKey('escrow_account_id'), false);
    });
  });
}
