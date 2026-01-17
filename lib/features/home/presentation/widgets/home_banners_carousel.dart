import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bourraq/core/constants/app_colors.dart';

/// Home Banners Carousel Widget (Breadfast-style)
/// Displays promotional banners in a horizontal carousel with dynamic config
class HomeBannersCarousel extends StatefulWidget {
  final List<BannerItem> banners;
  final Function(BannerItem)? onBannerTap;
  final bool autoScroll;
  final int autoScrollIntervalMs;

  const HomeBannersCarousel({
    super.key,
    required this.banners,
    this.onBannerTap,
    this.autoScroll = true,
    this.autoScrollIntervalMs = 4000,
  });

  @override
  State<HomeBannersCarousel> createState() => _HomeBannersCarouselState();
}

class _HomeBannersCarouselState extends State<HomeBannersCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    if (widget.autoScroll && widget.banners.length > 1) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    Future.delayed(Duration(milliseconds: widget.autoScrollIntervalMs), () {
      if (mounted && widget.autoScroll) {
        final nextPage = (_currentPage + 1) % widget.banners.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    // Fixed height - images will be scaled to fit within this height
    const bannerHeight = 160.0;

    return Column(
      children: [
        SizedBox(
          height: bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              // Use correct language image if available
              final isArabic = context.locale.languageCode == 'ar';
              final imageUrl = isArabic
                  ? banner.imageUrl
                  : (banner.imageUrlEn ?? banner.imageUrl);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => widget.onBannerTap?.call(banner),
                  child: Container(
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.skeletonBase,
                    ),
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) => Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: AppColors.skeletonBase,
                              ),
                            ),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholderBanner(index),
                          )
                        : _buildPlaceholderBanner(index),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Page Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppColors.deepOlive
                    : AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderBanner(int index) {
    final colors = [
      AppColors.deepOlive,
      AppColors.primaryGreen,
      AppColors.darkGreen,
    ];
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[index % colors.length],
            colors[index % colors.length].withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 48,
          color: AppColors.white.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Banner model for carousel
class BannerItem {
  final String id;
  final String imageUrl;
  final String? imageUrlEn;
  final String? actionUrl;
  final bool isExternal;

  const BannerItem({
    required this.id,
    required this.imageUrl,
    this.imageUrlEn,
    this.actionUrl,
    this.isExternal = false,
  });
}
