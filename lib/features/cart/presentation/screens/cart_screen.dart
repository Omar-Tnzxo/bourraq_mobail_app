import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/core/notifiers/cart_badge_notifier.dart';
import 'package:bourraq/core/widgets/shimmer_skeleton.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/cart/data/cart_repository.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';
import 'package:bourraq/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:bourraq/features/cart/presentation/widgets/cart_empty_state.dart';
import 'package:bourraq/features/cart/presentation/widgets/free_delivery_banner.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/core/utils/guest_restriction_helper.dart';
import 'package:bourraq/core/widgets/app_price_display.dart';

/// Cart Screen - Premium Rabbit-style design
class CartScreen extends StatefulWidget {
  final VoidCallback? onGoToHome;

  const CartScreen({super.key, this.onGoToHome});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  CartService? _cartService;
  List<CartItem> _items = [];
  bool _isLoading = true;
  List<String> _removedOutOfStock = [];

  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();

    _arrowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _arrowAnimation = Tween<double>(begin: 0, end: 5).animate(
      CurvedAnimation(
        parent: _arrowAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _initCart();
  }

  @override
  void dispose() {
    _arrowAnimationController.dispose();
    super.dispose();
  }

  Future<void> _initCart() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    _cartService = CartService(prefs, CartRepository());

    // Get user's current area ID (if available)
    final addressService = AddressService();
    final defaultAddress = await addressService.getDefaultAddress();
    if (!mounted) return;

    final areaId = defaultAddress?.areaId;

    await _cartService!.init(areaId: areaId);
    if (!mounted) return;

    // Check for removed out of stock items
    _removedOutOfStock = await _cartService!.checkAndRemoveOutOfStock();
    if (!mounted) return;

    _loadCart();

    // Show notification if items were removed
    if (_removedOutOfStock.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'cart.items_removed_stock'.tr(
              args: ['${_removedOutOfStock.length}'],
            ),
          ),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _loadCart() {
    if (_cartService == null) return;
    setState(() {
      _items = _cartService!.getCartItems();
      _isLoading = false;
    });
  }

  double get _cartTotal => _cartService?.getCartTotal() ?? 0;
  num get _itemCount => _cartService?.getCartItemCount() ?? 0;

  double get _remainingForFreeDelivery =>
      _cartService?.getRemainingForFreeDelivery() ?? 0;

  bool get _isFreeDeliveryEnabled =>
      _cartService?.isFreeDeliveryEnabled ?? false;

  Future<void> _updateQuantity(String productId, double newQuantity) async {
    HapticFeedback.selectionClick();

    await _cartService?.updateQuantity(productId, newQuantity);
    _loadCart();
    _refreshBadge();
  }

  Future<void> _removeItem(String productId) async {
    HapticFeedback.mediumImpact();
    await _cartService?.removeFromCart(productId);
    _loadCart();
    _refreshBadge();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cart.item_removed'.tr()),
          backgroundColor: AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _clearCart() async {
    HapticFeedback.mediumImpact();

    final confirmed = await BourraqDialog.show(
      context,
      title: 'cart.clear_cart'.tr(),
      message: 'cart.clear_cart_confirm'.tr(),
      confirmLabel: 'cart.clear_all'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      icon: LucideIcons.trash2,
    );

    if (confirmed == true) {
      await _cartService?.clearCart();
      _loadCart();
      _refreshBadge();
    }
  }

  void _refreshBadge() {
    if (mounted) {
      context.read<CartBadgeNotifier>().refresh();
    }
  }

  Future<void> _onCheckout() async {
    HapticFeedback.selectionClick();

    // Block guest users from checkout - require login first
    if (GuestRestrictionHelper.checkAndPromptLogin(context)) return;

    // Check if user has address
    final addressService = AddressService();
    final defaultAddress = await addressService.getDefaultAddress();

    if (defaultAddress != null) {
      if (mounted) context.push('/checkout');
    } else {
      if (mounted) context.push('/add-address');
    }
  }

  String get _locale => context.locale.languageCode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Premium Curved Header
          _buildHeader(),

          // Content
          Expanded(
            child: _isLoading
                ? const ShimmerList(
                    itemCount: 4,
                    itemBuilder: ShimmerListTile(
                      hasLeading: true,
                      hasTrailing: true,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  )
                : _items.isEmpty
                ? CartEmptyState(onBrowseProducts: widget.onGoToHome)
                : _buildCartContent(),
          ),

          // Checkout Button (only if items exist)
          if (!_isLoading && _items.isNotEmpty) _buildCheckoutButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final canPop = Navigator.of(context).canPop();

    return BourraqHeader(
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button (only when navigated via push)
          if (canPop) ...[
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  _locale == 'ar'
                      ? LucideIcons.arrowRight
                      : LucideIcons.arrowLeft,
                  color: AppColors.accentYellow,
                  size: 28,
                ),
              ),
            ),
          ],

          // Title
          Text(
            'cart.my_cart'.tr(),
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.accentYellow,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),

          if (_itemCount > 0) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
              child: Text(
                '\u200E${_itemCount % 1 == 0 ? _itemCount.toInt() : _itemCount}\u200E',
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.0,
                ),
              ),
            ),
          ],

          const Spacer(),

          // Clear All Button
          if (_items.isNotEmpty)
            GestureDetector(
              onTap: _clearCart,
              child: Text(
                'cart.clear_all'.tr(),
                style: const TextStyle(
                  color: AppColors.accentYellow,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            itemCount: _items.length,
            itemBuilder: (context, index) {
              final item = _items[index];
              return CartItemTile(
                item: item,
                locale: _locale,
                onQuantityChanged: (qty) =>
                    _updateQuantity(item.productId, qty),
                onRemove: () => _removeItem(item.productId),
              );
            },
          ),
        ),

        // Free Delivery Banner (show progress OR achieved state)
        if (_isFreeDeliveryEnabled)
          FreeDeliveryBanner(remainingAmount: _remainingForFreeDelivery),
      ],
    );
  }

  Widget _buildCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _onCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deepOlive,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'cart.checkout'.tr(),
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  // Separator line
                  Container(
                    height: 16,
                    width: 1.5,
                    color: AppColors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(width: 12),
                  AppPriceDisplay(
                    price: _cartTotal,
                    textColor: AppColors.white,
                    scale: 1.1,
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _arrowAnimation,
                    builder: (context, child) {
                      // Move left for Arabic, right for others
                      final direction = _locale == 'ar' ? -1.0 : 1.0;
                      return Transform.translate(
                        offset: Offset(_arrowAnimation.value * direction, 0),
                        child: child,
                      );
                    },
                    child: Icon(
                      _locale == 'ar'
                          ? LucideIcons.arrowLeft
                          : LucideIcons.arrowRight,
                      size: 20,
                      color: AppColors.accentYellow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
