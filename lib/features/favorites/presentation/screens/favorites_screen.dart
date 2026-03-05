import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/router/app_router.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:bourraq/features/products/data/models/product_model.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/products/presentation/widgets/product_details_sheet.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/features/location/data/address_model.dart';
import 'package:bourraq/features/home/presentation/widgets/address_picker_bottom_sheet.dart';
import 'package:shimmer/shimmer.dart';

/// Favorites Screen - Using unified ProductCard widget
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  CartService? _cartService;
  final AddressService _addressService = AddressService();
  Address? _defaultAddress;

  @override
  void initState() {
    super.initState();
    context.read<FavoritesCubit>().loadFavorites();
    _initCartService();
    _loadDefaultAddress();
  }

  Future<void> _loadDefaultAddress() async {
    final address = await _addressService.getDefaultAddress();
    if (mounted) {
      setState(() {
        _defaultAddress = address;
      });
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
      _loadDefaultAddress();
    });
  }

  void _initCartService() {
    try {
      _cartService = CartService.instance;
      _cartService?.addListener(_onCartUpdate);
    } catch (_) {
      _cartService = null;
    }
  }

  void _onCartUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cartService?.removeListener(_onCartUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final cartCount = _cartService?.getCartItemCount() ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          BourraqHeader(
            child: Row(
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title
                Expanded(
                  child: Text(
                    'favorites.title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                // Cart Button
                GestureDetector(
                  onTap: () => context.push('/cart'),
                  child: Badge(
                    isLabelVisible: cartCount > 0,
                    label: Text(
                      '$cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: const Color(
                      0xFFE02E4C,
                    ), // Use favorite red for badge
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.shoppingBasket,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(slivers: [_buildHeader(), _buildContent()]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoaded && state.favorites.isNotEmpty) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE02E4C).withValues(alpha: 0.1),
                    const Color(0xFFE02E4C).withValues(alpha: 0.02),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE02E4C).withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE02E4C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.heartHandshake,
                      color: Color(0xFFE02E4C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'favorites.saved_products'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'favorites.products_count'.tr(
                            namedArgs: {
                              'count': state.favorites.length.toString(),
                            },
                          ),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent() {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        if (state is FavoritesLoading) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildShimmerGrid(),
          );
        }

        if (state is FavoritesError) {
          return SliverFillRemaining(
            child: _buildErrorState(context, state.message),
          );
        }

        if (state is FavoritesLoaded) {
          if (state.favorites.isEmpty) {
            return SliverFillRemaining(child: _buildEmptyState(context));
          }

          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.64,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = state.favorites[index];
                return _buildProductCard(product, state.processingIds);
              }, childCount: state.favorites.length),
            ),
          );
        }

        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  /// Uses the unified ProductCard widget
  Widget _buildProductCard(Product product, Set<String> processingIds) {
    return ProductCard(
      product: product.toProductItem(),
      isFavorite: true, // All items in favorites are favorited
      cartService: _cartService,
      onTap: () => ProductDetailsSheet.show(context, product.id),
      onFavoriteTap: () {
        // Remove from favorites
        context.read<FavoritesCubit>().removeFavorite(product.id);
      },
      hasAddress: _defaultAddress != null,
      onLocationRequired: _showLocationPrompt,
      onCartUpdated: () => setState(() {}),
    );
  }

  SliverGrid _buildShimmerGrid() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.64,
      ),
      delegate: SliverChildBuilderDelegate((context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          period: const Duration(milliseconds: 1500),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }, childCount: 6),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFE02E4C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.heartCrack,
                size: 56,
                color: const Color(0xFFE02E4C).withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'favorites.empty'.tr(),
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'favorites.empty_message'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => AppRouter.router.go('/home'),
              icon: const Icon(LucideIcons.shoppingBag),
              label: Text('favorites.browse_products'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.cloudOff,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'common.error'.tr(),
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message.tr(),
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<FavoritesCubit>().loadFavorites(),
              icon: const Icon(LucideIcons.refreshCw),
              label: Text('common.retry'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
