import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/widgets/app_price_display.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';

/// Premium cart item tile with larger image and weight display
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final String locale;
  final Function(double) onQuantityChanged;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.item,
    required this.locale,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.productId),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        onRemove();
        return false;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Image
            _buildProductImage(),
            const SizedBox(width: 16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    item.getName(locale),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Weight/Size
                  if (item.getWeightDisplay(locale).isNotEmpty)
                    Text(
                      item.getWeightDisplay(locale),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Price
                  _buildPrice(),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Quantity Controls
            _buildQuantityControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return SizedBox(
      width: 70,
      height: 70,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.imageUrl != null && item.imageUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: item.imageUrl!,
                width: 70,
                height: 70,
                fit: BoxFit.contain,
                placeholder: (_, _) => _buildPlaceholder(),
                errorWidget: (_, _, _) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: AppColors.skeletonBase,
      child: Center(
        child: Icon(LucideIcons.image, size: 24, color: AppColors.textLight),
      ),
    );
  }

  Widget _buildPrice() {
    return AppPriceDisplay(
      price: item.totalPrice,
      scale: 1.1, // Slightly larger than standard 18px product card
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.deepOlive,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        children: [
          // Minus Button
          _buildQuantityButton(
            icon: LucideIcons.minus,
            onTap: () => onQuantityChanged(item.quantity - 1),
          ),

          // Quantity Display
          Container(
            constraints: const BoxConstraints(minWidth: 28),
            alignment: Alignment.center,
            child: Text(
              '\u200E${item.quantity == item.quantity.toInt() ? item.quantity.toInt() : item.quantity}\u200E',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Plus Button
          _buildQuantityButton(
            icon: LucideIcons.plus,
            onTap: () => onQuantityChanged(item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 44,
        color: Colors.transparent,
        child: Icon(icon, size: 20, color: AppColors.accentYellow),
      ),
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 28),
      child: Icon(LucideIcons.trash2, color: AppColors.white, size: 28),
    );
  }
}
