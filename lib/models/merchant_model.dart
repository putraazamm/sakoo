// lib/models/merchant_model.dart

class MerchantModel {
  final String merchantId;
  final String merchantName;
  final double merchantBalance;
  final bool isActive;

  MerchantModel({
    required this.merchantId,
    required this.merchantName,
    required this.merchantBalance,
    required this.isActive,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    return MerchantModel(
      merchantId: json['merchantId'] ?? '',
      merchantName: json['merchantName'] ?? '',
      merchantBalance: (json['merchantBalance'] ?? 0.0).toDouble(),
      isActive: json['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'merchantName': merchantName,
      'merchantBalance': merchantBalance,
      'isActive': isActive,
    };
  }
}