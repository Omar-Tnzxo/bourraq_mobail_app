import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نموذج عنصر الطلب (المنتج في الطلب)
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String? branchProductId;
  final String? branchId;
  final String productName;
  final String? productNameAr;
  final String? productNameEn;
  final String? productImage;
  final double price;
  final double? partnerPrice;
  final double? customerPrice;
  final double quantity;
  final double totalPrice;
  final String? redirectedBranchId;
  final double? weightValue;
  final String? weightUnitAr;
  final String? weightUnitEn;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.branchProductId,
    this.branchId,
    required this.productName,
    this.productNameAr,
    this.productNameEn,
    this.productImage,
    required this.price,
    this.partnerPrice,
    this.customerPrice,
    required this.quantity,
    required this.totalPrice,
    this.redirectedBranchId,
    this.weightValue,
    this.weightUnitAr,
    this.weightUnitEn,
  });

  /// Get localized name
  String getName(String locale) {
    if (locale == 'ar') return productNameAr ?? productName;
    return productNameEn ?? productName;
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      branchProductId: json['branch_product_id'] as String?,
      branchId: json['branch_id'] as String?,
      productName: json['product_name'] as String,
      productNameAr:
          json['partner_products']?['products']?['name_ar'] as String? ??
          json['products']?['name_ar'] as String? ??
          json['name_ar'] as String?,
      productNameEn:
          json['partner_products']?['products']?['name_en'] as String? ??
          json['products']?['name_en'] as String? ??
          json['name_en'] as String?,
      productImage: json['product_image'] as String?,
      price: (json['price'] as num).toDouble(),
      partnerPrice: (json['partner_price'] as num?)?.toDouble(),
      customerPrice: (json['customer_price'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      redirectedBranchId: json['redirected_branch_id'] as String?,
      weightValue:
          (json['partner_products']?['products']?['weight_value'] as num?)
              ?.toDouble() ??
          (json['partner_products']?['weight_value'] as num?)?.toDouble() ??
          (json['weight_value'] as num?)?.toDouble() ??
          (json['partner_products']?['products']?['weight'] as num?)
              ?.toDouble() ??
          (json['partner_products']?['products']?['size'] as num?)?.toDouble(),
      weightUnitAr:
          json['partner_products']?['products']?['weight_unit_ar'] as String? ??
          json['partner_products']?['weight_unit_ar'] as String? ??
          json['weight_unit_ar'] as String? ??
          json['partner_products']?['products']?['weight_unit'] as String? ??
          json['partner_products']?['products']?['unit_ar'] as String? ??
          json['partner_products']?['products']?['unit'] as String? ??
          json['weight_unit'] as String?,
      weightUnitEn:
          json['partner_products']?['products']?['weight_unit_en'] as String? ??
          json['partner_products']?['weight_unit_en'] as String? ??
          json['weight_unit_en'] as String? ??
          json['partner_products']?['products']?['weight_unit'] as String? ??
          json['partner_products']?['products']?['unit_en'] as String? ??
          json['partner_products']?['products']?['unit'] as String? ??
          json['weight_unit'] as String?,
    );
  }

  String getWeightDisplay(String langCode) {
    if (weightValue == null) return '';
    final String valueStr = weightValue! == weightValue!.toInt()
        ? weightValue!.toInt().toString()
        : weightValue!.toString();
    final unit = (langCode == 'ar' ? weightUnitAr : weightUnitEn) ?? '';
    return '$valueStr $unit';
  }

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'product_id': productId,
    'branch_product_id': branchProductId,
    'branch_id': branchId,
    'product_name': productName,
    'product_name_ar': productNameAr,
    'product_name_en': productNameEn,
    'product_image': productImage,
    'price': price,
    'partner_price': partnerPrice,
    'customer_price': customerPrice,
    'quantity': quantity,
    'total_price': totalPrice,
    'redirected_branch_id': redirectedBranchId,
    'weight_value': weightValue,
    'weight_unit_ar': weightUnitAr,
    'weight_unit_en': weightUnitEn,
  };
}

/// حالات الطلب
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  assigned,
  accepted,
  pickedUp,
  onTheWay,
  delivered,
  cancelled,
}

extension OrderStatusExtension on OrderStatus {
  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.confirmed:
        return 'confirmed';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.assigned:
        return 'assigned';
      case OrderStatus.accepted:
        return 'accepted';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get labelAr {
    switch (this) {
      case OrderStatus.pending:
        return 'قيد المراجعة';
      case OrderStatus.confirmed:
        return 'تم التأكيد';
      case OrderStatus.preparing:
        return 'جاري التحضير';
      case OrderStatus.ready:
        return 'جاهز للاستلام';
      case OrderStatus.assigned:
        return 'تم إسناد طيار';
      case OrderStatus.accepted:
        return 'جاري التنفيذ';
      case OrderStatus.pickedUp:
        return 'تم الاستلام';
      case OrderStatus.onTheWay:
        return 'في الطريق';
      case OrderStatus.delivered:
        return 'تم التوصيل';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }

  String get labelEn {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for Pickup';
      case OrderStatus.assigned:
        return 'Pilot Assigned';
      case OrderStatus.accepted:
        return 'In Progress';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.onTheWay:
        return 'On The Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get translationKey {
    switch (this) {
      case OrderStatus.pending:
        return 'orders.status.pending';
      case OrderStatus.confirmed:
        return 'orders.status.confirmed';
      case OrderStatus.preparing:
        return 'orders.status.preparing';
      case OrderStatus.ready:
        return 'orders.status.ready';
      case OrderStatus.assigned:
        return 'orders.status.assigned';
      case OrderStatus.accepted:
        return 'orders.status.accepted';
      case OrderStatus.pickedUp:
        return 'orders.status.picked_up';
      case OrderStatus.onTheWay:
        return 'orders.status.on_the_way';
      case OrderStatus.delivered:
        return 'orders.status.delivered';
      case OrderStatus.cancelled:
        return 'orders.status.cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
      case OrderStatus.ready:
        return 2;
      case OrderStatus.assigned:
      case OrderStatus.accepted:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  int get granularIndex {
    switch (this) {
      case OrderStatus.pending:
        return 0;
      case OrderStatus.confirmed:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.ready:
        return 3;
      case OrderStatus.assigned:
        return 4;
      case OrderStatus.accepted:
        return 5;
      case OrderStatus.pickedUp:
        return 6;
      case OrderStatus.onTheWay:
        return 7;
      case OrderStatus.delivered:
        return 8;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  bool get canCancel {
    return this == OrderStatus.pending ||
        this == OrderStatus.confirmed ||
        this == OrderStatus.preparing ||
        this == OrderStatus.ready;
  }

  bool get isActive {
    return this != OrderStatus.delivered && this != OrderStatus.cancelled;
  }

  static OrderStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'assigned':
        return OrderStatus.assigned;
      case 'accepted':
        return OrderStatus.accepted;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

/// طرق الدفع
enum PaymentMethod {
  cash, // الدفع عند الاستلام
  card, // بطاقة ائتمان
  wallet, // الدفع بالمحفظة
}

extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.wallet:
        return 'wallet';
    }
  }

  String get translationKey {
    switch (this) {
      case PaymentMethod.cash:
        return 'checkout.cash_on_delivery';
      case PaymentMethod.card:
        return 'checkout.credit_card';
      case PaymentMethod.wallet:
        return 'payment.wallet';
    }
  }

  String get labelAr {
    switch (this) {
      case PaymentMethod.cash:
        return 'الدفع عند الاستلام';
      case PaymentMethod.card:
        return 'بطاقة ائتمان';
      case PaymentMethod.wallet:
        return 'المحفظة';
    }
  }

  String get labelEn {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash on Delivery';
      case PaymentMethod.card:
        return 'Credit Card';
      case PaymentMethod.wallet:
        return 'Wallet';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.cash:
        return LucideIcons.banknote;
      case PaymentMethod.card:
        return LucideIcons.creditCard;
      case PaymentMethod.wallet:
        return LucideIcons.wallet;
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'card':
        return PaymentMethod.card;
      case 'wallet':
        return PaymentMethod.wallet;
      default:
        return PaymentMethod.cash;
    }
  }
}

/// نموذج الطلب الرئيسي
class Order {
  final String id;
  final String userId;
  final String addressId;
  final String? addressLabel;
  final String? addressText;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double serviceFee;
  final double discount;
  final double total;
  final String? couponCode;
  final String? notes;
  final bool isScheduled;
  final DateTime? scheduledTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final List<String> branchIds;
  final double branchTotal;
  final num? _itemsCount; // For list view when items aren't loaded

  const Order({
    required this.id,
    required this.userId,
    required this.addressId,
    this.addressLabel,
    this.addressText,
    required this.status,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    this.serviceFee = 0.0,
    required this.discount,
    required this.total,
    this.couponCode,
    this.notes,
    this.isScheduled = false,
    this.scheduledTime,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    this.branchIds = const [],
    this.branchTotal = 0.0,
    num? itemsCount,
  }) : _itemsCount = itemsCount;

  factory Order.fromJson(Map<String, dynamic> json, {List<OrderItem>? items}) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      addressId: json['address_id'] as String,
      addressLabel: json['address_label'] as String?,
      addressText: json['address_text'] as String?,
      status: OrderStatusExtension.fromString(
        json['status'] as String? ?? 'pending',
      ),
      paymentMethod: PaymentMethodExtension.fromString(
        json['payment_method'] as String? ?? 'cash',
      ),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      couponCode: json['coupon_code'] as String?,
      notes: json['notes'] as String?,
      isScheduled: json['is_scheduled'] as bool? ?? false,
      scheduledTime: json['scheduled_time'] != null
          ? DateTime.parse(json['scheduled_time'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      items: items ?? [],
      branchIds: json['branch_ids'] != null
          ? List<String>.from(json['branch_ids'] as List)
          : [],
      branchTotal: (json['branch_total'] as num?)?.toDouble() ?? 0.0,
      itemsCount: json['items_count'] as num?,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'address_id': addressId,
    'address_label': addressLabel,
    'address_text': addressText,
    'status': status.value,
    'payment_method': paymentMethod.value,
    'subtotal': subtotal,
    'delivery_fee': deliveryFee,
    'service_fee': serviceFee,
    'discount': discount,
    'total': total,
    'coupon_code': couponCode,
    'notes': notes,
    'is_scheduled': isScheduled,
    'scheduled_time': scheduledTime?.toIso8601String(),
    'branch_ids': branchIds,
    'branch_total': branchTotal,
  };

  /// عدد المنتجات في الطلب
  num get itemCount =>
      _itemsCount ?? items.fold(0.0, (sum, item) => sum + item.quantity);

  /// هل الطلب نشط (غير مكتمل وغير ملغي)
  bool get isActive =>
      status != OrderStatus.delivered && status != OrderStatus.cancelled;

  @override
  String toString() => 'Order(id: $id, status: ${status.value}, total: $total)';
}
