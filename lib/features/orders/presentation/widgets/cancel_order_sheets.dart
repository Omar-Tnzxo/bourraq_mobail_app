import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/features/orders/data/cancel_reason_service.dart';

/// Cancel Order Confirmation Bottom Sheet
/// Shows "Keep order" and "Cancel & refund" options
class CancelOrderConfirmSheet extends StatelessWidget {
  final VoidCallback onKeepOrder;
  final VoidCallback onCancelOrder;

  const CancelOrderConfirmSheet({
    super.key,
    required this.onKeepOrder,
    required this.onCancelOrder,
  });

  static Future<bool?> show(BuildContext context) {
    return BourraqBottomSheet.show<bool>(
      context: context,
      title: 'cancel_order.title'.tr(),
      actions: [
        // Cancel & Refund
        Expanded(
          child: BourraqButton(
            label: 'cancel_order.cancel_and_refund'.tr(),
            onPressed: () => Navigator.pop(context, true),
            isDangerous: true,
          ),
        ),
        const SizedBox(width: 12),
        // Keep Order
        Expanded(
          child: BourraqButton(
            label: 'cancel_order.keep_order'.tr(),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'cancel_order.confirm_message'.tr(),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This build method is kept for compatibility if called directly,
    // but the 'show' method now handles the sheet wrap.
    return const SizedBox.shrink();
  }
}

/// Why Cancel Reasons Bottom Sheet
/// Shows list of cancel reasons
class WhyCancelReasonsSheet extends StatefulWidget {
  final List<CancelReason> reasons;

  const WhyCancelReasonsSheet({super.key, required this.reasons});

  /// Shows the bottom sheet and return selected reason ID
  static Future<String?> show(
    BuildContext context,
    List<CancelReason> reasons,
  ) {
    return BourraqBottomSheet.show<String>(
      context: context,
      title: 'cancel_order.why_cancel_title'.tr(),
      child: WhyCancelReasonsSheet(reasons: reasons),
    );
  }

  @override
  State<WhyCancelReasonsSheet> createState() => _WhyCancelReasonsSheetState();
}

class _WhyCancelReasonsSheetState extends State<WhyCancelReasonsSheet> {
  String? _selectedReasonId;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.reasons.map((reason) {
          final isSelected = _selectedReasonId == reason.id;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedReasonId = reason.id);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  // Custom Radio
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : Colors.white38,
                        width: 2,
                      ),
                      color: isSelected
                          ? AppColors.primaryGreen
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            LucideIcons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Reason Text
                  Expanded(
                    child: Text(
                      reason.getText(languageCode),
                      style: TextStyle(
                        fontSize: 15,
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),

        // Confirm Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: BourraqButton(
            label: 'common.confirm'.tr(),
            onPressed: _selectedReasonId != null
                ? () => Navigator.pop(context, _selectedReasonId)
                : null,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
