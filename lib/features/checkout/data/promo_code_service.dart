import 'package:supabase_flutter/supabase_flutter.dart';

/// Promo Code Model - Full featured
class PromoCode {
  final String id;
  final String code;
  final String discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final String? descriptionAr;
  final String? descriptionEn;
  final double minOrderAmount;
  final double? maxDiscount;
  final int? usageLimit;
  final int usageCount;
  final int perUserLimit;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final bool isActive;

  PromoCode({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.descriptionAr,
    this.descriptionEn,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.usageLimit,
    this.usageCount = 0,
    this.perUserLimit = 1,
    this.startDate,
    this.expiryDate,
    required this.isActive,
  });

  factory PromoCode.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse numeric values (handles both String and num)
    double parseDouble(dynamic value, [double defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    return PromoCode(
      id: json['id'],
      code: json['code'],
      discountType: json['discount_type'],
      discountValue: parseDouble(json['discount_value']),
      descriptionAr: json['description_ar'],
      descriptionEn: json['description_en'],
      minOrderAmount: parseDouble(json['min_order_amount']),
      maxDiscount: json['max_discount'] != null
          ? parseDouble(json['max_discount'])
          : null,
      usageLimit: parseInt(json['usage_limit']),
      usageCount: parseInt(json['usage_count']) ?? 0,
      perUserLimit: parseInt(json['per_user_limit']) ?? 1,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  /// Calculate discount for a given order amount
  /// Note: free_shipping type returns 0 here - delivery fee is handled separately
  double calculateDiscount(double orderAmount) {
    if (orderAmount < minOrderAmount) return 0;

    // free_shipping doesn't give product discount
    if (discountType == 'free_shipping') return 0;

    double discount;
    if (discountType == 'percentage') {
      discount = orderAmount * (discountValue / 100);
      if (maxDiscount != null && discount > maxDiscount!) {
        discount = maxDiscount!;
      }
    } else {
      // fixed
      discount = discountValue;
    }

    return discount;
  }

  /// Check if this is a free shipping promo
  bool get isFreeShipping => discountType == 'free_shipping';

  /// Check if promo code is still valid
  bool get isValid {
    if (!isActive) return false;

    final now = DateTime.now();
    if (startDate != null && startDate!.isAfter(now)) return false;
    if (expiryDate != null && expiryDate!.isBefore(now)) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;

    return true;
  }

  /// Get description based on language
  String getDescription(String langCode) {
    if (langCode == 'ar') {
      return descriptionAr ?? '';
    }
    return descriptionEn ?? '';
  }
}

/// Service for promo code operations
class PromoCodeService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Validate and get promo code by code string
  Future<PromoCodeResult> validatePromoCode(
    String code,
    double orderAmount,
  ) async {
    try {
      final response = await _client
          .from('promo_codes')
          .select()
          .eq('code', code.toUpperCase())
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        return PromoCodeResult.error('كود الخصم غير صحيح');
      }

      final promoCode = PromoCode.fromJson(response);

      // Check validity (dates and usage limit)
      if (!promoCode.isValid) {
        return PromoCodeResult.error('كود الخصم منتهي الصلاحية');
      }

      // Check minimum order amount
      if (orderAmount < promoCode.minOrderAmount) {
        return PromoCodeResult.error(
          'الحد الأدنى للطلب ${promoCode.minOrderAmount.toStringAsFixed(0)} ج.م',
        );
      }

      // Check user usage limit
      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        final usageCount = await _getUserUsageCount(promoCode.id, userId);
        if (usageCount >= promoCode.perUserLimit) {
          return PromoCodeResult.error('لقد استخدمت هذا الكود من قبل');
        }
      }

      // Calculate discount
      final discount = promoCode.calculateDiscount(orderAmount);

      return PromoCodeResult.success(promoCode, discount);
    } catch (e) {
      return PromoCodeResult.error('حدث خطأ في التحقق من الكود');
    }
  }

  /// Get user's usage count for a promo code
  Future<int> _getUserUsageCount(String promoCodeId, String userId) async {
    try {
      final response = await _client
          .from('promo_code_usage')
          .select('id')
          .eq('promo_code_id', promoCodeId)
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Record promo code usage after order is placed
  Future<void> recordUsage({
    required String promoCodeId,
    required String? orderId,
    required double discountAmount,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _client.from('promo_code_usage').insert({
        'promo_code_id': promoCodeId,
        'user_id': userId,
        'order_id': orderId,
        'discount_amount': discountAmount,
      });

      // Increment usage count
      await _client.rpc(
        'increment_promo_usage',
        params: {'promo_id': promoCodeId},
      );
    } catch (e) {
      // Silent fail - don't block order
    }
  }
}

/// Result wrapper for promo code validation
class PromoCodeResult {
  final bool isSuccess;
  final PromoCode? promoCode;
  final double discount;
  final String? errorMessage;

  PromoCodeResult._({
    required this.isSuccess,
    this.promoCode,
    this.discount = 0,
    this.errorMessage,
  });

  factory PromoCodeResult.success(PromoCode code, double discount) {
    return PromoCodeResult._(
      isSuccess: true,
      promoCode: code,
      discount: discount,
    );
  }

  factory PromoCodeResult.error(String message) {
    return PromoCodeResult._(isSuccess: false, errorMessage: message);
  }
}
