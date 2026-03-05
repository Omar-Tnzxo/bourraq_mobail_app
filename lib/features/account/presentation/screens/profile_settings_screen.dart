import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';

/// صفحة إعدادات الملف الشخصي
/// Profile Settings Screen
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  void _loadUserData() {
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      _nameController.text = state.name;
      _phoneController.text = state.phone ?? '';
      _emailController.text = state.email;
    }
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final state = context.read<AuthCubit>().state;
    if (state is AuthAuthenticated) {
      final hasChanges =
          _nameController.text != state.name ||
          _phoneController.text != (state.phone ?? '') ||
          (!state.isGoogleAuth && _emailController.text != state.email);
      if (hasChanges != _hasChanges) {
        setState(() => _hasChanges = hasChanges);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AuthCubit>().updateProfile(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.update_success'.tr()),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        setState(() => _hasChanges = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.update_error'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetOtpSent) {
          context
              .push(
                '/reset-password-otp',
                extra: {'email': state.email, 'isProfileUpdate': true},
              )
              .then((_) => context.read<AuthCubit>().checkAuthStatus());
        } else if (state is AuthEmailUpdateOtpSent) {
          Navigator.pop(context);
          context
              .push('/email-verification', extra: {'email': state.email})
              .then((_) => context.read<AuthCubit>().checkAuthStatus());
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading || state is! AuthAuthenticated) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final isGoogleAuth = state.isGoogleAuth;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                // Header — same style as AccountScreen
                _buildHeader(state),

                // Body
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      children: [
                        // === Login Method Badge ===
                        _buildLoginMethodBadge(isGoogleAuth),

                        const SizedBox(height: 24),

                        // === Personal Info Section ===
                        _buildSectionTitle('profile.personal_info'.tr()),
                        const SizedBox(height: 12),
                        _buildPersonalInfoCard(isGoogleAuth),

                        const SizedBox(height: 24),

                        // === Security Section (Email users only) ===
                        if (!isGoogleAuth) ...[
                          _buildSectionTitle('profile.security'.tr()),
                          const SizedBox(height: 12),
                          _buildSecurityCard(),
                          const SizedBox(height: 24),
                        ],

                        // === Google Account Note ===
                        if (isGoogleAuth) ...[
                          _buildGoogleAccountNote(),
                          const SizedBox(height: 24),
                        ],

                        // === Save Button ===
                        if (_hasChanges) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveChanges,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text('common.save'.tr()),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // === Danger Zone ===
                        _buildSectionTitle(
                          'profile.danger_zone'.tr(),
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 12),
                        _buildDangerZoneCard(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Header — same BourraqHeader used in AccountScreen
  // ══════════════════════════════════════════════════════════════

  Widget _buildHeader(AuthAuthenticated state) {
    final isArabic = context.locale.languageCode == 'ar';

    return BourraqHeader(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back button row
          GestureDetector(
            onTap: () => context.pop(),
            child: Row(
              children: [
                Icon(
                  isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'profile.settings'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // User info
          Text(
            state.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            state.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Section Title — same as AccountScreen
  // ══════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title, {Color? color}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textSecondary,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Login Method Badge
  // ══════════════════════════════════════════════════════════════

  Widget _buildLoginMethodBadge(bool isGoogleAuth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGoogleAuth
            ? Colors.blue.shade50
            : AppColors.primaryGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGoogleAuth ? Colors.blue.shade200 : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: isGoogleAuth
                ? Image.asset('assets/icons/google.png', width: 22, height: 22)
                : const Icon(
                    LucideIcons.mail,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGoogleAuth
                      ? 'profile.signed_in_google'.tr()
                      : 'profile.signed_in_email'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGoogleAuth
                      ? 'profile.google_account_desc'.tr()
                      : 'profile.email_account_desc'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Personal Info Card — white container with border like account
  // ══════════════════════════════════════════════════════════════

  Widget _buildPersonalInfoCard(bool isGoogleAuth) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            style: AppTextStyles.bodyLarge,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'profile.name_required'.tr();
              }
              return null;
            },
            decoration: InputDecoration(
              labelText: 'profile.name'.tr(),
              prefixIcon: const Icon(
                LucideIcons.user,
                color: AppColors.primaryGreen,
                size: 22,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Email field
          TextFormField(
            controller: _emailController,
            readOnly: true,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            decoration: InputDecoration(
              labelText: 'profile.email'.tr(),
              prefixIcon: const Icon(
                LucideIcons.mail,
                color: AppColors.primaryGreen,
                size: 22,
              ),
              suffixIcon: isGoogleAuth
                  ? const Icon(
                      LucideIcons.lock,
                      size: 18,
                      color: AppColors.textSecondary,
                    )
                  : IconButton(
                      icon: const Icon(
                        LucideIcons.pencil,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                      onPressed: _showChangeEmailDialog,
                    ),
              fillColor: AppColors.background,
            ),
          ),

          const SizedBox(height: 16),

          // Phone field
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              labelText: 'profile.phone'.tr(),
              prefixIcon: const Icon(
                LucideIcons.phone,
                color: AppColors.primaryGreen,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Security Card
  // ══════════════════════════════════════════════════════════════

  Widget _buildSecurityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: _buildMenuItem(
        icon: LucideIcons.keyRound,
        title: 'profile.change_password'.tr(),
        onTap: () {
          context.read<AuthCubit>().sendPasswordResetOTP(
            _emailController.text.trim(),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Google Account Note
  // ══════════════════════════════════════════════════════════════

  Widget _buildGoogleAccountNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: Colors.blue[400], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'profile.google_account_note'.tr(),
              style: TextStyle(fontSize: 13, color: Colors.blue[700]),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Danger Zone Card
  // ══════════════════════════════════════════════════════════════

  Widget _buildDangerZoneCard() {
    return Column(
      children: [
        // Logout tile
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showLogoutConfirmation(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.logOut,
                        color: Colors.orange,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'account.logout'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                    Icon(
                      context.locale.languageCode == 'ar'
                          ? LucideIcons.arrowLeft
                          : LucideIcons.arrowRight,
                      size: 16,
                      color: Colors.orange.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Delete Account tile
        Container(
          decoration: BoxDecoration(
            color: Colors.red.shade50.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDeleteConfirmation(),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.trash2,
                        color: Colors.red.shade400,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'account.delete_account'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                    Icon(
                      context.locale.languageCode == 'ar'
                          ? LucideIcons.arrowLeft
                          : LucideIcons.arrowRight,
                      size: 16,
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Shared Widgets  — same pattern as AccountScreen
  // ══════════════════════════════════════════════════════════════

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final isArabic = context.locale.languageCode == 'ar';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.primaryGreen, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
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

  // ══════════════════════════════════════════════════════════════
  // Dialogs
  // ══════════════════════════════════════════════════════════════

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('account.logout_confirm_title'.tr()),
        content: Text('account.logout_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final authCubit = context.read<AuthCubit>();
              final router = GoRouter.of(context);
              Navigator.pop(ctx);
              await authCubit.logout();
              if (mounted) {
                router.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text('account.logout'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('account.delete_confirm_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('account.delete_confirm_message'.tr()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.triangleAlert,
                    color: Colors.red[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'account.delete_warning'.tr(),
                      style: TextStyle(fontSize: 13, color: Colors.red[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final authCubit = context.read<AuthCubit>();
              final router = GoRouter.of(context);
              Navigator.pop(ctx);
              await authCubit.deleteAccount();
              if (mounted) {
                router.go('/login');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('account.delete_account'.tr()),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'profile.change_email'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'profile.change_email_desc'.tr(),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'profile.new_email'.tr(),
                  prefixIcon: const Icon(
                    LucideIcons.mail,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'auth.error_email_required'.tr();
                  }
                  if (!value.contains('@')) {
                    return 'auth.error_email_invalid'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('common.cancel'.tr()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      context.read<AuthCubit>().requestEmailChange(
                        emailController.text.trim(),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('common.send'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
