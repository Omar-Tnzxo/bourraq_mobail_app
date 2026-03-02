import 'package:bourraq/features/categories/data/models/category_model.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';

class CategoriesListScreen extends StatelessWidget {
  final List<CategoryItem> categories;

  const CategoriesListScreen({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryGreen,
        elevation: 0,
        title: Text(
          'category.all_categories'.tr(),
          style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return _CategoryListItem(
            category: category,
            isArabic: isArabic,
            onTap: () {
              Navigator.of(context).pop(category.id);
            },
          );
        },
      ),
    );
  }
}

class _CategoryListItem extends StatelessWidget {
  final CategoryItem category;
  final bool isArabic;
  final VoidCallback onTap;

  const _CategoryListItem({
    required this.category,
    required this.isArabic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName = isArabic ? category.nameAr : category.nameEn;
    final hasName = categoryName.isNotEmpty && !category.hideNameOnCard;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  category.getImageUrl(context.locale.languageCode).isNotEmpty
                  ? Padding(
                      padding: EdgeInsets.all(hasName ? 12 : 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(hasName ? 8 : 16),
                        child: CachedNetworkImage(
                          imageUrl: category.getImageUrl(
                            context.locale.languageCode,
                          ),
                          width: double.infinity,
                          height: double.infinity,
                          fit: hasName ? BoxFit.contain : BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(LucideIcons.image, color: Colors.grey),
                        ),
                      ),
                    )
                  : const Icon(
                      LucideIcons.package,
                      color: AppColors.primaryGreen,
                      size: 32,
                    ),
            ),
          ),
          if (hasName) ...[
            const SizedBox(height: 8),
            Text(
              categoryName,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
