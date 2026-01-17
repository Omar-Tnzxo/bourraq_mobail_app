class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Bourraq';
  static const String appNameAr = 'بُـــراق';
  static const String appTagline = 'طلباتك، بين إيديك';
  static const String appTaglineEn = 'Your orders, in your hands';

  // Timing
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingExtraLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusExtraLarge = 20.0;

  // Button Heights
  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // Icon Sizes
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // User Limits
  static const int maxSavedAddresses = 5;
  static const int maxSearchHistory = 20;
  static const int maxAccountsPerPhone = 3;

  // Contact Info
  static const String facebookUrl = 'https://www.facebook.com/Bourraq';
  static const String websiteUrl = 'http://www.bourraq.com/';
  static const String whatsappNumber = '+20102450471';
  static const String email = 'bourraq.com@gmail.com';

  // Supabase (from environment or config)
  static const String supabaseUrl = 'https://vthdyrqdtudtngachsdl.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_wvIFjR_izzCDhV_IAXM_Vg_JDg_xWtH';
}
