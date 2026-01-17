import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleEmailLogin() async {
    // Smooth animation on button press
    setState(() => _isLoading = true);

    // Small delay for smooth visual feedback
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    context.push('/email-login');

    setState(() => _isLoading = false);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      await context.read<AuthCubit>().signInWithGoogle();
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _handleGuestExplore() {
    context.read<AuthCubit>().enterGuestMode();
    context.go('/home');
  }

  void _showLanguageDialog() {
    final isArabic = context.locale.languageCode == 'ar';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isArabic ? 'اختر اللغة' : 'Select Language',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arabic Option
              InkWell(
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  context.setLocale(const Locale('ar'));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isArabic
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isArabic
                          ? AppColors.primaryGreen
                          : AppColors.borderLight,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('🇪🇬', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'العربية',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isArabic
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isArabic
                                ? AppColors.primaryGreen
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isArabic)
                        Icon(
                          LucideIcons.circleCheck,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // English Option
              InkWell(
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  context.setLocale(const Locale('en'));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: !isArabic
                        ? AppColors.primaryGreen.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: !isArabic
                          ? AppColors.primaryGreen
                          : AppColors.borderLight,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text('🇬🇧', style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'English',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: !isArabic
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: !isArabic
                                ? AppColors.primaryGreen
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isArabic)
                        Icon(
                          LucideIcons.circleCheck,
                          color: AppColors.primaryGreen,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Check if we are in password reset flow
          final currentPath = GoRouter.of(
            context,
          ).routeInformationProvider.value.uri.path;
          if (currentPath.contains('reset-password') ||
              currentPath.contains('forgot-password')) {
            return;
          }
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            Column(
              children: [
                // Top Section: Image Background (55% of screen)
                Expanded(
                  flex: 55,
                  child: Stack(
                    children: [
                      // Background Image
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/login_background.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.orange.shade200,
                                    Colors.brown.shade300,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Subtle Dark Overlay for Text Readability
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.1),
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Language Switcher (Top Right) - Must be direct child of Stack
                      Positioned(
                        top: 50,
                        right: isArabic ? null : 20,
                        left: isArabic ? 20 : null,
                        child: GestureDetector(
                          onTap: _showLanguageDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isArabic ? '🇬🇧' : '🇪🇬',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  LucideIcons.chevronDown,
                                  size: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Welcome Text Over Image (Bottom of Image Section)
                      Positioned(
                        bottom: 30,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            // "Welcome to"
                            Text(
                              'auth.welcome_to'.tr(),
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                    color: Colors.black38,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // App Logo
                            Image.asset(
                              'assets/images/white_logo.png',
                              height: 60,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to text if logo fails to load
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'app_name'.tr().toLowerCase(),
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Section: White Background (45% of screen)
                Expanded(
                  flex: 45,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        // Tagline
                        Text(
                          'auth.login_tagline'.tr(),
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),

                        // Email Button
                        _buildAuthButton(
                          onPressed: _isLoading ? null : _handleEmailLogin,
                          icon: LucideIcons.mail,
                          iconColor: const Color(0xFFEA4335), // Gmail red
                          label: 'auth.continue_with_email'.tr(),
                        ),
                        const SizedBox(height: 14),

                        // Google Button
                        _buildAuthButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: null,
                          label: 'auth.google_signin'.tr(),
                          customIcon: Image.asset(
                            'assets/icons/google.png',
                            height: 22,
                            errorBuilder: (_, __, ___) => const Icon(
                              LucideIcons.globe,
                              size: 24,
                              color: Color(0xFF4285F4), // Google blue
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.borderLight,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'auth.or'.tr(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Container(
                                height: 1,
                                color: AppColors.borderLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Explore as Guest Button
                        GestureDetector(
                          onTap: _isLoading ? null : _handleGuestExplore,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.compass,
                                size: 20,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'guest.explore_without_account'.tr(),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Loading Overlay
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required VoidCallback? onPressed,
    IconData? icon,
    Color? iconColor,
    Widget? customIcon,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
            side: BorderSide(color: AppColors.borderLight, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, size: 22, color: iconColor ?? AppColors.textPrimary)
            else if (customIcon != null)
              customIcon,
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
