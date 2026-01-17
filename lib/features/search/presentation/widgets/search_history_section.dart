import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import '../../data/models/search_history_item.dart';

/// Search History Section
/// Shows recent searches with delete option
class SearchHistorySection extends StatelessWidget {
  final List<SearchHistoryItem> history;
  final ValueChanged<String> onHistoryTap;
  final ValueChanged<String> onDeleteItem;
  final VoidCallback onClearAll;

  const SearchHistorySection({
    super.key,
    required this.history,
    required this.onHistoryTap,
    required this.onDeleteItem,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with clear button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'search.recent_searches'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'search.clear_all'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // History list
        ...history.map((item) => _buildHistoryItem(item)),
      ],
    );
  }

  Widget _buildHistoryItem(SearchHistoryItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onHistoryTap(item.query),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // History icon
              const Icon(
                LucideIcons.history,
                size: 18,
                color: AppColors.textLight,
              ),
              const SizedBox(width: 14),
              // Query text
              Expanded(
                child: Text(
                  item.query,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Delete button
              IconButton(
                icon: const Icon(
                  LucideIcons.x,
                  size: 16,
                  color: AppColors.textLight,
                ),
                onPressed: () => onDeleteItem(item.id),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
