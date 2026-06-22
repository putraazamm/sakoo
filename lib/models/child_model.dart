// lib/models/child_model.dart

class ChildModel {
  final String childId;
  final String childName;
  final String childNickname;
  final String cardId;
  final String parentId;
  final double childBalance;
  final bool isActive;
  final double dailyLimit;

  // --- Scheduled Auto Top-Up ---
  final bool autoTopUpEnabled;
  final double autoTopUpAmount;
  final String autoTopUpFrequency; // 'daily' | 'weekly' | 'monthly'
  final int autoTopUpDay; // ISO weekday (1-7) for weekly, day-of-month (1-28) for monthly
  final DateTime? lastAutoTopUpAt;

  ChildModel({
    required this.childId,
    required this.childName,
    required this.childNickname,
    required this.cardId,
    required this.parentId,
    required this.childBalance,
    required this.isActive,
    required this.dailyLimit,
    this.autoTopUpEnabled = false,
    this.autoTopUpAmount = 0.0,
    this.autoTopUpFrequency = 'weekly',
    this.autoTopUpDay = 1,
    this.lastAutoTopUpAt,
  });

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    return ChildModel(
      childId: json['childId'] ?? '',
      childName: json['childName'] ?? '',
      childNickname: json['childNickname'] ?? '',
      cardId: json['cardId'] ?? '',
      parentId: json['parentId'] ?? '',
      childBalance: (json['childBalance'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? false,
      dailyLimit: (json['dailyLimit'] ?? 0.0).toDouble(),
      autoTopUpEnabled: json['autoTopUpEnabled'] ?? false,
      autoTopUpAmount: (json['autoTopUpAmount'] ?? 0.0).toDouble(),
      autoTopUpFrequency: json['autoTopUpFrequency'] ?? 'weekly',
      autoTopUpDay: json['autoTopUpDay'] ?? 1,
      lastAutoTopUpAt: json['lastAutoTopUpAt'] != null
          ? DateTime.tryParse(json['lastAutoTopUpAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'childId': childId,
      'childName': childName,
      'childNickname': childNickname,
      'cardId': cardId,
      'parentId': parentId,
      'childBalance': childBalance,
      'isActive': isActive,
      'dailyLimit': dailyLimit,
      'autoTopUpEnabled': autoTopUpEnabled,
      'autoTopUpAmount': autoTopUpAmount,
      'autoTopUpFrequency': autoTopUpFrequency,
      'autoTopUpDay': autoTopUpDay,
      'lastAutoTopUpAt': lastAutoTopUpAt?.toIso8601String(),
    };
  }

  // Convenience copyWith so the controller doesn't need to repeat every field
  // when only updating a couple of values.
  ChildModel copyWith({
    String? childId,
    String? childName,
    String? childNickname,
    String? cardId,
    String? parentId,
    double? childBalance,
    bool? isActive,
    double? dailyLimit,
    bool? autoTopUpEnabled,
    double? autoTopUpAmount,
    String? autoTopUpFrequency,
    int? autoTopUpDay,
    DateTime? lastAutoTopUpAt,
  }) {
    return ChildModel(
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      childNickname: childNickname ?? this.childNickname,
      cardId: cardId ?? this.cardId,
      parentId: parentId ?? this.parentId,
      childBalance: childBalance ?? this.childBalance,
      isActive: isActive ?? this.isActive,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      autoTopUpEnabled: autoTopUpEnabled ?? this.autoTopUpEnabled,
      autoTopUpAmount: autoTopUpAmount ?? this.autoTopUpAmount,
      autoTopUpFrequency: autoTopUpFrequency ?? this.autoTopUpFrequency,
      autoTopUpDay: autoTopUpDay ?? this.autoTopUpDay,
      lastAutoTopUpAt: lastAutoTopUpAt ?? this.lastAutoTopUpAt,
    );
  }
}