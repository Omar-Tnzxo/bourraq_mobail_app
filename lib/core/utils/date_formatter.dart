import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Smart date formatting utility
/// - Today → "Today" / "اليوم"
/// - Tomorrow → "Tomorrow" / "غداً"
/// - Otherwise → Day name (e.g., "Friday" / "الجمعة")
/// - Always uses 12-hour time format
class DateFormatter {
  DateFormatter._();

  /// Format date with smart day name + 12-hour time
  /// Example: "Today - 02:30 PM" or "اليوم - 02:30 م"
  static String formatSmartDateTime(DateTime date, BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final dayPart = _getSmartDayName(date, isArabic);
    final timePart = _format12HourTime(date, isArabic);

    return '$dayPart - $timePart';
  }

  /// Format date with smart day name + date + 12-hour time
  /// Example: "Today, 16 Jan - 02:30 PM" or "اليوم، 16 يناير - 02:30 م"
  static String formatFullDateTime(DateTime date, BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final dayPart = _getSmartDayName(date, isArabic);
    final datePart = _formatShortDate(date, isArabic);
    final timePart = _format12HourTime(date, isArabic);

    return '$dayPart$datePart - $timePart';
  }

  /// Format just the smart day name
  static String formatSmartDay(DateTime date, BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return _getSmartDayName(date, isArabic);
  }

  /// Format date for order lists (compact)
  /// Example: "Today 02:30 PM" or "Yesterday" or "16 Jan"
  static String formatOrderDate(DateTime date, BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    final timePart = _format12HourTime(date, isArabic);

    if (dateDay == today) {
      return '${'date.today'.tr()} $timePart';
    } else if (dateDay == yesterday) {
      return '${'date.yesterday'.tr()} $timePart';
    }

    // For older dates, show date + time
    final day = date.day;
    final month = _getMonthName(date.month, isArabic);
    return '$day $month - $timePart';
  }

  /// Get smart day name: Today, Tomorrow, or actual day name
  static String _getSmartDayName(DateTime date, bool isArabic) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'date.today'.tr();
    } else if (dateDay == tomorrow) {
      return 'date.tomorrow'.tr();
    } else {
      // Return day name
      return _getDayName(date.weekday, isArabic);
    }
  }

  /// Format 12-hour time (hh:mm AM/PM)
  static String _format12HourTime(DateTime date, bool isArabic) {
    final hour = date.hour;
    final minute = date.minute;

    final hour12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'date.pm'.tr() : 'date.am'.tr();

    return '\u200E${hour12.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}\u200E $period';
  }

  /// Format short date (d MMM)
  static String _formatShortDate(DateTime date, bool isArabic) {
    final day = date.day;
    final month = _getMonthName(date.month, isArabic);

    return ', $day $month';
  }

  /// Get day name from weekday number
  static String _getDayName(int weekday, bool isArabic) {
    return 'date.days.$weekday'.tr();
  }

  /// Get month name from month number
  static String _getMonthName(int month, bool isArabic) {
    return 'date.months.$month'.tr();
  }
}
