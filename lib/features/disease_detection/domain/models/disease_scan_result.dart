class DiseaseScanResult {
  final String id;
  final String cropName;
  final String diseaseNameHi;
  final String diseaseNameEn;
  final double confidenceScore;
  final String severity; // 'none', 'low', 'medium', 'severe'
  final String symptomsHi;
  final String organicTreatmentHi;
  final String chemicalTreatmentHi;
  final String preventionHi;
  final String? localImagePath;
  final String? serverImageUrl;
  final DateTime scannedAt;
  final bool isOfflineInference;

  const DiseaseScanResult({
    required this.id,
    required this.cropName,
    required this.diseaseNameHi,
    required this.diseaseNameEn,
    required this.confidenceScore,
    required this.severity,
    required this.symptomsHi,
    required this.organicTreatmentHi,
    required this.chemicalTreatmentHi,
    required this.preventionHi,
    this.localImagePath,
    this.serverImageUrl,
    required this.scannedAt,
    this.isOfflineInference = false,
  });

  factory DiseaseScanResult.fromJson(Map<String, dynamic> json) {
    return DiseaseScanResult(
      id: json['id'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? 'फसल',
      diseaseNameHi: json['disease_name_hi'] as String? ?? '',
      diseaseNameEn: json['disease_name_en'] as String? ?? '',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.90,
      severity: json['severity'] as String? ?? 'medium',
      symptomsHi: json['symptoms_hi'] as String? ?? '',
      organicTreatmentHi: json['organic_treatment_hi'] as String? ?? json['treatment_hi'] as String? ?? '',
      chemicalTreatmentHi: json['chemical_treatment_hi'] as String? ?? '',
      preventionHi: json['prevention_hi'] as String? ?? '',
      localImagePath: json['local_image_path'] as String?,
      serverImageUrl: json['image_url'] as String?,
      scannedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isOfflineInference: json['is_offline_inference'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSupabaseJson(String farmerId) {
    return {
      'id': id,
      'farmer_id': farmerId,
      'image_url': serverImageUrl ?? localImagePath ?? '',
      'crop_name': cropName,
      'disease_name_hi': diseaseNameHi,
      'disease_name_en': diseaseNameEn,
      'confidence_score': confidenceScore,
      'severity': severity,
      'treatment_hi': '$organicTreatmentHi\n\nरासायनिक उपचार:\n$chemicalTreatmentHi',
      'treatment_en': diseaseNameEn,
      'is_synced_with_server': !isOfflineInference,
      'created_at': scannedAt.toIso8601String(),
    };
  }
}

