import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/features/home/presentation/widgets/home_banners_carousel.dart';

/// Spotlight Banner Widget
/// Displays a static or manually scrollable banner section
class HomeBannersSpotlight extends StatelessWidget {
  final List<BannerItem> banners;
  final Function(BannerItem)? onBannerTap;

  const HomeBannersSpotlight({
    super.key,
    required this.banners,
    this.onBannerTap,
  });

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: banners
            .map((banner) => _buildBanner(context, banner))
            .toList(),
      ),
    );
  }

  Widget _buildBanner(BuildContext context, BannerItem banner) {
    final isArabic = context.locale.languageCode == 'ar';
    final imageUrl = isArabic
        ? banner.imageUrl
        : (banner.imageUrlEn ?? banner.imageUrl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => onBannerTap?.call(banner),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          height: 140,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.skeletonBase,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: AppColors.skeletonBase),
                  errorWidget: (context, url, error) => _buildPlaceholder(),
                )
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.deepOlive.withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.image, color: AppColors.deepOlive, size: 40),
      ),
    );
  }
}
