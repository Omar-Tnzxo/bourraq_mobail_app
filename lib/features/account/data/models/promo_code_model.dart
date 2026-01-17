import 'package:equatable/equatable.dart';

class PromoCode extends Equatable {
  final String id;
  final String code;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final String? descriptionAr;
  final String? descriptionEn;
  final DateTime expiryDate;
  final bool isActive;

  const PromoCode({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.descriptionAr,
    this.descriptionEn,
    required this.expiryDate,
    required this.isActive,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    return PromoCode(
      id: json['id'] as String,
      code: json['code'] as String,
      discountType: json['discount_type'] as String,
      discountValue: (json['discount_value'] as num).toDouble(),
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  String getDescription(String languageCode) {
    if (languageCode == 'ar') {
      return descriptionAr ?? descriptionEn ?? '';
    }
    return descriptionEn ?? descriptionAr ?? '';
  }

  @override
  List<Object?> get props => [
    id,
    code,
    discountType,
    discountValue,
    descriptionAr,
    descriptionEn,
    expiryDate,
    isActive,
  ];
}
