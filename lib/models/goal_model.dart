class GoalModel {
  final String goalId;
  final String childId;
  final String parentId;
  final String goalTitle;
  final double targetAmount;
  final double collectedAmount;

  GoalModel({
    required this.goalId,
    required this.childId,
    required this.parentId,
    required this.goalTitle,
    required this.targetAmount,
    required this.collectedAmount,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) {
    return GoalModel(
      goalId: json['goalId'] ?? '',
      childId: json['childId'] ?? '',
      parentId: json['parentId'] ?? '',
      goalTitle: json['goalTitle'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0.0).toDouble(),
      collectedAmount: (json['collectedAmount'] ?? 0.0).toDouble(),
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
    };
  }
}