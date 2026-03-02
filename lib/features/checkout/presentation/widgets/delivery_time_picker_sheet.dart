import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';

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
  static List<DeliveryTimeSlot> generateDailySlots() {
    final now = DateTime.now();
    final slots = <DeliveryTimeSlot>[];

    // Instant delivery option
    final instantArrival = now.add(const Duration(minutes: 45));
    final instantLabel = DateFormat('h:mm a').format(instantArrival);
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

      final startFormatted = DateFormat('h:mm a').format(start);
      final endFormatted = DateFormat('h:mm a').format(end);

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
/// Breadfast-style time selection
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
    final timeSlots = slots ?? DeliveryTimeSlot.generateDailySlots();

    return showModalBottomSheet<DeliveryTimeSlot>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DeliveryTimePickerSheet(
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

    return SafeArea(
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Close button
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        LucideIcons.x,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    'delivery_time.title'.tr(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Time Slots List
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: widget.slots.length,
                itemBuilder: (context, index) {
                  final slot = widget.slots[index];
                  final isSelected = _selectedSlotId == slot.id;
                  final isInstant = slot.isInstant;

                  // Section header for scheduled slots
                  Widget? sectionHeader;
                  if (index == 1) {
                    sectionHeader = Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 8),
                      child: Text(
                        'delivery_time.schedule_another'.tr(),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ?sectionHeader,
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedSlotId = slot.id);
                          // Auto-select and close for instant
                          if (isInstant) {
                            Future.delayed(
                              const Duration(milliseconds: 200),
                              () {
                                if (mounted) {
                                  Navigator.pop(context, _selectedSlot);
                                }
                              },
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isInstant && isSelected
                                ? AppColors.primaryGreen.withValues(alpha: 0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryGreen
                                  : AppColors.border,
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
                                    color: AppColors.primaryGreen.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'delivery_time.instant'.tr(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryGreen,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Icon(
                                        LucideIcons.zap,
                                        size: 16,
                                        color: AppColors.primaryGreen,
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
                                      ? DateFormat('h:mm a').format(
                                          DateTime.now().add(
                                            const Duration(minutes: 45),
                                          ),
                                        )
                                      : slot.getLabel(languageCode),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),

                              // Radio circle
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryGreen
                                        : AppColors.textSecondary,
                                    width: 2,
                                  ),
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Center(
                                        child: Icon(
                                          LucideIcons.check,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedSlot != null
                      ? () => Navigator.pop(context, _selectedSlot)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'common.confirm'.tr(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
