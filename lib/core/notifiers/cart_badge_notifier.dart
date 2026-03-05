import 'package:flutter/material.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';

/// Cart badge notifier for updating cart count in real-time
/// Now listens to CartService changes for instant updates
class CartBadgeNotifier extends ChangeNotifier {
  num _count = 0;
  bool _isInitialized = false;
  CartService? _cartService;

  num get count => _count;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    print('🛒 [CartBadgeNotifier] Initializing...');

    // Get CartService singleton
    _cartService = await CartService.initInstance();

    // Initialize CartService to load from Supabase
    await _cartService!.init();

    // Listen to cart changes
    _cartService!.addListener(_onCartChanged);

    _isInitialized = true;
    _updateCount();
    print('✅ [CartBadgeNotifier] Ready with count: $_count');
  }

  void _onCartChanged() {
    _updateCount();
  }

  void _updateCount() {
    if (_cartService == null) return;

    _count = _cartService!.getCartItemCount();
    notifyListeners();
  }

  /// Force refresh from CartService
  Future<void> refresh() async {
    if (!_isInitialized) {
      await init();
      return;
    }
    _updateCount();
  }

  @override
  void dispose() {
    _cartService?.removeListener(_onCartChanged);
    super.dispose();
  }
}
