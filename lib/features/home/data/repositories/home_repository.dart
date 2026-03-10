import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bourraq/core/services/cache_service.dart';
import 'package:bourraq/features/home/data/models/home_section_model.dart';

/// Repository for fetching Home Screen data from Supabase
class HomeRepository {
  final SupabaseClient _supabase;
  final CacheService _cache = CacheService();

  // Cache keys
  static const String _cacheKeyBanners = 'home_banners';
  static const String _cacheKeyCategories = 'home_categories';
  static const String _cacheKeyProducts = 'home_products';
  static const String _cacheKeySections = 'home_sections';

  HomeRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ============================================================================
  // CACHE METHODS
  // ============================================================================

  /// Save home data to cache
  Future<void> cacheHomeData({
    List<Map<String, dynamic>>? banners,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? sections,
  }) async {
    if (banners != null) {
      await _cache.set(_cacheKeyBanners, banners, cacheType: 'home_banners');
    }
    if (categories != null) {
      await _cache.set(
        _cacheKeyCategories,
        categories,
        cacheType: 'home_categories',
      );
    }
    if (products != null) {
      await _cache.set(_cacheKeyProducts, products, cacheType: 'home_products');
    }
    if (sections != null) {
      await _cache.set(_cacheKeySections, sections, cacheType: 'home_sections');
    }
  }

  /// Get cached banners
  List<Map<String, dynamic>>? getCachedBanners({bool stale = false}) {
    final data = stale
        ? _cache.getStale<List<dynamic>>(_cacheKeyBanners)
        : _cache.get<List<dynamic>>(
            _cacheKeyBanners,
            cacheType: 'home_banners',
          );
    return data?.cast<Map<String, dynamic>>();
  }

  /// Get cached categories
  List<Map<String, dynamic>>? getCachedCategories({bool stale = false}) {
    final data = stale
        ? _cache.getStale<List<dynamic>>(_cacheKeyCategories)
        : _cache.get<List<dynamic>>(
            _cacheKeyCategories,
            cacheType: 'home_categories',
          );
    return data?.cast<Map<String, dynamic>>();
  }

  /// Get cached products
  List<Map<String, dynamic>>? getCachedProducts({bool stale = false}) {
    final data = stale
        ? _cache.getStale<List<dynamic>>(_cacheKeyProducts)
        : _cache.get<List<dynamic>>(
            _cacheKeyProducts,
            cacheType: 'home_products',
          );
    return data?.cast<Map<String, dynamic>>();
  }

  /// Get cached sections
  List<Map<String, dynamic>>? getCachedSections({bool stale = false}) {
    final data = stale
        ? _cache.getStale<List<dynamic>>(_cacheKeySections)
        : _cache.get<List<dynamic>>(
            _cacheKeySections,
            cacheType: 'home_sections',
          );
    return data?.cast<Map<String, dynamic>>();
  }

  /// Check if any home cache exists (even expired)
  bool hasHomeCache() {
    return _cache.hasAnyCache(_cacheKeyBanners) ||
        _cache.hasAnyCache(_cacheKeyCategories) ||
        _cache.hasAnyCache(_cacheKeyProducts);
  }

  /// Get cache age in minutes
  int? getHomeCacheAge() {
    return _cache.getCacheAge(_cacheKeyProducts);
  }

  /// Invalidate all home cache
  Future<void> invalidateHomeCache() async {
    await _cache.invalidateByPrefix('home_');
  }

  // ============================================================================
  // API METHODS
  // ============================================================================

  /// Fetch active home sections ordered by display_order
  Future<List<HomeSection>> getHomeSections() async {
    final response = await _supabase
        .from('home_sections')
        .select()
        .eq('is_active', true)
        .order('display_order', ascending: true);

    return (response as List)
        .map((json) => HomeSection.fromJson(json))
        .toList();
  }

  /// Fetch active banners ordered by display_order
  Future<List<Map<String, dynamic>>> getBanners({
    int? limit,
    String? placement,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    var query = _supabase
        .from('banners')
        .select()
        .eq('is_active', true)
        .or('start_date.is.null,start_date.lte.$now')
        .or('end_date.is.null,end_date.gte.$now');

    if (placement != null) {
      query = query.eq('placement', placement);
    }

    dynamic transformQuery = query.order('display_order', ascending: true);

    if (limit != null) {
      transformQuery = transformQuery.limit(limit);
    }

    final response = await transformQuery;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch active categories ordered by display_order
  Future<List<Map<String, dynamic>>> getCategories({int? limit}) async {
    var query = _supabase
        .from('categories')
        .select()
        .eq('is_active', true)
        .isFilter('parent_id', null)
        .order('display_order', ascending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch products by source type
  Future<List<Map<String, dynamic>>> getProductsBySource({
    required String source,
    String? categoryId,
    int limit = 10,
  }) async {
    switch (source) {
      case 'best_sellers':
        return getBestSellers(limit: limit);
      case 'newest':
        return getNewestProducts(limit: limit);
      case 'offers':
        return getOfferProducts(limit: limit);
      case 'category':
        if (categoryId != null) {
          return getProductsByCategory(categoryId, limit: limit);
        }
        return [];
      default:
        return getBestSellers(limit: limit);
    }
  }

  /// Fetch best seller products
  Future<List<Map<String, dynamic>>> getBestSellers({int limit = 10}) async {
    final response = await _supabase
        .from('products')
        .select('*, partner_products(customer_price_before_discount)')
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .eq('is_best_seller', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch newest products
  Future<List<Map<String, dynamic>>> getNewestProducts({int limit = 10}) async {
    final response = await _supabase
        .from('products')
        .select('*, partner_products(customer_price_before_discount)')
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch products with offers (old_price > price)
  Future<List<Map<String, dynamic>>> getOfferProducts({int limit = 10}) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .not('old_price', 'is', null)
        .order('created_at', ascending: false)
        .limit(limit);

    // Filter where old_price > price
    final products = List<Map<String, dynamic>>.from(response);
    return products.where((p) {
      final price = (p['price'] as num?)?.toDouble() ?? 0;
      final oldPrice = (p['old_price'] as num?)?.toDouble();
      return oldPrice != null && oldPrice > price;
    }).toList();
  }

  /// Fetch products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(
    String categoryId, {
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .eq('category_id', categoryId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetch all active products (for search)
  Future<List<Map<String, dynamic>>> getAllProducts({
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Search products by name (AR or EN)
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    final response = await _supabase
        .from('products')
        .select()
        .eq('is_active', true)
        .isFilter('deleted_at', null)
        .or('name_ar.ilike.%$query%,name_en.ilike.%$query%')
        .order('name_ar', ascending: true)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);
  }
}
