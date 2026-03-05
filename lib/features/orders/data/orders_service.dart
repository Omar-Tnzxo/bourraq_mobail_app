import 'package:supabase_flutter/supabase_flutter.dart';
import 'order_model.dart';

/// خدمة إدارة الطلبات - متصلة بـ Supabase
class OrdersService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// كاش للـ public.users.id
  String? _cachedPublicUserId;

  /// جلب public.users.id من auth_user_id
  Future<String?> _getPublicUserId() async {
    if (_cachedPublicUserId != null) return _cachedPublicUserId;

    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();

      if (response != null) {
        _cachedPublicUserId = response['id'] as String;
        return _cachedPublicUserId;
      }
    } catch (e) {
      print('❌ [OrdersService] Error getting public user id: $e');
    }
    return null;
  }

  /// إنشاء طلب جديد
  Future<Order?> createOrder({
    required String addressId,
    required String addressLabel,
    required String addressText,
    required PaymentMethod paymentMethod,
    required double subtotal,
    required double deliveryFee,
    required double serviceFee,
    required double discount,
    required double total,
    required double branchTotal,
    required List<String> branchIds,
    required List<Map<String, dynamic>> cartItems,
    String? couponCode,
    String? notes,
    bool isScheduled = false,
    DateTime? scheduledTime,
  }) async {
    final userId = await _getPublicUserId();
    if (userId == null) {
      print('❌ [OrdersService] User not logged in');
      return null;
    }

    try {
      // إنشاء الطلب
      final orderResponse = await _supabase
          .from('orders')
          .insert({
            'user_id': userId,
            'address_id': addressId,
            'address_label': addressLabel,
            'address_text': addressText,
            'status': OrderStatus.pending.value,
            'payment_method': paymentMethod.value,
            'subtotal': subtotal,
            'delivery_fee': deliveryFee,
            'service_fee': serviceFee,
            'discount': discount,
            'total': total,
            'branch_total': branchTotal,
            'branch_ids': branchIds,
            'coupon_code': couponCode,
            'notes': notes,
            'is_scheduled': isScheduled,
            'scheduled_time': scheduledTime?.toIso8601String(),
          })
          .select()
          .single();

      final orderId = orderResponse['id'] as String;

      // إضافة عناصر الطلب
      final orderItems = cartItems
          .map(
            (item) => {
              'order_id': orderId,
              'product_id': item['id'],
              'product_name': item['name'],
              'product_image': item['image'],
              'price': item['price'],
              'partner_price': item['partner_price'],
              'customer_price': item['customer_price'],
              'branch_id': item['branch_id'],
              'branch_product_id': item['branch_product_id'],
              'quantity': item['quantity'],
              'total_price': (item['price'] as num) * (item['quantity'] as num),
            },
          )
          .toList();

      await _supabase.from('order_items').insert(orderItems);

      print('✅ [OrdersService] Order created: $orderId');
      return Order.fromJson(orderResponse);
    } catch (e) {
      print('❌ [OrdersService] Error creating order: $e');
      return null;
    }
  }

  /// جلب جميع طلبات المستخدم
  Future<List<Order>> getOrders({OrderStatus? filterStatus}) async {
    final userId = await _getPublicUserId();
    if (userId == null) return [];

    try {
      // Query with items count subquery
      var query = _supabase
          .from('orders')
          .select('*, order_items(count)')
          .eq('user_id', userId);

      if (filterStatus != null) {
        query = query.eq('status', filterStatus.value);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List).map((json) {
        // Extract items count from nested count
        final orderItemsData = json['order_items'] as List?;
        int itemsCount = 0;
        if (orderItemsData != null && orderItemsData.isNotEmpty) {
          final countData = orderItemsData.first as Map<String, dynamic>?;
          itemsCount = countData?['count'] as int? ?? 0;
        }

        // Create modified json with items_count
        final modifiedJson = Map<String, dynamic>.from(json);
        modifiedJson['items_count'] = itemsCount;
        modifiedJson.remove('order_items'); // Remove nested data

        return Order.fromJson(modifiedJson);
      }).toList();
    } catch (e) {
      print('❌ [OrdersService] Error fetching orders: $e');
      return [];
    }
  }

  /// جلب تفاصيل طلب معين مع منتجاته
  Future<Order?> getOrderDetails(String orderId) async {
    final userId = await _getPublicUserId();
    if (userId == null) return null;

    try {
      // جلب الطلب
      final orderResponse = await _supabase
          .from('orders')
          .select()
          .eq('id', orderId)
          .eq('user_id', userId)
          .maybeSingle();

      if (orderResponse == null) return null;

      // جلب عناصر الطلب
      final itemsResponse = await _supabase
          .from('order_items')
          .select(
            '*, partner_products(products(weight_value, weight_unit_ar, weight_unit_en))',
          )
          .eq('order_id', orderId);

      final items = (itemsResponse as List)
          .map((json) => OrderItem.fromJson(json))
          .toList();

      return Order.fromJson(orderResponse, items: items);
    } catch (e) {
      print('❌ [OrdersService] Error fetching order details: $e');
      return null;
    }
  }

  /// إلغاء الطلب
  Future<bool> cancelOrder(String orderId, {String? reasonId}) async {
    final userId = await _getPublicUserId();
    if (userId == null) return false;

    try {
      // تحقق من أن الطلب يمكن إلغاؤه
      final orderResponse = await _supabase
          .from('orders')
          .select('status')
          .eq('id', orderId)
          .eq('user_id', userId)
          .maybeSingle();

      if (orderResponse == null) return false;

      final currentStatus = OrderStatusExtension.fromString(
        orderResponse['status'] as String,
      );

      if (!currentStatus.canCancel) {
        print(
          '❌ [OrdersService] Order cannot be cancelled: ${currentStatus.value}',
        );
        return false;
      }

      // تحديث الحالة مع سبب الإلغاء
      final updateData = <String, dynamic>{
        'status': OrderStatus.cancelled.value,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (reasonId != null) {
        updateData['cancel_reason_id'] = reasonId;
      }

      await _supabase
          .from('orders')
          .update(updateData)
          .eq('id', orderId)
          .eq('user_id', userId);

      print('✅ [OrdersService] Order cancelled: $orderId');
      return true;
    } catch (e) {
      print('❌ [OrdersService] Error cancelling order: $e');
      return false;
    }
  }

  /// جلب الطلب النشط (إن وجد)
  Future<Order?> getActiveOrder() async {
    final userId = await _getPublicUserId();
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('orders')
          .select()
          .eq('user_id', userId)
          .inFilter('status', [
            OrderStatus.pending.value,
            OrderStatus.confirmed.value,
            OrderStatus.preparing.value,
            OrderStatus.onTheWay.value,
          ])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response != null ? Order.fromJson(response) : null;
    } catch (e) {
      print('❌ [OrdersService] Error fetching active order: $e');
      return null;
    }
  }

  /// تقييم الطلب
  Future<bool> rateOrder(String orderId, int rating, String? comment) async {
    final userId = await _getPublicUserId();
    if (userId == null) return false;

    try {
      await _supabase.from('order_ratings').insert({
        'order_id': orderId,
        'user_id': userId,
        'rating': rating,
        'comment': comment,
      });

      print('✅ [OrdersService] Order rated: $orderId');
      return true;
    } catch (e) {
      print('❌ [OrdersService] Error rating order: $e');
      return false;
    }
  }
}
