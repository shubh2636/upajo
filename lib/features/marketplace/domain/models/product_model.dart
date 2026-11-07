class ProductModel {
  final String id;
  final String farmerId;
  final String categoryId;
  final String titleHi;
  final String titleEn;
  final String descriptionHi;
  final String descriptionEn;
  final List<String> images;
  final double pricePerKg;
  final double stockKg;
  final List<int> packSizesKg;
  final DateTime harvestDate;
  final int shelfLifeDays;
  final List<String> deliveryModes;
  final bool isOrganic;
  final bool isActive;
  final String villageOrCity;
  final String district;
  final String state;
  final String pinCode;
  final double? locationLat;
  final double? locationLng;
  final DateTime createdAt;

  // Joined fields
  final String? farmerName;
  final String? farmerPhone;
  final bool farmerVerified;

  const ProductModel({
    required this.id,
    required this.farmerId,
    required this.categoryId,
    required this.titleHi,
    required this.titleEn,
    required this.descriptionHi,
    required this.descriptionEn,
    required this.images,
    required this.pricePerKg,
    required this.stockKg,
    required this.packSizesKg,
    required this.harvestDate,
    required this.shelfLifeDays,
    required this.deliveryModes,
    this.isOrganic = false,
    this.isActive = true,
    required this.villageOrCity,
    required this.district,
    required this.state,
    required this.pinCode,
    this.locationLat,
    this.locationLng,
    required this.createdAt,
    this.farmerName,
    this.farmerPhone,
    this.farmerVerified = false,
  });

  double getPriceForPack(int packSizeKg) {
    return pricePerKg * packSizeKg;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawPackSizes = json['pack_sizes_kg'];
    List<int> packSizes = [10, 20, 50];
    if (rawPackSizes is List) {
      packSizes = rawPackSizes.map((e) => (e as num).toInt()).toList();
    }

    final rawDelivery = json['delivery_modes'];
    List<String> modes = ['pickup', 'self_delivery'];
    if (rawDelivery is List) {
      modes = rawDelivery.map((e) => e.toString()).toList();
    }

    final rawImages = json['images'];
    List<String> imgList = [];
    if (rawImages is List) {
      imgList = rawImages.map((e) => e.toString()).toList();
    }

    // Farmer joined relation
    final farmerData = json['farmer'] as Map<String, dynamic>?;

    return ProductModel(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String,
      categoryId: json['category_id'] as String,
      titleHi: json['title_hi'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      descriptionHi: json['description_hi'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      images: imgList,
      pricePerKg: (json['price_per_kg'] as num?)?.toDouble() ?? 0.0,
      stockKg: (json['stock_kg'] as num?)?.toDouble() ?? 0.0,
      packSizesKg: packSizes,
      harvestDate: json['harvest_date'] != null
          ? DateTime.parse(json['harvest_date'] as String)
          : DateTime.now(),
      shelfLifeDays: (json['shelf_life_days'] as num?)?.toInt() ?? 180,
      deliveryModes: modes,
      isOrganic: json['is_organic'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      villageOrCity: json['village_or_city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pinCode: json['pin_code'] as String? ?? '',
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      farmerName: farmerData != null ? farmerData['full_name'] as String? : null,
      farmerPhone: farmerData != null ? farmerData['phone'] as String? : null,
      farmerVerified: farmerData != null ? (farmerData['verified_by_admin'] as bool? ?? false) : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'farmer_id': farmerId,
      'category_id': categoryId,
      'title_hi': titleHi,
      'title_en': titleEn,
      'description_hi': descriptionHi,
      'description_en': descriptionEn,
      'images': images,
      'price_per_kg': pricePerKg,
      'stock_kg': stockKg,
      'pack_sizes_kg': packSizesKg,
      'harvest_date': harvestDate.toIso8601String().split('T')[0],
      'shelf_life_days': shelfLifeDays,
      'delivery_modes': deliveryModes,
      'is_organic': isOrganic,
      'is_active': isActive,
      'village_or_city': villageOrCity,
      'district': district,
      'state': state,
      'pin_code': pinCode,
      'location_lat': locationLat,
      'location_lng': locationLng,
    };
  }
}

