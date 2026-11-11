import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/machinery_model.dart';
import '../../domain/models/rental_booking_model.dart';
import '../../domain/repositories/machinery_repository.dart';
import '../../data/repositories/machinery_repository_impl.dart';

final machineryRepositoryProvider = Provider<MachineryRepository>((ref) {
  return MachineryRepositoryImpl();
});

class MachineryState {
  final bool isLoading;
  final List<MachineryModel> machineryList;
  final String selectedType;
  final String selectedDistrict;
  final MachineryModel? selectedMachine;
  final List<RentalBookingModel> myLentRentals;
  final List<RentalBookingModel> myBorrowedRentals;
  final String? errorMessage;
  final bool isBookingSuccess;

  const MachineryState({
    this.isLoading = false,
    this.machineryList = const [],
    this.selectedType = 'all',
    this.selectedDistrict = 'Sehore',
    this.selectedMachine,
    this.myLentRentals = const [],
    this.myBorrowedRentals = const [],
    this.errorMessage,
    this.isBookingSuccess = false,
  });

  MachineryState copyWith({
    bool? isLoading,
    List<MachineryModel>? machineryList,
    String? selectedType,
    String? selectedDistrict,
    MachineryModel? selectedMachine,
    List<RentalBookingModel>? myLentRentals,
    List<RentalBookingModel>? myBorrowedRentals,
    String? errorMessage,
    bool? isBookingSuccess,
  }) {
    return MachineryState(
      isLoading: isLoading ?? this.isLoading,
      machineryList: machineryList ?? this.machineryList,
      selectedType: selectedType ?? this.selectedType,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedMachine: selectedMachine ?? this.selectedMachine,
      myLentRentals: myLentRentals ?? this.myLentRentals,
      myBorrowedRentals: myBorrowedRentals ?? this.myBorrowedRentals,
      errorMessage: errorMessage,
      isBookingSuccess: isBookingSuccess ?? this.isBookingSuccess,
    );
  }
}

class MachineryController extends StateNotifier<MachineryState> {
  final MachineryRepository _repository;

  MachineryController(this._repository) : super(const MachineryState()) {
    loadMachinery();
  }

  Future<void> loadMachinery({String? type, String? district}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final t = type ?? state.selectedType;
      final d = district ?? state.selectedDistrict;
      final list = await _repository.getAvailableMachinery(type: t, district: d);
      state = state.copyWith(
        machineryList: list,
        selectedType: t,
        selectedDistrict: d,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void filterByType(String type) {
    state = state.copyWith(selectedType: type);
    loadMachinery(type: type);
  }

  void selectMachine(MachineryModel machine) {
    state = state.copyWith(selectedMachine: machine, isBookingSuccess: false);
  }

  Future<bool> listNewMachinery(MachineryModel machine) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final saved = await _repository.listMachinery(machine);
      state = state.copyWith(
        machineryList: [saved, ...state.machineryList],
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> requestBooking({
    required String machineryId,
    required String renterId,
    required String ownerId,
    required DateTime startDate,
    required DateTime endDate,
    required double dailyRate,
    required double securityDeposit,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isBookingSuccess: false);
    try {
      final booking = await _repository.createRentalBooking(
        machineryId: machineryId,
        renterId: renterId,
        ownerId: ownerId,
        startDate: startDate,
        endDate: endDate,
        dailyRate: dailyRate,
        securityDeposit: securityDeposit,
      );
      state = state.copyWith(
        isLoading: false,
        isBookingSuccess: true,
        myBorrowedRentals: [booking, ...state.myBorrowedRentals],
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> loadUserRentals(String userId) async {
    state = state.copyWith(isLoading: true);
    try {
      final lent = await _repository.getUserRentals(userId: userId, asOwner: true);
      final borrowed = await _repository.getUserRentals(userId: userId, asOwner: false);
      state = state.copyWith(
        myLentRentals: lent,
        myBorrowedRentals: borrowed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> updateBookingStatus(String rentalId, String newStatus, String userId) async {
    await _repository.updateRentalStatus(rentalId: rentalId, newStatus: newStatus);
    await loadUserRentals(userId);
  }
}

final machineryControllerProvider =
    StateNotifierProvider<MachineryController, MachineryState>((ref) {
  final repo = ref.watch(machineryRepositoryProvider);
  return MachineryController(repo);
});

