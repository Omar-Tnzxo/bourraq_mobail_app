/// نموذج البطاقة المحفوظة
/// ملاحظة: لا نحفظ بيانات البطاقة الفعلية، فقط Token من PayMob
class SavedCard {
  final String id;
  final String userId;
  final String cardToken; // PayMob token
  final String lastFourDigits;
  final String cardBrand; // VISA, Mastercard, Meeza
  final String? cardLabel; // تسمية اختيارية (بطاقة الراتب)
  final bool isDefault;
  final DateTime createdAt;

  const SavedCard({
    required this.id,
    required this.userId,
    required this.cardToken,
    required this.lastFourDigits,
    required this.cardBrand,
    this.cardLabel,
    this.isDefault = false,
    required this.createdAt,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      cardToken: json['card_token'] as String,
      lastFourDigits: json['last_four_digits'] as String,
      cardBrand: json['card_brand'] as String? ?? 'VISA',
      cardLabel: json['card_label'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'card_token': cardToken,
    'last_four_digits': lastFourDigits,
    'card_brand': cardBrand,
    'card_label': cardLabel,
    'is_default': isDefault,
  };

  /// Display card number masked (•••• 1234)
  String get maskedNumber => '•••• •••• •••• $lastFourDigits';

  /// Get card brand icon name
  String get brandIconAsset {
    switch (cardBrand.toLowerCase()) {
      case 'visa':
        return 'assets/icons/visa.png';
      case 'mastercard':
        return 'assets/icons/mastercard.png';
      case 'meeza':
        return 'assets/icons/meeza.png';
      default:
        return 'assets/icons/card.png';
    }
  }

  /// Display name (label or brand + last 4)
  String get displayName {
    if (cardLabel != null && cardLabel!.isNotEmpty) {
      return cardLabel!;
    }
    return '$cardBrand •••• $lastFourDigits';
  }
}
