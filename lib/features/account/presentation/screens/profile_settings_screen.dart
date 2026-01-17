import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

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
          Navigator.pop(context); // Close dialog if open
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
          // Allow AuthAuthenticated OR AuthPasswordResetOtpSent (to keep showing settings while redirecting)
          // But effectively we only need data from AuthAuthenticated.
          // If state changes to AuthLoading/OtpSent, we might lose 'name/phone' from state if we're not careful,
          // assuming AuthCubit emits distinct states.
          // Actually AuthCubit emits NEW states, replacing the old one.
          // If we emit AuthLoading, 'state.name' will be unavailable if we try to access it via 'state as AuthAuthenticated'.
          // We need to handle the builder carefully.

          if (state is AuthLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // If we are in OtpSent state, we might still want to show the screen (or loading) until nav happens.
          // But usually we just want to ensure we have user data.
          // Let's check repository for current user data if state isn't authenticated?
          // Or better: The Cubit should probably maintain the user data in a common state or we rely on the cached controller values?

          // PROBLEM: When sendPasswordResetOTP is called, Cubit emits AuthLoading -> AuthPasswordResetOtpSent.
          // The builder below expects AuthAuthenticated to render the UI.
          // If it gets AuthPasswordResetOtpSent, it will fall into the "else" block (currently showing Loading).
          // That is actually acceptable for a momentary transition.

          if (state is! AuthAuthenticated) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final isGoogleAuth = state.isGoogleAuth;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.white,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                onPressed: () => context.pop(),
              ),
              title: Text(
                'profile.settings'.tr(),
                style: AppTextStyles.titleMedium,
              ),
              centerTitle: true,
              actions: [
                if (_hasChanges)
                  TextButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'common.save'.tr(),
                            style: TextStyle(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Login Method Indicator
                    _buildLoginMethodIndicator(isGoogleAuth),

                    const SizedBox(height: 24),

                    // Section Title
                    Text(
                      'profile.personal_info'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Name Field (Editable for all)
                    _buildInputField(
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

                    const SizedBox(height: 16),

                    // Email Field
                    _buildInputField(
                      controller: _emailController,
                      label: 'profile.email'.tr(),
                      icon: LucideIcons.mail,
                      readOnly: true, // Always read-only, edit via dialog
                      suffixIcon: isGoogleAuth
                          ? Icon(
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
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 16),

                    // Phone Field
                    _buildInputField(
                      controller: _phoneController,
                      label: 'profile.phone'.tr(),
                      icon: LucideIcons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 32),

                    // Security Section (Only for Email users)
                    if (!isGoogleAuth) ...[
                      Text(
                        'profile.security'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Change Password Button
                      _buildActionTile(
                        icon: LucideIcons.keyRound,
                        title: 'profile.change_password'.tr(),
                        onTap: () {
                          // Direct Password Reset Flow
                          // 1. Send OTP to current email
                          context.read<AuthCubit>().sendPasswordResetOTP(
                            _emailController.text.trim(),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                    ],

                    // Info Note
                    if (isGoogleAuth)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              color: Colors.blue[400],
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'profile.google_account_note'.tr(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Danger Zone
                    Text(
                      'profile.danger_zone'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[400],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Logout Button
                    _buildDangerTile(
                      icon: LucideIcons.logOut,
                      title: 'account.logout'.tr(),
                      color: Colors.orange,
                      onTap: () => _showLogoutConfirmation(),
                    ),

                    const SizedBox(height: 12),

                    // Delete Account Button
                    _buildDangerTile(
                      icon: LucideIcons.trash2,
                      title: 'account.delete_account'.tr(),
                      color: Colors.red,
                      onTap: () => _showDeleteConfirmation(),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginMethodIndicator(bool isGoogleAuth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGoogleAuth ? Colors.blue[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGoogleAuth ? Colors.blue[200]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGoogleAuth ? Colors.white : Colors.green[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: isGoogleAuth
                ? Image.asset('assets/icons/google.png', width: 24, height: 24)
                : Icon(
                    LucideIcons.mail,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGoogleAuth
                      ? 'profile.signed_in_google'.tr()
                      : 'profile.signed_in_email'.tr(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryGreen, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
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
      ),
    );
  }

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('profile.change_email'.tr()),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'profile.change_email_desc'.tr(),
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'profile.new_email'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(LucideIcons.mail),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'auth.email_required'.tr();
                  }
                  if (!value.contains('@')) {
                    return 'auth.email_invalid'.tr();
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('common.cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<AuthCubit>().requestEmailChange(
                  emailController.text.trim(),
                );
                // Don't pop here, wait for listener to pop and push (or handle loading)
                // Actually listener pops, but we might want to show loading indicator?
                // The main screen shows loading if state is AuthLoading.
                // But dialog covers it.
                // We should probably allow the listener to handle navigation.
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('common.send_otp'.tr()),
          ),
        ],
      ),
    );
  }
}
