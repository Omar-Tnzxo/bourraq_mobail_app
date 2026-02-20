import 'package:bourraq/features/products/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesRepository {
  final SupabaseClient _supabase;

  FavoritesRepository(this._supabase);

  /// Fetch user favorites with product details
  Future<List<Product>> getFavorites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Supabase join: select products derived from favorites table
      // Assuming foreign key `product_id` references `products.id`
      // We select the linked product data using standard Supabase join syntax
      final response = await _supabase
          .from('favorites')
          .select('product_id, products(*)')
          .eq('user_id', userId)
          .eq('products.is_active', true)
          .isFilter('products.deleted_at', null)
          .order('created_at', ascending: false);

      final List<Product> products = [];

      for (var item in response as List) {
        if (item['products'] != null) {
          products.add(Product.fromJson(item['products']));
        }
      }
      return products;
    } catch (e) {
      print('❌ [FavoritesRepository] Error fetching favorites: $e');
      throw Exception('Failed to load favorites');
    }
  }

  /// Add a product to favorites
  Future<void> addToFavorites(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      // Use upsert to handle race conditions
      await _supabase
          .from('favorites')
          .upsert(
            {'user_id': userId, 'product_id': productId},
            onConflict: 'user_id,product_id',
            ignoreDuplicates: true, // Ignore if already exists
          );
    } on PostgrestException catch (e) {
      // Handle duplicate key error gracefully
      if (e.code == '23505') {
        return; // Already favorite, treat as success
      }
      throw Exception('Failed to add favorite');
    } catch (e) {
      throw Exception('Failed to add favorite');
    }
  }

  /// Remove a product from favorites
  Future<void> removeFromFavorites(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      await _supabase
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      throw Exception('Failed to remove favorite');
    }
  }

  /// Check if a product is favorited
  Future<bool> isFavorite(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final response = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('product_id', productId)
        .maybeSingle();

    return response != null;
  }
}
