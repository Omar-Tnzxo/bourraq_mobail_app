import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? name;
  final String? phone;
  final String? password;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.name,
    this.phone,
    this.password,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _canResend = false;
  int _resendCountdown = 60;
  bool _isVerifying = false; // منع التكرار

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
          _startCountdown();
        } else {
          _canResend = true;
        }
      });
    });
  }

  void _verifyOtp() {
    // منع التكرار
    if (_isVerifying) return;

    final otp = _otpControllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.error_otp_required'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // تفعيل الحماية
    setState(() => _isVerifying = true);

    // Call AuthCubit to verify
    context.read<AuthCubit>().verifyOtpAndCreateAccount(
      email: widget.email,
      otp: otp,
      name: widget.name ?? '',
      phone: widget.phone ?? '',
      password: widget.password ?? '',
    );
  }

  void _resendOtp() {
    if (!_canResend) return;

    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    // Call AuthCubit to resend
    context.read<AuthCubit>().resendOtp(widget.email);
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Success - navigate to home
          context.go('/home');
        } else if (state is AuthOtpSent) {
          // OTP resent successfully
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('auth.otp_resent_success'.tr()),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AuthError) {
          // Reset verifying flag so user can retry
          setState(() => _isVerifying = false);
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message.tr()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                LucideIcons.arrowLeft,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.go('/login'),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icon
                  const Icon(
                    LucideIcons.mailCheck,
                    size: 80,
                    color: AppColors.primaryGreen,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'auth.otp_title'.tr(),
                    style: AppTextStyles.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(text: '${'auth.otp_subtitle'.tr()} '),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  //OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return SizedBox(
                        width: 48,
                        child: TextField(
                          controller: _otpControllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: AppTextStyles.headlineMedium,
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }

                            // Auto-verify when all fields are filled
                            if (index == 5 && value.isNotEmpty) {
                              _verifyOtp();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),

                  // Verify Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(elevation: 0),
                    onPressed: isLoading ? null : _verifyOtp,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.white,
                              ),
                            ),
                          )
                        : Text('auth.verify'.tr()),
                  ),
                  const SizedBox(height: 24),

                  // Resend OTP
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'auth.didnt_receive'.tr(),
                        style: AppTextStyles.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _canResend && !isLoading ? _resendOtp : null,
                        child: Text(
                          _canResend
                              ? 'auth.resend'.tr()
                              : 'auth.resend_after'.tr(
                                  namedArgs: {
                                    'seconds': _resendCountdown.toString(),
                                  },
                                ),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: _canResend
                                ? AppColors.primaryGreen
                                : AppColors.textLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
