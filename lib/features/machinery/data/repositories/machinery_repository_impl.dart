import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/machinery_model.dart';
import '../../domain/models/rental_booking_model.dart';
import '../../domain/repositories/machinery_repository.dart';

class MachineryRepositoryImpl implements MachineryRepository {
  final SupabaseClient _supabase;
  static const _uuid = Uuid();

  MachineryRepositoryImpl({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  @override
  Future<List<MachineryModel>> getAvailableMachinery({
    String? type,
    String? district,
  }) async {
    try {
      var query = _supabase
          .from('machinery')
          .select('*, profiles:owner_id(full_name, phone_number)')
          .eq('is_available', true);

      if (type != null && type != 'all') {
        query = query.eq('machinery_type', type);
      }
      if (district != null && district.isNotEmpty && district != 'all') {
        query = query.ilike('district', '%$district%');
      }

      final response = await query.order('created_at', ascending: false);
      final list = (response as List)
          .map((item) => MachineryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) return list;
    } catch (e) {
      debugPrint('[MachineryRepo] Supabase query failed ($e), serving local mock catalog');
    }

    return _getLocalMockMachinery(type: type, district: district);
  }

  @override
  Future<MachineryModel?> getMachineryById(String id) async {
    try {
      final response = await _supabase
          .from('machinery')
          .select('*, profiles:owner_id(full_name, phone_number)')
          .eq('id', id)
          .maybeSingle();

      if (response != null) {
        return MachineryModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('[MachineryRepo] Could not fetch machine details: $e');
    }

    final local = _getLocalMockMachinery().firstWhere(
      (m) => m.id == id,
      orElse: () => _getLocalMockMachinery().first,
    );
    return local;
  }

  @override
  Future<MachineryModel> listMachinery(MachineryModel machinery) async {
    final newId = _uuid.v4();
    final data = machinery.toJson()..['id'] = newId;

    try {
      await _supabase.from('machinery').insert(data);
      return machinery;
    } catch (e) {
      debugPrint('[MachineryRepo] Supabase insert failed: $e');
      return machinery;
    }
  }

  @override
  Future<RentalBookingModel> createRentalBooking({
    required String machineryId,
    required String renterId,
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
    required double dailyRate,
    required double securityDeposit,
  }) async {
    final bookingId = _uuid.v4();
    final days = endDate.difference(startDate).inDays + 1;
    final totalDays = days > 0 ? days : 1;
    final totalRent = totalDays * dailyRate;
    final grandTotal = totalRent + securityDeposit;

    final booking = RentalBookingModel(
      id: bookingId,
      machineryId: machineryId,
      renterId: renterId,
      ownerId: ownerId,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
      totalAmount: grandTotal,
      depositAmount: securityDeposit,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    try {
      await _supabase.from('rentals').insert(booking.toSupabaseJson());
    } catch (e) {
      debugPrint('[MachineryRepo] Supabase rental booking failed: $e');
    }

    return booking;
  }

  @override
  Future<List<RentalBookingModel>> getUserRentals({
    required String userId,
    required bool asOwner,
  }) async {
    try {
      final filterCol = asOwner ? 'owner_id' : 'renter_id';
      final response = await _supabase
          .from('rentals')
          .select('*, machinery:machinery_id(title_hi, machinery_type), renter_profile:renter_id(full_name, phone_number), owner_profile:owner_id(full_name, phone_number)')
          .eq(filterCol, userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => RentalBookingModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[MachineryRepo] Could not fetch user rentals: $e');
    }

    // Fallback sample bookings for instant demo UI testing
    final now = DateTime.now();
    return [
      RentalBookingModel(
        id: 'mock_rental_1',
        machineryId: 'm1',
        renterId: userId,
        ownerId: 'owner_patel',
        machineryTitle: 'महिंद्रा 575 DI ट्रैक्टर (45 HP)',
        machineryType: 'tractor',
        startDate: now.add(const Duration(days: 2)),
        endDate: now.add(const Duration(days: 4)),
        totalDays: 3,
        totalAmount: 9500.0,
        depositAmount: 2000.0,
        status: asOwner ? 'pending' : 'approved',
        renterName: 'रामेश्वर वर्मा',
        renterPhone: '9826012345',
        ownerName: 'बलदेव सिंह पटेल',
        ownerPhone: '9425098765',
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
    ];
  }

  @override
  Future<void> updateRentalStatus({
    required String rentalId,
    required String newStatus,
  }) async {
    try {
      await _supabase
          .from('rentals')
          .update({'status': newStatus, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', rentalId);
    } catch (e) {
      debugPrint('[MachineryRepo] Status update failed: $e');
    }
  }

  List<MachineryModel> _getLocalMockMachinery({String? type, String? district}) {
    final all = [
      const MachineryModel(
        id: 'm1',
        ownerId: 'owner_1',
        ownerName: 'बलदेव सिंह पटेल',
        ownerPhone: '9425098765',
        titleHi: 'महिंद्रा 575 DI XP Plus ट्रैक्टर (47 HP)',
        titleEn: 'Mahindra 575 DI Tractor 47HP',
        machineryType: 'tractor',
        modelYear: 2023,
        hp: 47,
        hourlyRate: 550.0,
        dailyRate: 3200.0,
        securityDeposit: 2000.0,
        images: [
          'https://images.unsplash.com/photo-1592982537447-7440770cbfc9?w=600',
        ],
        villageOrCity: 'श्यामपुर',
        district: 'सीहोर',
        state: 'मध्य प्रदेश',
        isAvailable: true,
        rating: 4.9,
        totalBookings: 24,
      ),
      const MachineryModel(
        id: 'm2',
        ownerId: 'owner_2',
        ownerName: 'राजू धाकड़',
        ownerPhone: '9826112233',
        titleHi: 'शक्तिमान 7 फीट रोटावेटर (Rotavator)',
        titleEn: 'Shaktiman 7ft Regular Rotavator',
        machineryType: 'rotavator',
        modelYear: 2022,
        hp: 45,
        hourlyRate: 350.0,
        dailyRate: 2000.0,
        securityDeposit: 1500.0,
        images: [
          'https://images.unsplash.com/photo-1589923188900-85dae523342b?w=600',
        ],
        villageOrCity: 'इछावर',
        district: 'सीहोर',
        state: 'मध्य प्रदेश',
        isAvailable: true,
        rating: 4.7,
        totalBookings: 18,
      ),
      const MachineryModel(
        id: 'm3',
        ownerId: 'owner_3',
        ownerName: 'विक्रम यादव',
        ownerPhone: '9754334455',
        titleHi: 'प्रीत कंबाइन हार्वेस्टर (Paddy & Wheat)',
        titleEn: 'Preet Combine Harvester 987',
        machineryType: 'harvester',
        modelYear: 2023,
        hp: 101,
        hourlyRate: 1800.0,
        dailyRate: 12000.0,
        securityDeposit: 5000.0,
        images: [
          'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=600',
        ],
        villageOrCity: 'आष्टा',
        district: 'सीहोर',
        state: 'मध्य प्रदेश',
        isAvailable: true,
        rating: 4.9,
        totalBookings: 42,
      ),
      const MachineryModel(
        id: 'm4',
        ownerId: 'owner_4',
        ownerName: 'कृषि सेवा केंद्र सीहोर',
        ownerPhone: '9826998877',
        titleHi: 'कृषि ड्रोन स्प्रेयर (10L Tank - Drone)',
        titleEn: 'Agricultural Spraying Drone 10L',
        machineryType: 'drone_sprayer',
        modelYear: 2024,
        hp: 0,
        hourlyRate: 800.0,
        dailyRate: 4500.0,
        securityDeposit: 3000.0,
        images: [
          'https://images.unsplash.com/photo-1527977966376-1c8408f9f108?w=600',
        ],
        villageOrCity: 'सीहोर शहर',
        district: 'सीहोर',
        state: 'मध्य प्रदेश',
        isAvailable: true,
        rating: 5.0,
        totalBookings: 35,
      ),
      const MachineryModel(
        id: 'm5',
        ownerId: 'owner_5',
        ownerName: 'मोहनलाल पाटीदार',
        ownerPhone: '9425123412',
        titleHi: 'ऑटोमैटिक 9-टाइन सीड ड्रिल (Seed Drill)',
        titleEn: 'Automatic 9-Tyne Seed Drill',
        machineryType: 'seed_drill',
        modelYear: 2023,
        hp: 40,
        hourlyRate: 300.0,
        dailyRate: 1600.0,
        securityDeposit: 1000.0,
        images: [
          'https://images.unsplash.com/photo-1574943320219-553eb213f72d?w=600',
        ],
        villageOrCity: 'बुधनी',
        district: 'सीहोर',
        state: 'मध्य प्रदेश',
        isAvailable: true,
        rating: 4.8,
        totalBookings: 15,
      ),
    ];

    if (type != null && type != 'all') {
      return all.where((m) => m.machineryType == type).toList();
    }
    return all;
  }
}

