import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';

/// Free delivery progress banner - Modern 2026 Design
/// Follows BRAND_IDENTITY.md and UI-UX-QUALITY-RULES.md
class FreeDeliveryBanner extends StatelessWidget {
  final double remainingAmount;
  final double threshold;

  const FreeDeliveryBanner({
    super.key,
    required this.remainingAmount,
    this.threshold = 300.0,
  });

  /// Progress percentage (0.0 to 1.0)
  double get _progress {
    if (threshold <= 0) return 1.0;
    final currentAmount = threshold - remainingAmount;
    return (currentAmount / threshold).clamp(0.0, 1.0);
  }

  /// Percentage display (0 to 100)
  int get _percentage => (_progress * 100).round();

  /// Whether free delivery is achieved
  bool get _isAchieved => remainingAmount <= 0;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isAchieved
              ? [
                  AppColors.primaryGreen.withValues(alpha: 0.15),
                  AppColors.lightGreen.withValues(alpha: 0.1),
                ]
              : [
                  AppColors.primaryGreen.withValues(alpha: 0.08),
                  AppColors.lightGreen.withValues(alpha: 0.05),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isAchieved
              ? AppColors.primaryGreen.withValues(alpha: 0.4)
              : AppColors.primaryGreen.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: _isAchieved ? _buildAchievedState() : _buildProgressState(),
    );
  }

  /// Build the progress state (not yet achieved)
  Widget _buildProgressState() {
    return Row(
      children: [
        // Circular Progress Indicator
        _buildCircularProgress(),
        const SizedBox(width: 12),

        // Message & Progress Bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Message Text
              _buildMessageText(),
              const SizedBox(height: 8),
              // Linear Progress Bar
              _buildLinearProgressBar(),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Bike Icon
        _buildBikeIcon(),
      ],
    );
  }

  /// Build the achieved state (free delivery unlocked)
  Widget _buildAchievedState() {
    return Row(
      children: [
        // Success Check Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(LucideIcons.check, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),

        // Success Message
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'cart.free_delivery_achieved'.tr(),
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'cart.free_delivery_subtitle'.tr(),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Celebration Icon
        const Text('🎉', style: TextStyle(fontSize: 28)),
      ],
    );
  }

  /// Circular progress indicator with percentage
  Widget _buildCircularProgress() {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Progress Circle
          SizedBox(
            width: 44,
            height: 44,
            child: CircularProgressIndicator(
              value: _progress,
              strokeWidth: 4,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primaryGreen,
              ),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Percentage Text
          Text(
            '$_percentage%',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// Message text with highlighted amount
  Widget _buildMessageText() {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          height: 1.3,
        ),
        children: [
          TextSpan(text: 'cart.add'.tr()),
          const TextSpan(text: ' '),
          TextSpan(
            text:
                '${remainingAmount.toStringAsFixed(0)} ${'common.currency_short'.tr()}',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(text: 'cart.free_delivery'.tr()),
        ],
      ),
    );
  }

  /// Linear progress bar
  Widget _buildLinearProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: 5,
        backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
      ),
    );
  }

  /// Bike icon container (delivery is by motorcycle)
  Widget _buildBikeIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(LucideIcons.bike, size: 18, color: AppColors.primaryGreen),
    );
  }
}
