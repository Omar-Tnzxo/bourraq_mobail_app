import 'package:flutter/material.dart';
import 'package:bourraq/core/constants/app_colors.dart';

/// A primary button designed with Bourraq branding.
/// Features a shadow when active and a consistent rounded design.
class BourraqButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final bool isDangerous;
  final double? width;
  final double height;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;

  const BourraqButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.isDangerous = false,
    this.width = double.infinity,
    this.height = 56,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    final Color bg =
        backgroundColor ??
        (isDangerous
            ? AppColors.error
            : (isSecondary ? Colors.white : AppColors.primaryGreen));
    final Color fg =
        foregroundColor ??
        (isSecondary ? AppColors.primaryGreen : Colors.white);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDisabled)
            BoxShadow(
              color: bg.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isSecondary && backgroundColor == null
                ? const BorderSide(color: AppColors.primaryGreen, width: 1.5)
                : BorderSide.none,
          ),
          elevation: 0,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: isLoading
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
              )
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: isSecondary ? 0 : 0.5,
                        color: isDisabled ? AppColors.textSecondary : fg,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
