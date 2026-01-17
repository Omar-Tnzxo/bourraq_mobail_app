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
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';
import 'package:bourraq/features/products/presentation/widgets/product_details_sheet.dart';

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
  CartService? _cartService;

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;
  int _selectedSubcategory = 0;
  String _sortBy = 'newest';
  RangeValues _priceRange = const RangeValues(0, 1000);
  bool _inStockOnly = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final Set<String> _favoriteIds = {};
  int _cartItemCount = 0;

  final List<String> _subcategoryKeys = [
    'all',
    'fresh',
    'imported',
    'organic',
    'offers',
  ];

  @override
  void initState() {
    super.initState();
    _initCartService();
    _loadProducts();
    _loadUserFavorites();

    // Track category view
    AnalyticsService().trackCategoryView(
      categoryId: widget.categoryId,
      categoryName: widget.categoryName,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category_id', widget.categoryId)
          .eq('is_active', true);

      setState(() {
        _allProducts = List<Map<String, dynamic>>.from(response);
        _applyFiltersAndSort();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
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
    List<Map<String, dynamic>> result = List.from(_allProducts);

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((p) {
        final nameAr = (p['name_ar'] as String? ?? '').toLowerCase();
        final nameEn = (p['name_en'] as String? ?? '').toLowerCase();
        return nameAr.contains(query) || nameEn.contains(query);
      }).toList();
    }

    // Subcategory filter
    if (_selectedSubcategory > 0) {
      final key = _subcategoryKeys[_selectedSubcategory];
      switch (key) {
        case 'fresh':
          result = result.where((p) {
            final tags = p['tags'] as String? ?? '';
            return tags.contains('fresh') || tags.contains('طازج');
          }).toList();
          break;
        case 'imported':
          result = result.where((p) {
            final tags = p['tags'] as String? ?? '';
            return tags.contains('imported') || tags.contains('مستورد');
          }).toList();
          break;
        case 'organic':
          result = result.where((p) {
            final tags = p['tags'] as String? ?? '';
            return tags.contains('organic') || tags.contains('عضوي');
          }).toList();
          break;
        case 'offers':
          result = result.where((p) {
            final price = (p['price'] as num?)?.toDouble() ?? 0;
            final oldPrice = (p['old_price'] as num?)?.toDouble();
            return oldPrice != null && oldPrice > price;
          }).toList();
          break;
      }
    }

    // Price range filter
    result = result.where((p) {
      final price = (p['price'] as num?)?.toDouble() ?? 0;
      return price >= _priceRange.start && price <= _priceRange.end;
    }).toList();

    // Stock filter
    if (_inStockOnly) {
      result = result.where((p) => p['is_active'] == true).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'newest':
        result.sort((a, b) {
          final aDate =
              DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(2000);
          final bDate =
              DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        break;
      case 'price_low':
        result.sort((a, b) {
          final aPrice = (a['price'] as num?)?.toDouble() ?? 0;
          final bPrice = (b['price'] as num?)?.toDouble() ?? 0;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'price_high':
        result.sort((a, b) {
          final aPrice = (a['price'] as num?)?.toDouble() ?? 0;
          final bPrice = (b['price'] as num?)?.toDouble() ?? 0;
          return bPrice.compareTo(aPrice);
        });
        break;
      case 'best_selling':
        result.sort((a, b) {
          final aSales = (a['sales_count'] as num?)?.toInt() ?? 0;
          final bSales = (b['sales_count'] as num?)?.toInt() ?? 0;
          return bSales.compareTo(aSales);
        });
        break;
    }

    setState(() => _filteredProducts = result);
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
            // Main content
            Column(
              children: [
                // Show search bar at top when searching
                if (_isSearching) _buildTopSearchBar(),
                if (!_isSearching) _buildAppBar(context, isArabic),
                if (!_isSearching) _buildCategoryTitle(),
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _error != null
                      ? _buildErrorState()
                      : _filteredProducts.isEmpty
                      ? _buildEmptyState()
                      : _buildProductsGrid(isArabic),
                ),
              ],
            ),
            // Floating bottom buttons (only when not searching)
            if (!_isSearching)
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

  // Top search bar that stays above keyboard
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
          // Close button
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
          // Search input
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

  Widget _buildAppBar(BuildContext context, bool isArabic) {
    final subcategoryLabels = [
      'category.all'.tr(),
      'category.fresh'.tr(),
      'category.imported'.tr(),
      'category.organic'.tr(),
      'category.offers'.tr(),
    ];

    return Container(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                isArabic ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
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
              child: SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: subcategoryLabels.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _selectedSubcategory == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedSubcategory = index);
                        _applyFiltersAndSort();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.deepOlive
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.deepOlive
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          subcategoryLabels[index],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  },
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
      ),
    );
  }

  Widget _buildCategoryTitle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Text(
            widget.categoryName,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.deepOlive,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '(${_filteredProducts.length})',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.deepOlive),
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
              onPressed: _loadProducts,
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
                  _selectedSubcategory = 0;
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

  Widget _buildProductsGrid(bool isArabic) {
    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppColors.deepOlive,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.52,
        ),
        itemCount: _filteredProducts.length,
        itemBuilder: (context, index) {
          final product = _filteredProducts[index];
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
    );
  }

  // Floating pill-shaped buttons - Rabbit style
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
            // Search button
            _buildFloatingButton(
              icon: LucideIcons.search,
              onTap: () => setState(() => _isSearching = true),
            ),
            // Divider line
            Container(
              width: 1,
              height: 28,
              color: AppColors.lightGreen.withValues(alpha: 0.3),
            ),
            // Cart button with badge
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
              'best_selling',
              LucideIcons.trendingUp,
              'category.best_selling'.tr(),
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
                    onPressed: () {
                      setSheetState(() {
                        tempPriceRange = const RangeValues(0, 1000);
                        tempInStockOnly = false;
                      });
                    },
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
      // Add new item to cart
      final cartItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        productId: productId,
        nameAr: widget.product['name_ar'] as String? ?? '',
        nameEn: widget.product['name_en'] as String? ?? '',
        price: (widget.product['price'] as num?)?.toDouble() ?? 0.0,
        quantity: 1,
        imageUrl: widget.product['image_url'] as String?,
        weightValue: (widget.product['weight_value'] as num?)?.toDouble(),
        weightUnit: widget.product['weight_unit'] as String?,
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
