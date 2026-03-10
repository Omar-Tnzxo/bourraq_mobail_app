import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';

/// A reusable scaffold designed specifically for Bourraq aesthetics.
/// Includes the branded curved header, standard back button logic, and consistent padding.
class BourraqScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBackButton;
  final bool isLoading;
  final Widget? footer;
  final Future<void> Function()? onRefresh;

  const BourraqScaffold({
    super.key,
    required this.title,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.actions,
    this.onBack,
    this.showBackButton = true,
    this.isLoading = false,
    this.footer,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    Widget content = isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          )
        : body;

    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppColors.primaryGreen,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          BourraqHeader(
            padding: const EdgeInsets.only(
              top: 16,
              bottom: 48,
              left: 16,
              right: 16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBackButton && canPop)
                  GestureDetector(
                    onTap: onBack ?? () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: EdgeInsets.only(
                        right: isArabic ? 0 : 12,
                        left: isArabic ? 12 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isArabic
                            ? LucideIcons.arrowRight
                            : LucideIcons.arrowLeft,
                        color: AppColors.accentYellow,
                        size: 24,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.accentYellow,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
          Expanded(child: content),
          if (footer != null) footer!,
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
