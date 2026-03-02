import 'package:bourraq/features/categories/data/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';

/// Home Categories Section Widget (Breadfast-style grid)
/// Displays all product categories in a 3-column grid
class HomeCategoriesSection extends StatelessWidget {
  final List<CategoryItem> categories;
  final String? title;

  const HomeCategoriesSection({
    super.key,
    required this.categories,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final displayTitle = title ?? 'home.categories'.tr();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            displayTitle,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Categories Grid (3 columns)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryCard(
                category: category,
                isArabic: isArabic,
                onTap: () => context.push(
                  '/category/${category.slug}?name=${Uri.encodeComponent(isArabic ? category.nameAr : category.nameEn)}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem category;
  final bool isArabic;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName = isArabic ? category.nameAr : category.nameEn;
    final hasName = categoryName.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: hasName ? Border.all(color: AppColors.borderLight) : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Image
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      category
                          .getImageUrl(context.locale.languageCode)
                          .isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: category.getImageUrl(
                            context.locale.languageCode,
                          ),
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              _buildPlaceholderIcon(),
                          errorWidget: (context, url, error) =>
                              _buildPlaceholderIcon(),
                        )
                      : _buildPlaceholderIcon(),
                ),
              ),
            ),
            if (!category.hideNameOnCard) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
                child: Text(
                  isArabic ? category.nameAr : category.nameEn,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.category_outlined,
          size: 32,
          color: AppColors.deepOlive,
        ),
      ),
    );
  }
}

/// Category model
