import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service for managing stock alerts - "Notify me when available"
class StockAlertService {
  static final StockAlertService _instance = StockAlertService._internal();
  factory StockAlertService() => _instance;
  StockAlertService._internal();

  final _client = Supabase.instance.client;

  /// Subscribe to stock alert for a product
  Future<bool> subscribeToAlert(String productId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      // Check if already subscribed
      final existing = await _client
          .from('stock_alerts')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      if (existing != null) {
        debugPrint('📦 [StockAlert] Already subscribed to $productId');
        return true;
      }

      // Create new alert
      await _client.from('stock_alerts').insert({
        'user_id': userId,
        'product_id': productId,
        'is_notified': false,
      });

      debugPrint('📦 [StockAlert] Subscribed to $productId');
      return true;
    } catch (e) {
      debugPrint('📦 [StockAlert] Error subscribing: $e');
      return false;
    }
  }

  /// Unsubscribe from stock alert
  Future<bool> unsubscribeFromAlert(String productId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      await _client
          .from('stock_alerts')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);

      debugPrint('📦 [StockAlert] Unsubscribed from $productId');
      return true;
    } catch (e) {
      debugPrint('📦 [StockAlert] Error unsubscribing: $e');
      return false;
    }
  }

  /// Check if user is subscribed to product alert
  Future<bool> isSubscribed(String productId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _client
          .from('stock_alerts')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      debugPrint('📦 [StockAlert] Error checking subscription: $e');
      return false;
    }
  }

  /// Get all active stock alerts for current user
  Future<List<Map<String, dynamic>>> getUserAlerts() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final result = await _client
          .from('stock_alerts')
          .select('*, products(id, name_ar, name_en, image_url, price)')
          .eq('user_id', userId)
          .eq('is_notified', false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('📦 [StockAlert] Error getting alerts: $e');
      return [];
    }
  }
}
