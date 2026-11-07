class RentalBookingModel {
  final String id;
  final String machineryId;
  final String renterId;
  final String ownerId;
  final String? machineryTitle;
  final String? machineryType;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double totalAmount;
  final double depositAmount;
  final String status; // 'pending', 'approved', 'rejected', 'in_use', 'completed', 'cancelled'
  final String? renterName;
  final String? renterPhone;
  final String? ownerName;
  final String? ownerPhone;
  final DateTime createdAt;

  const RentalBookingModel({
    required this.id,
    required this.machineryId,
    required this.renterId,
    required this.ownerId,
    this.machineryTitle,
    this.machineryType,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.totalAmount,
    required this.depositAmount,
    required this.status,
    this.renterName,
    this.renterPhone,
    this.ownerName,
    this.ownerPhone,
    required this.createdAt,
  });

  RentalBookingModel copyWith({
    String? status,
  }) {
    return RentalBookingModel(
      id: id,
      machineryId: machineryId,
      renterId: renterId,
      ownerId: ownerId,
      machineryTitle: machineryTitle,
      machineryType: machineryType,
      startDate: startDate,
      endDate: endDate,
      totalDays: totalDays,
      totalAmount: totalAmount,
      depositAmount: depositAmount,
      status: status ?? this.status,
      renterName: renterName,
      renterPhone: renterPhone,
      ownerName: ownerName,
      ownerPhone: ownerPhone,
      createdAt: createdAt,
    );
  }

  factory RentalBookingModel.fromJson(Map<String, dynamic> json) {
    return RentalBookingModel(
      id: json['id'] as String? ?? '',
      machineryId: json['machinery_id'] as String? ?? '',
      renterId: json['renter_id'] as String? ?? '',
      ownerId: json['owner_id'] as String? ?? '',
      machineryTitle: json['machinery']?['title_hi'] as String? ?? json['machinery_title'] as String?,
      machineryType: json['machinery']?['machinery_type'] as String? ?? json['machinery_type'] as String?,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : DateTime.now().add(const Duration(days: 1)),
      totalDays: (json['total_days'] as num?)?.toInt() ?? 1,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (json['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      renterName: json['renter_profile']?['full_name'] as String? ?? json['renter_name'] as String?,
      renterPhone: json['renter_profile']?['phone_number'] as String? ?? json['renter_phone'] as String?,
      ownerName: json['owner_profile']?['full_name'] as String? ?? json['owner_name'] as String?,
      ownerPhone: json['owner_profile']?['phone_number'] as String? ?? json['owner_phone'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'machinery_id': machineryId,
      'renter_id': renterId,
      'owner_id': ownerId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'total_days': totalDays,
      'total_amount': totalAmount,
      'deposit_amount': depositAmount,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

