import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/home/presentation/widgets/product_card.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/products/presentation/widgets/product_details_sheet.dart';

/// Home Products Section Widget
/// Displays a section title with "See All" button and product cards
class HomeProductsSection extends StatelessWidget {
  final String? titleKey;
  final String? title;
  final List<ProductItem> products;
  final String? seeAllRoute;
  final Function(ProductItem)? onProductTap;
  final Function(ProductItem)? onFavoriteToggle;
  final Set<String> favoriteIds;
  final CartService? cartService;
  final VoidCallback? onCartUpdated;

  const HomeProductsSection({
    super.key,
    this.titleKey,
    this.title,
    required this.products,
    this.seeAllRoute,
    this.onProductTap,
    this.onFavoriteToggle,
    this.favoriteIds = const {},
    this.cartService,
    this.onCartUpdated,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayTitle = title ?? (titleKey != null ? titleKey!.tr() : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayTitle,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (seeAllRoute != null)
                TextButton(
                  onPressed: () => context.push(seeAllRoute!),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: Text(
                    'home.see_all'.tr(),
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.deepOlive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Products Grid (3 columns - matching category screen)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.52,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                isFavorite: favoriteIds.contains(product.id),
                onTap: () {
                  if (onProductTap != null) {
                    onProductTap!(product);
                  } else {
                    ProductDetailsSheet.show(context, product.id);
                  }
                },
                onFavoriteTap: () => onFavoriteToggle?.call(product),
                cartService: cartService,
                onCartUpdated: onCartUpdated,
              );
            },
          ),
        ),
      ],
    );
  }
}
