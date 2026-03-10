import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/services/analytics_service.dart';
import 'package:bourraq/core/utils/error_handler.dart';
import 'package:bourraq/core/widgets/shimmer_skeleton.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/products/presentation/widgets/product_details_sheet.dart';
import 'package:bourraq/features/products/data/repositories/branch_product_repository.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/categories/data/models/category_model.dart';
import 'package:bourraq/features/products/data/models/product_model.dart';
import 'package:bourraq/features/products/data/models/branch_product_model.dart';
import 'package:bourraq/features/home/presentation/widgets/address_picker_bottom_sheet.dart';
import 'package:bourraq/features/categories/presentation/screens/categories_list_screen.dart';
import 'package:bourraq/features/favorites/data/repositories/favorites_repository.dart';

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

class _CategoryProductsScreenState extends State<CategoryProductsScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<CategoryItem> _mainCategories = [];
  String? _error;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadMainCategories();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadMainCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .isFilter('parent_id', null)
          .order('display_order', ascending: true);

      final categories = (response as List)
          .map<CategoryItem>((data) => CategoryItem.fromJson(data))
          .toList();

      if (mounted) {
        String targetId = widget.categoryId;
        // Resolve slug to ID
        final matchCat = categories.firstWhere(
          (c) => c.id == widget.categoryId || c.slug == widget.categoryId,
          orElse: () => categories.first,
        );
        targetId = matchCat.id;

        setState(() {
          _mainCategories = categories;
        });

        int initialIndex = _mainCategories.indexWhere((c) => c.id == targetId);
        if (initialIndex == -1 && _mainCategories.isNotEmpty) {
          initialIndex = 0;
        }

        if (_mainCategories.isNotEmpty) {
          _tabController = TabController(
            length: _mainCategories.length,
            vsync: this,
            initialIndex: initialIndex,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getErrorKey(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removed blocking full-screen loading to show skeleton body immediately

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primaryGreen,
          leading: IconButton(
            icon: Icon(
              context.locale.languageCode == 'ar'
                  ? LucideIcons.chevronRight
                  : LucideIcons.chevronLeft,
              color: AppColors.accentYellow,
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
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circleAlert, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                _error != null
                    ? 'common.error'.tr()
                    : 'category.no_products'.tr(),
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadMainCategories,
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

    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom Curved Header combining AppBar + Main Categories Tabs
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  bottom: 32,
                ), // More space to show indicator above curve
                decoration: const BoxDecoration(color: AppColors.primaryGreen),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom AppBar Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                isArabic
                                    ? LucideIcons.chevronRight
                                    : LucideIcons.chevronLeft,
                                color: AppColors.accentYellow,
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
                              child: _mainCategories.isEmpty
                                  ? _buildCategoriesShimmer()
                                  : TabBar(
                                      controller: _tabController,
                                      isScrollable: true,
                                      tabAlignment: TabAlignment.center,
                                      indicator: const UnderlineTabIndicator(
                                        borderSide: BorderSide(
                                          color: AppColors.accentYellow,
                                          width: 4,
                                        ),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(2),
                                          topRight: Radius.circular(2),
                                        ),
                                        insets: EdgeInsets.only(bottom: 6),
                                      ),
                                      labelColor: AppColors.accentYellow,
                                      unselectedLabelColor: AppColors.white,
                                      padding: const EdgeInsets.only(bottom: 8),
                                      labelStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      unselectedLabelStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      dividerColor: Colors.transparent,
                                      tabs: _mainCategories.map((c) {
                                        return Tab(
                                          text: isArabic ? c.nameAr : c.nameEn,
                                        );
                                      }).toList(),
                                    ),
                            ),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.layoutGrid,
                                color: AppColors.white,
                                size: 24,
                              ),
                              onPressed: () async {
                                final selectedId = await Navigator.of(context)
                                    .push<String>(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            CategoriesListScreen(
                                              categories: _mainCategories,
                                            ),
                                        fullscreenDialog: true,
                                      ),
                                    );

                                if (selectedId != null && mounted) {
                                  final newIndex = _mainCategories.indexWhere(
                                    (c) => c.id == selectedId,
                                  );
                                  if (newIndex != -1) {
                                    _tabController?.animateTo(newIndex);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Curve Overlay matching Home page aesthetics
              Positioned(
                bottom: -1,
                left: 0,
                right: 0,
                child: Container(
                  height: 24, // Keep curve height but overlap more
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Full Screen Body (Sub-categories inside TabBarView)
          Expanded(
            child: _tabController == null
                ? _buildInitialBodyShimmer()
                : TabBarView(
                    controller: _tabController,
                    children: _mainCategories.map((c) {
                      return _CategoryProductsBody(
                        mainCategoryId: c.id,
                        mainCategoryName: isArabic ? c.nameAr : c.nameEn,
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialBodyShimmer() {
    return Column(
      children: [
        // Dummy Subcategories
        Container(
          height: 48,
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(
              3,
              (index) => Container(
                width: 80,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        // Dummy Products
        const Expanded(
          child: ShimmerProductGrid(crossAxisCount: 3, itemCount: 9),
        ),
      ],
    );
  }

  Widget _buildCategoriesShimmer() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Container(
          width: 80,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _CategoryProductsBody extends StatefulWidget {
  final String mainCategoryId;
  final String mainCategoryName;

  const _CategoryProductsBody({
    required this.mainCategoryId,
    required this.mainCategoryName,
  });

  @override
  State<_CategoryProductsBody> createState() => _CategoryProductsBodyState();
}

class _CategoryProductsBodyState extends State<_CategoryProductsBody>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keep state when swiping tabs

  final SupabaseClient _supabase = Supabase.instance.client;
  final BranchProductRepository _branchProductRepo = BranchProductRepository();
  final AddressService _addressService = AddressService();
  late FavoritesRepository _favoritesRepository;

  // Controllers for Scrollable Lists
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  final ItemScrollController _tabsScrollController = ItemScrollController();

  CartService? _cartService;
  String? _areaId;

  List<CategoryItem> _allSubCategories = [];
  List<CategoryItem> _activeSubCategories =
      []; // Categories with products after filter
  List<Map<String, dynamic>> _allProducts = [];
  Map<String, List<Map<String, dynamic>>> _groupedProducts = {};
  bool _isLoading = true;
  String? _error;
  int _selectedSubCategoryIndex = 0;
  bool _isTabClick = false;

  final String _sortBy = 'newest';
  RangeValues _priceRange = const RangeValues(0, 1000);
  bool _inStockOnly = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _favoriteIds = {};
  num _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _favoritesRepository = FavoritesRepository(_supabase);
    _initCartService();
    _loadData();
    _loadUserFavorites();

    _itemPositionsListener.itemPositions.addListener(_onScrollPositionChanged);
    AnalyticsService().trackCategoryView(
      categoryId: widget.mainCategoryId,
      categoryName: widget.mainCategoryName,
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

    // Sort positions to ensure logic works regardless of delivery order
    final sortedPositions = positions.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    // BOTTOM OF PAGE DETECTION:
    // If the last item is visible and its trailing edge is close to 1.0 (bottom of viewport),
    // it likely means we can't scroll any further. Force select the last tab.
    final lastItem = sortedPositions.last;
    if (lastItem.index == _activeSubCategories.length - 1 &&
        lastItem.itemTrailingEdge <= 1.05) {
      if (_selectedSubCategoryIndex != lastItem.index) {
        if (mounted) {
          setState(() => _selectedSubCategoryIndex = lastItem.index);
          // _scrollToTab(lastItem.index); // Removed disturbing animation
        }
      }
      return;
    }

    // NORMAL SCROLL SPY LOGIC:
    // Find the item that is at the top of the viewport or just below the sticky area.
    // itemLeadingEdge: 0.0 is the top of the viewport.
    // We look for the first item whose leading edge is past the threshold (e.g., 0.1)
    int minIndex = _selectedSubCategoryIndex;

    // We find the first item that is prominently visible (top-most)
    final firstVisibleItem = sortedPositions.firstWhere(
      (item) => item.itemLeadingEdge > -0.1,
      orElse: () => sortedPositions.first,
    );

    minIndex = firstVisibleItem.index;

    if (minIndex != _selectedSubCategoryIndex &&
        minIndex < _activeSubCategories.length) {
      if (mounted) {
        setState(() {
          _selectedSubCategoryIndex = minIndex;
        });
        // _scrollToTab(minIndex); // Removed disturbing animation
      }
    }
  }

  Future<void> _initCartService() async {
    final prefs = await SharedPreferences.getInstance();
    _cartService = CartService(prefs);
    if (mounted) _updateCartCount();
  }

  void _updateCartCount() {
    if (_cartService != null) {
      setState(() => _cartItemCount = _cartService!.getCartItemCount());
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_areaId == null) {
        final defaultAddress = await _addressService.getDefaultAddress();
        _areaId = defaultAddress?.areaId;
      }

      // Fetch Sub-categories for this Main Category
      final subCategoriesData = await _supabase
          .from('categories')
          .select()
          .eq('is_active', true)
          .eq('parent_id', widget.mainCategoryId)
          .order('display_order', ascending: true);

      _allSubCategories = (subCategoriesData as List)
          .map<CategoryItem>((data) => CategoryItem.fromJson(data))
          .toList();

      if (_allSubCategories.isNotEmpty) {
        _allSubCategories.insert(
          0,
          CategoryItem(
            id: widget.mainCategoryId, // Fallback ID for null subcategories
            slug: widget.mainCategoryId,
            nameAr: 'الكل',
            nameEn: 'All',
            imageUrl: '',
          ),
        );
      } else {
        _allSubCategories.add(
          CategoryItem(
            id: widget.mainCategoryId,
            slug: widget.mainCategoryId,
            nameAr: widget.mainCategoryName,
            nameEn: widget.mainCategoryName,
            imageUrl: '',
          ),
        );
      }

      // Fetch Products
      final branchProducts = await _branchProductRepo
          .getAllBranchProductsForArea(areaId: _areaId);

      var filteredBranches = branchProducts
          .where((p) => p.categoryId == widget.mainCategoryId)
          .toList();

      if (_areaId == null) {
        final seenIds = <String>{};
        final uniqueProducts = <BranchProduct>[];
        for (var sp in filteredBranches) {
          if (!seenIds.contains(sp.productId)) {
            seenIds.add(sp.productId);
            uniqueProducts.add(sp);
          }
        }
        filteredBranches = uniqueProducts;
      }

      _allProducts = filteredBranches
          .map(
            (sp) => {
              'id': sp.productId,
              'branch_product_id': sp.id,
              'branch_id': sp.branchId,
              'name_ar': sp.nameAr,
              'name_en': sp.nameEn,
              'price': sp.customerPrice,
              'partner_price': sp.partnerPrice,
              'old_price': sp.customerPriceBeforeDiscount,
              'image_url': sp.imageUrl,
              'is_active': sp.isActive,
              'category_id': sp.categoryId,
              'sub_category_id': sp.subCategoryId,
              'avg_rating': sp.avgRating,
              'rating_count': sp.ratingCount,
              'branch_name_ar': sp.branchNameAr,
              'branch_name_en': sp.branchNameEn,
              'badge_name_ar': sp.badgeNameAr,
              'badge_name_en': sp.badgeNameEn,
              'badge_color': sp.badgeColor,
              'weight_value': sp.weightValue,
              'weight_unit_ar': sp.weightUnitAr,
              'weight_unit_en': sp.weightUnitEn,
              'customer_price_before_discount': sp.customerPriceBeforeDiscount,
              'created_at': DateTime.now().toIso8601String(),
              'tags': '',
            },
          )
          .toList();

      _applyFiltersAndSort();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // We do not call _onTabSelected(0) here because it triggers explicit scroll
        // animations out of nowhere when the page loads. The page is already naturally
        // at index 0 initially.
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getErrorKey(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserFavorites() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      final favorites = await _favoritesRepository.getFavorites(
        areaId: _areaId,
      );
      if (mounted) {
        setState(() {
          _favoriteIds.clear();
          _favoriteIds.addAll(favorites.map((p) => p.id));
        });
      }
    } catch (_) {}
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = List.from(_allProducts);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) {
        final nameAr = (p['name_ar'] as String? ?? '').toLowerCase();
        final nameEn = (p['name_en'] as String? ?? '').toLowerCase();
        return nameAr.contains(query) || nameEn.contains(query);
      }).toList();
    }

    filtered = filtered.where((p) {
      final price = (p['price'] as num?)?.toDouble() ?? 0;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    if (_inStockOnly) {
      filtered = filtered.where((p) => p['is_active'] == true).toList();
    }

    switch (_sortBy) {
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

    _groupedProducts = {};
    Set<String> activeCategoryIds = {};

    for (var product in filtered) {
      final mainCatId = product['category_id'] as String?;
      final subCatId = product['sub_category_id'] as String?;

      if (mainCatId != widget.mainCategoryId) continue;

      final groupKey = subCatId ?? mainCatId;

      if (groupKey != null) {
        if (!_groupedProducts.containsKey(groupKey)) {
          _groupedProducts[groupKey] = [];
          activeCategoryIds.add(groupKey);
        }
        _groupedProducts[groupKey]!.add(product);
      }
    }

    _activeSubCategories = _allSubCategories
        .where((c) => activeCategoryIds.contains(c.id))
        .toList();

    if (_selectedSubCategoryIndex >= _activeSubCategories.length) {
      _selectedSubCategoryIndex = 0;
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedSubCategoryIndex = index;
      _isTabClick = true;
    });

    // _scrollToTab(index); // Removed disturbing animation
    if (_itemScrollController.isAttached) {
      _itemScrollController
          .scrollTo(
            index: index,
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
          )
          .then((_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() => _isTabClick = false);
            });
          });
    } else {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _isTabClick = false);
      });
    }
  }

  Future<void> _toggleFavorite(Map<String, dynamic> product) async {
    final productId = product['id'] as String;
    final branchId = product['branch_id'] as String?;
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
          await _favoritesRepository.removeFromFavorites(productId);
        } else {
          await _favoritesRepository.addToFavorites(
            productId,
            branchId: branchId,
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

  void _showLocationPrompt() {
    AddressPickerBottomSheet.show(
      context: context,
      currentAddress: null,
      onAddressSelected: (address) async {
        final success = await _addressService.setDefaultAddress(address.id);
        if (success && mounted) {
          setState(() {
            _areaId = address.areaId;
          });
          _loadData();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // From AutomaticKeepAliveClientMixin
    final isArabic = context.locale.languageCode == 'ar';

    return Stack(
      children: [
        Column(
          children: [
            if (_isSearching) _buildTopSearchBar(),
            if (!_isSearching && _error == null)
              _buildSubCategoriesTabBar(isArabic),

            Expanded(
              child: _isLoading
                  ? _buildBodyLoadingState() // Use the new loading state for the body
                  : _error != null
                  ? _buildErrorState()
                  : _activeSubCategories.isEmpty
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
    );
  }

  Widget _buildBodyLoadingState() {
    return Column(
      children: [
        // Subcategories bar shimmer
        Container(
          height: 48,
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(
              3,
              (index) => Container(
                width: 80,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.skeletonBase,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        // Products grid shimmer
        const Expanded(
          child: ShimmerProductGrid(crossAxisCount: 3, itemCount: 9),
        ),
      ],
    );
  }

  Widget _buildCategoriesShimmer() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 4,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) => Container(
          width: 80,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.skeletonBase,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoriesTabBar(bool isArabic) {
    if (_isLoading) {
      // Show shimmer if loading
      return _buildCategoriesShimmer();
    }
    if (_activeSubCategories.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ScrollablePositionedList.builder(
        itemScrollController: _tabsScrollController,
        scrollDirection: Axis.horizontal,
        // Removed global padding as it causes RTL layout spacing issues in ScrollablePositionedList
        itemCount: _activeSubCategories.length,
        itemBuilder: (context, index) {
          final category = _activeSubCategories[index];
          final isSelected = _selectedSubCategoryIndex == index;
          return GestureDetector(
            onTap: () => _onTabSelected(index),
            child: Container(
              margin: EdgeInsetsDirectional.only(
                start: index == 0 ? 12 : 4,
                end: index == _activeSubCategories.length - 1 ? 12 : 4,
                top: 4,
                bottom: 4,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentYellow
                    : const Color(0xFFEBEBEB),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                isArabic ? category.nameAr.trim() : category.nameEn.trim(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: AppColors.primaryGreen,
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
      itemCount: _activeSubCategories.length,
      itemBuilder: (context, index) {
        final category = _activeSubCategories[index];
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
                    isArabic ? category.nameAr.trim() : category.nameEn.trim(),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepOlive,
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
                childAspectRatio: 0.60,
              ),
              itemCount: products.length,
              itemBuilder: (context, pIndex) {
                final productData = products[pIndex];
                final productId = productData['id'] as String;
                final productModel = Product.fromJson(productData);

                return ProductCard(
                  product: ProductItem.fromProduct(productModel),
                  isFavorite: _favoriteIds.contains(productId),
                  onTap: () => ProductDetailsSheet.show(context, productId),
                  onFavoriteTap: () => _toggleFavorite(productData),
                  cartService: _cartService,
                  onCartUpdated: _updateCartCount,
                  hasAddress: _areaId != null,
                  onLocationRequired: _showLocationPrompt,
                );
              },
            ),
          ],
        );
      },
    );
  }

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
                        _cartItemCount > 9
                            ? '9+'
                            : '\u200E${_cartItemCount % 1 == 0 ? _cartItemCount.toInt() : _cartItemCount}\u200E',
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
}
