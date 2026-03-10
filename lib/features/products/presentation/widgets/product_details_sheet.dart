import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/notifiers/cart_badge_notifier.dart';
import 'package:bourraq/core/utils/guest_restriction_helper.dart';
import 'package:bourraq/core/services/analytics_service.dart';
import 'package:bourraq/core/widgets/app_price_display.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/favorites/data/repositories/favorites_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/features/products/data/models/product_model.dart';
import 'package:bourraq/features/products/data/repositories/product_repository.dart';
import 'package:bourraq/features/products/presentation/widgets/notify_when_available_button.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/features/location/data/address_model.dart';
import 'package:bourraq/features/home/presentation/widgets/address_picker_bottom_sheet.dart';

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
      elevation: 0, // Match BourraqBottomSheet.show
      useSafeArea: true,
      builder: (context) => ProductDetailsSheet(productId: productId),
    );
  }

  @override
  State<ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<ProductDetailsSheet> {
  final ProductRepository _repository = ProductRepository();
  final AddressService _addressService = AddressService();

  Product? _product;
  Address? _defaultAddress;
  List<Product> _relatedProducts = [];
  bool _isLoading = true;
  String? _error;

  num _quantity = 0;
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

    final isFav = await _favoritesRepository.isFavorite(widget.productId);
    final address = await _addressService.getDefaultAddress();

    if (!mounted) return;

    setState(() {
      _servicesInitialized = true;
      _isFavorite = isFav;
      _defaultAddress = address;
    });

    // Reload product now that we have the address/area, to get correct price/availability
    _loadProduct();
    _loadQuantityFromCart();
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
    if (!mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final product = await _repository.getProductById(
        widget.productId,
        areaId: _defaultAddress?.areaId,
      );

      if (product == null) {
        if (mounted) {
          setState(() {
            _error = 'product.loading_error'.tr();
            _isLoading = false;
          });
        }
        return;
      }

      if (product.subCategoryId != null || product.categoryId != null) {
        final related = await _repository.getRelatedProducts(
          subCategoryId: product.subCategoryId,
          categoryId: product.categoryId,
          excludeProductId: widget.productId,
          areaId: _defaultAddress?.areaId,
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
        await _favoritesRepository.addToFavorites(
          widget.productId,
          branchId: _product?.branchId,
        );
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

    // 1. Check if guest - block action and show login prompt
    if (GuestRestrictionHelper.checkAndPromptLogin(context)) return;

    // 2. Check if location is required
    if (_defaultAddress == null) {
      _showLocationPrompt();
      return;
    }

    HapticFeedback.mediumImpact();

    final existingItems = _cartService.getCartItems();
    final existingItem = existingItems
        .where((i) => i.productId == widget.productId)
        .firstOrNull;

    if (existingItem != null) {
      await _cartService.updateQuantity(
        widget.productId,
        (existingItem.quantity + 1).toDouble(),
      );
    } else {
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: widget.productId,
        nameAr: _product!.nameAr,
        nameEn: _product!.nameEn,
        price: _product!.price, // Still use this as base price
        quantity: 1.0,
        imageUrl: _product!.imageUrl,
        branchId: _product!.branchId,
        branchProductId: _product!.branchProductId,
        customerPrice: _product!.price, // Explicitly pass as customer price
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

  void _showLocationPrompt() {
    AddressPickerBottomSheet.show(
      context: context,
      currentAddress: _defaultAddress,
      onAddressSelected: (address) async {
        final success = await _addressService.setDefaultAddress(address.id);
        if (success && mounted) {
          setState(() {
            _defaultAddress = address;
          });
          // Note: Home screen will refresh when this sheet closes if we trigger it
        }
      },
    ).then((_) {
      // Re-load default address to be sure
      _addressService.getDefaultAddress().then((address) {
        if (mounted) setState(() => _defaultAddress = address);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_product == null && !_isLoading && _error == null) {
      return const SizedBox.shrink();
    }

    final isArabic = context.locale.languageCode == 'ar';
    final productName = _product != null
        ? (isArabic ? _product!.nameAr : _product!.nameEn)
        : '';

    return BourraqBottomSheet(
      title: productName,
      maxHeightMultiplier: 0.95,
      actions: _product != null ? [_buildBottomBarContent()] : null,
      child: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.1),
      highlightColor: Colors.white.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 24),
          // Title placeholder
          Container(height: 24, width: 200, color: Colors.white),
          const SizedBox(height: 12),
          // Price placeholder
          Container(height: 32, width: 120, color: Colors.white),
          const SizedBox(height: 24),
          // Description placeholder
          Container(height: 100, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.circleAlert,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _error ?? 'product.loading_error'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            BourraqButton(
              label: 'common.retry'.tr(),
              icon: LucideIcons.refreshCw,
              onPressed: _loadProduct,
              backgroundColor: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final isArabic = context.locale.languageCode == 'ar';
    final description = isArabic
        ? _product!.descriptionAr
        : _product!.descriptionEn;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        _buildProductImage(),

        const SizedBox(height: 20),

        // Product Info
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? _product!.nameAr : _product!.nameEn,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  if (_product!.weightValue != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _product!.getLocalizedWeight(context.locale.languageCode),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _toggleFavorite,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: _isFavorite ? 1.0 : 0.05,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isFavorite
                        ? AppColors.error
                        : Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? AppColors.error : Colors.white70,
                  size: 24,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Price Row with Stock Status
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppPriceDisplay(
              price: _product!.price,
              oldPrice: _product!.oldPrice,
              textColor: AppColors.accentYellow,
              scale: 1.6,
            ),
            const Spacer(),
            // Stock status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _product!.isInStock
                    ? AppColors.primaryGreen.withValues(alpha: 0.15)
                    : AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _product!.isInStock
                      ? AppColors.primaryGreen.withValues(alpha: 0.3)
                      : AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _product!.isInStock
                          ? AppColors.primaryGreen
                          : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _product!.isInStock
                        ? 'product.in_stock'.tr()
                        : 'product.out_of_stock'.tr(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _product!.isInStock
                          ? AppColors.primaryGreen
                          : AppColors.error,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Notify When Available
        NotifyWhenAvailableButton(
          productId: widget.productId,
          isOutOfStock: !_product!.isInStock,
        ),

        // Description
        if (description != null && description.isNotEmpty)
          _buildDescriptionSection(description),

        if (_relatedProducts.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text(
            'product.similar_products'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildRelatedProducts(),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDescriptionSection(String description) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.textSelect,
                color: AppColors.accentYellow,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'product.product_details'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedProducts() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.58,
      ),
      itemCount: _relatedProducts.length,
      itemBuilder: (context, index) {
        final product = _relatedProducts[index];
        return ProductCard(
          product: product.toProductItem(),
          cartService: _servicesInitialized ? _cartService : null,
          hasAddress: _defaultAddress != null,
          onLocationRequired: _showLocationPrompt,
          onTap: () {
            Navigator.pop(context);
            ProductDetailsSheet.show(context, product.id);
          },
        );
      },
    );
  }

  Widget _buildProductImage() {
    final isArabic = context.locale.languageCode == 'ar';
    final hasDiscount =
        _product?.oldPrice != null && _product!.oldPrice! > _product!.price;
    final discountPercent = hasDiscount
        ? ((_product!.oldPrice! - _product!.price) / _product!.oldPrice! * 100)
              .round()
        : 0;

    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          // Image
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _product?.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _product!.imageUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      errorWidget: (_, _, _) => const Center(
                        child: Icon(
                          LucideIcons.image,
                          size: 48,
                          color: Colors.white24,
                        ),
                      ),
                    )
                  : const Icon(
                      LucideIcons.image,
                      size: 48,
                      color: Colors.white24,
                    ),
            ),
          ),
          // Discount badge
          if (hasDiscount)
            Positioned(
              top: 16,
              left: isArabic ? null : 16,
              right: isArabic ? 16 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  '-$discountPercent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBarContent() {
    final isInStock = _product?.isInStock ?? false;
    final totalPrice = _product!.price * (_quantity > 0 ? _quantity : 1);

    return Row(
      children: [
        // Price summary
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _quantity > 0 ? 'product.total'.tr() : 'product.price'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                AppPriceDisplay(
                  price: totalPrice,
                  textColor: Colors.white,
                  scale: 1.25,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Quantity counter or Add button
        Expanded(
          flex: 3,
          child: _quantity > 0
              ? _buildBrandedQuantityCounter()
              : BourraqButton(
                  label: 'product.add_to_cart'.tr(),
                  icon: LucideIcons.shoppingBasket,
                  onPressed: isInStock ? _addToCart : null,
                  backgroundColor: isInStock
                      ? AppColors.accentYellow
                      : Colors.white10,
                  foregroundColor: isInStock
                      ? AppColors.deepOlive
                      : Colors.white38,
                ),
        ),
      ],
    );
  }

  Widget _buildBrandedQuantityCounter() {
    return Container(
      height: 56, // Match BourraqButton height
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _decrementQuantity,
            icon: const Icon(LucideIcons.minus, color: Colors.white, size: 22),
          ),
          Text(
            '\u200E${_quantity % 1 == 0 ? _quantity.toInt() : _quantity}\u200E',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          IconButton(
            onPressed: _incrementQuantity,
            icon: const Icon(LucideIcons.plus, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}
