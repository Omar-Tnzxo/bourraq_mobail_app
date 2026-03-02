import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/features/products/data/models/branch_product_model.dart';

/// Repository for fetching branch products — area-filtered, sorted by price/rating/distance
class BranchProductRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Common select query for partner_products with joins
  static const String _selectQuery = '''
    id, branch_id, product_id, partner_price, customer_price,
    avg_rating, rating_count, is_available, approval_status, badge_id,
    products (
      id, name_ar, name_en, description_ar, description_en,
      image_url, category_id, sub_category_id, is_active, is_best_seller
    ),
    branches (
      id, name_ar, name_en, latitude, longitude, area_id, is_active
    ),
    product_badges!partner_products_badge_id_fkey (
      id, badge_type
    )
  ''';

  /// Fetch branch products filtered by area, with smart sorting
  /// Sort priority: price ASC → avg_rating DESC → distance ASC
  Future<List<BranchProduct>> getBranchProductsByArea({
    required String areaId,
    String? categoryId,
    int limit = 40,
    int offset = 0,
    double? userLat,
    double? userLng,
  }) async {
    var query = _supabase
        .from('partner_products')
        .select(_selectQuery)
        .eq('is_available', true)
        .eq('approval_status', 'approved')
        .eq('branches.area_id', areaId)
        .eq('branches.is_active', true)
        .eq('products.is_active', true);

    if (categoryId != null) {
      query = query.eq('products.category_id', categoryId);
    }

    final response = await query
        .order('customer_price', ascending: true)
        .order('avg_rating', ascending: false)
        .range(offset, offset + limit - 1);

    // Filter out items where the joined branch/product is null (filtered by PostgREST)
    final items = (response as List)
        .where((json) => json['products'] != null && json['branches'] != null)
        .map((json) => BranchProduct.fromJson(json))
        .toList();

    // Apply distance-based secondary sort if user location is available
    if (userLat != null && userLng != null) {
      items.sort((a, b) {
        // Primary: price
        final priceDiff = a.customerPrice.compareTo(b.customerPrice);
        if (priceDiff != 0) return priceDiff;

        // Secondary: rating (higher first)
        final ratingDiff = b.avgRating.compareTo(a.avgRating);
        if (ratingDiff != 0) return ratingDiff;

        // Tertiary: distance (closer first)
        final distA = _calcDistance(userLat, userLng, a.branchLat, a.branchLng);
        final distB = _calcDistance(userLat, userLng, b.branchLat, b.branchLng);
        return distA.compareTo(distB);
      });
    }

    return items;
  }

  /// Fetch best seller products for an area
  Future<List<BranchProduct>> getBestSellersForArea({
    required String areaId,
    int limit = 10,
  }) async {
    final response = await _supabase
        .from('partner_products')
        .select(_selectQuery)
        .eq('is_available', true)
        .eq('approval_status', 'approved')
        .eq('branches.area_id', areaId)
        .eq('branches.is_active', true)
        .eq('products.is_active', true)
        .eq('products.is_best_seller', true)
        .order('avg_rating', ascending: false)
        .limit(limit);

    return (response as List)
        .where((json) => json['products'] != null && json['branches'] != null)
        .map((json) => BranchProduct.fromJson(json))
        .toList();
  }

  /// Fetch newest products for an area
  Future<List<BranchProduct>> getNewestForArea({
    required String areaId,
    int limit = 10,
  }) async {
    final response = await _supabase
        .from('partner_products')
        .select(_selectQuery)
        .eq('is_available', true)
        .eq('approval_status', 'approved')
        .eq('branches.area_id', areaId)
        .eq('branches.is_active', true)
        .eq('products.is_active', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .where((json) => json['products'] != null && json['branches'] != null)
        .map((json) => BranchProduct.fromJson(json))
        .toList();
  }

  /// Fetch offer products (customer_price < product.old_price)
  Future<List<BranchProduct>> getOffersForArea({
    required String areaId,
    int limit = 10,
  }) async {
    final response = await _supabase
        .from('partner_products')
        .select(_selectQuery)
        .eq('is_available', true)
        .eq('approval_status', 'approved')
        .eq('branches.area_id', areaId)
        .eq('branches.is_active', true)
        .eq('products.is_active', true)
        .order('customer_price', ascending: true)
        .limit(limit);

    // Filter client-side for offers (old_price > price)
    return (response as List)
        .where((json) => json['products'] != null && json['branches'] != null)
        .where((json) {
          final productJson = json['products'] as Map?;
          final customerPrice =
              (json['customer_price'] as num?)?.toDouble() ?? 0;
          final oldPrice = (productJson?['old_price'] as num?)?.toDouble();
          return oldPrice != null && oldPrice > customerPrice;
        })
        .map((json) => BranchProduct.fromJson(json))
        .toList();
  }

  /// Search branch products by name in an area
  Future<List<BranchProduct>> searchInArea({
    required String areaId,
    required String query,
    int limit = 50,
  }) async {
    final response = await _supabase
        .from('partner_products')
        .select(_selectQuery)
        .eq('is_available', true)
        .eq('approval_status', 'approved')
        .eq('branches.area_id', areaId)
        .eq('branches.is_active', true)
        .eq('products.is_active', true)
        .or('products.name_ar.ilike.%$query%,products.name_en.ilike.%$query%')
        .order('avg_rating', ascending: false)
        .limit(limit);

    return (response as List)
        .where((json) => json['products'] != null && json['branches'] != null)
        .map((json) => BranchProduct.fromJson(json))
        .toList();
  }

  /// Fetch a single branch product by ID
  Future<BranchProduct?> getById(String branchProductId) async {
    try {
      final response = await _supabase
          .from('partner_products')
          .select(_selectQuery)
          .eq('id', branchProductId)
          .maybeSingle();

      if (response == null) return null;
      return BranchProduct.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Fetch all branch products for a specific base product (for displaying multiple offers)
  Future<List<BranchProduct>> getOffersForProduct({
    required String productId,
    required String areaId,
  }) async {
    final response = await _supabase
        .from('partner_products')
        .select(_selectQuery)
        .eq('product_id', productId)
        .eq('is_available', true)
        .eq('approval_status', 'approved')
        .eq('branches.area_id', areaId)
        .eq('branches.is_active', true)
        .order('customer_price', ascending: true);

    return (response as List)
        .where((json) => json['products'] != null && json['branches'] != null)
        .map((json) => BranchProduct.fromJson(json))
        .toList();
  }

  /// Calculate distance in km (Haversine)
  double _calcDistance(double lat1, double lng1, double? lat2, double? lng2) {
    if (lat2 == null || lng2 == null) return double.infinity;

    const R = 6371.0; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  /// Fetch ALL branch products for an area (for Scrollable Tab View)
  Future<List<BranchProduct>> getAllBranchProductsForArea({
    required String areaId,
  }) async {
    final response = await _supabase
        .from('partner_products')
        .select(_selectQuery)
        .eq('is_available', true)
        .eq('approval_status', 'approved')
        .eq('branches.area_id', areaId)
        .eq('branches.is_active', true)
        .eq('products.is_active', true)
        .order('customer_price', ascending: true);

    return (response as List)
        .where((json) => json['products'] != null && json['branches'] != null)
        .map((json) => BranchProduct.fromJson(json))
        .toList();
  }
}
