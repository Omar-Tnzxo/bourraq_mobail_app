import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';

/// Product bottom bar with quantity selector and add to cart button
/// Breadfast-style design - fixed at bottom
class ProductBottomBar extends StatelessWidget {
  final int quantity;
  final double unitPrice;
  final double? oldPrice;
  final bool isInStock;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAddToCart;

  const ProductBottomBar({
    super.key,
    required this.quantity,
    required this.unitPrice,
    this.oldPrice,
    this.isInStock = true,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final totalPrice = unitPrice * (quantity > 0 ? quantity : 1);
    final hasDiscount = oldPrice != null && oldPrice! > unitPrice;
    final oldTotalPrice = hasDiscount
        ? oldPrice! * (quantity > 0 ? quantity : 1)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Quantity selector
            Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decrement button
                  _QuantityButton(
                    icon: LucideIcons.minus,
                    onTap: quantity > 1 ? onDecrement : null,
                    isEnabled: quantity > 1,
                  ),
                  // Quantity display
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: Text(
                        '${quantity > 0 ? quantity : 1}',
                        key: ValueKey<int>(quantity),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Increment button
                  _QuantityButton(
                    icon: LucideIcons.plus,
                    onTap: onIncrement,
                    isEnabled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Add to cart button
            Expanded(
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isInStock ? onAddToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    disabledBackgroundColor: AppColors.textLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'cart.add'.tr(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Price section
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (hasDiscount && oldTotalPrice != null)
                            Text(
                              '${oldTotalPrice.toStringAsFixed(2)} ${'common.currency_short'.tr()}',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.white.withValues(alpha: 0.7),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          Text(
                            '${totalPrice.toStringAsFixed(2)} ${'common.currency_short'.tr()}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual quantity button (+ or -)
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isEnabled;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled
            ? () {
                HapticFeedback.selectionClick();
                onTap?.call();
              }
            : null,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 40,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 18,
            color: isEnabled ? AppColors.textPrimary : AppColors.textLight,
          ),
        ),
      ),
    );
  }
}
