import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import 'dart:ui' as ui;

class AppPriceDisplay extends StatelessWidget {
  final double price;
  final double? oldPrice;
  final double scale;
  final bool showCurrency;
  final Color textColor;

  const AppPriceDisplay({
    super.key,
    required this.price,
    this.oldPrice,
    this.scale = 1.0,
    this.showCurrency = true,
    this.textColor = AppColors.deepOlive,
  });

  bool get hasDiscount => oldPrice != null && oldPrice! > price;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    final currencyText = showCurrency
        ? Text(
            'common.currency_short'.tr(),
            style: TextStyle(
              fontSize: 12 * scale,
              color: textColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          )
        : const SizedBox.shrink();

    final newPriceWidget = Container(
      padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 0),
      decoration: BoxDecoration(
        color: hasDiscount ? AppColors.bottomNavActive : Colors.transparent,
        borderRadius: BorderRadius.circular(4 * scale),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textBaseline: TextBaseline.alphabetic,
        textDirection: ui.TextDirection.ltr,
        children: [
          Text(
            price.floor().toString(),
            style: TextStyle(
              fontSize: 18 * scale,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.0,
            ),
          ),
          SizedBox(width: 1 * scale),
          Text(
            ((price - price.floor()) * 100).round().toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: 12 * scale,
              fontWeight: FontWeight.w500,
              color: textColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );

    Widget? oldPriceWidget;
    if (hasDiscount) {
      oldPriceWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        textBaseline: TextBaseline.alphabetic,
        textDirection: ui.TextDirection.ltr,
        children: [
          Text(
            oldPrice!.floor().toString(),
            style: TextStyle(
              fontSize: 15 * scale,
              color: textColor.withValues(alpha: 0.6),
              decoration: TextDecoration.lineThrough,
              decorationColor: const Color(0xFFFF6B6B),
              decorationThickness: 1.5,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          Text(
            ((oldPrice! - oldPrice!.floor()) * 100).round().toString().padLeft(
              2,
              '0',
            ),
            style: TextStyle(
              fontSize: 10 * scale,
              color: textColor.withValues(alpha: 0.6),
              decoration: TextDecoration.lineThrough,
              decorationColor: const Color(0xFFFF6B6B),
              decorationThickness: 1.5,
              fontWeight: FontWeight.w500,
              height: 1.0,
            ),
          ),
        ],
      );
    }

    Widget content;
    if (isArabic) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          newPriceWidget,
          if (hasDiscount) ...[SizedBox(width: 6 * scale), oldPriceWidget!],
          if (showCurrency) ...[SizedBox(width: 4 * scale), currencyText],
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showCurrency) ...[currencyText, SizedBox(width: 4 * scale)],
          newPriceWidget,
          if (hasDiscount) ...[SizedBox(width: 6 * scale), oldPriceWidget!],
        ],
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
      child: content,
    );
  }
}
