import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/cart_item.dart';
import 'delivery_settings.dart';

/// Cart repository for Supabase operations
class CartRepository {
  final SupabaseClient _supabase;

  CartRepository([SupabaseClient? client])
    : _supabase = client ?? Supabase.instance.client;

  String? get _userId => _supabase.auth.currentUser?.id;

  /// Get all cart items with product details
  Future<List<CartItem>> getCartItems() async {
    if (_userId == null) return [];

    try {
      final response = await _supabase
          .from('cart_items')
          .select('''
            id,
            product_id,
            quantity,
            products (
              name_ar,
              name_en,
              price,
              old_price,
              image_url,
              weight_value,
              weight_unit,
              stock_quantity,
              is_active
            )
          ''')
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      final items = (response as List)
          .map((json) => CartItem.fromJson(json))
          .toList();

      return items;
    } catch (e) {
      return [];
    }
  }

  /// Add item to cart (upsert - increases quantity if exists)
  Future<void> addToCart(String productId, {int quantity = 1}) async {
    if (_userId == null) return;

    try {
      // Check if item already exists
      final existing = await _supabase
          .from('cart_items')
          .select('id, quantity')
          .eq('user_id', _userId!)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        // Update quantity - use RPC or direct update
        final newQty = (existing['quantity'] as int) + quantity;
        await _supabase
            .from('cart_items')
            .update({
              'quantity': newQty,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        // Insert new item using upsert to handle race conditions
        await _supabase
            .from('cart_items')
            .upsert(
              {
                'user_id': _userId,
                'product_id': productId,
                'quantity': quantity,
              },
              onConflict: 'user_id,product_id',
              ignoreDuplicates: false,
            );
      }
    } on PostgrestException catch (e) {
      // Handle duplicate key error gracefully - item was added by concurrent request
      if (e.code == '23505') {
        // Duplicate key - fetch and update instead
        final existing = await _supabase
            .from('cart_items')
            .select('id, quantity')
            .eq('user_id', _userId!)
            .eq('product_id', productId)
            .maybeSingle();

        if (existing != null) {
          final newQty = (existing['quantity'] as int) + quantity;
          await _supabase
              .from('cart_items')
              .update({
                'quantity': newQty,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', existing['id']);
        }
      } else {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    if (_userId == null) return;

    try {
      if (quantity <= 0) {
        await removeFromCart(productId);
      } else {
        await _supabase
            .from('cart_items')
            .update({
              'quantity': quantity,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', _userId!)
            .eq('product_id', productId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Remove item from cart
  Future<void> removeFromCart(String productId) async {
    if (_userId == null) return;

    try {
      await _supabase
          .from('cart_items')
          .delete()
          .eq('user_id', _userId!)
          .eq('product_id', productId);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all cart items
  Future<void> clearCart() async {
    if (_userId == null) return;

    try {
      await _supabase.from('cart_items').delete().eq('user_id', _userId!);
    } catch (e) {
      rethrow;
    }
  }

  /// Get delivery settings for an area (or default)
  Future<DeliverySettings> getDeliverySettings(String? areaId) async {
    try {
      // First try to get area-specific settings
      if (areaId != null) {
        final areaSettings = await _supabase
            .from('delivery_settings')
            .select()
            .eq('area_id', areaId)
            .eq('is_active', true)
            .maybeSingle();

        if (areaSettings != null) {
          return DeliverySettings.fromJson(areaSettings);
        }
      }

      // Fall back to default settings (area_id is null)
      final defaultSettings = await _supabase
          .from('delivery_settings')
          .select()
          .isFilter('area_id', null)
          .eq('is_active', true)
          .maybeSingle();

      if (defaultSettings != null) {
        return DeliverySettings.fromJson(defaultSettings);
      }

      // Return hard-coded defaults if nothing in DB
      return const DeliverySettings();
    } catch (e) {
      return const DeliverySettings();
    }
  }

  /// Remove out of stock items from cart
  Future<List<String>> removeOutOfStockItems() async {
    if (_userId == null) return [];

    try {
      // Get cart items with product stock info
      final response = await _supabase
          .from('cart_items')
          .select('product_id, products(stock_quantity)')
          .eq('user_id', _userId!);

      final outOfStock = <String>[];

      for (final item in response as List) {
        final stock = item['products']?['stock_quantity'] as int? ?? 0;
        if (stock <= 0) {
          outOfStock.add(item['product_id'] as String);
        }
      }

      // Remove out of stock items
      for (final productId in outOfStock) {
        await removeFromCart(productId);
      }

      return outOfStock;
    } catch (e) {
      return [];
    }
  }

  /// Sync local cart to Supabase (for after login)
  Future<void> syncLocalCart(List<CartItem> localItems) async {
    if (_userId == null || localItems.isEmpty) return;

    try {
      for (final item in localItems) {
        await addToCart(item.productId, quantity: item.quantity);
      }
    } catch (e) {
      // Silently fail sync
    }
  }

  /// Get delivery fee for a specific area directly from areas table
  Future<double?> getAreaDeliveryFee(String areaId) async {
    try {
      final response = await _supabase
          .from('areas')
          .select('delivery_fee')
          .eq('id', areaId)
          .maybeSingle();

      if (response != null && response['delivery_fee'] != null) {
        return (response['delivery_fee'] as num).toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
