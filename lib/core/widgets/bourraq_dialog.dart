import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A premium stylized dialog for Bourraq with a dark green theme.
/// Used for critical confirmations like logout or account deletion.
class BourraqDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String? warningMessage;
  final Widget? content;
  final String confirmLabel;
  final String? cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final IconData icon;
  final Color iconColor;
  final bool isDangerous;
  final bool isLoading;

  const BourraqDialog({
    super.key,
    required this.title,
    this.message,
    this.warningMessage,
    this.content,
    required this.confirmLabel,
    this.cancelLabel,
    required this.onConfirm,
    this.onCancel,
    required this.icon,
    this.iconColor = AppColors.accentYellow,
    this.isDangerous = false,
    this.isLoading = false,
  });

  /// Static helper to show the dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    String? message,
    String? warningMessage,
    Widget? content,
    required String confirmLabel,
    String? cancelLabel,
    required IconData icon,
    Color iconColor = AppColors.accentYellow,
    bool isDangerous = false,
    bool isLoading = false,
    bool barrierDismissible = true,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => BourraqDialog(
        title: title,
        message: message,
        warningMessage: warningMessage,
        content: content,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        iconColor: iconColor,
        isDangerous: isDangerous,
        isLoading: isLoading,
        onConfirm: onConfirm ?? () => Navigator.of(context).pop(true),
        onCancel:
            onCancel ??
            (cancelLabel != null
                ? () => Navigator.of(context).pop(false)
                : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.primaryGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: AppColors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle-like accent at top
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Icon container - Premium Style
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: AppTextStyles.headlineSmall.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.white,
                fontSize: 22,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            if (message != null)
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                  height: 1.5,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

            // Custom Content
            if (content != null) content!,

            if (warningMessage != null) ...[
              const SizedBox(height: 20),
              // Warning Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.circleAlert,
                      color: AppColors.accentYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        warningMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                // Primary action (Cancel/Remain) - Yellow & Green (Safe Action)
                if (cancelLabel != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onCancel?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDangerous
                            ? AppColors.white.withValues(alpha: 0.05)
                            : AppColors.accentYellow,
                        foregroundColor: isDangerous
                            ? AppColors.white
                            : AppColors.primaryGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: isDangerous
                              ? BorderSide(
                                  color: AppColors.white.withValues(alpha: 0.2),
                                  width: 1.5,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: Text(
                        cancelLabel!,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.5,
                          color: isDangerous
                              ? AppColors.white.withValues(alpha: 0.9)
                              : AppColors.primaryGreen,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Secondary action (Confirm/Delete/Logout/Ok)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () {
                      if (isDangerous) {
                        HapticFeedback.heavyImpact();
                      } else {
                        HapticFeedback.mediumImpact();
                      }
                      onConfirm();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDangerous
                          ? Colors.red.shade400
                          : (cancelLabel == null
                                ? AppColors.primaryGreen
                                : AppColors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDangerous
                              ? Colors.red.shade400.withValues(alpha: 0.5)
                              : (cancelLabel == null
                                    ? AppColors.accentYellow
                                    : AppColors.white.withValues(alpha: 0.2)),
                          width: 1.5,
                        ),
                      ),
                      backgroundColor: isDangerous
                          ? Colors.red.shade400.withValues(alpha: 0.1)
                          : (cancelLabel == null
                                ? AppColors.accentYellow
                                : AppColors.white.withValues(alpha: 0.05)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            confirmLabel,
                            style: TextStyle(
                              color: isDangerous
                                  ? Colors.red.shade400
                                  : (cancelLabel == null
                                        ? AppColors.primaryGreen
                                        : AppColors.white.withValues(
                                            alpha: 0.9,
                                          )),
                              fontWeight: isDangerous || cancelLabel == null
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
