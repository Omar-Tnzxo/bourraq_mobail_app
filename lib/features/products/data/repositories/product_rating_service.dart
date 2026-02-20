import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for rating store products after purchase
class ProductRatingService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Submit a rating for a specific store product
  Future<bool> submitProductRating({
    required String storeProductId,
    required String orderId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _client.from('store_product_ratings').insert({
        'store_product_id': storeProductId,
        'order_id': orderId,
        'user_id': userId,
        'rating': rating,
        'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
      });

      // Update avg_rating and rating_count on store_products
      await _recalculateAvgRating(storeProductId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has already rated a store product for a specific order
  Future<bool> hasRatedProduct({
    required String storeProductId,
    required String orderId,
  }) async {
    try {
      final response = await _client
          .from('store_product_ratings')
          .select('id')
          .eq('store_product_id', storeProductId)
          .eq('order_id', orderId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Get all unrated store products for a delivered order
  Future<List<Map<String, dynamic>>> getUnratedProductsForOrder({
    required String orderId,
    required String userId,
  }) async {
    try {
      // Get order items with store_product info
      final orderItems = await _client
          .from('order_items')
          .select('''
            id, product_name, store_product_id, store_id,
            store_products (
              id, avg_rating
            )
          ''')
          .eq('order_id', orderId)
          .not('store_product_id', 'is', null);

      // Filter out already-rated items
      final unrated = <Map<String, dynamic>>[];
      for (final item in (orderItems as List)) {
        final spId = item['store_product_id'] as String?;
        if (spId == null) continue;

        final alreadyRated = await hasRatedProduct(
          storeProductId: spId,
          orderId: orderId,
        );

        if (!alreadyRated) {
          unrated.add(item);
        }
      }

      return unrated;
    } catch (e) {
      return [];
    }
  }

  /// Get average rating for a specific store product
  Future<Map<String, dynamic>?> getProductRatingSummary(
    String storeProductId,
  ) async {
    try {
      final response = await _client
          .from('store_products')
          .select('avg_rating, rating_count')
          .eq('id', storeProductId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Recalculate average rating after a new review
  Future<void> _recalculateAvgRating(String storeProductId) async {
    try {
      final ratings = await _client
          .from('store_product_ratings')
          .select('rating')
          .eq('store_product_id', storeProductId);

      if ((ratings as List).isEmpty) return;

      final count = ratings.length;
      final sum = ratings.fold<int>(0, (s, r) => s + (r['rating'] as int));
      final avg = (sum / count * 10).round() / 10; // 1 decimal

      await _client
          .from('store_products')
          .update({'avg_rating': avg, 'rating_count': count})
          .eq('id', storeProductId);
    } catch (e) {
      // Non-critical — next rating will fix it
    }
  }
}
