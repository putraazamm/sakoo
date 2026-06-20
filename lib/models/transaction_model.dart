// lib/models/transaction_model.dart

class TransactionModel {
  final String merchantId;
  final String merchantName;
  final String childId;
  final String childName;
  final String category;
  final double amount;
  final DateTime createdAt;

  TransactionModel({
    required this.merchantId,
    required this.merchantName,
    required this.childId,
    required this.childName,
    required this.category,
    required this.amount,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      merchantId: json['merchantId'] ?? '',
      merchantName: json['merchantName'] ?? '',
      childId: json['childId'] ?? 'Unknown',
      childName: json['child'] != null ? (json['child']['childName']) ?? '' : '',
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
