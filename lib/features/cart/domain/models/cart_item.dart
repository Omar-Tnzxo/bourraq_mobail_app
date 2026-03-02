import 'package:equatable/equatable.dart';

/// Cart item model with full product details, weight, and store product support
class CartItem extends Equatable {
  final String id;
  final String productId;
  final String nameAr;
  final String nameEn;
  final double price;
  final double? oldPrice;
  final int quantity;
  final String? imageUrl;
  final double? weightValue;
  final String? weightUnit;
  final int stockQuantity;
  final bool isInStock;

  // Branch product fields (partner system)
  final String? branchProductId;
  final String? branchId;
  final double? partnerPrice;
  final double? customerPrice;
  final double? avgRating;
  final int? ratingCount;

  const CartItem({
    required this.id,
    required this.productId,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    this.oldPrice,
    required this.quantity,
    this.imageUrl,
    this.weightValue,
    this.weightUnit,
    this.stockQuantity = 100,
    this.isInStock = true,
    this.branchProductId,
    this.branchId,
    this.partnerPrice,
    this.customerPrice,
    this.avgRating,
    this.ratingCount,
  });

  /// Get localized name
  String getName(String locale) => locale == 'ar' ? nameAr : nameEn;

  /// Get formatted weight display (e.g., "500 g" or "1.5 kg")
  String? getWeightDisplay(String locale) {
    if (weightValue == null || weightUnit == null) return null;

    final unitLabels = {
      'kg': locale == 'ar' ? 'كجم' : 'kg',
      'g': locale == 'ar' ? 'جم' : 'g',
      'mg': locale == 'ar' ? 'ملجم' : 'mg',
      'l': locale == 'ar' ? 'لتر' : 'L',
      'ml': locale == 'ar' ? 'مل' : 'ml',
      'piece': locale == 'ar' ? 'حبة' : 'pc',
      'pack': locale == 'ar' ? 'عبوة' : 'pack',
      'box': locale == 'ar' ? 'علبة' : 'box',
      'dozen': locale == 'ar' ? 'درزن' : 'dz',
      'bundle': locale == 'ar' ? 'ربطة' : 'bundle',
      'bottle': locale == 'ar' ? 'زجاجة' : 'bottle',
      'can': locale == 'ar' ? 'علبة' : 'can',
      'bag': locale == 'ar' ? 'كيس' : 'bag',
      'carton': locale == 'ar' ? 'كرتونة' : 'carton',
    };

    final label = unitLabels[weightUnit] ?? weightUnit;

    // Format weight value (remove .0 for whole numbers)
    final valueStr = weightValue! % 1 == 0
        ? weightValue!.toInt().toString()
        : weightValue!.toStringAsFixed(1);

    return '$valueStr $label';
  }

  /// Effective price: uses customerPrice if available, otherwise price
  double get effectivePrice => customerPrice ?? price;

  double get totalPrice => effectivePrice * quantity;

  CartItem copyWith({
    String? id,
    String? productId,
    String? nameAr,
    String? nameEn,
    double? price,
    double? oldPrice,
    int? quantity,
    String? imageUrl,
    double? weightValue,
    String? weightUnit,
    int? stockQuantity,
    bool? isInStock,
    String? branchProductId,
    String? branchId,
    double? partnerPrice,
    double? customerPrice,
    double? avgRating,
    int? ratingCount,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      weightValue: weightValue ?? this.weightValue,
      weightUnit: weightUnit ?? this.weightUnit,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isInStock: isInStock ?? this.isInStock,
      branchProductId: branchProductId ?? this.branchProductId,
      branchId: branchId ?? this.branchId,
      partnerPrice: partnerPrice ?? this.partnerPrice,
      customerPrice: customerPrice ?? this.customerPrice,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
    );
  }

  /// Create from JSON (Supabase response with joined product)
  factory CartItem.fromJson(Map<String, dynamic> json) {
    final product = json['products'] as Map<String, dynamic>?;

    return CartItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      nameAr: product?['name_ar'] as String? ?? '',
      nameEn: product?['name_en'] as String? ?? '',
      price: (product?['price'] as num?)?.toDouble() ?? 0,
      oldPrice: (product?['old_price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: product?['image_url'] as String?,
      weightValue: (product?['weight_value'] as num?)?.toDouble(),
      weightUnit: product?['weight_unit'] as String?,
      stockQuantity: product?['stock_quantity'] as int? ?? 100,
      isInStock:
          (product?['stock_quantity'] as int?) == null ||
          (product?['stock_quantity'] as int?)! > 0,
      branchProductId: json['branch_product_id'] as String?,
      branchId: json['branch_id'] as String?,
      partnerPrice: (json['partner_price'] as num?)?.toDouble(),
      customerPrice: (json['customer_price'] as num?)?.toDouble(),
    );
  }

  /// Create from local storage JSON (with backwards compatibility)
  factory CartItem.fromLocalJson(Map<String, dynamic> json) {
    final legacyName = json['productName'] as String? ?? '';

    return CartItem(
      id: json['id'] as String,
      productId: json['product_id'] ?? json['productId'] as String,
      nameAr: json['name_ar'] as String? ?? legacyName,
      nameEn: json['name_en'] as String? ?? legacyName,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      oldPrice: (json['old_price'] as num?)?.toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: json['image_url'] ?? json['imageUrl'] as String?,
      weightValue: (json['weight_value'] as num?)?.toDouble(),
      weightUnit: json['weight_unit'] as String?,
      stockQuantity: json['stock_quantity'] as int? ?? 100,
      isInStock: json['is_in_stock'] as bool? ?? true,
      branchProductId: json['branch_product_id'] as String?,
      branchId: json['branch_id'] as String?,
      partnerPrice: (json['partner_price'] as num?)?.toDouble(),
      customerPrice: (json['customer_price'] as num?)?.toDouble(),
      avgRating: (json['avg_rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'] as int?,
    );
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'id': id,
      'product_id': productId,
      'name_ar': nameAr,
      'name_en': nameEn,
      'price': price,
      'old_price': oldPrice,
      'quantity': quantity,
      'image_url': imageUrl,
      'weight_value': weightValue,
      'weight_unit': weightUnit,
      'stock_quantity': stockQuantity,
      'is_in_stock': isInStock,
      'branch_product_id': branchProductId,
      'branch_id': branchId,
      'partner_price': partnerPrice,
      'customer_price': customerPrice,
      'avg_rating': avgRating,
      'rating_count': ratingCount,
    };
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    nameAr,
    nameEn,
    price,
    oldPrice,
    quantity,
    imageUrl,
    weightValue,
    weightUnit,
    stockQuantity,
    isInStock,
    branchProductId,
    branchId,
    partnerPrice,
    customerPrice,
    avgRating,
    ratingCount,
  ];
}
