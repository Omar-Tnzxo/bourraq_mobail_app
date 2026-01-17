import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/notifiers/cart_badge_notifier.dart';
import 'package:bourraq/core/utils/guest_restriction_helper.dart';
import 'package:bourraq/core/services/analytics_service.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/favorites/data/repositories/favorites_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/features/products/data/models/product_model.dart';
import 'package:bourraq/features/products/data/repositories/product_repository.dart';
import 'package:bourraq/features/products/presentation/widgets/expandable_details_section.dart';
import 'package:bourraq/features/products/presentation/widgets/notify_when_available_button.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';

/// Show product details in a draggable bottom sheet
/// Usage: ProductDetailsSheet.show(context, productId);
class ProductDetailsSheet extends StatefulWidget {
  final String productId;

  const ProductDetailsSheet({super.key, required this.productId});

  /// Static method to show the sheet
  static Future<void> show(BuildContext context, String productId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => ProductDetailsSheet(productId: productId),
    );
  }

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  final ProductRepository _repository = ProductRepository();

  Product? _product;
  List<Product> _relatedProducts = [];
  bool _isLoading = true;
  String? _error;

  int _quantity = 0;
  bool _isFavorite = false;

  late CartService _cartService;
  late FavoritesRepository _favoritesRepository;
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    _initServices();
    _loadProduct();
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _cartService = CartService(prefs);
    _favoritesRepository = FavoritesRepository(Supabase.instance.client);

    _cartService.addListener(_loadQuantityFromCart);

    if (mounted) {
      final isFav = await _favoritesRepository.isFavorite(widget.productId);
      setState(() {
        _servicesInitialized = true;
        _isFavorite = isFav;
        _loadQuantityFromCart();
      });
    }
  }

  @override
  void dispose() {
    if (_servicesInitialized) {
      _cartService.removeListener(_loadQuantityFromCart);
    }
    super.dispose();
  }

  void _loadQuantityFromCart() {
    if (!mounted || !_servicesInitialized) return;
    final items = _cartService.getCartItems();
    final cartItem = items
        .where((item) => item.productId == widget.productId)
        .firstOrNull;
    setState(() => _quantity = cartItem?.quantity ?? 0);
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final product = await _repository.getProductById(widget.productId);

      if (product == null) {
        setState(() {
          _error = 'product.loading_error'.tr();
          _isLoading = false;
        });
        return;
      }

      if (product.categoryId != null) {
        final related = await _repository.getRelatedProducts(
          categoryId: product.categoryId!,
          excludeProductId: widget.productId,
        );
        if (mounted) setState(() => _relatedProducts = related);
      }

      if (mounted) {
        setState(() {
          _product = product;
          _isLoading = false;
        });

        // Track product view
        AnalyticsService().trackProductView(
          productId: product.id,
          productName: product.nameEn,
          category: product.categoryId,
          price: product.price,
          discountPercent: product.oldPrice != null
              ? ((product.oldPrice! - product.price) / product.oldPrice! * 100)
              : null,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'product.loading_error'.tr();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (!_servicesInitialized) return;
    if (GuestRestrictionHelper.checkAndPromptLogin(context)) return;

    HapticFeedback.selectionClick();
    final previousState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);

    try {
      if (_isFavorite) {
        await _favoritesRepository.addToFavorites(widget.productId);
        // Track add to favorites
        AnalyticsService().trackAddToFavorites(
          productId: widget.productId,
          productName: _product?.nameEn ?? '',
        );
      } else {
        await _favoritesRepository.removeFromFavorites(widget.productId);
        // Track remove from favorites
        AnalyticsService().trackRemoveFromFavorites(
          productId: widget.productId,
          productName: _product?.nameEn ?? '',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _isFavorite = previousState);
    }
  }

  Future<void> _addToCart() async {
    if (!_servicesInitialized || _product == null) return;
    if (GuestRestrictionHelper.checkAndPromptLogin(context)) return;

    HapticFeedback.mediumImpact();

    final existingItems = _cartService.getCartItems();
    final existingItem = existingItems
        .where((i) => i.productId == widget.productId)
        .firstOrNull;

    if (existingItem != null) {
      await _cartService.updateQuantity(
        widget.productId,
        existingItem.quantity + 1,
      );
    } else {
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: widget.productId,
        nameAr: _product!.nameAr,
        nameEn: _product!.nameEn,
        price: _product!.price,
        quantity: 1,
        imageUrl: _product!.imageUrl,
      );
      await _cartService.addToCart(cartItem);
    }

    if (mounted) context.read<CartBadgeNotifier>().refresh();
  }

  void _incrementQuantity() {
    if (!_servicesInitialized) return;
    HapticFeedback.selectionClick();
    _addToCart();
  }

  void _decrementQuantity() {
    if (!_servicesInitialized) return;
    if (_quantity > 1) {
      HapticFeedback.selectionClick();
      _cartService.updateQuantity(widget.productId, _quantity - 1);
    } else if (_quantity == 1) {
      HapticFeedback.selectionClick();
      _cartService.removeFromCart(widget.productId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              _buildHandle(),
              // Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _error != null
                    ? _buildErrorState()
                    : _buildContent(scrollController),
              ),
              // Bottom Bar
              if (_product != null && !_isLoading) _buildBottomBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          // Close button (X)
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(LucideIcons.x),
            color: const Color(0xFF113511),
            iconSize: 24,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          // Handle bar in center
          Expanded(
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Cart icon with badge
          _buildCartIcon(),
        ],
      ),
    );
  }

  Widget _buildCartIcon() {
    return Consumer<CartBadgeNotifier>(
      builder: (context, cartNotifier, _) {
        final itemCount = cartNotifier.count;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
              context.push('/cart');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    LucideIcons.shoppingBasket,
                    size: 24,
                    color: AppColors.deepOlive,
                  ),
                  if (itemCount > 0)
                    Positioned(
                      right: -8,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          itemCount > 99 ? '99+' : '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 20),
            // Title placeholder
            Container(height: 24, width: 200, color: Colors.white),
            const SizedBox(height: 12),
            // Price placeholder
            Container(height: 32, width: 120, color: Colors.white),
            const SizedBox(height: 20),
            // Description placeholder
            Container(height: 100, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.circleAlert, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error ?? 'product.loading_error'.tr(),
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProduct,
              icon: const Icon(LucideIcons.refreshCw),
              label: Text('common.retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    final isArabic = context.locale.languageCode == 'ar';
    final productName = isArabic ? _product!.nameAr : _product!.nameEn;
    final description = isArabic
        ? _product!.descriptionAr
        : _product!.descriptionEn;

    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        // Product Image
        _buildProductImage(),

        // Product Info
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and favorite
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      productName,
                      style: AppTextStyles.titleLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleFavorite,
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite
                          ? const Color(0xFFE02E4C)
                          : AppColors.textSecondary,
                      size: 28,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Price Row with Stock Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Price (styled like ProductCard)
                  Text(
                    _product!.price.floor().toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepOlive,
                      height: 1,
                    ),
                  ),
                  Text(
                    '.${((_product!.price - _product!.price.floor()) * 100).round().toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.deepOlive,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'common.egp'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  if (_product!.oldPrice != null) ...[
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${_product!.oldPrice!.toStringAsFixed(2)} ${'common.egp'.tr()}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Stock status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _product!.isInStock
                          ? AppColors.primaryGreen.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _product!.isInStock
                          ? 'product.in_stock'.tr()
                          : 'product.out_of_stock'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _product!.isInStock
                            ? AppColors.primaryGreen
                            : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Notify When Available
        NotifyWhenAvailableButton(
          productId: widget.productId,
          isOutOfStock: !_product!.isInStock,
        ),

        // Description
        if (description != null && description.isNotEmpty)
          ExpandableDetailsSection(
            description: description,
            title: 'product.product_details'.tr(),
          ),

        // Related Products
        if (_relatedProducts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'product.similar_products'.tr(),
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _relatedProducts.length,
              itemBuilder: (context, index) {
                final product = _relatedProducts[index];
                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  child: ProductCard(
                    product: ProductItem(
                      id: product.id,
                      nameAr: product.nameAr,
                      nameEn: product.nameEn,
                      price: product.price,
                      oldPrice: product.oldPrice,
                      imageUrl: product.imageUrl ?? '',
                    ),
                    cartService: _servicesInitialized ? _cartService : null,
                    onTap: () {
                      Navigator.pop(context);
                      ProductDetailsSheet.show(context, product.id);
                    },
                  ),
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: _product?.imageUrl != null
          ? CachedNetworkImage(
              imageUrl: _product!.imageUrl!,
              fit: BoxFit.contain,
              placeholder: (_, __) => const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              ),
              errorWidget: (_, __, ___) => const Center(
                child: Icon(
                  LucideIcons.image,
                  size: 48,
                  color: AppColors.textLight,
                ),
              ),
            )
          : const Center(
              child: Icon(
                LucideIcons.image,
                size: 48,
                color: AppColors.textLight,
              ),
            ),
    );
  }

  Widget _buildBottomBar() {
    final isInStock = _product?.isInStock ?? false;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Price summary
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _quantity > 0 ? 'product.total'.tr() : 'product.price'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Builder(
                      builder: (context) {
                        final totalPrice =
                            _product!.price * (_quantity > 0 ? _quantity : 1);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              totalPrice.floor().toString(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.deepOlive,
                                height: 1,
                              ),
                            ),
                            Text(
                              '.${((totalPrice - totalPrice.floor()) * 100).round().toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.deepOlive,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'common.egp'.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Quantity counter or Add button
          _quantity > 0 ? _buildQuantityCounter() : _buildAddButton(isInStock),
        ],
      ),
    );
  }

  Widget _buildAddButton(bool isInStock) {
    return Material(
      color: isInStock ? AppColors.primaryGreen : Colors.grey[300],
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isInStock ? _addToCart : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.shoppingBasket,
                size: 20,
                color: isInStock ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'product.add_to_cart'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isInStock ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build price with smaller decimals
  Widget _buildFormattedPrice(double price, double fontSize) {
    final parts = price.toStringAsFixed(2).split('.');
    final wholePart = parts[0];
    final decimalPart = parts[1];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          wholePart,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: AppColors.deepOlive,
          ),
        ),
        Text(
          '.$decimalPart',
          style: TextStyle(
            fontSize: fontSize * 0.55,
            fontWeight: FontWeight.w700,
            color: AppColors.deepOlive,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityCounter() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepOlive,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _decrementQuantity,
            icon: const Icon(LucideIcons.minus, color: Colors.white, size: 20),
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '$_quantity',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _incrementQuantity,
            icon: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
