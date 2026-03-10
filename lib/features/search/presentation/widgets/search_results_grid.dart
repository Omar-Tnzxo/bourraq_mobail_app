import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/products/presentation/widgets/product_details_sheet.dart';

/// Search Results Grid
/// Displays search results in a grid layout with infinite scrolling
class SearchResultsGrid extends StatefulWidget {
  final List<Map<String, dynamic>> results;
  final String query;
  final CartService? cartService;
  final VoidCallback? onCartUpdated;
  final bool hasAddress;
  final VoidCallback? onLocationRequired;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final Set<String>? favoriteIds;
  final Function(ProductItem)? onFavoriteToggle;

  const SearchResultsGrid({
    super.key,
    required this.results,
    required this.query,
    this.cartService,
    this.onCartUpdated,
    this.hasAddress = true,
    this.onLocationRequired,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.favoriteIds,
    this.onFavoriteToggle,
  });

  @override
  State<SearchResultsGrid> createState() => _SearchResultsGridState();
}

class _SearchResultsGridState extends State<SearchResultsGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!widget.isLoadingMore && widget.onLoadMore != null) {
        widget.onLoadMore!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Results count header
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.white,
          width: double.infinity,
          child: Text(
            'search.results_for'.tr(
              args: [widget.query, '${widget.results.length}'],
            ),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        // Results grid
        Expanded(
          child: widget.results.isEmpty && !widget.isLoadingMore
              ? _buildEmptyState(context)
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              childAspectRatio: 0.60,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = widget.results[index];
                          final productItem = ProductItem.fromMap(product);
                          return ProductCard(
                            product: productItem,
                            isFavorite:
                                widget.favoriteIds?.contains(productItem.id) ??
                                false,
                            onFavoriteTap: () =>
                                widget.onFavoriteToggle?.call(productItem),
                            cartService: widget.cartService,
                            onCartUpdated: widget.onCartUpdated,
                            hasAddress: widget.hasAddress,
                            onLocationRequired: widget.onLocationRequired,
                            onTap: () => ProductDetailsSheet.show(
                              context,
                              product['id'],
                            ),
                          );
                        }, childCount: widget.results.length),
                      ),
                    ),
                    if (widget.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: AppColors.textLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'search.no_results'.tr(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'search.try_different'.tr(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
