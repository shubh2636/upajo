import 'dart:io';
import '../models/disease_scan_result.dart';

abstract class DiseaseDetectionRepository {
  /// Runs on-device TFLite inference or FastAPI fallback on the leaf photograph
  Future<DiseaseScanResult> detectDisease({
    required File imageFile,
    required String farmerId,
  });

  /// Fetches historical scans performed by the farmer
  Future<List<DiseaseScanResult>> getFarmerScanHistory(String farmerId);
}

