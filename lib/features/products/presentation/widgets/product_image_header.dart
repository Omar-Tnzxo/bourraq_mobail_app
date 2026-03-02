import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';

import 'package:bourraq/core/constants/app_colors.dart';

/// Product image header with close and cart buttons
/// Breadfast-style design - clean icons without background circles
class ProductImageHeader extends StatelessWidget {
  final String? imageUrl;
  final VoidCallback? onCartTap;
  final int cartCount;

  const ProductImageHeader({
    super.key,
    this.imageUrl,
    this.onCartTap,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(LucideIcons.x, color: AppColors.textPrimary, size: 24),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      actions: [
        GestureDetector(
          onTap: onCartTap ?? () => context.go('/home'),
          child: Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.all(8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  LucideIcons.shoppingBasket,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                // Cart badge
                if (cartCount > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        cartCount > 99 ? '99+' : '$cartCount',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: AppColors.white,
          child: Center(
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: 250,
                    placeholder: (_, _) => _buildPlaceholder(),
                    errorWidget: (_, _, _) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        LucideIcons.image,
        size: 64,
        color: AppColors.textLight,
      ),
    );
  }
}
