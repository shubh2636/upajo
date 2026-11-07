import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/disease_scan_result.dart';
import '../../domain/repositories/disease_detection_repository.dart';
import '../../data/repositories/disease_detection_repository_impl.dart';

final diseaseDetectionRepositoryProvider = Provider<DiseaseDetectionRepository>((ref) {
  return DiseaseDetectionRepositoryImpl();
});

class DiseaseDetectionState {
  final bool isAnalyzing;
  final File? selectedImage;
  final DiseaseScanResult? scanResult;
  final List<DiseaseScanResult> scanHistory;
  final String? errorMessage;

  const DiseaseDetectionState({
    this.isAnalyzing = false,
    this.selectedImage,
    this.scanResult,
    this.scanHistory = const [],
    this.errorMessage,
  });

  DiseaseDetectionState copyWith({
    bool? isAnalyzing,
    File? selectedImage,
    DiseaseScanResult? scanResult,
    List<DiseaseScanResult>? scanHistory,
    String? errorMessage,
  }) {
    return DiseaseDetectionState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      selectedImage: selectedImage ?? this.selectedImage,
      scanResult: scanResult ?? this.scanResult,
      scanHistory: scanHistory ?? this.scanHistory,
      errorMessage: errorMessage,
    );
  }
}

class DiseaseDetectionController extends StateNotifier<DiseaseDetectionState> {
  final DiseaseDetectionRepository _repository;
  final ImagePicker _picker = ImagePicker();

  DiseaseDetectionController(this._repository) : super(const DiseaseDetectionState());

  Future<void> pickAndAnalyzeImage({
    required ImageSource source,
    required String farmerId,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 90,
      );

      if (picked == null) return;

      final file = File(picked.path);
      state = state.copyWith(
        selectedImage: file,
        isAnalyzing: true,
        errorMessage: null,
      );

      final result = await _repository.detectDisease(
        imageFile: file,
        farmerId: farmerId,
      );

      state = state.copyWith(
        isAnalyzing: false,
        scanResult: result,
        scanHistory: [result, ...state.scanHistory],
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'रोग विश्लेषण में त्रुटि: $e',
      );
    }
  }

  Future<void> loadScanHistory(String farmerId) async {
    try {
      final history = await _repository.getFarmerScanHistory(farmerId);
      state = state.copyWith(scanHistory: history);
    } catch (e) {
      // Graceful local handling
    }
  }

  void clearCurrentScan() {
    state = state.copyWith(
      selectedImage: null,
      scanResult: null,
      errorMessage: null,
    );
  }
}

final diseaseDetectionControllerProvider =
    StateNotifierProvider<DiseaseDetectionController, DiseaseDetectionState>((ref) {
  final repo = ref.watch(diseaseDetectionRepositoryProvider);
  return DiseaseDetectionController(repo);
});

