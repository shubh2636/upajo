class CropCalendarTask {
  final String id;
  final String titleHi;
  final String titleEn;
  final String descriptionHi;
  final String descriptionEn;
  final String stage; // 'soil_prep', 'sowing', 'irrigation', 'fertilizer', 'pest_control', 'harvesting'
  final int daysAfterSowing;
  final DateTime dueDate;
  final bool isCompleted;

  const CropCalendarTask({
    required this.id,
    required this.titleHi,
    required this.titleEn,
    required this.descriptionHi,
    required this.descriptionEn,
    required this.stage,
    required this.daysAfterSowing,
    required this.dueDate,
    this.isCompleted = false,
  });

  CropCalendarTask copyWith({bool? isCompleted}) {
    return CropCalendarTask(
      id: id,
      titleHi: titleHi,
      titleEn: titleEn,
      descriptionHi: descriptionHi,
      descriptionEn: descriptionEn,
      stage: stage,
      daysAfterSowing: daysAfterSowing,
      dueDate: dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory CropCalendarTask.fromJson(Map<String, dynamic> json) {
    return CropCalendarTask(
      id: json['id'] as String? ?? '',
      titleHi: json['title_hi'] as String? ?? '',
      titleEn: json['title_en'] as String? ?? '',
      descriptionHi: json['description_hi'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      stage: json['stage'] as String? ?? 'sowing',
      daysAfterSowing: (json['days_after_sowing'] as num?)?.toInt() ?? 0,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      isCompleted: json['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title_hi': titleHi,
      'title_en': titleEn,
      'description_hi': descriptionHi,
      'description_en': descriptionEn,
      'stage': stage,
      'days_after_sowing': daysAfterSowing,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'is_completed': isCompleted,
    };
  }
}

class CropRecommendation {
  final String cropId;
  final String nameHi;
  final String nameEn;
  final String scientificName;
  final String variety;
  final double expectedYieldMinQuintal;
  final double expectedYieldMaxQuintal;
  final double totalExpectedYieldQuintal;
  final double confidenceScore;
  final String summaryHi;
  final List<CropCalendarTask> calendarSchedule;

  const CropRecommendation({
    required this.cropId,
    required this.nameHi,
    required this.nameEn,
    required this.scientificName,
    required this.variety,
    required this.expectedYieldMinQuintal,
    required this.expectedYieldMaxQuintal,
    required this.totalExpectedYieldQuintal,
    required this.confidenceScore,
    required this.summaryHi,
    required this.calendarSchedule,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    final rawTasks = json['calendar_schedule'] as List? ?? [];
    final tasks = rawTasks
        .map((t) => CropCalendarTask.fromJson(t as Map<String, dynamic>))
        .toList();

    return CropRecommendation(
      cropId: json['crop_id'] as String? ?? '',
      nameHi: json['name_hi'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      scientificName: json['scientific_name'] as String? ?? '',
      variety: json['variety'] as String? ?? '',
      expectedYieldMinQuintal: (json['expected_yield_min'] as num?)?.toDouble() ?? 15.0,
      expectedYieldMaxQuintal: (json['expected_yield_max'] as num?)?.toDouble() ?? 20.0,
      totalExpectedYieldQuintal: (json['total_expected_yield'] as num?)?.toDouble() ?? 37.0,
      confidenceScore: (json['confidence'] as num?)?.toDouble() ?? 0.95,
      summaryHi: json['summary_hi'] as String? ?? '',
      calendarSchedule: tasks,
    );
  }
}
