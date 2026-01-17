import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

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

  const PopularItemsSection({
    super.key,
    required this.products,
    this.cartService,
    this.onCartUpdated,
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
              childAspectRatio: 0.52,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: ProductItem.fromMap(product),
                cartService: cartService,
                onCartUpdated: onCartUpdated,
                onTap: () => ProductDetailsSheet.show(context, product['id']),
              );
            },
          ),
        ),
      ],
    );
  }
}
