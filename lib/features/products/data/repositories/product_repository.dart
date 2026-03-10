import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/features/products/data/models/product_model.dart';

/// Repository for fetching product data from Supabase
class ProductRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetch a single product by ID
  /// Prices are fetched from partner_products to ensure latest customer_price logic
  Future<Product?> getProductById(String id, {String? areaId}) async {
    try {
      // We query partner_products to get the customer_price
      // and join products to get the static details.
      // We also join branches and branch_areas to filter by area if provided.
      var query = _supabase
          .from('partner_products')
          .select('''
            customer_price, 
            customer_price_before_discount,
            branch_id, 
            id,
            products!inner(*), 
            branches!inner(
              branch_areas!inner(area_id)
            )
          ''')
          .eq('product_id', id)
          .eq('is_available', true)
          .eq('approval_status', 'approved')
          .eq('products.is_active', true)
          .isFilter('products.deleted_at', null);

      if (areaId != null && areaId.isNotEmpty) {
        query = query.eq('branches.branch_areas.area_id', areaId);
      }

      // Pick the best available price (lowest) if multiple branches offer it
      final response = await query
          .order('customer_price', ascending: true)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        // Fallback: If no partner offering found for this area, try global if areaId was provided
        if (areaId != null && areaId.isNotEmpty) {
          return getProductById(id, areaId: null);
        }
        return null;
      }

      final productJson = Map<String, dynamic>.from(
        response['products'] as Map,
      );
      // Explicitly inject the calculated customer balance/price
      productJson['price'] = response['customer_price'];
      productJson['customer_price_before_discount'] =
          response['customer_price_before_discount'];
      productJson['branch_id'] = response['branch_id'];
      productJson['branch_product_id'] = response['id'];

      return Product.fromJson(productJson);
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Fetch related products from the same category or sub-category
  /// Excludes the current product
  Future<List<Product>> getRelatedProducts({
    String? categoryId,
    String? subCategoryId,
    required String excludeProductId,
    String? areaId,
    int? limit = 24,
  }) async {
    try {
      // We query partner_products to ensure we only get products that are available and approved.
      // This prevents the "Failed to fetch product" error when clicking a related product.
      var query = _supabase
          .from('partner_products')
          .select('''
            customer_price,
            customer_price_before_discount,
            branch_id,
            id,
            products!inner(*),
            branches!inner(
              branch_areas!inner(area_id)
            )
          ''')
          .eq('is_available', true)
          .eq('approval_status', 'approved')
          .eq('products.is_active', true)
          .isFilter('products.deleted_at', null)
          .neq('product_id', excludeProductId);

      if (areaId != null && areaId.isNotEmpty) {
        query = query.eq('branches.branch_areas.area_id', areaId);
      }

      if (subCategoryId != null) {
        query = query.eq('products.sub_category_id', subCategoryId);
      } else if (categoryId != null) {
        query = query.eq('products.category_id', categoryId);
      } else {
        return [];
      }

      final response = await query
          .order('customer_price', ascending: true)
          .limit(limit ?? 24);

      final results = <Product>[];
      final seenProductIds = <String>{};

      for (final item in response as List) {
        final productId = item['products']['id'] as String;
        if (!seenProductIds.contains(productId)) {
          final productJson = Map<String, dynamic>.from(
            item['products'] as Map,
          );
          productJson['price'] = item['customer_price'];
          productJson['customer_price_before_discount'] =
              item['customer_price_before_discount'];
          productJson['branch_id'] = item['branch_id'];
          productJson['branch_product_id'] = item['id'];
          results.add(Product.fromJson(productJson));
          seenProductIds.add(productId);
        }
      }

      return results;
    } catch (e) {
      // Fallback to basic products query if the complex one fails
      try {
        final response = await _supabase
            .from('products')
            .select()
            .eq('is_active', true)
            .isFilter('deleted_at', null)
            .neq('id', excludeProductId)
            .limit(limit ?? 24);

        return (response as List)
            .map((json) => Product.fromJson(json))
            .toList();
      } catch (_) {
        return [];
      }
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
