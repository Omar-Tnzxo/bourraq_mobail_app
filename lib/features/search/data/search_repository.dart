import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

    // Normalize Arabic text for better matching
    final normalizedQuery = _normalizeArabic(query.trim());
    final searchPattern = '%$normalizedQuery%';

    // Search in both Arabic and English names
    final response = await _supabase
        .from('products')
        .select('*')
        .eq('is_active', true)
        .or(
          'name_ar.ilike.$searchPattern,name_en.ilike.$searchPattern,description_ar.ilike.$searchPattern,description_en.ilike.$searchPattern',
        )
        .order('is_best_seller', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Search products within a specific category
  Future<List<Map<String, dynamic>>> searchProductsInCategory(
    String query,
    String categoryId,
  ) async {
    if (query.trim().isEmpty) return [];

    final normalizedQuery = _normalizeArabic(query.trim());
    final searchPattern = '%$normalizedQuery%';

    final response = await _supabase
        .from('products')
        .select('*')
        .eq('is_active', true)
        .eq('category_id', categoryId)
        .or('name_ar.ilike.$searchPattern,name_en.ilike.$searchPattern')
        .order('is_best_seller', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);
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
    final response = await _supabase
        .from('products')
        .select('*')
        .eq('is_active', true)
        .eq('is_best_seller', true)
        .order('created_at', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response);
  }
}
