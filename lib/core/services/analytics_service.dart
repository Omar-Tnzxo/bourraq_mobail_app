import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart' as perf;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Comprehensive Analytics Service
/// Tracks all user interactions across the app
/// Supports: Firebase Analytics, Crashlytics, Performance, Supabase custom events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Firebase instances
  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  late final perf.FirebasePerformance _performance;

  // Supabase client
  final _supabase = Supabase.instance.client;

  // Debug mode
  final bool _isDebugMode = kDebugMode;

  /// Initialize all analytics services
  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _performance = perf.FirebasePerformance.instance;

    // Enable debug mode for development
    if (_isDebugMode) {
      await _analytics.setAnalyticsCollectionEnabled(true);
      debugPrint('📊 [Analytics] Debug mode enabled');
    }

    // Enable Crashlytics
    await _crashlytics.setCrashlyticsCollectionEnabled(true);

    // Enable Performance monitoring
    await _performance.setPerformanceCollectionEnabled(true);

    debugPrint('📊 [Analytics] Service initialized');
  }

  /// Get Firebase Analytics instance for router observer
  FirebaseAnalytics get analytics => _analytics;

  /// Get Firebase Analytics observer for navigation tracking
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ============================================
  // USER PROPERTIES
  // ============================================

  /// Set user ID for tracking
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
    if (userId != null) {
      await _crashlytics.setUserIdentifier(userId);
    }
    debugPrint('📊 [Analytics] User ID set: $userId');
  }

  /// Set user properties for segmentation
  Future<void> setUserProperties({
    String? area,
    String? language,
    int? ordersCount,
    double? totalSpent,
    String? firstOrderDate,
    String? accountType, // 'guest' or 'registered'
  }) async {
    if (area != null) {
      await _analytics.setUserProperty(name: 'user_area', value: area);
    }
    if (language != null) {
      await _analytics.setUserProperty(name: 'user_language', value: language);
    }
    if (ordersCount != null) {
      await _analytics.setUserProperty(
        name: 'orders_count',
        value: ordersCount.toString(),
      );
    }
    if (totalSpent != null) {
      await _analytics.setUserProperty(
        name: 'total_spent',
        value: totalSpent.toStringAsFixed(0),
      );
    }
    if (firstOrderDate != null) {
      await _analytics.setUserProperty(
        name: 'first_order_date',
        value: firstOrderDate,
      );
    }
    if (accountType != null) {
      await _analytics.setUserProperty(
        name: 'account_type',
        value: accountType,
      );
    }
    debugPrint('📊 [Analytics] User properties updated');
  }

  // ============================================
  // SCREEN TRACKING
  // ============================================

  /// Track screen view
  Future<void> trackScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
    await _logToSupabase('screen_view', {
      'screen_name': screenName,
      'screen_class': screenClass,
    });
    debugPrint('📊 [Analytics] Screen: $screenName');
  }

  // ============================================
  // PRODUCT TRACKING
  // ============================================

  /// Track product view
  Future<void> trackProductView({
    required String productId,
    required String productName,
    String? category,
    double? price,
    double? discountPercent,
  }) async {
    await _analytics.logViewItem(
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          itemCategory: category,
          price: price,
          discount: discountPercent,
        ),
      ],
    );
    await _logToSupabase('view_product', {
      'product_id': productId,
      'product_name': productName,
      'category': category,
      'price': price,
      'discount_percent': discountPercent,
    });
    debugPrint('📊 [Analytics] Product view: $productName');
  }

  /// Track category view
  Future<void> trackCategoryView({
    required String categoryId,
    required String categoryName,
  }) async {
    await _analytics.logEvent(
      name: 'view_category',
      parameters: {'category_id': categoryId, 'category_name': categoryName},
    );
    await _logToSupabase('view_category', {
      'category_id': categoryId,
      'category_name': categoryName,
    });
    debugPrint('📊 [Analytics] Category view: $categoryName');
  }

  // ============================================
  // CART TRACKING
  // ============================================

  /// Track add to cart
  Future<void> trackAddToCart({
    required String productId,
    required String productName,
    required int quantity,
    required double price,
    double? cartTotal,
    int? itemCount,
  }) async {
    await _analytics.logAddToCart(
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          quantity: quantity,
          price: price,
        ),
      ],
      value: price * quantity,
      currency: 'EGP',
    );
    await _logToSupabase('add_to_cart', {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
      'cart_total': cartTotal,
      'item_count': itemCount,
    });
    debugPrint('📊 [Analytics] Add to cart: $productName x$quantity');
  }

  /// Track remove from cart
  Future<void> trackRemoveFromCart({
    required String productId,
    required String productName,
    required int quantity,
    required double price,
  }) async {
    await _analytics.logRemoveFromCart(
      items: [
        AnalyticsEventItem(
          itemId: productId,
          itemName: productName,
          quantity: quantity,
          price: price,
        ),
      ],
      value: price * quantity,
      currency: 'EGP',
    );
    await _logToSupabase('remove_from_cart', {
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'price': price,
    });
    debugPrint('📊 [Analytics] Remove from cart: $productName');
  }

  /// Track cart quantity update
  Future<void> trackUpdateCartQuantity({
    required String productId,
    required int oldQuantity,
    required int newQuantity,
  }) async {
    await _analytics.logEvent(
      name: 'update_cart_quantity',
      parameters: {
        'product_id': productId,
        'old_quantity': oldQuantity,
        'new_quantity': newQuantity,
      },
    );
    await _logToSupabase('update_cart_quantity', {
      'product_id': productId,
      'old_quantity': oldQuantity,
      'new_quantity': newQuantity,
    });
  }

  /// Track clear cart
  Future<void> trackClearCart({int? itemCount, double? cartTotal}) async {
    await _analytics.logEvent(
      name: 'clear_cart',
      parameters: {'item_count': ?itemCount, 'cart_total': ?cartTotal},
    );
    await _logToSupabase('clear_cart', {
      'item_count': itemCount,
      'cart_total': cartTotal,
    });
    debugPrint('📊 [Analytics] Cart cleared');
  }

  // ============================================
  // FAVORITES TRACKING
  // ============================================

  /// Track add to favorites
  Future<void> trackAddToFavorites({
    required String productId,
    required String productName,
  }) async {
    await _analytics.logAddToWishlist(
      items: [AnalyticsEventItem(itemId: productId, itemName: productName)],
    );
    await _logToSupabase('add_to_favorites', {
      'product_id': productId,
      'product_name': productName,
    });
    debugPrint('📊 [Analytics] Add to favorites: $productName');
  }

  /// Track remove from favorites
  Future<void> trackRemoveFromFavorites({
    required String productId,
    required String productName,
  }) async {
    await _analytics.logEvent(
      name: 'remove_from_favorites',
      parameters: {'product_id': productId, 'product_name': productName},
    );
    await _logToSupabase('remove_from_favorites', {
      'product_id': productId,
      'product_name': productName,
    });
  }

  // ============================================
  // CHECKOUT & PURCHASE TRACKING
  // ============================================

  /// Track checkout started
  Future<void> trackBeginCheckout({
    required double cartTotal,
    required int itemCount,
  }) async {
    await _analytics.logBeginCheckout(value: cartTotal, currency: 'EGP');
    await _logToSupabase('begin_checkout', {
      'cart_total': cartTotal,
      'item_count': itemCount,
    });
    debugPrint('📊 [Analytics] Checkout started: $cartTotal EGP');
  }

  /// Track address selection
  Future<void> trackSelectAddress({required String addressId}) async {
    await _analytics.logEvent(
      name: 'select_address',
      parameters: {'address_id': addressId},
    );
    await _logToSupabase('select_address', {'address_id': addressId});
  }

  /// Track payment method selection
  Future<void> trackSelectPaymentMethod({required String method}) async {
    await _analytics.logEvent(
      name: 'select_payment_method',
      parameters: {'method': method},
    );
    await _logToSupabase('select_payment_method', {'method': method});
  }

  /// Track promo code applied
  Future<void> trackPromoCodeApplied({
    required String code,
    required bool success,
    double? discount,
    String? errorMessage,
  }) async {
    await _analytics.logEvent(
      name: success ? 'promo_code_success' : 'promo_code_failed',
      parameters: {'code': code, 'discount': ?discount, 'error': ?errorMessage},
    );
    await _logToSupabase(success ? 'promo_code_success' : 'promo_code_failed', {
      'code': code,
      'discount': discount,
      'error': errorMessage,
    });
    debugPrint('📊 [Analytics] Promo code $code: ${success ? "✅" : "❌"}');
  }

  /// Track purchase completed
  Future<void> trackPurchase({
    required String orderId,
    required double total,
    required double subtotal,
    double? discount,
    double? deliveryFee,
    required String paymentMethod,
    required int itemCount,
  }) async {
    await _analytics.logPurchase(
      transactionId: orderId,
      value: total,
      currency: 'EGP',
      shipping: deliveryFee,
    );
    await _logToSupabase('purchase', {
      'order_id': orderId,
      'total': total,
      'subtotal': subtotal,
      'discount': discount,
      'delivery_fee': deliveryFee,
      'payment_method': paymentMethod,
      'item_count': itemCount,
    });
    debugPrint('📊 [Analytics] Purchase: $orderId - $total EGP');
  }

  // ============================================
  // SEARCH TRACKING
  // ============================================

  /// Track search
  Future<void> trackSearch({
    required String searchTerm,
    required int resultsCount,
  }) async {
    await _analytics.logSearch(searchTerm: searchTerm);
    await _logToSupabase('search', {
      'search_term': searchTerm,
      'results_count': resultsCount,
    });
    debugPrint('📊 [Analytics] Search: "$searchTerm" ($resultsCount results)');
  }

  /// Track search with no results
  Future<void> trackSearchNoResults({required String searchTerm}) async {
    await _analytics.logEvent(
      name: 'search_no_results',
      parameters: {'search_term': searchTerm},
    );
    await _logToSupabase('search_no_results', {'search_term': searchTerm});
  }

  /// Track search result click
  Future<void> trackSearchResultClick({
    required String searchTerm,
    required String productId,
    required int position,
  }) async {
    await _analytics.logEvent(
      name: 'search_result_click',
      parameters: {
        'search_term': searchTerm,
        'product_id': productId,
        'position': position,
      },
    );
    await _logToSupabase('search_result_click', {
      'search_term': searchTerm,
      'product_id': productId,
      'position': position,
    });
  }

  // ============================================
  // USER TRACKING
  // ============================================

  /// Track sign up
  Future<void> trackSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
    await _logToSupabase('sign_up', {'method': method});
    debugPrint('📊 [Analytics] Sign up: $method');
  }

  /// Track login
  Future<void> trackLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
    await _logToSupabase('login', {'method': method});
    debugPrint('📊 [Analytics] Login: $method');
  }

  /// Track logout
  Future<void> trackLogout() async {
    await _analytics.logEvent(name: 'logout');
    await _logToSupabase('logout', {});
    await setUserId(null);
    debugPrint('📊 [Analytics] Logout');
  }

  /// Track profile update
  Future<void> trackUpdateProfile({List<String>? updatedFields}) async {
    await _analytics.logEvent(
      name: 'update_profile',
      parameters: {
        if (updatedFields != null) 'fields': updatedFields.join(','),
      },
    );
    await _logToSupabase('update_profile', {'fields': updatedFields});
  }

  /// Track address added
  Future<void> trackAddAddress({required String addressType}) async {
    await _analytics.logEvent(
      name: 'add_address',
      parameters: {'address_type': addressType},
    );
    await _logToSupabase('add_address', {'address_type': addressType});
  }

  /// Track account deletion
  Future<void> trackDeleteAccount() async {
    await _analytics.logEvent(name: 'delete_account');
    await _logToSupabase('delete_account', {});
    debugPrint('📊 [Analytics] Account deleted');
  }

  /// Track area request
  Future<void> trackRequestArea({required String areaName}) async {
    await _analytics.logEvent(
      name: 'request_area',
      parameters: {'area_name': areaName},
    );
    await _logToSupabase('request_area', {'area_name': areaName});
  }

  // ============================================
  // ERROR TRACKING
  // ============================================

  /// Track error
  Future<void> trackError({
    required String errorCode,
    required String errorMessage,
    String? screenName,
    Map<String, dynamic>? extra,
  }) async {
    await _analytics.logEvent(
      name: 'error_occurred',
      parameters: {
        'error_code': errorCode,
        'error_message': errorMessage.substring(
          0,
          errorMessage.length.clamp(0, 100),
        ),
        'screen_name': ?screenName,
      },
    );
    await _crashlytics.recordError(
      Exception(errorMessage),
      StackTrace.current,
      reason: errorCode,
      information:
          extra?.entries.map((e) => '${e.key}: ${e.value}').toList() ?? [],
    );
    await _logToSupabase('error_occurred', {
      'error_code': errorCode,
      'error_message': errorMessage,
      'screen_name': screenName,
      ...?extra,
    });
    debugPrint('📊 [Analytics] Error: $errorCode - $errorMessage');
  }

  /// Track API error
  Future<void> trackApiError({
    required String endpoint,
    required int statusCode,
    String? errorMessage,
  }) async {
    await _analytics.logEvent(
      name: 'api_error',
      parameters: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'error': ?errorMessage,
      },
    );
    await _logToSupabase('api_error', {
      'endpoint': endpoint,
      'status_code': statusCode,
      'error': errorMessage,
    });
  }

  /// Track network error
  Future<void> trackNetworkError() async {
    await _analytics.logEvent(name: 'network_error');
    await _logToSupabase('network_error', {});
  }

  /// Track payment failed
  Future<void> trackPaymentFailed({
    required String reason,
    required double amount,
  }) async {
    await _analytics.logEvent(
      name: 'payment_failed',
      parameters: {'reason': reason, 'amount': amount},
    );
    await _logToSupabase('payment_failed', {
      'reason': reason,
      'amount': amount,
    });
  }

  // ============================================
  // NOTIFICATION TRACKING
  // ============================================

  /// Track notification received
  Future<void> trackNotificationReceived({
    required String notificationId,
    required String type,
  }) async {
    await _analytics.logEvent(
      name: 'notification_received',
      parameters: {'notification_id': notificationId, 'type': type},
    );
    await _logToSupabase('notification_received', {
      'notification_id': notificationId,
      'type': type,
    });
  }

  /// Track notification opened
  Future<void> trackNotificationOpened({
    required String notificationId,
    required String type,
  }) async {
    await _analytics.logEvent(
      name: 'notification_opened',
      parameters: {'notification_id': notificationId, 'type': type},
    );
    await _logToSupabase('notification_opened', {
      'notification_id': notificationId,
      'type': type,
    });
  }

  // ============================================
  // APP LIFECYCLE
  // ============================================

  /// Track app open
  Future<void> trackAppOpen() async {
    await _analytics.logAppOpen();
    await _logToSupabase('app_open', {});
    debugPrint('📊 [Analytics] App opened');
  }

  /// Track session start
  Future<void> trackSessionStart() async {
    await _analytics.logEvent(name: 'session_start');
    await _logToSupabase('session_start', {});
  }

  // ============================================
  // PERFORMANCE TRACKING
  // ============================================

  /// Start a performance trace
  perf.Trace startTrace(String name) {
    return _performance.newTrace(name);
  }

  /// Track HTTP metric
  perf.HttpMetric startHttpMetric(String url, perf.HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }

  // ============================================
  // SUPABASE LOGGING
  // ============================================

  /// Log event to Supabase for custom analytics
  Future<void> _logToSupabase(
    String eventName,
    Map<String, dynamic> params,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      try {
        await _supabase.from('analytics_events').insert({
          'user_id': userId,
          'event_name': eventName,
          'event_params': params,
          'platform': _getPlatform(),
          'app_version': '1.0.0', // TODO: Get from package_info
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Fallback: If fk_analytics_events_user fails (user exists in auth but not in public.users), log without user_id
        if (e.toString().contains('fk_analytics_events_user') &&
            userId != null) {
          await _supabase.from('analytics_events').insert({
            'user_id': null,
            'event_name': eventName,
            'event_params': params,
            'platform': _getPlatform(),
            'app_version': '1.0.0',
            'created_at': DateTime.now().toIso8601String(),
          });
        } else {
          rethrow;
        }
      }
    } catch (e) {
      // Silent fail - don't block app functionality
      if (_isDebugMode) {
        debugPrint('📊 [Analytics] Supabase log failed: $e');
      }
    }
  }

  String _getPlatform() {
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'unknown';
  }
}
