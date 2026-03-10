import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';

/// Delivery Time Slot model
class DeliveryTimeSlot {
  final String id;
  final String labelAr;
  final String labelEn;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isInstant;

  const DeliveryTimeSlot({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    this.startTime,
    this.endTime,
    this.isInstant = false,
  });

  String getLabel(String languageCode) {
    return languageCode == 'ar' ? labelAr : labelEn;
  }

  /// Generate time slots for the day
  static List<DeliveryTimeSlot> generateDailySlots(String locale) {
    final now = DateTime.now();
    final slots = <DeliveryTimeSlot>[];

    // Instant delivery option
    final instantArrival = now.add(const Duration(minutes: 45));
    final timeFormat = DateFormat.jm(locale);
    final instantLabel = timeFormat.format(instantArrival);
    slots.add(
      DeliveryTimeSlot(
        id: 'instant',
        labelAr: 'التوصيل الفوري $instantLabel',
        labelEn: 'Instant $instantLabel',
        isInstant: true,
      ),
    );

    // Generate hourly slots from current hour + 1 to end of day
    int startHour = now.hour + 2;
    if (startHour > 23) startHour = 8; // Next day starts at 8 AM

    for (int hour = startHour; hour < 24; hour++) {
      final start = DateTime(now.year, now.month, now.day, hour);
      final end = DateTime(now.year, now.month, now.day, hour + 1);

      final startFormatted = timeFormat.format(start);
      final endFormatted = timeFormat.format(end);

      slots.add(
        DeliveryTimeSlot(
          id: 'slot_$hour',
          labelAr: '$startFormatted - $endFormatted',
          labelEn: '$startFormatted - $endFormatted',
          startTime: start,
          endTime: end,
          isInstant: false,
        ),
      );
    }

    return slots;
  }
}

/// Delivery Time Picker Bottom Sheet
/// Now uses [BourraqBottomSheet] for premium consistency.
class DeliveryTimePickerSheet extends StatefulWidget {
  final String? currentSlotId;
  final List<DeliveryTimeSlot> slots;

  const DeliveryTimePickerSheet({
    super.key,
    this.currentSlotId,
    required this.slots,
  });

  /// Shows the bottom sheet and returns selected slot
  static Future<DeliveryTimeSlot?> show(
    BuildContext context, {
    String? currentSlotId,
    List<DeliveryTimeSlot>? slots,
  }) {
    final timeSlots =
        slots ?? DeliveryTimeSlot.generateDailySlots(context.locale.toString());

    return BourraqBottomSheet.show<DeliveryTimeSlot>(
      context: context,
      title: 'delivery_time.title'.tr(),
      child: DeliveryTimePickerSheet(
        currentSlotId: currentSlotId,
        slots: timeSlots,
      ),
    );
  }

  @override
  State<DeliveryTimePickerSheet> createState() =>
      _DeliveryTimePickerSheetState();
}

class _DeliveryTimePickerSheetState extends State<DeliveryTimePickerSheet> {
  late String? _selectedSlotId;

  @override
  void initState() {
    super.initState();
    _selectedSlotId = widget.currentSlotId ?? widget.slots.firstOrNull?.id;
  }

  DeliveryTimeSlot? get _selectedSlot {
    if (_selectedSlotId == null) return null;
    return widget.slots.firstWhere(
      (s) => s.id == _selectedSlotId,
      orElse: () => widget.slots.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Time Slots List
        ...widget.slots.asMap().entries.map((entry) {
          final index = entry.key;
          final slot = entry.value;
          final isSelected = _selectedSlotId == slot.id;
          final isInstant = slot.isInstant;

          // Section header for scheduled slots
          Widget? sectionHeader;
          if (index == 1) {
            sectionHeader = Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Text(
                'delivery_time.schedule_another'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sectionHeader != null) sectionHeader,
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSlotId = slot.id);
                  // Auto-select and close for instant
                  if (isInstant) {
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (mounted) {
                        Navigator.pop(context, _selectedSlot);
                      }
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentYellow
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Instant badge with lightning icon
                      if (isInstant) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentYellow.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'delivery_time.instant'.tr(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.accentYellow,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                LucideIcons.zap,
                                size: 14,
                                color: AppColors.accentYellow,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],

                      // Time label
                      Expanded(
                        child: Text(
                          isInstant
                              ? DateFormat.jm(languageCode).format(
                                  DateTime.now().add(
                                    const Duration(minutes: 45),
                                  ),
                                )
                              : slot.getLabel(languageCode),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),

                      // Radio indicator-like icon
                      Icon(
                        isSelected
                            ? LucideIcons.circleCheck
                            : LucideIcons.circle,
                        size: 22,
                        color: isSelected
                            ? AppColors.accentYellow
                            : Colors.white24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),

        const SizedBox(height: 16),

        // Confirm Button (Only for scheduled slots)
        if (_selectedSlotId != 'instant')
          BourraqButton(
            label: 'common.confirm'.tr(),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context, _selectedSlot);
            },
            backgroundColor: AppColors.accentYellow,
            foregroundColor: AppColors.deepOlive,
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}
