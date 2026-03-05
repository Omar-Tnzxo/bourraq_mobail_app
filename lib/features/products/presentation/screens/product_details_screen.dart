import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/notifiers/cart_badge_notifier.dart';
import 'package:bourraq/core/utils/guest_restriction_helper.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/favorites/data/repositories/favorites_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/features/products/data/models/product_model.dart';
import 'package:bourraq/features/products/data/repositories/product_repository.dart';
import 'package:bourraq/features/products/presentation/widgets/product_image_header.dart';
import 'package:bourraq/features/products/presentation/widgets/product_info_section.dart';
import 'package:bourraq/features/products/presentation/widgets/expandable_details_section.dart';
import 'package:bourraq/features/products/presentation/widgets/product_bottom_bar.dart';
import 'package:bourraq/features/products/presentation/widgets/notify_when_available_button.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/features/location/data/address_model.dart';
import 'package:bourraq/features/home/presentation/widgets/address_picker_bottom_sheet.dart';

/// Product Details Screen - Breadfast Style
/// Fetches product data dynamically from Supabase
class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ProductRepository _repository = ProductRepository();

  final AddressService _addressService = AddressService();

  Product? _product;
  List<Product> _relatedProducts = [];
  Map<String, String>? _category;
  Address? _defaultAddress;
  bool _isLoading = true;
  String? _error;

  num _quantity = 1;
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

    // Listen to cart changes for realtime updates
    _cartService.addListener(_loadQuantityFromCart);

    if (mounted) {
      // Load favorite status and default address
      final isFav = await _favoritesRepository.isFavorite(widget.productId);
      final address = await _addressService.getDefaultAddress();
      setState(() {
        _servicesInitialized = true;
        _isFavorite = isFav;
        _defaultAddress = address;
        _loadQuantityFromCart();
      });
    }
  }

  @override
  void dispose() {
    // Remove listener before disposing
    _cartService.removeListener(_loadQuantityFromCart);
    super.dispose();
  }

  void _loadQuantityFromCart() {
    if (!mounted || !_servicesInitialized) return;
    final items = _cartService.getCartItems();
    final cartItem = items
        .where((item) => item.productId == widget.productId)
        .firstOrNull;
    if (cartItem != null) {
      setState(() => _quantity = cartItem.quantity);
    }
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

      // Load category name if available
      Map<String, String>? category;
      if (product.categoryId != null) {
        category = await _repository.getCategoryById(product.categoryId!);

        // Load related products
        final related = await _repository.getRelatedProducts(
          categoryId: product.categoryId!,
          excludeProductId: widget.productId,
        );
        if (mounted) {
          setState(() => _relatedProducts = related);
        }
      }

      if (mounted) {
        setState(() {
          _product = product;
          _category = category;
          _isLoading = false;
        });
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

    // Optimistic UI update
    final previousState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);

    try {
      if (_isFavorite) {
        await _favoritesRepository.addToFavorites(widget.productId);
      } else {
        await _favoritesRepository.removeFromFavorites(widget.productId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite ? 'favorites.added'.tr() : 'favorites.removed'.tr(),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() => _isFavorite = previousState);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('common.error'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

    // Check if item already exists in cart
    final existingItems = _cartService.getCartItems();
    final existingItem = existingItems
        .where((i) => i.productId == widget.productId)
        .firstOrNull;

    if (existingItem != null) {
      // Item exists - update quantity (add 1 more)
      await _cartService.updateQuantity(
        widget.productId,
        existingItem.quantity + 1,
      );
    } else {
      // New item - add with quantity 1
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: widget.productId,
        nameAr: _product!.nameAr,
        nameEn: _product!.nameEn,
        price: _product!.price,
        quantity: 1.0,
        imageUrl: _product!.imageUrl,
      );
      await _cartService.addToCart(cartItem);
    }

    if (mounted) {
      context.read<CartBadgeNotifier>().refresh();
    }
  }

  void _incrementQuantity() {
    if (!_servicesInitialized) return;
    HapticFeedback.selectionClick();
    // Use updateQuantity for immediate cart update
    _cartService.updateQuantity(widget.productId, _quantity + 1);
  }

  void _decrementQuantity() {
    if (!_servicesInitialized) return;
    if (_quantity > 1) {
      HapticFeedback.selectionClick();
      // Use updateQuantity for immediate cart update
      _cartService.updateQuantity(widget.productId, _quantity - 1);
    } else if (_quantity == 1) {
      HapticFeedback.selectionClick();
      // Remove from cart when going below 1
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
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
          ? _buildErrorState()
          : _buildContent(isArabic),
      bottomNavigationBar: _product != null && !_isLoading
          ? ProductBottomBar(
              quantity: _quantity,
              unitPrice: _product!.price,
              oldPrice: _product!.oldPrice,
              isInStock: _product!.isInStock,
              onIncrement: _incrementQuantity,
              onDecrement: _decrementQuantity,
              onAddToCart: _addToCart,
            )
          : null,
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primaryGreen),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.circleAlert,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'product.loading_error'.tr(),
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadProduct,
              icon: const Icon(LucideIcons.refreshCw),
              label: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isArabic) {
    final productName = isArabic ? _product!.nameAr : _product!.nameEn;
    final description = isArabic
        ? _product!.descriptionAr
        : _product!.descriptionEn;
    final categoryName = _category != null
        ? (isArabic ? _category!['name_ar'] : _category!['name_en'])
        : null;

    return CustomScrollView(
      slivers: [
        // Image Header
        Consumer<CartBadgeNotifier>(
          builder: (context, cartNotifier, child) {
            return ProductImageHeader(
              imageUrl: _product!.imageUrl,
              cartCount: cartNotifier.count,
              onCartTap: () => context.push('/cart'),
            );
          },
        ),

        // Product Info Section
        SliverToBoxAdapter(
          child: ProductInfoSection(
            productName: productName,
            price: _product!.price,
            oldPrice: _product!.oldPrice,
            isInStock: _product!.isInStock,
            isFavorite: _isFavorite,
            weight: _product!.getLocalizedWeight(context.locale.languageCode),
            onFavoriteTap: _toggleFavorite,
          ),
        ),

        // Notify When Available Button (for out of stock products)
        SliverToBoxAdapter(
          child: NotifyWhenAvailableButton(
            productId: widget.productId,
            isOutOfStock: !_product!.isInStock,
          ),
        ),

        // Expandable Details Section
        SliverToBoxAdapter(
          child: ExpandableDetailsSection(
            description: description,
            title: 'product.product_details'.tr(),
          ),
        ),

        // Related Products Section
        if (_relatedProducts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Text(
                'product.similar_products'.tr(),
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.64,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = _relatedProducts[index];
                return ProductCard(
                  product: ProductItem(
                    id: product.id,
                    nameAr: product.nameAr,
                    nameEn: product.nameEn,
                    price: product.price,
                    oldPrice: product.oldPrice,
                    imageUrl: product.imageUrl ?? '',
                  ),
                  cartService: _servicesInitialized ? _cartService : null,
                  hasAddress: _defaultAddress != null,
                  onLocationRequired: _showLocationPrompt,
                  onTap: () => context.push('/product/${product.id}'),
                  onFavoriteTap: () async {
                    if (GuestRestrictionHelper.checkAndPromptLogin(context)) {
                      return;
                    }
                    try {
                      final isCurrentlyFavorite = await _favoritesRepository
                          .isFavorite(product.id);
                      if (isCurrentlyFavorite) {
                        await _favoritesRepository.removeFromFavorites(
                          product.id,
                        );
                      } else {
                        await _favoritesRepository.addToFavorites(product.id);
                      }
                    } catch (e) {
                      // Silent error for related products
                    }
                  },
                  isFavorite:
                      false, // Will be managed by ProductCard's internal state
                );
              }, childCount: _relatedProducts.length),
            ),
          ),
        ],

        // Bottom padding
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
