import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// A product offered by a specific branch with its own price and rating.
/// Each branch can offer the same base product at a different price.
class BranchProduct {
  final String id;
  final String branchId;
  final String productId;

  // Product base info (from joined products table)
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? imageUrl;
  final String? categoryId;
  final String? subCategoryId;
  final bool isActive;
  final double? weightValue;
  final String? weightUnitAr;
  final String? weightUnitEn;

  // Branch-specific pricing
  final double partnerPrice;
  final double customerPrice;

  // Rating
  final double avgRating;
  final int ratingCount;

  // Branch location (for distance sorting)
  final double? branchLat;
  final double? branchLng;
  // Branch info
  final String? branchNameAr;
  final String? branchNameEn;
  final String? branchAreaId;

  // Availability
  final bool isAvailable;
  final String approvalStatus;

  // Badge
  final String? badgeNameAr;
  final String? badgeNameEn;
  final String? badgeColor;

  const BranchProduct({
    required this.id,
    required this.branchId,
    required this.productId,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    this.imageUrl,
    this.categoryId,
    this.subCategoryId,
    this.isActive = true,
    required this.partnerPrice,
    required this.customerPrice,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.branchLat,
    this.branchLng,
    this.branchNameAr,
    this.branchNameEn,
    this.branchAreaId,
    this.isAvailable = true,
    this.approvalStatus = 'approved',
    this.badgeNameAr,
    this.badgeNameEn,
    this.badgeColor,
    this.weightValue,
    this.weightUnitAr,
    this.weightUnitEn,
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
    if (badgeNameAr != null && badgeNameAr!.startsWith('product.badge_')) {
      return badgeNameAr!.tr();
    }
    if (context == null) return badgeNameAr;
    return context.locale.languageCode == 'ar' ? badgeNameAr : badgeNameEn;
  }

  String? getWeightUnit(String langCode) {
    return langCode == 'ar' ? weightUnitAr : weightUnitEn;
  }

  String getLocalizedWeight(String langCode) {
    if (weightValue == null) return '';
    final String valueStr = weightValue! == weightValue!.toInt()
        ? weightValue!.toInt().toString()
        : weightValue!.toString();
    final unit = getWeightUnit(langCode) ?? '';
    return '$valueStr $unit';
  }

  /// Create from Supabase JSON (partner_products join products, branches, badges)
  factory BranchProduct.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;
    final branch = json['branches'] as Map<String, dynamic>?;
    final badge = json['product_badges'] as Map<String, dynamic>?;

    return BranchProduct(
      id: json['id'] as String,
      branchId: json['branch_id'] as String,
      productId: json['product_id'] as String,
      nameAr:
          product?['name_ar'] as String? ?? json['name_ar'] as String? ?? '',
      nameEn:
          product?['name_en'] as String? ?? json['name_en'] as String? ?? '',
      descriptionAr: product?['description_ar'] as String?,
      descriptionEn: product?['description_en'] as String?,
      imageUrl: product?['image_url'] as String?,
      categoryId: product?['category_id'] as String?,
      subCategoryId: product?['sub_category_id'] as String?,
      isActive: product?['is_active'] as bool? ?? true,
      partnerPrice: (json['partner_price'] as num?)?.toDouble() ?? 0,
      customerPrice: (json['customer_price'] as num?)?.toDouble() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['rating_count'] as int? ?? 0,
      branchLat: (branch?['latitude'] as num?)?.toDouble(),
      branchLng: (branch?['longitude'] as num?)?.toDouble(),
      branchNameAr: branch?['name_ar'] as String?,
      branchNameEn: branch?['name_en'] as String?,
      branchAreaId: branch?['area_id'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      approvalStatus: json['approval_status'] as String? ?? 'approved',
      badgeNameAr: _getBadgeNameAr(badge?['badge_type'] as String?),
      badgeNameEn: _getBadgeNameEn(badge?['badge_type'] as String?),
      badgeColor: _getBadgeColor(badge?['badge_type'] as String?),
      weightValue:
          (product?['weight_value'] as num? ?? json['weight_value'] as num?)
              ?.toDouble(),
      weightUnitAr:
          product?['weight_unit_ar'] as String? ??
          json['weight_unit_ar'] as String?,
      weightUnitEn:
          product?['weight_unit_en'] as String? ??
          json['weight_unit_en'] as String?,
    );
  }

  static String? _getBadgeNameAr(String? type) {
    if (type == null) return null;
    return 'product.badge_$type';
  }

  static String? _getBadgeNameEn(String? type) {
    if (type == null) return null;
    return 'product.badge_$type';
  }

  static String? _getBadgeColor(String? type) {
    switch (type) {
      case 'featured':
        return 'FFD700'; // Gold
      case 'best_seller':
        return 'FF4500'; // OrangeRed
      case 'new':
        return '32CD32'; // LimeGreen
      case 'top_rated':
        return '1E90FF'; // DodgerBlue
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'product_id': productId,
      'partner_price': partnerPrice,
      'customer_price': customerPrice,
      'avg_rating': avgRating,
      'rating_count': ratingCount,
      'is_available': isAvailable,
      'approval_status': approvalStatus,
    };
  }

  /// Convert to ProductItem for use with ProductCard widget
  dynamic toProductItem() {
    // Import cycle hack: use external mapper or dynamic
    // but here we just return the object because ProductCard.fromBranchProduct expects dynamic
    return this;
  }
}
