import 'package:bourraq/features/products/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesRepository {
  final SupabaseClient _supabase;

  FavoritesRepository(this._supabase);

  /// Fetch user favorites with product details
  /// If [areaId] is provided, it attempts to fetch the branch-specific price
  Future<List<Product>> getFavorites({String? areaId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      // Query favorites and join products.
      // We also join partner_products to get the price for the specific area/branch favorited.
      var query = _supabase
          .from('favorites')
          .select('''
            product_id,
            branch_id,
            products!inner(
              *,
              partner_products(
                id,
                customer_price,
                customer_price_before_discount,
                is_available,
                branch_id
              )
            )
          ''')
          .eq('user_id', userId)
          .eq('products.is_active', true)
          .isFilter('products.deleted_at', null);

      final response = await query.order('created_at', ascending: false);

      final List<Product> products = [];

      for (var item in response as List) {
        if (item['products'] != null) {
          final productJson = Map<String, dynamic>.from(item['products']);
          final partnerOfferings = productJson['partner_products'] as List?;

          Map<String, dynamic>? selectedOffering;
          if (partnerOfferings != null && partnerOfferings.isNotEmpty) {
            final favoritedBranchId = item['branch_id'];
            if (favoritedBranchId != null) {
              selectedOffering = partnerOfferings.firstWhere(
                (offer) => offer['branch_id'] == favoritedBranchId,
                orElse: () => partnerOfferings.first,
              );
            } else {
              selectedOffering = partnerOfferings.first;
            }
          }

          if (selectedOffering != null) {
            productJson['price'] = selectedOffering['customer_price'];
            productJson['customer_price_before_discount'] =
                selectedOffering['customer_price_before_discount'];
            productJson['stock_quantity'] =
                selectedOffering['is_available'] == true ? 100 : 0;
            productJson['branch_id'] = selectedOffering['branch_id'];
            productJson['branch_product_id'] = selectedOffering['id'];
          }

          products.add(Product.fromJson(productJson));
        }
      }
      return products;
    } catch (e) {
      print('❌ [FavoritesRepository] Error fetching favorites: $e');
      throw Exception('Failed to load favorites');
    }
  }

  /// Add a product to favorites
  Future<void> addToFavorites(String productId, {String? branchId}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    try {
      // Use upsert to handle race conditions
      await _supabase
          .from('favorites')
          .upsert(
            {'user_id': userId, 'product_id': productId, 'branch_id': branchId},
            onConflict: 'user_id,product_id',
            ignoreDuplicates: true,
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
