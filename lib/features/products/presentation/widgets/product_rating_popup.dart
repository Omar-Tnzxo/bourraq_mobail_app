import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/features/products/data/repositories/product_rating_service.dart';

/// Pop-up dialog for rating partner products after delivery
class ProductRatingPopup extends StatefulWidget {
  final String orderId;
  final String userId;
  final List<Map<String, dynamic>> unratedItems;
  final VoidCallback? onComplete;

  const ProductRatingPopup({
    super.key,
    required this.orderId,
    required this.userId,
    required this.unratedItems,
    this.onComplete,
  });

  /// Show the popup after delivery
  static Future<void> showIfNeeded({
    required BuildContext context,
    required String orderId,
    required String userId,
  }) async {
    final ratingService = ProductRatingService();
    final unrated = await ratingService.getUnratedProductsForOrder(
      orderId: orderId,
      userId: userId,
    );

    if (unrated.isEmpty) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductRatingPopup(
        orderId: orderId,
        userId: userId,
        unratedItems: unrated,
      ),
    );
  }

  @override
  State<ProductRatingPopup> createState() => _ProductRatingPopupState();
}

class _ProductRatingPopupState extends State<ProductRatingPopup> {
  final _ratingService = ProductRatingService();
  int _currentIndex = 0;
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  Map<String, dynamic> get _currentItem => widget.unratedItems[_currentIndex];

  String get _productName {
    final locale = context.locale.languageCode;
    return locale == 'ar'
        ? (_currentItem['product_name'] as String? ?? '')
        : (_currentItem['product_name'] as String? ?? '');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0 || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    HapticFeedback.mediumImpact();

    final branchProductId = _currentItem['branch_product_id'] as String;

    await _ratingService.submitProductRating(
      branchProductId: branchProductId,
      orderId: widget.orderId,
      userId: widget.userId,
      rating: _selectedRating,
      comment: _commentController.text,
    );

    if (!mounted) return;

    // Move to next item or close
    if (_currentIndex < widget.unratedItems.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedRating = 0;
        _commentController.clear();
        _isSubmitting = false;
      });
    } else {
      Navigator.of(context).pop();
      widget.onComplete?.call();
    }
  }

  void _skip() {
    if (_currentIndex < widget.unratedItems.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedRating = 0;
        _commentController.clear();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  LucideIcons.star,
                  color: Color(0xFFFFB800),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isArabic ? 'قيّم المنتج' : 'Rate Product',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                // Progress indicator
                Text(
                  '${_currentIndex + 1}/${widget.unratedItems.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Product name
            Text(
              _productName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Stars row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedRating = starIndex);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: AnimatedScale(
                      scale: _selectedRating >= starIndex ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        _selectedRating >= starIndex
                            ? Icons.star
                            : Icons.star_border,
                        color: const Color(0xFFFFB800),
                        size: 36,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Optional comment
            TextField(
              controller: _commentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: isArabic
                    ? 'أضف تعليق (اختياري)'
                    : 'Add comment (optional)',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textLight,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                // Skip
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skip,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isArabic ? 'تخطي' : 'Skip',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Submit
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedRating > 0 ? _submitRating : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.deepOlive,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            isArabic ? 'إرسال التقييم' : 'Submit Rating',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
