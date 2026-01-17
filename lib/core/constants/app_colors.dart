import 'dart:ui';

/// App color constants based on Bourraq brand identity
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryGreen = Color(
    0xFF113511,
  ); // Deep olive (primary for dark text/buttons on white)
  static const Color lightGreen = Color(
    0xFF87BF54,
  ); // Light brand green (for dark backgrounds)
  static const Color deepOlive = Color(
    0xFF113511,
  ); // Deep olive (primary for headers)
  static const Color darkGreen = Color(0xFF226923); // Dark green for text
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Background Colors
  static const Color background = Color(0xFFF8F8F8); // Light gray background
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A); // Dark text
  static const Color textSecondary = Color(0xFF666666); // Medium gray
  static const Color textLight = Color(0xFF999999); // Light gray
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White on green

  // Accent Colors (from Rabbit UI reference)
  static const Color accentYellow = Color(
    0xFFCAFF00,
  ); // Yellow/Lime for highlights

  // State Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // Border Color
  static const Color border = Color(0xFFE0E0E0);

  // Discount/Sale Colors
  static const Color discount = Color(0xFFE53935); // Red for discount badges
  static const Color oldPrice = Color(0xFF999999); // Strikethrough price

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFEEEEEE);

  // Bottom Navigation (Dark Green like Rabbit)
  static const Color bottomNavBackground = Color(0xFF1A4D2E);
  static const Color bottomNavActive = Color(0xFFCAFF00); // Yellow
  static const Color bottomNavInactive = Color(0xFFB0B0B0);

  // Badge Colors
  static const Color badgeRed = Color(0xFFE53935);
  static const Color badgeGreen = Color(0xFF4CAF50);

  // Skeleton Loader
  static const Color skeletonBase = Color(0xFFE0E0E0);
  static const Color skeletonHighlight = Color(0xFFF5F5F5);
}
