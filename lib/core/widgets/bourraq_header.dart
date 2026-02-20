import 'package:flutter/material.dart';
import 'package:bourraq/core/constants/app_colors.dart';

/// A reusable header component with the Bourraq brand identity
/// Features a deep olive background and a curved bottom white overlay
class BourraqHeader extends StatelessWidget {
  final Widget child;
  final double? height;
  final double curveHeight;
  final Color backgroundColor;
  final Color curveColor;
  final EdgeInsetsGeometry? padding;

  const BourraqHeader({
    super.key,
    required this.child,
    this.height,
    this.curveHeight = 32,
    this.backgroundColor = AppColors.deepOlive,
    this.curveColor = AppColors.background,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Background
        Container(
          width: double.infinity,
          height: height,
          padding: padding ?? const EdgeInsets.fromLTRB(20, 16, 20, 48),
          decoration: BoxDecoration(color: backgroundColor),
          child: SafeArea(bottom: false, child: child),
        ),

        // Bottom Curve Overlay
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          child: Container(
            height: curveHeight,
            decoration: BoxDecoration(
              color: curveColor,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(curveHeight),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
