import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/notifiers/cart_badge_notifier.dart';
import 'package:bourraq/core/utils/guest_restriction_helper.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';

/// Product Card Widget - Grabit Style
/// Features: image with quantity counter overlay, discount badge, favorite icon
/// Now a StatefulWidget with built-in cart management and animations
class ProductCard extends StatefulWidget {
  final ProductItem product;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final CartService? cartService;
  final VoidCallback? onCartUpdated;

  const ProductCard({
    super.key,
    required this.product,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
    this.cartService,
    this.onCartUpdated,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  int _quantity = 0;
  late bool _isFavorite;
  AnimationController? _scaleController;
  Animation<double>? _scaleAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
    _initAnimation();
    _loadQuantity();
    // Listen to cart changes for realtime updates
    widget.cartService?.addListener(_loadQuantity);
  }

  void _initAnimation() {
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _scaleController!, curve: Curves.easeInOut),
    );
    _isInitialized = true;
  }

  @override
  void dispose() {
    // Remove listener before disposing
    widget.cartService?.removeListener(_loadQuantity);
    _scaleController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFavorite != widget.isFavorite) {
      setState(() => _isFavorite = widget.isFavorite);
    }
    // Handle cartService change
    if (oldWidget.cartService != widget.cartService) {
      oldWidget.cartService?.removeListener(_loadQuantity);
      widget.cartService?.addListener(_loadQuantity);
      _loadQuantity();
    }
  }

  void _loadQuantity() {
    if (!mounted) return;
    if (widget.cartService != null) {
      final items = widget.cartService!.getCartItems();
      final cartItem = items
          .where((item) => item.productId == widget.product.id)
          .firstOrNull;
      setState(() => _quantity = cartItem?.quantity ?? 0);
    }
  }

  void _animateTap() {
    if (_isInitialized && _scaleController != null) {
      _scaleController!.forward().then((_) {
        if (mounted) _scaleController?.reverse();
      });
    }
  }

  Future<void> _incrementQuantity() async {
    // Check if guest - block action and show login prompt
    if (GuestRestrictionHelper.checkAndPromptLogin(context)) return;

    HapticFeedback.mediumImpact();
    if (widget.cartService == null) return;

    _animateTap();

    if (_quantity == 0) {
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: widget.product.id,
        nameAr: widget.product.nameAr,
        nameEn: widget.product.nameEn,
        price: widget.product.price,
        quantity: 1,
        imageUrl: widget.product.imageUrl,
      );
      await widget.cartService!.addToCart(cartItem);
    } else {
      await widget.cartService!.updateQuantity(
        widget.product.id,
        _quantity + 1,
      );
    }

    if (!mounted) return;
    setState(() => _quantity++);
    widget.onCartUpdated?.call();
    // Update cart badge in real-time
    context.read<CartBadgeNotifier>().refresh();
  }

  Future<void> _decrementQuantity() async {
    HapticFeedback.lightImpact();
    if (widget.cartService == null || _quantity <= 0) return;

    _animateTap();

    if (_quantity == 1) {
      await widget.cartService!.removeFromCart(widget.product.id);
      if (!mounted) return;
      setState(() => _quantity = 0);
    } else {
      await widget.cartService!.updateQuantity(
        widget.product.id,
        _quantity - 1,
      );
      if (!mounted) return;
      setState(() => _quantity--);
    }

    widget.onCartUpdated?.call();
    // Update cart badge in real-time
    context.read<CartBadgeNotifier>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final productName = isArabic
        ? widget.product.nameAr
        : widget.product.nameEn;
    final hasDiscount =
        widget.product.oldPrice != null &&
        widget.product.oldPrice! > widget.product.price;
    final discountPercent = hasDiscount
        ? ((widget.product.oldPrice! - widget.product.price) /
                  widget.product.oldPrice! *
                  100)
              .round()
        : 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageHeight = constraints.maxHeight * 0.55;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                SizedBox(
                  height: imageHeight,
                  child: Stack(
                    children: [
                      // Product image
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: widget.product.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.product.imageUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) => _buildPlaceholder(),
                                  errorWidget: (_, __, ___) =>
                                      _buildPlaceholder(),
                                )
                              : _buildPlaceholder(),
                        ),
                      ),
                      // Discount badge
                      if (hasDiscount)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-$discountPercent%',
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      // Favorite button
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Material(
                          color: AppColors.white,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () {
                              // Check if guest - block action and show login prompt
                              if (GuestRestrictionHelper.checkAndPromptLogin(
                                context,
                              ))
                                return;
                              HapticFeedback.selectionClick();
                              setState(() => _isFavorite = !_isFavorite);
                              widget.onFavoriteTap?.call();
                            },
                            customBorder: const CircleBorder(),
                            splashColor: AppColors.error.withValues(alpha: 0.2),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.border.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Icon(
                                _isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _isFavorite
                                    ? AppColors.error
                                    : AppColors.textLight,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Quantity counter or Add button
                      Positioned(
                        bottom: 8,
                        right: 8,
                        left: _quantity > 0 ? 8 : null,
                        child: _quantity > 0
                            ? _buildQuantityCounter()
                            : _buildAddButton(),
                      ),
                    ],
                  ),
                ),
                // Info Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount)
                              Text(
                                '${widget.product.oldPrice!.toStringAsFixed(2)} ${'common.currency_short'.tr()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Row(
                              children: [
                                Text(
                                  widget.product.price.floor().toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deepOlive,
                                  ),
                                ),
                                Text(
                                  '.${((widget.product.price - widget.product.price.floor()) * 100).round().toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.deepOlive,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'common.currency_short'.tr(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Quantity counter [ - ] 1 [ + ] with animations
  Widget _buildQuantityCounter() {
    if (_scaleAnimation == null || !_isInitialized) {
      return _buildQuantityCounterContent();
    }

    return AnimatedBuilder(
      animation: _scaleAnimation!,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation!.value, child: child);
      },
      child: _buildQuantityCounterContent(),
    );
  }

  Widget _buildQuantityCounterContent() {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.deepOlive,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minus button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _decrementQuantity,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  LucideIcons.minus,
                  color: AppColors.lightGreen,
                  size: 18,
                ),
              ),
            ),
          ),
          // Animated quantity number
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Text(
              '$_quantity',
              key: ValueKey<int>(_quantity),
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Plus button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _incrementQuantity,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16),
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: Icon(
                  LucideIcons.plus,
                  color: AppColors.lightGreen,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple add button
  Widget _buildAddButton() {
    return Material(
      color: AppColors.deepOlive,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: AppColors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: _incrementQuantity,
        customBorder: const CircleBorder(),
        splashColor: AppColors.white.withValues(alpha: 0.3),
        highlightColor: AppColors.white.withValues(alpha: 0.1),
        child: const SizedBox(
          width: 32,
          height: 32,
          child: Icon(LucideIcons.plus, color: AppColors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(LucideIcons.image, size: 32, color: AppColors.textLight),
      ),
    );
  }
}

/// Product model for ProductCard
class ProductItem {
  final String id;
  final String nameAr;
  final String nameEn;
  final double price;
  final double? oldPrice;
  final String imageUrl;
  final bool isAvailable;

  const ProductItem({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.price,
    this.oldPrice,
    required this.imageUrl,
    this.isAvailable = true,
  });

  /// Create ProductItem from a Map (useful for Supabase data)
  factory ProductItem.fromMap(
    Map<String, dynamic> map, {
    bool isArabic = false,
  }) {
    return ProductItem(
      id: map['id'] as String? ?? '',
      nameAr: map['name_ar'] as String? ?? map['name_en'] as String? ?? '',
      nameEn: map['name_en'] as String? ?? map['name_ar'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      oldPrice: (map['old_price'] as num?)?.toDouble(),
      imageUrl: map['image_url'] as String? ?? '',
      isAvailable: map['in_stock'] as bool? ?? true,
    );
  }
}
