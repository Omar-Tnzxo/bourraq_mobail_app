import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling order ratings
class OrderRatingService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Check if an order has already been rated
  Future<bool> hasOrderBeenRated(String orderId) async {
    try {
      final response = await _client
          .from('order_ratings')
          .select('id')
          .eq('order_id', orderId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Submit a rating for an order
  Future<bool> submitRating({
    required String orderId,
    required String userId,
    required int rating,
    String? comment,
  }) async {
    try {
      await _client.from('order_ratings').insert({
        'order_id': orderId,
        'user_id': userId,
        'rating': rating,
        'comment': comment?.trim().isEmpty == true ? null : comment?.trim(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the rating for an order (if exists)
  Future<Map<String, dynamic>?> getOrderRating(String orderId) async {
    try {
      final response = await _client
          .from('order_ratings')
          .select()
          .eq('order_id', orderId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}
