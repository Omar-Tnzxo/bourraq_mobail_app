import 'package:flutter/material.dart';
import 'package:bourraq/core/constants/app_colors.dart';

/// A branded card component for Bourraq.
/// Provides consistent shadows, borders, and rounded corners.
class BourraqCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? borderSide;
  final double borderRadius;
  final double elevation;
  final List<BoxShadow>? customShadow;

  const BourraqCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.borderSide,
    this.borderRadius = 16.0,
    this.elevation = 4.0,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidget = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.fromBorderSide(
          borderSide ??
              BorderSide(
                color: AppColors.border.withValues(alpha: 0.5),
                width: 1,
              ),
        ),
        boxShadow:
            customShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: elevation * 3,
                offset: Offset(0, elevation),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding!, child: child),
        ),
      ),
    );

    return cardWidget;
  }
}
