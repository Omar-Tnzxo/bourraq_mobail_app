import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';
import 'package:bourraq/features/home/presentation/cubit/home_cubit.dart';
import 'package:bourraq/features/home/presentation/widgets/home_header.dart';
import 'package:bourraq/features/home/presentation/widgets/home_banners_carousel.dart';
import 'package:bourraq/features/home/presentation/widgets/home_categories_section.dart';
import 'package:bourraq/features/home/presentation/widgets/home_products_section.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/home/presentation/widgets/address_picker_bottom_sheet.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/features/location/data/address_model.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/favorites/data/repositories/favorites_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:bourraq/features/products/presentation/widgets/product_details_sheet.dart';

/// Home Tab Screen - Main scrollable content
/// Connected to Supabase via HomeCubit
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with WidgetsBindingObserver {
  late HomeCubit _homeCubit;
  final AddressService _addressService = AddressService();
  CartService? _cartService;
  late FavoritesRepository _favoritesRepository;
  final Set<String> _favoriteIds = {};

  // Dynamic user data
  Address? _defaultAddress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _homeCubit = HomeCubit();
    _homeCubit.loadHomeData();
    _loadDefaultAddress();
    _initServices();
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _cartService = CartService(prefs);
    _favoritesRepository = FavoritesRepository(Supabase.instance.client);

    // Load favorite IDs from Supabase
    await _loadFavoriteIds();

    if (mounted) setState(() {});
  }

  Future<void> _loadFavoriteIds() async {
    try {
      final favorites = await _favoritesRepository.getFavorites();
      if (mounted) {
        setState(() {
          _favoriteIds.clear();
          _favoriteIds.addAll(favorites.map((p) => p.id));
        });
      }
    } catch (e) {
      // Silent error - favorites will just not be highlighted
    }
  }

  void _updateCartCount() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload address when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      _loadDefaultAddress();
      _updateCartCount();
    }
  }

  Future<void> _loadDefaultAddress() async {
    try {
      final address = await _addressService.getDefaultAddress();
      if (mounted) {
        setState(() {
          _defaultAddress = address;
        });
      }
    } catch (e) {
      // Silently fail - will show fallback text
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _homeCubit.close();
    super.dispose();
  }

  Future<void> _toggleFavorite(ProductItem product) async {
    // Optimistic UI update
    final wasInFavorites = _favoriteIds.contains(product.id);
    setState(() {
      if (wasInFavorites) {
        _favoriteIds.remove(product.id);
      } else {
        _favoriteIds.add(product.id);
      }
    });

    // Sync with Supabase
    try {
      if (wasInFavorites) {
        await _favoritesRepository.removeFromFavorites(product.id);
      } else {
        await _favoritesRepository.addToFavorites(product.id);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          if (wasInFavorites) {
            _favoriteIds.add(product.id);
          } else {
            _favoriteIds.remove(product.id);
          }
        });
      }
    }
  }

  void _onLocationTap() {
    AddressPickerBottomSheet.show(
      context: context,
      currentAddress: _defaultAddress,
      onAddressSelected: (address) async {
        // Save the selected address as default in database
        final success = await _addressService.setDefaultAddress(address.id);
        if (success && mounted) {
          setState(() {
            _defaultAddress = address;
          });
        }
      },
    ).then((_) {
      // Reload address after bottom sheet is closed (in case user added/managed addresses)
      _loadDefaultAddress();
    });
  }

  void _onBannerTap(BannerItem banner) {
    if (banner.actionUrl != null && banner.actionUrl!.isNotEmpty) {
      if (banner.isExternal) {
        // TODO: Open external URL
      } else {
        context.push(banner.actionUrl!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeCubit,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  // Header (Rabbit-style) - Pinned outside RefreshIndicator
                  SliverToBoxAdapter(
                    child: BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        // Get user name from AuthCubit
                        String userName = '';
                        if (authState is AuthAuthenticated) {
                          userName = authState.name;
                        }

                        // Get location name from default address
                        String locationName =
                            _defaultAddress?.addressLabel ??
                            'home.select_location'.tr();

                        return HomeHeader(
                          userName: userName,
                          locationName: locationName,
                          onLocationTap: _onLocationTap,
                        );
                      },
                    ),
                  ),
                ];
              },
              // RefreshIndicator only wraps the body content (below header)
              body: RefreshIndicator(
                onRefresh: () => _homeCubit.refresh(),
                color: AppColors.deepOlive,
                child: CustomScrollView(
                  slivers: [
                    // Main Content based on state
                    if (state is HomeLoading) ...[
                      _buildLoadingState(),
                    ] else if (state is HomeError) ...[
                      _buildErrorState(state.message),
                    ] else if (state is HomeLoaded) ...[
                      // Dynamic sections based on DB config
                      ..._buildDynamicSections(state),
                    ] else ...[
                      // Initial state - show loading
                      _buildLoadingState(),
                    ],

                    // Bottom Spacing
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banners shimmer
            _buildShimmerBox(height: 160),
            const SizedBox(height: 24),
            // Categories title shimmer
            _buildShimmerBox(width: 120, height: 24),
            const SizedBox(height: 16),
            // Categories grid shimmer
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => _buildShimmerBox(),
            ),
            const SizedBox(height: 24),
            // Products title shimmer
            _buildShimmerBox(width: 150, height: 24),
            const SizedBox(height: 16),
            // Products grid shimmer
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => _buildShimmerBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBox({double? width, double? height}) {
    return Shimmer.fromColors(
      baseColor: AppColors.skeletonBase,
      highlightColor: AppColors.skeletonHighlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    // The message is now a translation key from ErrorHandler
    final displayMessage = message.tr();

    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circleAlert, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text('common.error'.tr(), style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                displayMessage,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _homeCubit.loadHomeData(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepOlive,
                ),
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build dynamic sections based on DB configuration
  List<Widget> _buildDynamicSections(HomeLoaded state) {
    final isArabic = context.locale.languageCode == 'ar';
    final List<Widget> slivers = [];

    for (final section in state.sections) {
      switch (section.sectionType) {
        case 'banners':
          final banners = state.getBanners(section.id);
          if (banners.isNotEmpty) {
            slivers.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: HomeBannersCarousel(
                    banners: banners,
                    onBannerTap: _onBannerTap,
                    autoScroll: section.config.autoScroll,
                    autoScrollIntervalMs: section.config.scrollIntervalMs,
                  ),
                ),
              ),
            );
          }
          break;

        case 'categories':
          final categories = state.getCategories(section.id);
          if (categories.isNotEmpty) {
            slivers.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: HomeCategoriesSection(
                    categories: categories,
                    title: section.config.showTitle
                        ? section.getTitle(isArabic ? 'ar' : 'en')
                        : null,
                  ),
                ),
              ),
            );
          }
          break;

        case 'products':
          final products = state.getProducts(section.id);
          if (products.isNotEmpty) {
            slivers.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: HomeProductsSection(
                    title: section.getTitle(isArabic ? 'ar' : 'en'),
                    products: products,
                    seeAllRoute: section.config.showSeeAll
                        ? section.config.seeAllRoute
                        : null,
                    favoriteIds: _favoriteIds,
                    cartService: _cartService,
                    onCartUpdated: _updateCartCount,
                    onFavoriteToggle: _toggleFavorite,
                    onProductTap: (product) =>
                        ProductDetailsSheet.show(context, product.id),
                  ),
                ),
              ),
            );
          }
          break;
      }
    }

    return slivers;
  }
}
