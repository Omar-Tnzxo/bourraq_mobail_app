import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';

/// Cancel Reason BottomSheet
/// Fetches reasons from Supabase and returns selected reason ID
class CancelReasonSheet extends StatefulWidget {
  const CancelReasonSheet({super.key});

  /// Show the bottom sheet and return the selected reason ID
  static Future<String?> show(BuildContext context) async {
    return BourraqBottomSheet.show<String>(
      context: context,
      title: 'orders.cancel_reason_title'.tr(),
      child: const CancelReasonSheet(),
    );
  }

  @override
  State<CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<CancelReasonSheet> {
  List<Map<String, dynamic>> _reasons = [];
  String? _selectedReasonId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReasons();
  }

  Future<void> _loadReasons() async {
    try {
      final response = await Supabase.instance.client
          .from('cancel_reasons')
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      if (!mounted) return;
      setState(() {
        _reasons = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'orders.cancel_reason_subtitle'.tr(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 20),

        // Reasons List
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
        else ...[
          ..._reasons.map((reason) {
            final reasonId = reason['id'] as String;
            final reasonText = isArabic
                ? reason['text_ar'] as String
                : reason['text_en'] as String;
            final isSelected = _selectedReasonId == reasonId;

            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedReasonId = reasonId);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.error.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.error
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.error : Colors.white38,
                          width: 2,
                        ),
                        color: isSelected
                            ? AppColors.error
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
                    Expanded(
                      child: Text(
                        reasonText,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 15,
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
          BourraqButton(
            label: 'orders.confirm_cancel'.tr(),
            onPressed: _selectedReasonId != null
                ? () => Navigator.pop(context, _selectedReasonId)
                : null,
            backgroundColor: AppColors.error,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
