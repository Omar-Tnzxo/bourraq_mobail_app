import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/onboarding_repository.dart';
import '../data/onboarding_screen_model.dart';

/// Dynamic Onboarding Screen - fetches content from database
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final OnboardingRepository _repository = OnboardingRepository();

  List<OnboardingScreenModel> _screens = [];
  bool _isLoading = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadOnboardingScreens();
  }

  Future<void> _loadOnboardingScreens() async {
    final screens = await _repository.getOnboardingScreens();

    if (mounted) {
      setState(() {
        _screens = screens;
        _isLoading = false;
      });

      // If no screens from DB, use fallback
      if (_screens.isEmpty) {
        _useFallbackScreens();
      }
    }
  }

  /// Fallback screens if database is empty or unavailable
  void _useFallbackScreens() {
    _screens = [
      OnboardingScreenModel(
        id: '1',
        imageUrl: 'assets/oneboarding/online_order.png',
        titleAr: 'onboarding.page1_title'.tr(),
        titleEn: 'onboarding.page1_title'.tr(),
        descriptionAr: 'onboarding.page1_desc'.tr(),
        descriptionEn: 'onboarding.page1_desc'.tr(),
        displayOrder: 1,
      ),
      OnboardingScreenModel(
        id: '2',
        imageUrl: 'assets/oneboarding/fast_delivery_motorcycle.png',
        titleAr: 'onboarding.page2_title'.tr(),
        titleEn: 'onboarding.page2_title'.tr(),
        descriptionAr: 'onboarding.page2_desc'.tr(),
        descriptionEn: 'onboarding.page2_desc'.tr(),
        displayOrder: 2,
      ),
      OnboardingScreenModel(
        id: '3',
        imageUrl: 'assets/oneboarding/order_tracking.png',
        titleAr: 'onboarding.page3_title'.tr(),
        titleEn: 'onboarding.page3_title'.tr(),
        descriptionAr: 'onboarding.page3_desc'.tr(),
        descriptionEn: 'onboarding.page3_desc'.tr(),
        displayOrder: 3,
      ),
    ];
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;
    final isArabic = languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              )
            : Column(
                children: [
                  // Skip Button
                  Align(
                    alignment: isArabic
                        ? Alignment.topLeft
                        : Alignment.topRight,
                    child: TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        'onboarding.skip'.tr(),
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // Page View
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemCount: _screens.length,
                      itemBuilder: (context, index) {
                        final screen = _screens[index];
                        return Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Illustration Image
                              _buildImage(screen.imageUrl),
                              const SizedBox(height: 48),

                              // Title
                              Text(
                                screen.getTitle(languageCode),
                                style: AppTextStyles.headlineLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              // Description
                              Text(
                                screen.getDescription(languageCode),
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _screens.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.deepOlive
                              : AppColors.deepOlive.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Next/Get Started Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == _screens.length - 1) {
                            _completeOnboarding();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: Text(
                          _currentPage == _screens.length - 1
                              ? 'onboarding.get_started'.tr()
                              : 'onboarding.next'.tr(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  /// Build image widget - supports both local assets and network URLs
  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      // Network image
      return Image.network(
        imageUrl,
        width: 280,
        height: 280,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            width: 280,
            height: 280,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primaryGreen,
              ),
            ),
          );
        },
      );
    } else {
      // Local asset
      return Image.asset(
        imageUrl,
        width: 280,
        height: 280,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 80,
        color: AppColors.primaryGreen.withValues(alpha: 0.5),
      ),
    );
  }
}
