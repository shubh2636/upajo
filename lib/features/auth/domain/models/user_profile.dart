class UserProfile {
  final String id;
  final String role; // 'farmer', 'consumer', 'admin'
  final String phone;
  final String fullName;
  final String? avatarUrl;
  final String preferredLanguage;
  final String? state;
  final String? district;
  final String? villageOrCity;
  final String? pinCode;
  final String? addressLine;
  final double? locationLat;
  final double? locationLng;
  final String kycStatus; // 'pending', 'submitted', 'verified', 'rejected'
  final bool verifiedByAdmin;
  final String? fcmToken;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.role,
    required this.phone,
    required this.fullName,
    this.avatarUrl,
    this.preferredLanguage = 'hi',
    this.state,
    this.district,
    this.villageOrCity,
    this.pinCode,
    this.addressLine,
    this.locationLat,
    this.locationLng,
    this.kycStatus = 'pending',
    this.verifiedByAdmin = false,
    this.fcmToken,
    required this.createdAt,
  });

  bool get isFarmer => role == 'farmer';
  bool get isConsumer => role == 'consumer';
  bool get isAdmin => role == 'admin';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: json['role'] as String? ?? 'consumer',
      phone: json['phone'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      preferredLanguage: json['preferred_language'] as String? ?? 'hi',
      state: json['state'] as String?,
      district: json['district'] as String?,
      villageOrCity: json['village_or_city'] as String?,
      pinCode: json['pin_code'] as String?,
      addressLine: json['address_line'] as String?,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      kycStatus: json['kyc_status'] as String? ?? 'pending',
      verifiedByAdmin: json['verified_by_admin'] as bool? ?? false,
      fcmToken: json['fcm_token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'phone': phone,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'preferred_language': preferredLanguage,
      'state': state,
      'district': district,
      'village_or_city': villageOrCity,
      'pin_code': pinCode,
      'address_line': addressLine,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'kyc_status': kycStatus,
      'verified_by_admin': verifiedByAdmin,
      'fcm_token': fcmToken,
    };
  }

  UserProfile copyWith({
    String? role,
    String? fullName,
    String? avatarUrl,
    String? preferredLanguage,
    String? state,
    String? district,
    String? villageOrCity,
    String? pinCode,
    String? addressLine,
    String? kycStatus,
    bool? verifiedByAdmin,
    String? fcmToken,
  }) {
    return UserProfile(
      id: id,
      role: role ?? this.role,
      phone: phone,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      state: state ?? this.state,
      district: district ?? this.district,
      villageOrCity: villageOrCity ?? this.villageOrCity,
      pinCode: pinCode ?? this.pinCode,
      addressLine: addressLine ?? this.addressLine,
      locationLat: locationLat,
      locationLng: locationLng,
      kycStatus: kycStatus ?? this.kycStatus,
      verifiedByAdmin: verifiedByAdmin ?? this.verifiedByAdmin,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
