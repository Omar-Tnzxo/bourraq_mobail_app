import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';

/// Product info section with name, weight, stock status, and favorite button
/// Breadfast-style design
class ProductInfoSection extends StatelessWidget {
  final String productName;
  final double price;
  final double? oldPrice;
  final bool isInStock;
  final bool isFavorite;
  final String? weight;
  final VoidCallback? onFavoriteTap;

  const ProductInfoSection({
    super.key,
    required this.productName,
    required this.price,
    this.oldPrice,
    this.isInStock = true,
    this.isFavorite = false,
    this.weight,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = oldPrice != null && oldPrice! > price;

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stock status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isInStock
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isInStock ? 'product.in_stock'.tr() : 'product.out_of_stock'.tr(),
              style: TextStyle(
                color: isInStock ? AppColors.success : AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Product name
          Text(
            productName,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          if (weight != null && weight!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              weight!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Price and favorite row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Price section
              if (hasDiscount) ...[
                Text(
                  '${oldPrice!.toStringAsFixed(2)} ${'common.currency_short'.tr()}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price.floor().toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.deepOlive,
                    ),
                  ),
                  Text(
                    '.${((price - price.floor()) * 100).round().toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'common.currency_short'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),

              // Favorite button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onFavoriteTap?.call();
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.error : AppColors.textLight,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
