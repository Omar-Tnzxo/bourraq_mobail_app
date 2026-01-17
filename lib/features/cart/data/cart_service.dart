import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../domain/models/cart_item.dart';
import 'cart_repository.dart';
import 'delivery_settings.dart';
import 'package:bourraq/core/services/analytics_service.dart';

/// Hybrid cart service - local storage + Supabase sync
/// Uses SINGLETON pattern + ChangeNotifier for realtime updates across all screens
class CartService extends ChangeNotifier {
  static const String _cartKey = 'shopping_cart';

  // Singleton instance
  static CartService? _instance;
  static SharedPreferences? _prefs;

  final CartRepository _repository;

  List<CartItem> _cachedItems = [];
  DeliverySettings _deliverySettings = const DeliverySettings();
  bool _isInitialized = false;

  // Private constructor
  CartService._internal([CartRepository? repository])
    : _repository = repository ?? CartRepository();

  /// Get singleton instance
  /// Call initInstance() first at app startup
  static CartService get instance {
    if (_instance == null) {
      throw StateError(
        'CartService not initialized. Call CartService.initInstance() first.',
      );
    }
    return _instance!;
  }

  /// Initialize singleton instance (call once at app startup)
  static Future<CartService> initInstance() async {
    if (_instance != null) return _instance!;

    _prefs = await SharedPreferences.getInstance();
    _instance = CartService._internal();
    return _instance!;
  }

  /// Legacy constructor for backward compatibility
  /// Returns the singleton instance instead of creating new
  factory CartService(SharedPreferences prefs, [CartRepository? repository]) {
    if (_instance == null) {
      _prefs = prefs;
      _instance = CartService._internal(repository);
    }
    return _instance!;
  }

  /// Check if initialized
  bool get isInitialized => _isInitialized;

  /// Get delivery settings
  DeliverySettings get deliverySettings => _deliverySettings;

  /// Initialize and sync cart
  Future<void> init({String? areaId}) async {
    if (_isInitialized) {
      print('🛒 [CartService] Already initialized, skipping init');
      return;
    }

    print('🛒 [CartService] Initializing cart...');

    // Load delivery settings (with fallback)
    try {
      _deliverySettings = await _repository.getDeliverySettings(areaId);
      print('🛒 [CartService] Delivery settings loaded');
    } catch (e) {
      print('⚠️ [CartService] Delivery settings failed: $e');
      _deliverySettings = const DeliverySettings();
    }

    // Always load local items first (fast startup)
    _cachedItems = _getLocalItems();
    print('🛒 [CartService] Local items: ${_cachedItems.length}');

    // Then try to sync with cloud if user is logged in
    try {
      print('🛒 [CartService] Fetching cloud items...');
      final cloudItems = await _repository.getCartItems();
      print('🛒 [CartService] Cloud items: ${cloudItems.length}');

      if (cloudItems.isNotEmpty) {
        // Cloud has items - use them and update local
        _cachedItems = cloudItems;
        await _saveLocal(_cachedItems);
        print('🛒 [CartService] Synced ${cloudItems.length} items FROM cloud');
      } else if (_cachedItems.isNotEmpty) {
        // Local has items but cloud empty - sync to cloud
        await _repository.syncLocalCart(_cachedItems);
        print('🛒 [CartService] Synced ${_cachedItems.length} items TO cloud');
      }
    } catch (e) {
      // Supabase failed - continue with local items
      print('❌ [CartService] Cloud sync failed: $e');
    }

    _isInitialized = true;
    notifyListeners();
    print('✅ [CartService] Initialized with ${_cachedItems.length} items');
  }

  /// Get all cart items
  List<CartItem> getCartItems() => List.unmodifiable(_cachedItems);

  /// Get cart total
  double getCartTotal() {
    return _cachedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Get cart item count
  int getCartItemCount() {
    return _cachedItems.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get remaining for free delivery
  double getRemainingForFreeDelivery() {
    return _deliverySettings.getRemainingForFreeDelivery(getCartTotal());
  }

  /// Check if free delivery enabled
  bool get isFreeDeliveryEnabled => _deliverySettings.freeDeliveryEnabled;

  /// Check if qualifies for free delivery
  bool get hasFreeDelivery => _deliverySettings.isFreeDelivery(getCartTotal());

  /// Add item to cart
  Future<void> addToCart(CartItem item) async {
    // Find existing
    final existingIndex = _cachedItems.indexWhere(
      (i) => i.productId == item.productId,
    );

    if (existingIndex != -1) {
      // Update quantity
      final existing = _cachedItems[existingIndex];
      _cachedItems[existingIndex] = existing.copyWith(
        quantity: existing.quantity + item.quantity,
      );
    } else {
      _cachedItems.add(item);
    }

    notifyListeners(); // Notify all listeners immediately
    await _saveLocal(_cachedItems);

    // Sync to cloud
    await _repository.addToCart(item.productId, quantity: item.quantity);

    // Track analytics
    AnalyticsService().trackAddToCart(
      productId: item.productId,
      productName: item.nameEn,
      quantity: item.quantity,
      price: item.price,
      cartTotal: getCartTotal(),
      itemCount: getCartItemCount(),
    );
  }

  /// Update item quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    final index = _cachedItems.indexWhere((i) => i.productId == productId);

    if (index != -1) {
      if (quantity <= 0) {
        _cachedItems.removeAt(index);
      } else {
        _cachedItems[index] = _cachedItems[index].copyWith(quantity: quantity);
      }
      notifyListeners(); // Notify all listeners immediately
      await _saveLocal(_cachedItems);
    }

    // Sync to cloud
    await _repository.updateQuantity(productId, quantity);
  }

  /// Remove item from cart
  Future<void> removeFromCart(String productId) async {
    _cachedItems.removeWhere((item) => item.productId == productId);
    notifyListeners(); // Notify all listeners immediately
    await _saveLocal(_cachedItems);

    // Sync to cloud
    await _repository.removeFromCart(productId);
  }

  /// Clear all cart items
  Future<void> clearCart() async {
    final itemCount = getCartItemCount();
    final cartTotal = getCartTotal();

    _cachedItems.clear();
    notifyListeners(); // Notify all listeners immediately
    await _prefs?.remove(_cartKey);

    // Sync to cloud
    await _repository.clearCart();

    // Track analytics
    AnalyticsService().trackClearCart(
      itemCount: itemCount,
      cartTotal: cartTotal,
    );
  }

  /// Check and remove out of stock items
  Future<List<String>> checkAndRemoveOutOfStock() async {
    final removed = await _repository.removeOutOfStockItems();

    // Also remove from local
    for (final productId in removed) {
      _cachedItems.removeWhere((item) => item.productId == productId);
    }

    if (removed.isNotEmpty) {
      await _saveLocal(_cachedItems);
    }

    return removed;
  }

  /// Refresh from cloud
  Future<void> refresh({String? areaId}) async {
    await init(areaId: areaId);
  }

  /// Get items from local storage
  List<CartItem> _getLocalItems() {
    final String? cartJson = _prefs?.getString(_cartKey);
    if (cartJson == null) return [];

    try {
      final List<dynamic> cartList = json.decode(cartJson);
      return cartList.map((item) => CartItem.fromLocalJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save items to local storage
  Future<void> _saveLocal(List<CartItem> items) async {
    final cartJson = json.encode(
      items.map((item) => item.toLocalJson()).toList(),
    );
    await _prefs?.setString(_cartKey, cartJson);
  }
}
