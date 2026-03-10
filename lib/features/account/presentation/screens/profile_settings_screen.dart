import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';
import 'package:bourraq/core/widgets/logout_confirmation_dialog.dart';
import 'package:bourraq/core/widgets/delete_account_confirmation_dialog.dart';

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
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveChanges,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: AppColors.primaryGreen.withValues(
                                  alpha: 0.3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'common.save'.tr(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 44),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                color: AppColors.accentYellow,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title
          Expanded(
            child: Text(
              'profile.settings'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
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
            ? Colors.blue.withValues(alpha: 0.05)
            : AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGoogleAuth
              ? Colors.blue.withValues(alpha: 0.15)
              : AppColors.primaryGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
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
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGoogleAuth
                      ? 'profile.google_account_desc'.tr()
                      : 'profile.email_account_desc'.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
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

  // ══════════════════════════════════════════════════════════════
  // Personal Info Card — white container with border like account
  // ══════════════════════════════════════════════════════════════

  Widget _buildPersonalInfoCard(bool isGoogleAuth) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Name field
          _buildTextField(
            controller: _nameController,
            label: 'profile.name'.tr(),
            icon: LucideIcons.user,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'profile.name_required'.tr();
              }
              return null;
            },
          ),

          const SizedBox(height: 12),
          _buildDivider(),
          const SizedBox(height: 12),

          // Email field
          _buildTextField(
            controller: _emailController,
            label: 'profile.email'.tr(),
            icon: LucideIcons.mail,
            readOnly: true,
            suffixIcon: isGoogleAuth
                ? Icon(
                    LucideIcons.lock,
                    size: 18,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  )
                : IconButton(
                    icon: const Icon(
                      LucideIcons.pencil,
                      size: 18,
                      color: AppColors.primaryGreen,
                    ),
                    onPressed: _showChangeEmailDialog,
                  ),
          ),

          const SizedBox(height: 12),
          _buildDivider(),
          const SizedBox(height: 12),

          // Phone field
          _buildTextField(
            controller: _phoneController,
            label: 'profile.phone'.tr(),
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTextStyles.bodyLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.primaryGreen.withValues(alpha: 0.8),
          size: 20,
        ),
        suffixIcon: suffixIcon,
        filled: false,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
            ),
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
                        color: AppColors.primaryGreen.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.logOut,
                        color: AppColors.primaryGreen,
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
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    Icon(
                      context.locale.languageCode == 'ar'
                          ? LucideIcons.arrowLeft
                          : LucideIcons.arrowRight,
                      size: 16,
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
            ),
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
                        color: AppColors.primaryGreen.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.trash2,
                        color: AppColors.primaryGreen.withValues(alpha: 0.7),
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
                          color: AppColors.primaryGreen.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    Icon(
                      context.locale.languageCode == 'ar'
                          ? LucideIcons.arrowLeft
                          : LucideIcons.arrowRight,
                      size: 16,
                      color: AppColors.primaryGreen.withValues(alpha: 0.3),
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

  Widget _buildDivider() {
    return Container(height: 1, color: AppColors.border.withValues(alpha: 0.5));
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

  void _showLogoutConfirmation() async {
    final shouldLogout = await LogoutConfirmationDialog.show(context);
    if (shouldLogout && context.mounted) {
      context.read<AuthCubit>().logout();
    }
  }

  void _showDeleteConfirmation() async {
    final shouldDelete = await DeleteAccountConfirmationDialog.show(context);
    if (shouldDelete && context.mounted) {
      context.read<AuthCubit>().deleteAccount();
    }
  }

  void _showChangeEmailDialog() async {
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldChange = await BourraqDialog.show(
      context,
      title: 'profile.change_email'.tr(),
      confirmLabel: 'common.confirm'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      icon: LucideIcons.mail,
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
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            BourraqTextField(
              label: 'profile.new_email'.tr(),
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(
                LucideIcons.mail,
                color: AppColors.primaryGreen,
                size: 22,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'auth.error_email_required'.tr();
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value.trim())) {
                  return 'auth.error_invalid_email'.tr();
                }
                if (value.trim() == _emailController.text) {
                  return 'profile.email_same_error'.tr();
                }
                return null;
              },
            ),
          ],
        ),
      ),
      onConfirm: () {
        if (formKey.currentState!.validate()) {
          Navigator.pop(context, true);
        }
      },
    );

    if (shouldChange == true && mounted) {
      context.read<AuthCubit>().requestEmailChange(emailController.text.trim());
    }
  }
}
