import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';

/// Custom Search Bar Widget
/// Matches Rabbit app reference style
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool showCancelButton;
  final VoidCallback? onCancel;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.showCancelButton = false,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 0,
      ), // Removed padding as it's now in the header
      color: Colors
          .transparent, // Background is now handled by the parent (Header)
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.white, // Search field itself is white
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: hintText ?? 'search.hint'.tr(),
                  hintStyle: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () {
                            controller.clear();
                            onClear?.call();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
          ),
          // Cancel button (when searching)
          if (showCancelButton) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor:
                    AppColors.white, // White text for visibility on green
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: Text(
                'common.cancel'.tr(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
