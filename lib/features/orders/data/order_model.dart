/// نموذج عنصر الطلب (المنتج في الطلب)
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String productName;
  final String? productImage;
  final double price;
  final int quantity;
  final double totalPrice;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    required this.quantity,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productImage: json['product_image'] as String?,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      totalPrice: (json['total_price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'order_id': orderId,
    'product_id': productId,
    'product_name': productName,
    'product_image': productImage,
    'price': price,
    'quantity': quantity,
    'total_price': totalPrice,
  };
}

/// حالات الطلب
enum OrderStatus {
  pending, // قيد المراجعة
  confirmed, // تم التأكيد
  preparing, // جاري التحضير
  onTheWay, // في الطريق
  delivered, // تم التوصيل
  cancelled, // ملغي
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
      case OrderStatus.onTheWay:
        return 'On The Way';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Translation key for easy_localization
  String get translationKey {
    switch (this) {
      case OrderStatus.pending:
        return 'orders.status.pending';
      case OrderStatus.confirmed:
        return 'orders.status.confirmed';
      case OrderStatus.preparing:
        return 'orders.status.preparing';
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
        return 2;
      case OrderStatus.onTheWay:
        return 3;
      case OrderStatus.delivered:
        return 4;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  bool get canCancel {
    return this == OrderStatus.pending ||
        this == OrderStatus.confirmed ||
        this == OrderStatus.preparing;
  }

  /// Returns true if the order is still active (not delivered or cancelled)
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
}

extension PaymentMethodExtension on PaymentMethod {
  String get value {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
    }
  }

  String get labelAr {
    switch (this) {
      case PaymentMethod.cash:
        return 'الدفع عند الاستلام';
      case PaymentMethod.card:
        return 'بطاقة ائتمان';
    }
  }

  String get labelEn {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash on Delivery';
      case PaymentMethod.card:
        return 'Credit Card';
    }
  }

  static PaymentMethod fromString(String value) {
    switch (value) {
      case 'card':
        return PaymentMethod.card;
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
  final double discount;
  final double total;
  final String? couponCode;
  final String? notes;
  final bool isScheduled;
  final DateTime? scheduledTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;
  final int? _itemsCount; // For list view when items aren't loaded

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
    required this.discount,
    required this.total,
    this.couponCode,
    this.notes,
    this.isScheduled = false,
    this.scheduledTime,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
    int? itemsCount,
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
      itemsCount: json['items_count'] as int?,
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
    'discount': discount,
    'total': total,
    'coupon_code': couponCode,
    'notes': notes,
    'is_scheduled': isScheduled,
    'scheduled_time': scheduledTime?.toIso8601String(),
  };

  /// عدد المنتجات في الطلب
  int get itemCount =>
      _itemsCount ?? items.fold(0, (sum, item) => sum + item.quantity);

  /// هل الطلب نشط (غير مكتمل وغير ملغي)
  bool get isActive =>
      status != OrderStatus.delivered && status != OrderStatus.cancelled;

  @override
  String toString() => 'Order(id: $id, status: ${status.value}, total: $total)';
}
