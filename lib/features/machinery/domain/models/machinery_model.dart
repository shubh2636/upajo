class MachineryModel {
  final String id;
  final String ownerId;
  final String? ownerName;
  final String? ownerPhone;
  final String titleHi;
  final String titleEn;
  final String machineryType; // 'tractor', 'harvester', 'rotavator', 'thresher', 'seed_drill', 'drone_sprayer', 'laser_leveler'
  final int modelYear;
  final int hp; // Horsepower
  final double hourlyRate;
  final double dailyRate;
  final double securityDeposit;
  final List<String> images;
  final String villageOrCity;
  final String district;
  final String state;
  final bool isAvailable;
  final double rating;
  final int totalBookings;

  const MachineryModel({
    required this.id,
    required this.ownerId,
    this.ownerName,
    this.ownerPhone,
    required this.titleHi,
    required this.titleEn,
    required this.machineryType,
    required this.modelYear,
    required this.hp,
    required this.hourlyRate,
    required this.dailyRate,
    required this.securityDeposit,
    this.images = const [],
    required this.villageOrCity,
    required this.district,
    required this.state,
    this.isAvailable = true,
    this.rating = 4.8,
    this.totalBookings = 12,
  });

  factory MachineryModel.fromJson(Map<String, dynamic> json) {
    return MachineryModel(
      id: json['id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      ownerName: json['profiles']?['full_name'] as String? ?? json['owner_name'] as String?,
      ownerPhone: json['profiles']?['phone_number'] as String? ?? json['owner_phone'] as String?,
      titleHi: json['title_hi'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      machineryType: json['machinery_type'] as String? ?? 'tractor',
      modelYear: (json['model_year'] as num?)?.toInt() ?? 2022,
      hp: (json['hp'] as num?)?.toInt() ?? 45,
      hourlyRate: (json['hourly_rate'] as num?)?.toDouble() ?? 500.0,
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 3000.0,
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 1500.0,
      images: (json['images'] as List?)?.cast<String>() ?? [],
      villageOrCity: json['village_or_city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      totalBookings: (json['total_bookings'] as num?)?.toInt() ?? 12,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title_hi': titleHi,
      'title_en': titleEn,
      'machinery_type': machineryType,
      'model_year': modelYear,
      'hp': hp,
      'hourly_rate': hourlyRate,
      'daily_rate': dailyRate,
      'security_deposit': securityDeposit,
      'images': images,
      'village_or_city': villageOrCity,
      'district': district,
      'state': state,
      'is_available': isAvailable,
    };
  }
}
