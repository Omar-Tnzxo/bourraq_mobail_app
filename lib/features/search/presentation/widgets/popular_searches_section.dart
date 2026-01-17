import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import '../../data/models/popular_search_item.dart';

/// Popular Searches Section
/// Displays chips for popular/trending searches
class PopularSearchesSection extends StatelessWidget {
  final List<PopularSearchItem> popularSearches;
  final ValueChanged<String> onSearchTap;

  const PopularSearchesSection({
    super.key,
    required this.popularSearches,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    if (popularSearches.isEmpty) return const SizedBox.shrink();

    final isArabic = context.locale.languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'search.popular_searches'.tr(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: popularSearches.map((item) {
              final keyword = item.getKeyword(isArabic);
              return _buildChip(keyword);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String keyword) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onSearchTap(keyword),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            keyword,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
