import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// CacheService - Local data persistence using Hive
///
/// Provides:
/// 1. TTL-based cache expiration
/// 2. Type-safe JSON storage
/// 3. Cache invalidation methods
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _cacheBoxName = 'app_cache';
  static const String _metaBoxName = 'cache_meta';

  Box<String>? _cacheBox;
  Box<int>? _metaBox;

  bool _isInitialized = false;

  /// Default TTL durations (in minutes)
  static const Map<String, int> defaultTTL = {
    'home_sections': 30, // 30 minutes
    'home_banners': 60, // 1 hour
    'home_categories': 120, // 2 hours
    'home_products': 15, // 15 minutes (more dynamic)
    'favorites': 10, // 10 minutes
    'orders': 5, // 5 minutes
    'default': 30, // 30 minutes default
  };

  /// Initialize Hive and open cache boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      _cacheBox = await Hive.openBox<String>(_cacheBoxName);
      _metaBox = await Hive.openBox<int>(_metaBoxName);
      _isInitialized = true;
      debugPrint('✅ [CACHE] Service initialized');
    } catch (e) {
      debugPrint('❌ [CACHE] Failed to initialize: $e');
    }
  }

  /// Check if service is ready
  bool get isReady => _isInitialized && _cacheBox != null && _metaBox != null;

  /// Store data with TTL
  Future<bool> set(String key, dynamic data, {String? cacheType}) async {
    if (!isReady) return false;

    try {
      final jsonStr = json.encode(data);
      await _cacheBox!.put(key, jsonStr);

      // Store timestamp
      final now = DateTime.now().millisecondsSinceEpoch;
      await _metaBox!.put('${key}_ts', now);

      debugPrint('💾 [CACHE] Stored: $key');
      return true;
    } catch (e) {
      debugPrint('❌ [CACHE] Failed to store $key: $e');
      return false;
    }
  }

  /// Get cached data (returns null if expired or not found)
  T? get<T>(String key, {String? cacheType, bool ignoreExpiry = false}) {
    if (!isReady) return null;

    try {
      final jsonStr = _cacheBox!.get(key);
      if (jsonStr == null) return null;

      // Check expiry
      if (!ignoreExpiry && isExpired(key, cacheType: cacheType)) {
        debugPrint('⏰ [CACHE] Expired: $key');
        return null;
      }

      final data = json.decode(jsonStr);
      debugPrint('📖 [CACHE] Retrieved: $key');
      return data as T;
    } catch (e) {
      debugPrint('❌ [CACHE] Failed to get $key: $e');
      return null;
    }
  }

  /// Get cached data even if expired (for offline fallback)
  T? getStale<T>(String key) {
    return get<T>(key, ignoreExpiry: true);
  }

  /// Check if cache entry is expired
  bool isExpired(String key, {String? cacheType}) {
    if (!isReady) return true;

    final timestamp = _metaBox!.get('${key}_ts');
    if (timestamp == null) return true;

    final ttlMinutes = defaultTTL[cacheType] ?? defaultTTL['default']!;
    final expiryTime = timestamp + (ttlMinutes * 60 * 1000);
    final now = DateTime.now().millisecondsSinceEpoch;

    return now > expiryTime;
  }

  /// Get cache age in minutes
  int? getCacheAge(String key) {
    if (!isReady) return null;

    final timestamp = _metaBox!.get('${key}_ts');
    if (timestamp == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    return ((now - timestamp) / 60000).round();
  }

  /// Invalidate specific cache entry
  Future<void> invalidate(String key) async {
    if (!isReady) return;

    await _cacheBox!.delete(key);
    await _metaBox!.delete('${key}_ts');
    debugPrint('🗑️ [CACHE] Invalidated: $key');
  }

  /// Invalidate all cache entries matching a prefix
  Future<void> invalidateByPrefix(String prefix) async {
    if (!isReady) return;

    final keysToDelete = _cacheBox!.keys
        .where((key) => key.toString().startsWith(prefix))
        .toList();

    for (final key in keysToDelete) {
      await invalidate(key.toString());
    }
  }

  /// Clear all cache
  Future<void> clearAll() async {
    if (!isReady) return;

    await _cacheBox!.clear();
    await _metaBox!.clear();
    debugPrint('🧹 [CACHE] Cleared all cache');
  }

  /// Check if valid cache exists for key
  bool hasValidCache(String key, {String? cacheType}) {
    if (!isReady) return false;

    final data = _cacheBox!.get(key);
    if (data == null) return false;

    return !isExpired(key, cacheType: cacheType);
  }

  /// Check if ANY cache exists (even expired)
  bool hasAnyCache(String key) {
    if (!isReady) return false;
    return _cacheBox!.containsKey(key);
  }
}
