import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isPasswordVisible = false;
  bool _agreedToTerms = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleRegister() {
    FocusScope.of(context).unfocus();

    if (!_agreedToTerms) {
      _showErrorDialog('auth.errors.agree_terms_required'.tr());
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
    );
  }

  void _showErrorDialog(String message) {
    BourraqDialog.show(
      context,
      title: 'auth.auth_error'.tr(),
      message: message.tr(),
      confirmLabel: 'common.close'.tr(),
      icon: LucideIcons.circleAlert,
      iconColor: AppColors.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          final email = Uri.encodeComponent(state.email);
          final name = Uri.encodeComponent(_nameController.text.trim());
          final phone = Uri.encodeComponent(_phoneController.text.trim());
          final password = Uri.encodeComponent(_passwordController.text);
          context.go(
            '/otp-verification?email=$email&name=$name&phone=$phone&password=$password',
          );
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
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),

                          // زر الرجوع
                          const Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _BackButton(),
                          ),

                          SizedBox(height: size.height * 0.02),

                          // الشعار
                          _buildLogo(),

                          SizedBox(height: size.height * 0.02),

                          // العنوان والوصف
                          _buildHeader(),

                          const SizedBox(height: 24),

                          // حقول الإدخال
                          _buildNameField(),
                          const SizedBox(height: 14),
                          _buildEmailField(),
                          const SizedBox(height: 14),
                          _buildPhoneField(),
                          const SizedBox(height: 14),
                          _buildPasswordField(),

                          const SizedBox(height: 20),

                          // الموافقة على الشروط
                          _buildTermsCheckbox(),

                          const SizedBox(height: 24),

                          // زر إنشاء الحساب
                          _buildRegisterButton(isLoading),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Center(
      child: Hero(
        tag: 'app_logo',
        child: Image.asset(
          'assets/icons/green_icon_logo.png',
          height: 120,
          width: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'auth.register_title'.tr(),
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'auth.register_subtitle'.tr(),
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return _AnimatedInputField(
      controller: _nameController,
      focusNode: _nameFocus,
      label: 'auth.full_name'.tr(),
      hint: 'auth.full_name_hint'.tr(),
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      prefixIcon: LucideIcons.user,
      iconColor: AppColors.primaryGreen,
      textCapitalization: TextCapitalization.words,
      onFieldSubmitted: (_) => _emailFocus.requestFocus(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'auth.errors.name_required'.tr();
        }
        if (value.length < 3) {
          return 'auth.errors.name_min'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return _AnimatedInputField(
      controller: _emailController,
      focusNode: _emailFocus,
      label: 'auth.email'.tr(),
      hint: 'example@email.com',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      prefixIcon: LucideIcons.mail,
      iconColor: const Color(0xFFEA4335),
      onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'auth.errors.email_required'.tr();
        }
        final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
        if (!emailRegex.hasMatch(value.trim())) {
          return 'auth.errors.email_invalid'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return _AnimatedInputField(
      controller: _phoneController,
      focusNode: _phoneFocus,
      label: 'auth.phone'.tr(),
      hint: 'auth.phone_hint'.tr(),
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      prefixIcon: LucideIcons.phone,
      iconColor: const Color(0xFF4285F4),
      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'auth.errors.phone_required'.tr();
        }
        if (!RegExp(r'^01[0-9]{9}$').hasMatch(value)) {
          return 'auth.errors.phone_invalid'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return _AnimatedInputField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      label: 'auth.password'.tr(),
      hint: '••••••••',
      obscureText: !_isPasswordVisible,
      textInputAction: TextInputAction.next,
      prefixIcon: LucideIcons.lock,
      iconColor: AppColors.primaryGreen,
      suffixIcon: IconButton(
        icon: Icon(
          _isPasswordVisible ? LucideIcons.eye : LucideIcons.eyeOff,
          color: AppColors.textSecondary,
        ),
        onPressed: () =>
            setState(() => _isPasswordVisible = !_isPasswordVisible),
      ),
      onFieldSubmitted: (_) => _handleRegister(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'auth.errors.password_required'.tr();
        }
        if (value.length < 6) {
          return 'auth.errors.password_min'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _agreedToTerms
              ? AppColors.primaryGreen
              : AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _agreedToTerms,
              onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
              activeColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontFamily: context.locale.languageCode == 'ar'
                      ? 'PingAR'
                      : null,
                ),
                children: [
                  TextSpan(
                    text: 'auth.agree_terms'.tr(),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () =>
                          setState(() => _agreedToTerms = !_agreedToTerms),
                  ),
                  TextSpan(text: ' '),
                  TextSpan(
                    text: 'auth.terms'.tr(),
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/pages/terms'),
                  ),
                  TextSpan(text: ' ${'auth.and'.tr()} '),
                  TextSpan(
                    text: 'auth.privacy'.tr(),
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => context.push('/pages/privacy'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton(bool isLoading) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: isLoading || !_agreedToTerms
              ? [Colors.grey.shade400, Colors.grey.shade500]
              : [AppColors.primaryGreen, const Color(0xFF6BAB3D)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading || !_agreedToTerms ? null : _handleRegister,
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
                      const Icon(
                        LucideIcons.userPlus,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'auth.create_account'.tr(),
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

// ═══════════════════════════════════════════════════════════════
// CUSTOM WIDGETS
// ═══════════════════════════════════════════════════════════════

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
    );
  }
}

class _AnimatedInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final IconData prefixIcon;
  final Color iconColor;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;

  const _AnimatedInputField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.hint,
    required this.prefixIcon,
    required this.iconColor,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onFieldSubmitted,
  });

  @override
  State<_AnimatedInputField> createState() => _AnimatedInputFieldState();
}

class _AnimatedInputFieldState extends State<_AnimatedInputField> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: widget.iconColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.textCapitalization,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: widget.validator,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            child: Icon(
              widget.prefixIcon,
              color: _isFocused ? widget.iconColor : AppColors.textSecondary,
              size: 22,
            ),
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
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
            borderSide: BorderSide(color: widget.iconColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.error, width: 2),
          ),
        ),
      ),
    );
  }
}
