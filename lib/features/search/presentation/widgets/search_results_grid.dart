import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/products/presentation/widgets/product_details_sheet.dart';

/// Search Results Grid
/// Displays search results in a grid layout
class SearchResultsGrid extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final String query;
  final CartService? cartService;
  final VoidCallback? onCartUpdated;
  final bool hasAddress;
  final VoidCallback? onLocationRequired;

  const SearchResultsGrid({
    super.key,
    required this.results,
    required this.query,
    this.cartService,
    this.onCartUpdated,
    this.hasAddress = true,
    this.onLocationRequired,
  });

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
            context.locale.languageCode == 'ar'
                ? 'نتائج البحث عن "$query" (${results.length})'
                : 'Results for "$query" (${results.length})',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        // Results grid
        Expanded(
          child: results.isEmpty
              ? _buildEmptyState(context)
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.64,
                  ),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final product = results[index];
                    return ProductCard(
                      product: ProductItem.fromMap(product),
                      cartService: cartService,
                      onCartUpdated: onCartUpdated,
                      hasAddress: hasAddress,
                      onLocationRequired: onLocationRequired,
                      onTap: () =>
                          ProductDetailsSheet.show(context, product['id']),
                    );
                  },
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
