import 'package:equatable/equatable.dart';

/// Delivery settings model for an area
class DeliverySettings extends Equatable {
  final String? id;
  final String? areaId;
  final double freeDeliveryThreshold;
  final bool freeDeliveryEnabled;
  final double deliveryFee;
  final double minOrderAmount;
  final bool isActive;

  const DeliverySettings({
    this.id,
    this.areaId,
    this.freeDeliveryThreshold = 300.0,
    this.freeDeliveryEnabled = false,
    this.deliveryFee = 15.0,
    this.minOrderAmount = 50.0,
    this.isActive = true,
  });

  factory DeliverySettings.fromJson(Map<String, dynamic> json) {
    return DeliverySettings(
      id: json['id'] as String?,
      areaId: json['area_id'] as String?,
      freeDeliveryThreshold:
          (json['free_delivery_threshold'] as num?)?.toDouble() ?? 300.0,
      freeDeliveryEnabled: json['free_delivery_enabled'] as bool? ?? false,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 15.0,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ?? 50.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Check if order qualifies for free delivery
  bool isFreeDelivery(double orderTotal) {
    if (!freeDeliveryEnabled) return false;
    return orderTotal >= freeDeliveryThreshold;
  }

  /// Get remaining amount for free delivery
  double getRemainingForFreeDelivery(double orderTotal) {
    if (!freeDeliveryEnabled) return 0;
    final remaining = freeDeliveryThreshold - orderTotal;
    return remaining > 0 ? remaining : 0;
  }

  /// Get actual delivery fee based on order total
  double getDeliveryFee(double orderTotal) {
    if (isFreeDelivery(orderTotal)) return 0;
    return deliveryFee;
  }

  @override
  List<Object?> get props => [
    id,
    areaId,
    freeDeliveryThreshold,
    freeDeliveryEnabled,
    deliveryFee,
    minOrderAmount,
    isActive,
  ];
}
