import '../models/machinery_model.dart';
import '../models/rental_booking_model.dart';

abstract class MachineryRepository {
  /// Fetches available machinery filtered optionally by type and district
  Future<List<MachineryModel>> getAvailableMachinery({
    String? type,
    String? district,
  });

  /// Fetches single machinery details
  Future<MachineryModel?> getMachineryById(String id);

  /// Allows any farmer/user to list their tractor or implement for rent
  Future<MachineryModel> listMachinery(MachineryModel machinery);

  /// Requests a rental booking for specific dates
  Future<RentalBookingModel> createRentalBooking({
    required String machineryId,
    required String renterId,
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
    required double dailyRate,
    required double securityDeposit,
  });

  /// Fetches bookings where user is renter or owner
  Future<List<RentalBookingModel>> getUserRentals({
    required String userId,
    required bool asOwner,
  });

  /// Updates rental booking state (e.g. approve, reject, complete)
  Future<void> updateRentalStatus({
    required String rentalId,
    required String newStatus,
  });
}
