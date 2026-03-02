import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';

class Product {
  final String id;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final double price;
  final double? oldPrice;
  final String? imageUrl;
  final String? categoryId;
  final String? subCategoryId;
  final bool isActive;
  final bool isBestSeller;
  final int stockQuantity;

  const Product({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.price,
    this.oldPrice,
    this.imageUrl,
    this.categoryId,
    this.subCategoryId,
    this.isActive = true,
    this.isBestSeller = false,
    this.stockQuantity = 100,
  });

  /// Product is in stock if active AND has stock quantity > 0
  bool get isInStock => isActive && stockQuantity > 0;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      descriptionAr: json['description_ar'] as String?,
      descriptionEn: json['description_en'] as String?,
      price: (json['price'] as num).toDouble(),
      oldPrice: json['old_price'] != null
          ? (json['old_price'] as num).toDouble()
          : null,
      imageUrl: json['image_url'] as String?,
      categoryId: json['category_id'] as String?,
      subCategoryId: json['sub_category_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isBestSeller: json['is_best_seller'] as bool? ?? false,
      stockQuantity: json['stock_quantity'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_ar': nameAr,
      'name_en': nameEn,
      'description_ar': descriptionAr,
      'description_en': descriptionEn,
      'price': price,
      'old_price': oldPrice,
      'image_url': imageUrl,
      'category_id': categoryId,
      'sub_category_id': subCategoryId,
      'is_active': isActive,
      'is_best_seller': isBestSeller,
      'stock_quantity': stockQuantity,
    };
  }

  String getName(BuildContext? context) {
    if (context == null) return nameAr;
    return context.locale.languageCode == 'ar' ? nameAr : nameEn;
  }

  String? getDescription(BuildContext? context) {
    if (context == null) return descriptionAr;
    return context.locale.languageCode == 'ar' ? descriptionAr : descriptionEn;
  }

  /// Convert to ProductItem for use with ProductCard widget
  ProductItem toProductItem() {
    return ProductItem(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      price: price,
      oldPrice: oldPrice,
      imageUrl: imageUrl ?? '',
      isAvailable: isInStock,
    );
  }
}
