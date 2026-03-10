import 'package:bourraq/core/widgets/bourraq_widgets.dart';
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
    return BourraqScaffold(
      title: 'category.all_categories'.tr(),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.74, // Adjusted for slightly more title room
          crossAxisSpacing: 16,
          mainAxisSpacing: 24,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return BourraqListItem(
            index: index,
            child: _CategoryGridItem(
              category: category,
              onTap: () => Navigator.of(context).pop(category.id),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryGridItem extends StatelessWidget {
  final CategoryItem category;
  final VoidCallback onTap;

  const _CategoryGridItem({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = context.locale.languageCode;
    final categoryName = lang == 'ar' ? category.nameAr : category.nameEn;
    final showName = categoryName.isNotEmpty && !category.hideNameOnCard;
    final imageUrl = category.getImageUrl(lang);

    return Column(
      children: [
        Expanded(
          child: BourraqCard(
            onTap: onTap,
            padding: EdgeInsets.zero,
            backgroundColor: Colors.white,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AppColors.primaryGreen.withValues(alpha: 0.02),
                ),
                if (imageUrl.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.all(showName ? 10 : 0),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(showName ? 12 : 16),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: showName ? BoxFit.contain : BoxFit.cover,
                          placeholder: (_, __) => const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => const Icon(
                            LucideIcons.imageOff,
                            color: Colors.black12,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Icon(
                      LucideIcons.package,
                      color: Colors.black12,
                      size: 36,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 12),
          Text(
            categoryName,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
