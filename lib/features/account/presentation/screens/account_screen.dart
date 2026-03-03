import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/core/widgets/contact_options_sheet.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';
import 'package:bourraq/features/wallet/data/wallet_service.dart';

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

                    const SizedBox(height: 24),

                    // === Social Media Links ===
                    _buildSocialLinks(context),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${'account.hello'.tr()} $userName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          if (isGuest)
            GestureDetector(
              onTap: () => context.go('/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'account.login_or_register'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => context.push('/profile-settings'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.settings,
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'account.profile_settings'.tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
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
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _walletBalance.floor().toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '.${((_walletBalance - _walletBalance.floor()) * 100).round().toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'common.egp'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                Localizations.localeOf(context).languageCode == 'ar'
                    ? LucideIcons.arrowLeft
                    : LucideIcons.arrowRight,
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

  /// Account Section (Addresses, Cards, Language, Country)
  Widget _buildAccountSection(BuildContext context, bool isGuest) {
    return Container(
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
                  Icon(
                    isArabic ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
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

  /// Social Links
  Widget _buildSocialLinks(BuildContext context) {
    return Column(
      children: [
        Text(
          'account.follow_us'.tr(),
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(
              icon: LucideIcons.facebook,
              onTap: () => _launchUrl('https://www.facebook.com/Bourraq'),
            ),
            const SizedBox(width: 24),
            _buildSocialIcon(
              icon: LucideIcons.globe,
              onTap: () => _launchUrl('http://www.bourraq.com/'),
            ),
            const SizedBox(width: 24),
            _buildSocialIcon(
              icon: LucideIcons.phone,
              onTap: () => _launchUrl('https://wa.me/+201102450471'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 22),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Dialog Methods
  // ══════════════════════════════════════════════════════════════

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'settings.select_language'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildLanguageOption(
              context: context,
              title: 'العربية',
              isSelected: context.locale.languageCode == 'ar',
              onTap: () {
                context.setLocale(const Locale('ar'));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            _buildLanguageOption(
              context: context,
              title: 'English',
              isSelected: context.locale.languageCode == 'en',
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.border,
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? AppColors.primaryGreen
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'account.legal'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(LucideIcons.fileText),
              title: Text('account.terms'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/pages/terms');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.shield),
              title: Text('account.privacy'.tr()),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/pages/privacy');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
