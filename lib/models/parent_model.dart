// lib/models/parent_model.dart

class ParentModel {
  final String parentId;
  final String parentName;
  final String parentEmail;
  final double parentBalance;

  ParentModel({
    required this.parentId,
    required this.parentName,
    required this.parentEmail,
    required this.parentBalance,
  });

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      parentId: json['parentId'] ?? '',
      parentName: json['parentName'] ?? '',
      parentEmail: json['parentEmail'] ?? '',
      parentBalance: (json['parentBalance'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentId': parentId,
      'parentName': parentName,
      'parentEmail': parentEmail,
      'parentBalance': parentBalance,
    };
  }
}