class GoalModel {
  final String goalId;
  final String childId;
  final String parentId;
  final String goalTitle;
  final double targetAmount;
  final double collectedAmount;
  final DateTime? createdAt;
  final String icon;
  final bool isCompleted;

  GoalModel({
    required this.goalId,
    required this.childId,
    required this.parentId,
    required this.goalTitle,
    required this.targetAmount,
    required this.collectedAmount,
    this.createdAt,
    this.icon = '🎯',
    this.isCompleted = false,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (collectedAmount / targetAmount).clamp(0, 1);

  double get remainingAmount =>
      (targetAmount - collectedAmount).clamp(0, targetAmount);

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      goalId: json['goalId'] ?? '',
      childId: json['childId'] ?? '',
      parentId: json['parentId'] ?? '',
      goalTitle: json['goalTitle'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0.0).toDouble(),
      collectedAmount: (json['collectedAmount'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      icon: json['icon'] ?? '🎯',
      isCompleted: json['isCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goalId': goalId,
      'childId': childId,
      'parentId': parentId,
      'goalTitle': goalTitle,
      'targetAmount': targetAmount,
      'collectedAmount': collectedAmount,
      'icon': icon,
      'isCompleted': isCompleted,
    };
  }
}