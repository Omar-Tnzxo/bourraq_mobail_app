import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';

/// A reusable premium bottom sheet wrapper for the Bourraq app.
/// Following the dark green theme and high-craft UI/UX.
class BourraqBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final bool showCloseButton;
  final double maxHeightMultiplier;

  const BourraqBottomSheet({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.showCloseButton = true,
    this.maxHeightMultiplier = 0.85,
  });

  /// Helper static method to show the bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    List<Widget>? actions,
    bool showCloseButton = true,
    double maxHeightMultiplier = 0.85,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      builder: (context) => BourraqBottomSheet(
        title: title,
        actions: actions,
        showCloseButton: showCloseButton,
        maxHeightMultiplier: maxHeightMultiplier,
        child: child,
      ),
    );
  }

  /// Helper to show a choice-based bottom sheet
  static Future<T?> showChoice<T>(
    BuildContext context, {
    required String title,
    required List<BottomSheetOption<T>> options,
    T? initialSelectedId,
    required ValueChanged<BottomSheetOption<T>> onSelect,
  }) {
    return show<T>(
      context: context,
      title: title,
      child: Column(
        children: options.map((option) {
          final isSelected = option.id == initialSelectedId;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onSelect(option);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentYellow.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.05),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (option.icon != null) ...[
                        Icon(
                          option.icon,
                          color: isSelected
                              ? AppColors.accentYellow
                              : Colors.white70,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                      ],
                      Expanded(
                        child: Text(
                          option.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.accentYellow
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (option.trailing != null) option.trailing!,
                      if (isSelected) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          LucideIcons.check,
                          color: AppColors.accentYellow,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Existing build code...
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * maxHeightMultiplier,
      ),
      decoration: const BoxDecoration(
        color: AppColors.deepOlive,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Title (Centered for premium feel)
                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),

                // Close button on the "End" side (Left in Arabic, Right in English)
                if (showCloseButton)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          color: AppColors.deepOlive,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: child,
            ),
          ),

          // Footer (Actions)
          if (actions != null && actions!.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 24),
                child: Row(
                  children: actions!.map((action) {
                    final index = actions!.indexOf(action);
                    return Expanded(
                      flex: action is! IconButton && action is! Container
                          ? 1
                          : 0,
                      child: Padding(
                        padding: EdgeInsetsDirectional.only(
                          end: index < actions!.length - 1 ? 12 : 0,
                        ),
                        child: action,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Option for BourraqBottomSheet.showChoice
class BottomSheetOption<T> {
  final T id;
  final String label;
  final IconData? icon;
  final Widget? trailing;

  const BottomSheetOption({
    required this.id,
    required this.label,
    this.icon,
    this.trailing,
  });
}
