import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A product offered by a specific store with its own price and rating.
/// Each store can offer the same base product at a different price.
class StoreProduct {
  final String id;
  final String storeId;
  final String productId;

  // Product base info (from joined products table)
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? imageUrl;
  final String? categoryId;
  final bool isActive;

  // Store-specific pricing
  final double merchantPrice;
  final double customerPrice;

  // Rating
  final double avgRating;
  final int ratingCount;

  // Store location (for distance sorting)
  final double? storeLat;
  final double? storeLng;

  // Store info
  final String? storeNameAr;
  final String? storeNameEn;
  final String? storeAreaId;

  // Availability
  final bool isAvailable;
  final String approvalStatus;

  // Badge
  final String? badgeNameAr;
  final String? badgeNameEn;
  final String? badgeColor;

  const StoreProduct({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.imageUrl,
    this.categoryId,
    this.isActive = true,
    required this.merchantPrice,
    required this.customerPrice,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.storeLat,
    this.storeLng,
    this.storeNameAr,
    this.storeNameEn,
    this.storeAreaId,
    this.isAvailable = true,
    this.approvalStatus = 'approved',
    this.badgeNameAr,
    this.badgeNameEn,
    this.badgeColor,
  });

  /// Get localized name
  String getName(BuildContext? context) {
    if (context == null) return nameAr;
    return context.locale.languageCode == 'ar' ? nameAr : nameEn;
  }

  /// Get localized description
  String? getDescription(BuildContext? context) {
    if (context == null) return descriptionAr;
    return context.locale.languageCode == 'ar' ? descriptionAr : descriptionEn;
  }

  /// Get localized badge name
  String? getBadgeName(BuildContext? context) {
    if (badgeNameAr == null && badgeNameEn == null) return null;
    if (context == null) return badgeNameAr;
    return context.locale.languageCode == 'ar' ? badgeNameAr : badgeNameEn;
  }

  /// Create from Supabase JSON (store_products join products, stores, badges)
  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    final store = json['stores'] as Map<String, dynamic>?;
    final badge = json['product_badges'] as Map<String, dynamic>?;

    return StoreProduct(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      productId: json['product_id'] as String,
      nameAr:
          product?['name_ar'] as String? ?? json['name_ar'] as String? ?? '',
      nameEn:
          product?['name_en'] as String? ?? json['name_en'] as String? ?? '',
      descriptionAr: product?['description_ar'] as String?,
      descriptionEn: product?['description_en'] as String?,
      imageUrl: product?['image_url'] as String?,
      categoryId: product?['category_id'] as String?,
      isActive: product?['is_active'] as bool? ?? true,
      merchantPrice: (json['merchant_price'] as num?)?.toDouble() ?? 0,
      customerPrice: (json['customer_price'] as num?)?.toDouble() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      storeLat: (store?['latitude'] as num?)?.toDouble(),
      storeLng: (store?['longitude'] as num?)?.toDouble(),
      storeNameAr: store?['name_ar'] as String?,
      storeNameEn: store?['name_en'] as String?,
      storeAreaId: store?['area_id'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      approvalStatus: json['approval_status'] as String? ?? 'approved',
      badgeNameAr: badge?['name_ar'] as String?,
      badgeNameEn: badge?['name_en'] as String?,
      badgeColor: badge?['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'product_id': productId,
      'merchant_price': merchantPrice,
      'customer_price': customerPrice,
      'avg_rating': avgRating,
      'rating_count': ratingCount,
      'is_available': isAvailable,
      'approval_status': approvalStatus,
    };
  }
}
