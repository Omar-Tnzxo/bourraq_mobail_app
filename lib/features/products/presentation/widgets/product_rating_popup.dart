import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/features/products/data/repositories/product_rating_service.dart';

/// Pop-up dialog for rating partner products after delivery.
/// Now uses [BourraqDialog] for premium consistency.
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

    try {
      await _ratingService.submitProductRating(
        branchProductId: branchProductId,
        orderId: widget.orderId,
        userId: widget.userId,
        rating: _selectedRating,
        comment: _commentController.text,
      );
    } catch (e) {
      // Logic for error handling if needed
    }

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
    return BourraqDialog(
      title: 'orders.rate_product_title'.tr(),
      confirmLabel: 'orders.submit_rating'.tr(),
      cancelLabel: 'common.skip'.tr(),
      onConfirm: _selectedRating > 0 ? _submitRating : () {},
      onCancel: _skip,
      icon: LucideIcons.star,
      iconColor: const Color(0xFFFFB800),
      isLoading: _isSubmitting,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          // Progress indicator in design style
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentIndex + 1} / ${widget.unratedItems.length}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Product name
          Text(
            _productName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Stars row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              final isLit = _selectedRating >= starIndex;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedRating = starIndex);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedScale(
                    scale: isLit ? 1.25 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      isLit ? LucideIcons.star : LucideIcons.star,
                      fill: isLit ? 1 : 0,
                      color: isLit
                          ? const Color(0xFFFFB800)
                          : Colors.white.withValues(alpha: 0.2),
                      size: 40,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Optional comment
          TextField(
            controller: _commentController,
            maxLines: 2,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'orders.add_comment_hint'.tr(),
              hintStyle: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.accentYellow),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
