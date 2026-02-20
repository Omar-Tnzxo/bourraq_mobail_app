import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';

import 'package:bourraq/core/widgets/bourraq_header.dart';

/// Home Header Widget (Rabbit-style)
/// Displays greeting and delivery location
class HomeHeader extends StatelessWidget {
  final String userName;
  final String locationName;
  final VoidCallback? onLocationTap;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.locationName,
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return BourraqHeader(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Text Content (Greeting + Address)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Greeting - Large Bold
                Text(
                  '${'home.greeting'.tr()} $userName',
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                // Delivery Location - Tappable
                GestureDetector(
                  onTap: onLocationTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'home.delivering_to'.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                locationName,
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.chevronDown,
                              color: AppColors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Logo - Large
          Image.asset(
            'assets/icons/white_icon_logo.png',
            height: 72,
            width: 72,
          ),
        ],
      ),
    );
  }
}
