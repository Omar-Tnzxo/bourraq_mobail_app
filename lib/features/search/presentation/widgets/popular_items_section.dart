import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/products/presentation/widgets/product_details_sheet.dart';

/// Popular Items Section
/// Shows popular/best-selling products in user's area
class PopularItemsSection extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final CartService? cartService;
  final VoidCallback? onCartUpdated;
  final bool hasAddress;
  final VoidCallback? onLocationRequired;
  final Set<String>? favoriteIds;
  final Function(ProductItem)? onFavoriteToggle;

  const PopularItemsSection({
    super.key,
    required this.products,
    this.cartService,
    this.onCartUpdated,
    this.hasAddress = true,
    this.onLocationRequired,
    this.favoriteIds,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title with emoji
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'search.popular_items'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Text('🔥', style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Products grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.60,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final productItem = ProductItem.fromMap(product);
              return ProductCard(
                product: productItem,
                isFavorite: favoriteIds?.contains(productItem.id) ?? false,
                onFavoriteTap: () => onFavoriteToggle?.call(productItem),
                cartService: cartService,
                onCartUpdated: onCartUpdated,
                hasAddress: hasAddress,
                onLocationRequired: onLocationRequired,
                onTap: () => ProductDetailsSheet.show(context, product['id']),
              );
            },
          ),
        ),
      ],
    );
  }
}
