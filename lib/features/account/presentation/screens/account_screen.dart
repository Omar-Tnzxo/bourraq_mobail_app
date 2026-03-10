import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/core/widgets/contact_options_sheet.dart';
import 'package:bourraq/core/widgets/app_price_display.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';
import 'package:bourraq/features/wallet/data/wallet_service.dart';
import 'package:bourraq/core/widgets/logout_confirmation_dialog.dart';

/// صفحة الحساب - مُعاد تصميمها وفقاً لـ Rabbit UI Reference
/// وتتبع UI-UX-QUALITY-RULES.MD و BRAND_IDENTITY.md
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final WalletService _walletService = WalletService();
  double _walletBalance = 0.0;
  bool _isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _loadWalletBalance();
  }

  Future<void> _loadWalletBalance() async {
    final wallet = await _walletService.getWallet();
    if (mounted) {
      setState(() {
        _walletBalance = wallet?.balance ?? 0.0;
        _isLoadingBalance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final bool isGuest = state is! AuthAuthenticated;
        final String userName = state is AuthAuthenticated
            ? state.name
            : 'account.guest'.tr();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // Premium Curved Account Header
              _buildHeader(context, userName, isGuest),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    // === Quick Actions (3 icons row) ===
                    if (!isGuest) ...[
                      _buildQuickActions(context),
                      const SizedBox(height: 20),
                    ],

                    // === Wallet Card (for authenticated) OR Login Card (for guests) ===
                    if (!isGuest) ...[
                      _buildWalletCard(context),
                      const SizedBox(height: 24),
                    ] else ...[
                      _buildLoginPromotionCard(context),
                      const SizedBox(height: 24),
                    ],

                    // === Account Section ===
                    _buildSectionTitle('account.section_account'.tr()),
                    const SizedBox(height: 12),
                    _buildAccountSection(context, isGuest),

                    const SizedBox(height: 24),

                    // === Help & Support Section ===
                    _buildSectionTitle('account.section_support'.tr()),
                    const SizedBox(height: 12),
                    _buildSupportSection(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String userName, bool isGuest) {
    return BourraqHeader(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 44),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Logo Circle
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.accentYellow,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              'assets/icons/white_icon_logo.png', // Assuming this is the logo, using white_icon_logo as reference
              color: AppColors.primaryGreen,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'account.hello'.tr(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.white,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isGuest) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentYellow.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.logIn,
                            size: 13,
                            color: AppColors.accentYellow,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'account.login_or_register'.tr(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accentYellow,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Logout / Action Button
          if (!isGuest)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.logOut,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => _showLogoutConfirmation(context),
            ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) async {
    final shouldLogout = await LogoutConfirmationDialog.show(context);
    if (shouldLogout && context.mounted) {
      context.read<AuthCubit>().logout();
    }
  }

  /// Quick Actions Row (My Orders, Promo Codes, Saved Items)
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickActionItem(
            icon: LucideIcons.receiptText,
            label: 'account.my_orders'.tr(),
            onTap: () => context.push('/orders'),
          ),
          _buildVerticalDivider(),
          _buildQuickActionItem(
            icon: LucideIcons.ticket,
            label: 'account.promo_codes'.tr(),
            onTap: () {
              context.push('/promo-codes');
            },
          ),
          _buildVerticalDivider(),
          _buildQuickActionItem(
            icon: LucideIcons.heart,
            label: 'account.saved_items'.tr(),
            onTap: () => context.push('/favorites'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 26),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 50, width: 1, color: AppColors.border);
  }

  /// Wallet Card with balance and view transactions link
  Widget _buildWalletCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/wallet'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryGreen.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Balance Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'wallet.balance'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _isLoadingBalance
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : AppPriceDisplay(
                              price: _walletBalance,
                              textColor: Colors.white,
                              scale: 1.77,
                            ),
                    ],
                  ),
                ],
              ),
            ),

            // View Transactions Link
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(
                    'wallet.transactions'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    LucideIcons.refreshCw,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Login Promotion Card for guests
  Widget _buildLoginPromotionCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/login'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGreen,
              AppColors.primaryGreen.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Login Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'guest.login_card_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'guest.login_card_subtitle'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.arrowRight,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Title
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// Account Section (Profile, Addresses, Cards, Language)
  Widget _buildAccountSection(BuildContext context, bool isGuest) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (!isGuest) ...[
            _buildMenuItem(
              context: context,
              icon: LucideIcons.user,
              title: 'account.profile_settings'.tr(),
              onTap: () => context.push('/profile-settings'),
            ),
            _buildDivider(),
            _buildMenuItem(
              context: context,
              icon: LucideIcons.mapPin,
              title: 'account.my_addresses'.tr(),
              onTap: () => context.push('/addresses'),
            ),
            _buildDivider(),
            _buildMenuItem(
              context: context,
              icon: LucideIcons.creditCard,
              title: 'account.saved_cards'.tr(),
              onTap: () => context.push('/wallet/saved-cards'),
            ),
            _buildDivider(),
          ],
          _buildMenuItem(
            context: context,
            icon: LucideIcons.languages,
            title: 'settings.language'.tr(),
            trailing: Text(
              context.locale.languageCode == 'ar'
                  ? 'settings.arabic'.tr()
                  : 'settings.english'.tr(),
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            onTap: () => _showLanguagePicker(context),
          ),
        ],
      ),
    );
  }

  /// Support Section (FAQs, Contact, Missing Something, Legal)
  Widget _buildSupportSection(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            context: context,
            icon: LucideIcons.circleQuestionMark,
            title: 'account.faqs'.tr(),
            onTap: () => context.push('/faqs'),
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: LucideIcons.messageCircle,
            title: 'account.contact_us'.tr(),
            subtitle: 'account.share_feedback'.tr(),
            onTap: () => ContactOptionsSheet.show(context),
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: LucideIcons.circlePlus,
            title: 'account.missing_area'.tr(),
            subtitle: 'account.request_area'.tr(),
            onTap: () => context.push('/area-request'),
          ),
          _buildDivider(),
          _buildMenuItem(
            context: context,
            icon: LucideIcons.fileText,
            title: 'account.legal'.tr(),
            onTap: () => _showLegalOptions(context),
          ),
        ],
      ),
    );
  }

  /// Menu Item Widget
  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 1,
      color: AppColors.border,
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Dialog Methods
  // ══════════════════════════════════════════════════════════════

  void _showLanguagePicker(BuildContext context) {
    BourraqBottomSheet.show(
      context: context,
      title: 'settings.select_language'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageOption(
            context: context,
            title: 'العربية',
            isSelected: context.locale.languageCode == 'ar',
            onTap: () {
              HapticFeedback.selectionClick();
              context.setLocale(const Locale('ar'));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _buildLanguageOption(
            context: context,
            title: 'English',
            isSelected: context.locale.languageCode == 'en',
            onTap: () {
              HapticFeedback.selectionClick();
              context.setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                LucideIcons.circleCheck,
                color: AppColors.primaryGreen,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showLegalOptions(BuildContext context) {
    BourraqBottomSheet.show(
      context: context,
      title: 'account.legal'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegalItem(
            icon: LucideIcons.fileText,
            title: 'account.terms'.tr(),
            onTap: () {
              Navigator.pop(context);
              context.push('/pages/terms');
            },
          ),
          const SizedBox(height: 12),
          _buildLegalItem(
            icon: LucideIcons.shield,
            title: 'account.privacy'.tr(),
            onTap: () {
              Navigator.pop(context);
              context.push('/pages/privacy');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLegalItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white24,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
