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

  ChildModel({
    required this.childId,
    required this.childName,
    required this.childNickname,
    required this.cardId,
    required this.parentId,
    required this.childBalance,
    required this.isActive,
    required this.dailyLimit,
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
    };
  }
}
