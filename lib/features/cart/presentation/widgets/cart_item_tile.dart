import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';

/// Premium cart item tile with larger image and weight display
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final String locale;
  final Function(int) onQuantityChanged;
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Product Image (100x100)
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
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Weight/Size
                  if (item.getWeightDisplay(locale) != null)
                    Text(
                      item.getWeightDisplay(locale)!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Price Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Price (flexible to shrink if needed)
                      Flexible(child: _buildPrice()),

                      // Spacing between price and quantity controls
                      const SizedBox(width: 12),

                      // Quantity Controls
                      _buildQuantityControls(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Stack(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => _buildPlaceholder(),
                    errorWidget: (_, __, ___) => _buildPlaceholder(),
                  )
                : _buildPlaceholder(),
          ),

          // Delete Button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                onRemove();
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.x, size: 16, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 100,
      height: 100,
      color: AppColors.skeletonBase,
      child: Center(
        child: Icon(LucideIcons.image, size: 32, color: AppColors.textLight),
      ),
    );
  }

  Widget _buildPrice() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          locale == 'ar' ? 'ج.م ' : 'EGP ',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.deepOlive,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          item.totalPrice.toStringAsFixed(2),
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.deepOlive,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.deepOlive, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus Button
          _buildQuantityButton(
            icon: LucideIcons.minus,
            onTap: () => onQuantityChanged(item.quantity - 1),
          ),

          // Quantity Display
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${item.quantity}',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.deepOlive,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Plus Button
          _buildQuantityButton(
            icon: LucideIcons.plus,
            onTap: () => onQuantityChanged(item.quantity + 1),
            isAdd: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isAdd = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isAdd ? AppColors.deepOlive : Colors.transparent,
          borderRadius: BorderRadius.only(
            topLeft: isAdd ? Radius.zero : const Radius.circular(6.5),
            bottomLeft: isAdd ? Radius.zero : const Radius.circular(6.5),
            topRight: isAdd ? const Radius.circular(6.5) : Radius.zero,
            bottomRight: isAdd ? const Radius.circular(6.5) : Radius.zero,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isAdd ? AppColors.white : AppColors.deepOlive,
        ),
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
