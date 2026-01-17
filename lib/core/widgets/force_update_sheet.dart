import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'package:bourraq/core/constants/app_colors.dart';

/// App Update Model
class AppVersion {
  final String versionNumber;
  final int buildNumber;
  final bool isForceUpdate;
  final String? minSupportedVersion;
  final String titleAr;
  final String titleEn;
  final String messageAr;
  final String messageEn;
  final String? illustrationUrl;
  final String androidStoreUrl;
  final String iosStoreUrl;

  AppVersion({
    required this.versionNumber,
    required this.buildNumber,
    required this.isForceUpdate,
    this.minSupportedVersion,
    required this.titleAr,
    required this.titleEn,
    required this.messageAr,
    required this.messageEn,
    this.illustrationUrl,
    required this.androidStoreUrl,
    required this.iosStoreUrl,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      versionNumber: json['version_number'] as String,
      buildNumber: json['build_number'] as int,
      isForceUpdate: json['is_force_update'] as bool? ?? false,
      minSupportedVersion: json['min_supported_version'] as String?,
      titleAr: json['title_ar'] as String? ?? 'تحديث متاح',
      titleEn: json['title_en'] as String? ?? 'Update Available',
      messageAr: json['message_ar'] as String? ?? 'يتوفر تحديث جديد للتطبيق',
      messageEn: json['message_en'] as String? ?? 'A new version is available',
      illustrationUrl: json['illustration_url'] as String?,
      androidStoreUrl:
          json['android_store_url'] as String? ??
          'https://play.google.com/store/apps/details?id=com.bourraq.app',
      iosStoreUrl:
          json['ios_store_url'] as String? ??
          'https://apps.apple.com/app/bourraq/id123456789',
    );
  }

  /// Get localized title
  String getTitle(bool isArabic) => isArabic ? titleAr : titleEn;

  /// Get localized message
  String getMessage(bool isArabic) => isArabic ? messageAr : messageEn;

  /// Get store URL based on platform
  String get storeUrl => Platform.isAndroid ? androidStoreUrl : iosStoreUrl;
}

/// Force Update Bottom Sheet
/// Similar to language picker in Account Screen
class ForceUpdateSheet extends StatelessWidget {
  final AppVersion appVersion;
  final VoidCallback? onSkip;

  const ForceUpdateSheet({super.key, required this.appVersion, this.onSkip});

  /// Check for updates and show sheet if needed
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      debugPrint('🔄 [ForceUpdate] Checking for updates...');

      // Get current app version (you can use package_info_plus for real version)
      const currentVersion = '1.0.0';
      const currentBuild = 1;

      final client = Supabase.instance.client;
      final platform = Platform.isAndroid ? 'android' : 'ios';

      debugPrint(
        '🔄 [ForceUpdate] Platform: $platform, Current: v$currentVersion ($currentBuild)',
      );

      // Fetch active app version for current platform
      final response = await client
          .from('app_versions')
          .select()
          .or('platform.eq.$platform,platform.eq.all')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      debugPrint('🔄 [ForceUpdate] Response: $response');

      if (response == null) {
        debugPrint('🔄 [ForceUpdate] No active version found in database');
        return;
      }

      final appVersion = AppVersion.fromJson(response);
      debugPrint(
        '🔄 [ForceUpdate] Server version: v${appVersion.versionNumber} (${appVersion.buildNumber})',
      );

      // Check if update is needed
      final needsUpdate =
          _compareVersions(currentVersion, appVersion.versionNumber) < 0 ||
          currentBuild < appVersion.buildNumber;

      // Check if below minimum supported version
      final belowMinimum =
          appVersion.minSupportedVersion != null &&
          _compareVersions(currentVersion, appVersion.minSupportedVersion!) < 0;

      debugPrint(
        '🔄 [ForceUpdate] needsUpdate: $needsUpdate, belowMinimum: $belowMinimum, isForce: ${appVersion.isForceUpdate}',
      );

      if (needsUpdate || belowMinimum) {
        debugPrint('🔄 [ForceUpdate] Showing update sheet...');
        if (context.mounted) {
          // Wait for user to dismiss the sheet before proceeding
          // canSkip depends ONLY on is_force_update column
          await show(
            context,
            appVersion: appVersion,
            canSkip:
                !appVersion.isForceUpdate, // Only is_force_update controls this
          );
          debugPrint('🔄 [ForceUpdate] Sheet dismissed');
        }
      } else {
        debugPrint('🔄 [ForceUpdate] App is up to date');
      }
    } catch (e, stack) {
      debugPrint('🔄 [ForceUpdate] Error checking for updates: $e');
      debugPrint('🔄 [ForceUpdate] Stack: $stack');
    }
  }

  /// Compare version strings (returns -1, 0, or 1)
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  /// Show the update sheet and return whether user can proceed
  /// Returns true if user skipped, false if force update (can't proceed)
  static Future<bool> show(
    BuildContext context, {
    required AppVersion appVersion,
    bool canSkip = true,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: canSkip,
      enableDrag: canSkip,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => PopScope(
        canPop: canSkip,
        child: ForceUpdateSheet(
          appVersion: appVersion,
          onSkip: canSkip ? () => Navigator.pop(ctx, true) : null,
        ),
      ),
    );

    // If force update and user didn't skip, they should not proceed
    return result == true || canSkip;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final canSkip = onSkip != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Illustration (default or from URL)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                appVersion.illustrationUrl != null &&
                    appVersion.illustrationUrl!.isNotEmpty
                ? Image.network(
                    appVersion.illustrationUrl!,
                    height: 120,
                    width: 160,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultIllustration(),
                  )
                : _buildDefaultIllustration(),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            appVersion.getTitle(isArabic),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            appVersion.getMessage(isArabic),
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Version info
          Text(
            isArabic
                ? 'الإصدار الجديد: ${appVersion.versionNumber}'
                : 'New version: ${appVersion.versionNumber}',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // Update Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _launchStore(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.externalLink, size: 20),
              label: Text(
                isArabic ? 'تحديث الآن' : 'Update Now',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Skip Button (only if not force update)
          if (canSkip) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isArabic ? 'لاحقاً' : 'Later',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          // Force update warning
          if (!canSkip) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.info, color: Colors.orange, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isArabic
                          ? 'هذا التحديث مطلوب لاستخدام التطبيق'
                          : 'This update is required to use the app',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _launchStore() async {
    final uri = Uri.parse(appVersion.storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Default illustration from assets
  Widget _buildDefaultIllustration() {
    return Image.asset(
      'assets/images/update-illustration.png',
      height: 120,
      width: 160,
      fit: BoxFit.contain,
    );
  }
}
