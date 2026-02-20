import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/notifiers/cart_badge_notifier.dart';
import 'package:bourraq/core/services/analytics_service.dart';
import 'package:bourraq/core/utils/error_handler.dart';
import 'package:bourraq/core/widgets/shimmer_skeleton.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';
import 'package:bourraq/features/products/presentation/widgets/product_details_sheet.dart';
import 'package:bourraq/features/products/data/repositories/store_product_repository.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:bourraq/features/home/data/repositories/home_repository.dart';
import 'package:bourraq/features/home/presentation/widgets/home_categories_section.dart';

/// Category Products Screen - Rabbit Style UI
class CategoryProductsScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final StoreProductRepository _storeProductRepo = StoreProductRepository();
  final HomeRepository _homeRepo = HomeRepository();
  final AddressService _addressService = AddressService();

  // Controllers for Scrollable Lists
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final ItemScrollController _tabsScrollController = ItemScrollController();

  CartService? _cartService;
  String? _areaId;

  // Data
  List<CategoryItem> _allCategories = [];
  List<CategoryItem> _activeCategories =
      []; // Categories with products after filter
  List<Map<String, dynamic>> _allProducts = [];
  Map<String, List<Map<String, dynamic>>> _groupedProducts =
      {}; // Grouped by categoryId

  // State
  bool _isLoading = true;
  String? _error;
  int _selectedCategoryIndex = 0;
  bool _isTabClick = false; // Prevent feedback loop during tab click

  // Filters
  String _sortBy = 'newest';
  RangeValues _priceRange = const RangeValues(0, 1000);
  bool _inStockOnly = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _favoriteIds = {};
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _initCartService();
    _loadData();
    _loadUserFavorites();

    // Listen to scroll positions to update active tab
    _itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);

    AnalyticsService().trackCategoryView(
      categoryId: widget.categoryId,
      categoryName: widget.categoryName,
    );
  }

  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(
      _onScrollPositionChanged,
    );
    _searchController.dispose();
    super.dispose();
  }

  void _onScrollPositionChanged() {
    if (_isTabClick) return;

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Find the item with the minimum index that is visible
    final minIndex = positions
        .where(
          (item) => item.itemLeadingEdge < 0.5,
        ) // Adjust based on visibility preference
        .reduce((min, item) => item.index < min.index ? item : min)
        .index;

    if (minIndex != _selectedCategoryIndex &&
        minIndex < _activeCategories.length) {
      setState(() {
        _selectedCategoryIndex = minIndex;
      });
      _scrollToTab(minIndex);
    }
  }

  void _scrollToTab(int index) {
    _tabsScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.4, // Center align
    );
  }

  Future<void> _initCartService() async {
    final prefs = await SharedPreferences.getInstance();
    _cartService = CartService(prefs);
    _updateCartCount();
  }

  void _updateCartCount() {
    if (_cartService != null) {
      setState(() => _cartItemCount = _cartService!.getCartItemCount());
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_areaId == null) {
        final defaultAddress = await _addressService.getDefaultAddress();
        _areaId = defaultAddress?.areaId;
      }

      // 1. Fetch Categories
      final categoriesData = await _homeRepo.getCategories();
      _allCategories = categoriesData
          .map(
            (data) => CategoryItem(
              id: data['id'],
              nameAr: data['name_ar'],
              nameEn: data['name_en'],
              imageUrl: data['image_url'] ?? '',
            ),
          )
          .toList();

      // 2. Fetch Products (Store-aware or Fallback)
      if (_areaId != null) {
        final storeProducts = await _storeProductRepo
            .getAllStoreProductsForArea(areaId: _areaId!);

        _allProducts = storeProducts
            .map(
              (sp) => {
                'id': sp.productId,
                'store_product_id': sp.id,
                'store_id': sp.storeId,
                'name_ar': sp.nameAr,
                'name_en': sp.nameEn,
                'price': sp.customerPrice,
                'merchant_price': sp.merchantPrice,
                'old_price': null,
                'image_url': sp.imageUrl,
                'is_active': sp.isActive,
                'category_id': sp.categoryId,
                'avg_rating': sp.avgRating,
                'rating_count': sp.ratingCount,
                'store_name_ar': sp.storeNameAr,
                'store_name_en': sp.storeNameEn,
                'badge_name_ar': sp.badgeNameAr,
                'badge_name_en': sp.badgeNameEn,
                'badge_color': sp.badgeColor,
                'created_at': DateTime.now().toIso8601String(),
                'tags': '',
              },
            )
            .toList();
      } else {
        // Fallback: Fetch from base products table if no area selected
        final response = await _supabase
            .from('products')
            .select()
            .eq('is_active', true)
            .isFilter('deleted_at', null);

        _allProducts = (response as List).map<Map<String, dynamic>>((p) {
          final productMap = Map<String, dynamic>.from(p as Map);
          return {
            ...productMap,
            'store_name_ar': 'Bourraq',
            'store_name_en': 'Bourraq',
            'merchant_price': productMap['price'],
            'avg_rating': 0.0,
            'rating_count': 0,
          };
        }).toList();
      }

      // 3. Process Data
      _applyFiltersAndSort();

      setState(() {
        _isLoading = false;
      });

      // 4. Initial Scroll to selected Category
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final initialIndex = _activeCategories.indexWhere(
          (c) => c.id == widget.categoryId,
        );
        if (initialIndex != -1) {
          _onTabSelected(initialIndex);
        }
      });
    } catch (e) {
      debugPrint('❌ Error loading products: $e');
      setState(() {
        _error = ErrorHandler.getErrorKey(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserFavorites() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final response = await _supabase
          .from('favorites')
          .select('product_id')
          .eq('user_id', user.id);
      setState(() {
        _favoriteIds.clear();
        for (final fav in response) {
          _favoriteIds.add(fav['product_id'] as String);
        }
      });
    } catch (_) {}
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_allProducts);

    // 1. Filter by Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final nameAr = (p['name_ar'] as String? ?? '').toLowerCase();
        final nameEn = (p['name_en'] as String? ?? '').toLowerCase();
        return nameAr.contains(query) || nameEn.contains(query);
      }).toList();
    }

    // 2. Filter by Price
    filtered = filtered.where((p) {
      final price = (p['price'] as num?)?.toDouble() ?? 0;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // 3. Filter by Stock
    if (_inStockOnly) {
      filtered = filtered.where((p) => p['is_active'] == true).toList();
    }

    // 4. Sort
    switch (_sortBy) {
      case 'newest':
        // Mock created_at sort or keep default
        break;
      case 'price_low':
        filtered.sort(
          (a, b) => ((a['price'] as num).toDouble()).compareTo(
            (b['price'] as num).toDouble(),
          ),
        );
        break;
      case 'price_high':
        filtered.sort(
          (a, b) => ((b['price'] as num).toDouble()).compareTo(
            (a['price'] as num).toDouble(),
          ),
        );
        break;
      case 'rating':
        filtered.sort(
          (a, b) => ((b['avg_rating'] as num).toDouble()).compareTo(
            (a['avg_rating'] as num).toDouble(),
          ),
        );
        break;
    }

    // 5. Group by Category
    _groupedProducts = {};
    Set<String> activeCategoryIds = {};

    for (var product in filtered) {
      final catId = product['category_id'] as String?;
      if (catId != null) {
        if (!_groupedProducts.containsKey(catId)) {
          _groupedProducts[catId] = [];
          activeCategoryIds.add(catId);
        }
        _groupedProducts[catId]!.add(product);
      }
    }

    // 6. Update Active Categories List (maintain order from _allCategories)
    _activeCategories = _allCategories
        .where((c) => activeCategoryIds.contains(c.id))
        .toList();

    // Ensure selected index is valid
    if (_selectedCategoryIndex >= _activeCategories.length) {
      _selectedCategoryIndex = 0;
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _isTabClick = true;
    });

    _scrollToTab(index);
    _itemScrollController
        .scrollTo(
          index: index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        )
        .then((_) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) setState(() => _isTabClick = false);
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (_isSearching) _buildTopSearchBar(),
                if (!_isSearching) _buildCustomAppBar(context),
                if (!_isSearching && !_isLoading && _error == null)
                  _buildCategoriesTabBar(isArabic),

                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _error != null
                      ? _buildErrorState()
                      : _activeCategories.isEmpty
                      ? _buildEmptyState()
                      : _buildScrollableContent(isArabic),
                ),
              ],
            ),
            if (!_isSearching && !_isLoading && _error == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 24,
                child: _buildFloatingButtons(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              context.locale.languageCode == 'ar'
                  ? LucideIcons.chevronRight
                  : LucideIcons.chevronLeft,
              color: AppColors.deepOlive,
              size: 28,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/');
              }
            },
          ),
          Expanded(
            child: Text(
              'home.products'.tr(), // Or 'All Products'
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.deepOlive,
                fontSize: 20,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.arrowUpDown, size: 22),
            color: AppColors.textPrimary,
            onPressed: () => _showSortSheet(context),
          ),
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal, size: 22),
            color: AppColors.textPrimary,
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTabBar(bool isArabic) {
    if (_activeCategories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      color: AppColors.white,
      child: ScrollablePositionedList.builder(
        itemScrollController: _tabsScrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: _activeCategories.length,
        itemBuilder: (context, index) {
          final category = _activeCategories[index];
          final isSelected = _selectedCategoryIndex == index;
          return GestureDetector(
            onTap: () => _onTabSelected(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.deepOlive
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.deepOlive
                      : AppColors.borderLight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                isArabic ? category.nameAr : category.nameEn,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildScrollableContent(bool isArabic) {
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.only(bottom: 100), // Space for floating buttons
      itemCount: _activeCategories.length,
      itemBuilder: (context, index) {
        final category = _activeCategories[index];
        final products = _groupedProducts[category.id] ?? [];
        if (products.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              color: AppColors.background,
              width: double.infinity,
              child: Row(
                children: [
                  Text(
                    isArabic ? category.nameAr : category.nameEn,
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepOlive,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${products.length})',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Products Grid for this Category
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.52,
              ),
              itemCount: products.length,
              itemBuilder: (context, pIndex) {
                final product = products[pIndex];
                final productId = product['id'] as String;
                return _ProductCard(
                  product: product,
                  isArabic: isArabic,
                  isFavorite: _favoriteIds.contains(productId),
                  onTap: () => ProductDetailsSheet.show(context, productId),
                  onFavoriteTap: () => _toggleFavorite(productId),
                  cartService: _cartService,
                  onCartUpdated: _updateCartCount,
                );
              },
            ),
          ],
        );
      },
    );
  }

  // --- Search & UI Components (kept similar but simplified) ---

  Widget _buildTopSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
                _applyFiltersAndSort();
              },
              borderRadius: BorderRadius.circular(12),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  LucideIcons.arrowLeft,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.deepOlive, width: 1.5),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                  _applyFiltersAndSort();
                },
                decoration: InputDecoration(
                  hintText: 'search.hint'.tr(),
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: AppColors.deepOlive,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const ShimmerProductGrid(
      crossAxisCount: 3,
      itemCount: 12,
      childAspectRatio: 0.52,
      padding: EdgeInsets.all(8),
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
            Text('common.error'.tr(), style: AppTextStyles.titleLarge),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deepOlive,
              ),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.package, size: 64, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text('category.no_products'.tr(), style: AppTextStyles.titleLarge),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                  _priceRange = const RangeValues(0, 1000);
                  _inStockOnly = false;
                });
                _applyFiltersAndSort();
              },
              child: Text('category.reset'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButtons(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.deepOlive,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFloatingButton(
              icon: LucideIcons.search,
              onTap: () => setState(() => _isSearching = true),
            ),
            Container(
              width: 1,
              height: 28,
              color: AppColors.lightGreen.withValues(alpha: 0.3),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildFloatingButton(
                  icon: LucideIcons.shoppingBasket,
                  onTap: () => context.push('/cart'),
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _cartItemCount > 9 ? '9+' : '$_cartItemCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(32),
        splashColor: AppColors.lightGreen.withValues(alpha: 0.3),
        highlightColor: AppColors.lightGreen.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Icon(icon, color: AppColors.lightGreen, size: 26),
        ),
      ),
    );
  }

  // --- Sort & Filter Sheets (Simplified) ---

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('category.sort_by'.tr(), style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            _buildSortOption(
              'newest',
              LucideIcons.sparkles,
              'category.newest'.tr(),
            ),
            _buildSortOption(
              'price_low',
              LucideIcons.arrowUp,
              'category.price_low_high'.tr(),
            ),
            _buildSortOption(
              'price_high',
              LucideIcons.arrowDown,
              'category.price_high_low'.tr(),
            ),
            _buildSortOption(
              'rating',
              LucideIcons.star,
              'category.highest_rated'.tr(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, IconData icon, String label) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.deepOlive : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? AppColors.deepOlive : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(LucideIcons.check, color: AppColors.deepOlive)
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        _applyFiltersAndSort();
        Navigator.pop(context);
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    // Reuse existing filter logic...
    RangeValues tempPriceRange = _priceRange;
    bool tempInStockOnly = _inStockOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'category.filters'.tr(),
                    style: AppTextStyles.titleLarge,
                  ),
                  TextButton(
                    onPressed: () => setSheetState(() {
                      tempPriceRange = const RangeValues(0, 1000);
                      tempInStockOnly = false;
                    }),
                    child: Text('category.reset'.tr()),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'category.price_range'.tr(),
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tempPriceRange.start.round()} ${'common.currency'.tr()}',
                  ),
                  Text(
                    '${tempPriceRange.end.round()} ${'common.currency'.tr()}',
                  ),
                ],
              ),
              RangeSlider(
                values: tempPriceRange,
                min: 0,
                max: 1000,
                divisions: 100,
                activeColor: AppColors.deepOlive,
                onChanged: (values) =>
                    setSheetState(() => tempPriceRange = values),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text('category.in_stock_only'.tr()),
                value: tempInStockOnly,
                activeColor: AppColors.deepOlive,
                onChanged: (value) =>
                    setSheetState(() => tempInStockOnly = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _priceRange = tempPriceRange;
                      _inStockOnly = tempInStockOnly;
                    });
                    _applyFiltersAndSort();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepOlive,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('category.apply'.tr()),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(String productId) async {
    final user = _supabase.auth.currentUser;
    final wasFavorite = _favoriteIds.contains(productId);

    setState(() {
      if (wasFavorite) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasFavorite ? 'favorites.removed'.tr() : 'favorites.added'.tr(),
        ),
        backgroundColor: wasFavorite
            ? AppColors.textSecondary
            : AppColors.deepOlive,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );

    if (user != null) {
      try {
        if (wasFavorite) {
          await _supabase
              .from('favorites')
              .delete()
              .eq('user_id', user.id)
              .eq('product_id', productId);
        } else {
          await _supabase
              .from('favorites')
              .upsert(
                {'user_id': user.id, 'product_id': productId},
                onConflict: 'user_id,product_id',
                ignoreDuplicates: true,
              );
        }
      } catch (_) {
        setState(() {
          if (wasFavorite) {
            _favoriteIds.add(productId);
          } else {
            _favoriteIds.remove(productId);
          }
        });
      }
    }
  }
}

/// Product Card with Quantity Counter - Grabit Style
class _ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isArabic;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final CartService? cartService;
  final VoidCallback onCartUpdated;

  const _ProductCard({
    required this.product,
    required this.isArabic,
    required this.isFavorite,
    required this.onTap,
    required this.onFavoriteTap,
    required this.cartService,
    required this.onCartUpdated,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard>
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
  void didUpdateWidget(covariant _ProductCard oldWidget) {
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
      final productId = widget.product['id'] as String;
      final items = widget.cartService!.getCartItems();
      final cartItem = items
          .where((item) => item.productId == productId)
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
    HapticFeedback.mediumImpact();
    if (widget.cartService == null) return;

    _animateTap();

    final productId = widget.product['id'] as String;

    if (_quantity == 0) {
      // Add new item to cart — use store-specific data if available
      final storeProductId = widget.product['store_product_id'] as String?;
      final storeId = widget.product['store_id'] as String?;
      final customerPrice = widget.product['price'] as num?;
      final merchantPrice = widget.product['merchant_price'] as num?;

      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        nameAr: widget.product['name_ar'] as String? ?? '',
        nameEn: widget.product['name_en'] as String? ?? '',
        price: customerPrice?.toDouble() ?? 0.0,
        quantity: 1,
        imageUrl: widget.product['image_url'] as String?,
        weightValue: (widget.product['weight_value'] as num?)?.toDouble(),
        weightUnit: widget.product['weight_unit'] as String?,
        storeProductId: storeProductId,
        storeId: storeId,
        merchantPrice: merchantPrice?.toDouble(),
        customerPrice: customerPrice?.toDouble(),
      );
      await widget.cartService!.addToCart(cartItem);
    } else {
      // Increment existing item
      await widget.cartService!.updateQuantity(productId, _quantity + 1);
    }

    setState(() => _quantity++);
    widget.onCartUpdated();
    // Update cart badge in real-time
    if (mounted) context.read<CartBadgeNotifier>().refresh();
  }

  Future<void> _decrementQuantity() async {
    HapticFeedback.lightImpact();
    if (widget.cartService == null || _quantity <= 0) return;

    _animateTap();

    final productId = widget.product['id'] as String;

    if (_quantity == 1) {
      // Remove item from cart
      await widget.cartService!.removeFromCart(productId);
      setState(() => _quantity = 0);
    } else {
      // Decrement existing item
      await widget.cartService!.updateQuantity(productId, _quantity - 1);
      setState(() => _quantity--);
    }

    widget.onCartUpdated();
    // Update cart badge in real-time
    if (mounted) context.read<CartBadgeNotifier>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.isArabic
        ? (widget.product['name_ar'] ?? '')
        : (widget.product['name_en'] ?? '');
    final price = (widget.product['price'] as num?)?.toDouble() ?? 0.0;
    final oldPrice = (widget.product['old_price'] as num?)?.toDouble();
    final imageUrl = widget.product['image_url'] as String? ?? '';

    final hasDiscount = oldPrice != null && oldPrice > price;
    final discountPercent = hasDiscount
        ? ((oldPrice - price) / oldPrice * 100).round()
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
                          child: imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: imageUrl,
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
                              HapticFeedback.selectionClick();
                              setState(() => _isFavorite = !_isFavorite);
                              widget.onFavoriteTap();
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
                          name,
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
                                '${oldPrice.toStringAsFixed(2)} ${'common.currency_short'.tr()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textLight,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Row(
                              children: [
                                Text(
                                  price.floor().toString(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.deepOlive,
                                  ),
                                ),
                                Text(
                                  '.${((price - price.floor()) * 100).round().toString().padLeft(2, '0')}',
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

  // Quantity counter widget [ - ] 1 [ + ] with animations
  Widget _buildQuantityCounter() {
    // If animation not ready, return without animation
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
