
// lib/models/card_model.dart

class CardModel {
  final String cardId; 
  final String cardNumber;
  final String childId; 
  final String parentId;
  final bool isActive;
  final DateTime? linkedAt;

  CardModel({
    required this.cardId,
    required this.cardNumber,
    required this.childId,
    required this.parentId,
    required this.isActive,
    this.linkedAt,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      cardId: json['cardId'] ?? '',
      cardNumber: json['cardNumber'] ?? '',
      childId: json['childId'] ?? '',
      parentId: json['parentId'] ?? '',
      isActive: json['isActive'] ?? false,
      linkedAt: json['linkedAt'] != null ? DateTime.parse(json['linkedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'cardNumber': cardNumber,
      'childId': childId,
      'parentId': parentId,
      'isActive': isActive,
      'linkedAt': linkedAt?.toIso8601String(),
    };
  }
}