import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';

/// Expandable product details section
/// Breadfast-style design with chevron icon
class ExpandableDetailsSection extends StatefulWidget {
  final String? description;
  final String title;

  const ExpandableDetailsSection({
    super.key,
    this.description,
    this.title = '',
  });

  @override
  State<ExpandableDetailsSection> createState() =>
      _ExpandableDetailsSectionState();
}

class _ExpandableDetailsSectionState extends State<ExpandableDetailsSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _iconRotation;
  late Animation<double> _contentHeight;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _iconRotation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _contentHeight = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasDescription =
        widget.description != null && widget.description!.isNotEmpty;

    if (!hasDescription) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: AppColors.white,
      child: Column(
        children: [
          // Header - tappable
          InkWell(
            onTap: _toggleExpanded,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    widget.title.isEmpty
                        ? 'product.product_details'.tr()
                        : widget.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  RotationTransition(
                    turns: _iconRotation,
                    child: const Icon(
                      LucideIcons.chevronDown,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content - animated
          SizeTransition(
            sizeFactor: _contentHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.description ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
          ),
          // Divider
          Container(height: 1, color: AppColors.border.withValues(alpha: 0.3)),
        ],
      ),
    );
  }
}
