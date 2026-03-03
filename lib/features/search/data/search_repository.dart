import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/features/products/data/repositories/branch_product_repository.dart';
import 'package:bourraq/features/products/data/models/branch_product_model.dart';

import 'models/search_history_item.dart';
import 'models/popular_search_item.dart';

/// Search Repository
/// Handles all search-related Supabase operations
class SearchRepository {
  final SupabaseClient _supabase;
  static const int _maxHistoryItems = 20;

  SearchRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Normalize Arabic text for better search matching
  /// Handles: أ/إ/آ→ا، ى→ي، ة→ه، removes diacritics
  String _normalizeArabic(String text) {
    return text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll('ـ', '') // Remove tatweel
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '') // Remove diacritics
        .toLowerCase()
        .trim();
  }

  // ==========================================
  // SEARCH PRODUCTS
  // ==========================================

  /// Search products with Arabic normalization and bilingual support
  /// Searches in both name_ar and name_en
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (query.trim().isEmpty) return [];

    // Check for user's selected area
    final addressService = AddressService();
    final defaultAddress = await addressService.getDefaultAddress();

    if (defaultAddress?.areaId != null) {
      final areaId = defaultAddress!.areaId!;
      final branchProductRepo = BranchProductRepository();

      // Perform search using branch products in the specific area
      final branchProducts = await branchProductRepo.searchInArea(
        areaId: areaId,
        queryStr: query.trim(),
        limit: 50,
      );

      return branchProducts
          .map(
            (sp) => {
              'id': sp
                  .productId, // ID must map to product ID for details to fetch properly
              'branch_product_id': sp.id,
              'branch_id': sp.branchId,
              'name_ar': sp.nameAr,
              'name_en': sp.nameEn,
              'price': sp.customerPrice,
              'partner_price': sp.partnerPrice,
              'old_price': null,
              'image_url': sp.imageUrl,
              'is_active': sp.isActive,
              'category_id': sp.categoryId,
              'sub_category_id': sp.subCategoryId,
              'avg_rating': sp.avgRating,
              'rating_count': sp.ratingCount,
              'branch_name_ar': sp.branchNameAr,
              'branch_name_en': sp.branchNameEn,
            },
          )
          .toList();
    }
    final branchProductRepo = BranchProductRepository();
    final branchProducts = await branchProductRepo.searchInArea(
      queryStr: query.trim(),
      limit: 50,
    );

    // De-duplicate by product ID
    final products = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var sp in branchProducts) {
      if (!seenIds.contains(sp.productId)) {
        seenIds.add(sp.productId);
        products.add({
          'id': sp.productId,
          'branch_product_id': sp.id,
          'branch_id': sp.branchId,
          'name_ar': sp.nameAr,
          'name_en': sp.nameEn,
          'price': sp.customerPrice,
          'partner_price': sp.partnerPrice,
          'old_price': null,
          'image_url': sp.imageUrl,
          'is_active': sp.isActive,
          'category_id': sp.categoryId,
          'sub_category_id': sp.subCategoryId,
          'avg_rating': sp.avgRating,
          'rating_count': sp.ratingCount,
          'branch_name_ar': sp.branchNameAr,
          'branch_name_en': sp.branchNameEn,
        });
      }
    }
    return products;
  }

  /// Search products within a specific category
  Future<List<Map<String, dynamic>>> searchProductsInCategory(
    String query,
    String categoryId,
  ) async {
    if (query.trim().isEmpty) return [];
    final normalizedQuery = _normalizeArabic(query.trim());
    final searchPattern = '%$normalizedQuery%';

    var queryRepo = _supabase
        .from('partner_products')
        .select(BranchProductRepository.selectQuery)
        .eq('is_available', true)
        .eq('approval_status', 'approved')
        .eq('branches.is_active', true)
        .eq('products.is_active', true)
        .eq('products.category_id', categoryId)
        .or(
          'products.name_ar.ilike.$searchPattern,products.name_en.ilike.$searchPattern',
        );

    final response = await queryRepo
        .order('avg_rating', ascending: false)
        .limit(100);

    final branchProducts = (response as List)
        .where((json) => json['products'] != null && json['branches'] != null)
        .map((json) => BranchProduct.fromJson(json))
        .toList();

    // De-duplicate by product ID
    final products = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var sp in branchProducts) {
      if (!seenIds.contains(sp.productId)) {
        seenIds.add(sp.productId);
        products.add({
          'id': sp.productId,
          'branch_product_id': sp.id,
          'branch_id': sp.branchId,
          'name_ar': sp.nameAr,
          'name_en': sp.nameEn,
          'price': sp.customerPrice,
          'partner_price': sp.partnerPrice,
          'old_price': null,
          'image_url': sp.imageUrl,
          'is_active': sp.isActive,
          'category_id': sp.categoryId,
          'sub_category_id': sp.subCategoryId,
          'avg_rating': sp.avgRating,
          'rating_count': sp.ratingCount,
          'branch_name_ar': sp.branchNameAr,
          'branch_name_en': sp.branchNameEn,
        });
      }
    }

    return products;
  }

  // ==========================================
  // SEARCH HISTORY
  // ==========================================

  /// Get user's search history (last 20)
  Future<List<SearchHistoryItem>> getSearchHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('search_history')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(_maxHistoryItems);

    return (response as List)
        .map((item) => SearchHistoryItem.fromMap(item))
        .toList();
  }

  /// Add a search query to history
  /// Maintains max 20 items per user
  Future<void> addToSearchHistory(String query) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || query.trim().isEmpty) return;

    final trimmedQuery = query.trim();

    try {
      // Check if this query already exists for this user
      final existing = await _supabase
          .from('search_history')
          .select('id')
          .eq('user_id', userId)
          .eq('query', trimmedQuery)
          .maybeSingle();

      if (existing != null) {
        // Update timestamp to move it to top
        await _supabase
            .from('search_history')
            .update({'created_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', existing['id']);
      } else {
        // Insert new entry
        await _supabase.from('search_history').insert({
          'user_id': userId,
          'query': trimmedQuery,
        });

        // Clean up old entries (keep only last 20)
        await _cleanupOldHistory(userId);
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('❌ [SEARCH] Failed to save history: $e');
    }
  }

  /// Delete a single search history item
  Future<void> deleteSearchHistoryItem(String id) async {
    await _supabase.from('search_history').delete().eq('id', id);
  }

  /// Clear all search history for current user
  Future<void> clearSearchHistory() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _supabase.from('search_history').delete().eq('user_id', userId);
  }

  /// Remove old history entries beyond the limit
  Future<void> _cleanupOldHistory(String userId) async {
    try {
      // Get count
      final countResponse = await _supabase
          .from('search_history')
          .select('id, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final items = List<Map<String, dynamic>>.from(countResponse);

      if (items.length > _maxHistoryItems) {
        // Delete oldest entries
        final idsToDelete = items
            .skip(_maxHistoryItems)
            .map((item) => item['id'] as String)
            .toList();

        for (final id in idsToDelete) {
          await _supabase.from('search_history').delete().eq('id', id);
        }
      }
    } catch (e) {
      // Silently fail for cleanup
    }
  }

  // ==========================================
  // POPULAR SEARCHES
  // ==========================================

  /// Get active popular searches ordered by display_order
  Future<List<PopularSearchItem>> getPopularSearches() async {
    try {
      final response = await _supabase
          .from('popular_searches')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      return (response as List)
          .map((item) => PopularSearchItem.fromMap(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==========================================
  // POPULAR PRODUCTS (In User's Area)
  // ==========================================

  /// Get best-selling/popular products
  Future<List<Map<String, dynamic>>> getPopularProducts({
    int limit = 10,
  }) async {
    final addressService = AddressService();
    final defaultAddress = await addressService.getDefaultAddress();

    if (defaultAddress?.areaId != null) {
      final areaId = defaultAddress!.areaId!;
      final branchProductRepo = BranchProductRepository();

      final branchProducts = await branchProductRepo.getBestSellersForArea(
        areaId: areaId,
        limit: limit,
      );

      return branchProducts
          .map(
            (sp) => {
              'id': sp.productId,
              'branch_product_id': sp.id,
              'branch_id': sp.branchId,
              'name_ar': sp.nameAr,
              'name_en': sp.nameEn,
              'price': sp.customerPrice,
              'partner_price': sp.partnerPrice,
              'old_price': null,
              'image_url': sp.imageUrl,
              'is_active': sp.isActive,
              'category_id': sp.categoryId,
              'sub_category_id': sp.subCategoryId,
              'avg_rating': sp.avgRating,
              'rating_count': sp.ratingCount,
              'branch_name_ar': sp.branchNameAr,
              'branch_name_en': sp.branchNameEn,
            },
          )
          .toList();
    }
    // Global browsing for popular products
    final branchProductRepo = BranchProductRepository();
    final branchProducts = await branchProductRepo.getBestSellersForArea(
      limit: limit * 2,
    );

    final products = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (var sp in branchProducts) {
      if (!seenIds.contains(sp.productId) && products.length < limit) {
        seenIds.add(sp.productId);
        products.add({
          'id': sp.productId,
          'branch_product_id': sp.id,
          'branch_id': sp.branchId,
          'name_ar': sp.nameAr,
          'name_en': sp.nameEn,
          'price': sp.customerPrice,
          'partner_price': sp.partnerPrice,
          'old_price': null,
          'image_url': sp.imageUrl,
          'is_active': sp.isActive,
          'category_id': sp.categoryId,
          'sub_category_id': sp.subCategoryId,
          'avg_rating': sp.avgRating,
          'rating_count': sp.ratingCount,
          'branch_name_ar': sp.branchNameAr,
          'branch_name_en': sp.branchNameEn,
        });
      }
    }
    return products;
  }
}
