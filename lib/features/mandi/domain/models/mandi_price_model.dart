class MandiPriceModel {
  final String id;
  final String cropNameHi;
  final String cropNameEn;
  final String mandiName;
  final String district;
  final String state;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final double change24h;
  final double arrivalsTonnes;
  final DateTime priceDate;
  final List<double> historicalTrend; // Last 7-30 days modal prices

  const MandiPriceModel({
    required this.id,
    required this.cropNameHi,
    required this.cropNameEn,
    required this.mandiName,
    required this.district,
    required this.state,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.change24h,
    required this.arrivalsTonnes,
    required this.priceDate,
    this.historicalTrend = const [],
  });

  factory MandiPriceModel.fromJson(Map<String, dynamic> json) {
    return MandiPriceModel(
      id: json['id'] as String? ?? '',
      cropNameHi: json['crop_name_hi'] as String? ?? '',
      cropNameEn: json['crop_name_en'] as String? ?? '',
      mandiName: json['mandi_name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? 'मध्य प्रदेश',
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 2000.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 2600.0,
      modalPrice: (json['modal_price'] as num?)?.toDouble() ?? 2400.0,
      change24h: (json['change_24h'] as num?)?.toDouble() ?? 0.0,
      arrivalsTonnes: (json['arrivals_tonnes'] as num?)?.toDouble() ?? 150.0,
      priceDate: json['price_date'] != null
          ? DateTime.parse(json['price_date'] as String)
          : DateTime.now(),
      historicalTrend: (json['historical_trend'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          const [2800.0, 2850.0, 2900.0, 2920.0, 2980.0, 3050.0, 3120.0],
    );
  }
}

class PriceAlertModel {
  final String id;
  final String farmerId;
  final String cropName;
  final double targetPrice;
  final String condition; // 'above', 'below'
  final bool isTriggered;
  final DateTime createdAt;

  const PriceAlertModel({
    required this.id,
    required this.farmerId,
    required this.cropName,
    required this.targetPrice,
    required this.condition,
    this.isTriggered = false,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'crop_name': cropName,
      'target_price': targetPrice,
      'condition': condition,
      'is_triggered': isTriggered,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

