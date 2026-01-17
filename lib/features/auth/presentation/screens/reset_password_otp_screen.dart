import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';
import 'dart:async';
import 'dart:ui' as ui;

class ResetPasswordOTPScreen extends StatefulWidget {
  final String email;
  final bool isProfileUpdate;

  const ResetPasswordOTPScreen({
    super.key,
    required this.email,
    this.isProfileUpdate = false,
  });

  @override
  State<ResetPasswordOTPScreen> createState() => _ResetPasswordOTPScreenState();
}

class _ResetPasswordOTPScreenState extends State<ResetPasswordOTPScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmVisible = false;
  bool _otpVerified = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendCountdown = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _resendTimer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String get _otpCode => _otpControllers.map((c) => c.text).join();

  void _handleVerifyOTP() {
    if (_otpCode.length != 6) {
      _showErrorDialog('auth.errors.otp_required'.tr());
      return;
    }

    context.read<AuthCubit>().verifyPasswordResetOTP(
      email: widget.email,
      otp: _otpCode,
    );
  }

  void _handleResetPassword() {
    FocusScope.of(context).unfocus();

    final password = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty) {
      _showErrorDialog('auth.errors.password_required'.tr());
      return;
    }
    if (password.length < 6) {
      _showErrorDialog('auth.errors.password_min'.tr());
      return;
    }
    if (password != confirm) {
      _showErrorDialog('auth.errors.passwords_not_match'.tr());
      return;
    }

    context.read<AuthCubit>().resetPassword(
      email: widget.email,
      otp: _otpCode,
      newPassword: password,
    );
  }

  void _handleResend() {
    if (!_canResend) return;
    context.read<AuthCubit>().sendPasswordResetOTP(widget.email);
    _startResendTimer();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.circleAlert,
            color: AppColors.error,
            size: 40,
          ),
        ),
        content: Text(
          message.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('common.close'.tr()),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.circleCheck,
            color: AppColors.primaryGreen,
            size: 50,
          ),
        ),
        title: Text(
          'auth.password_reset_success'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'auth.password_reset_success_message'.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (widget.isProfileUpdate) {
                  // If updating profile, just pop back to settings
                  context.pop();
                } else {
                  // If forgot password, go to login
                  context.go('/email-login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                widget.isProfileUpdate
                    ? 'common.continue'.tr()
                    : 'auth.login'.tr(),
              ),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthPasswordResetOtpVerified) {
          setState(() => _otpVerified = true);
        } else if (state is AuthPasswordResetSuccess) {
          _showSuccessDialog();
        } else if (state is AuthError) {
          _showErrorDialog(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),

                      // زر الرجوع
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _buildBackButton(),
                      ),

                      const SizedBox(height: 30),

                      // الأيقونة
                      _buildIcon(),

                      const SizedBox(height: 30),

                      // العنوان
                      _buildHeader(),

                      const SizedBox(height: 32),

                      if (!_otpVerified) ...[
                        // حقول OTP
                        _buildOTPFields(),

                        const SizedBox(height: 24),

                        // إعادة الإرسال
                        _buildResendRow(),

                        const SizedBox(height: 32),

                        // زر التحقق
                        _buildVerifyButton(isLoading),
                      ] else ...[
                        // حقول كلمة المرور الجديدة
                        _buildPasswordFields(),

                        const SizedBox(height: 32),

                        // زر إعادة تعيين كلمة المرور
                        _buildResetButton(isLoading),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _otpVerified ? LucideIcons.lockOpen : LucideIcons.mail,
          size: 50,
          color: AppColors.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _otpVerified ? 'auth.new_password_title'.tr() : 'auth.otp_title'.tr(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            children: [
              TextSpan(
                text: _otpVerified
                    ? 'auth.new_password_subtitle'.tr()
                    : '${'auth.otp_subtitle'.tr()} ',
              ),
              if (!_otpVerified)
                TextSpan(
                  text: widget.email,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryGreen,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPFields() {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(6, (index) {
          return SizedBox(
            width: 48,
            height: 58,
            child: TextFormField(
              controller: _otpControllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.borderLight,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryGreen,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty && index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }

                if (_otpCode.length == 6) {
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildResendRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'auth.didnt_receive'.tr(),
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: _canResend ? _handleResend : null,
          child: Text(
            _canResend
                ? 'auth.resend'.tr()
                : 'auth.resend_after'.tr(args: [_resendCountdown.toString()]),
            style: TextStyle(
              color: _canResend
                  ? AppColors.primaryGreen
                  : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        // كلمة المرور الجديدة
        _buildPasswordField(
          controller: _newPasswordController,
          focusNode: _passwordFocus,
          label: 'auth.new_password'.tr(),
          isVisible: _isPasswordVisible,
          onToggle: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
          onSubmitted: () => _confirmFocus.requestFocus(),
        ),

        const SizedBox(height: 16),

        // تأكيد كلمة المرور
        _buildPasswordField(
          controller: _confirmPasswordController,
          focusNode: _confirmFocus,
          label: 'auth.confirm_password'.tr(),
          isVisible: _isConfirmVisible,
          onToggle: () =>
              setState(() => _isConfirmVisible = !_isConfirmVisible),
          onSubmitted: _handleResetPassword,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
    required VoidCallback onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: !isVisible,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) => onSubmitted(),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: '••••••••',
        prefixIcon: Icon(LucideIcons.lock, color: AppColors.primaryGreen),
        suffixIcon: IconButton(
          icon: Icon(
            isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
            color: AppColors.textSecondary,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }

  Widget _buildVerifyButton(bool isLoading) {
    return _buildGradientButton(
      onTap: isLoading ? null : _handleVerifyOTP,
      isLoading: isLoading,
      icon: LucideIcons.circleCheck,
      label: 'auth.verify'.tr(),
    );
  }

  Widget _buildResetButton(bool isLoading) {
    return _buildGradientButton(
      onTap: isLoading ? null : _handleResetPassword,
      isLoading: isLoading,
      icon: LucideIcons.keyRound,
      label: 'auth.reset_password'.tr(),
    );
  }

  Widget _buildGradientButton({
    required VoidCallback? onTap,
    required bool isLoading,
    required IconData icon,
    required String label,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isLoading
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [AppColors.primaryGreen, const Color(0xFF6BAB3D)],
        ),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
