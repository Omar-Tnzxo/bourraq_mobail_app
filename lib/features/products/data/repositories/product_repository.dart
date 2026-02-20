import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/features/products/data/models/product_model.dart';

/// Repository for fetching product data from Supabase
class ProductRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch a single product by ID
  Future<Product?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Fetch related products from the same category
  /// Excludes the current product and limits to 6 items
  Future<List<Product>> getRelatedProducts({
    required String categoryId,
    required String excludeProductId,
    int limit = 6,
  }) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category_id', categoryId)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .neq('id', excludeProductId)
          .limit(limit);

      return (response as List).map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch related products: $e');
    }
  }

  /// Fetch category name by ID
  Future<Map<String, String>?> getCategoryById(String id) async {
    try {
      final response = await _supabase
          .from('categories')
          .select('name_ar, name_en')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return {
        'name_ar': response['name_ar'] as String,
        'name_en': response['name_en'] as String,
      };
    } catch (e) {
      return null;
    }
  }
}
