import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/core/widgets/maintenance_view.dart';

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
  final String? changelogAr;
  final String? changelogEn;
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
    this.changelogAr,
    this.changelogEn,
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
      changelogAr: json['changelog_ar'] as String?,
      changelogEn: json['changelog_en'] as String?,
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

  /// Get localized changelog
  String? getChangelog(bool isArabic) => isArabic ? changelogAr : changelogEn;

  /// Get store URL based on platform
  String get storeUrl => Platform.isAndroid ? androidStoreUrl : iosStoreUrl;
}

/// Force Update Bottom Sheet
class ForceUpdateSheet extends StatelessWidget {
  final AppVersion appVersion;
  final VoidCallback? onSkip;

  const ForceUpdateSheet({super.key, required this.appVersion, this.onSkip});

  /// Check for updates and show sheet if needed
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      debugPrint('🔄 [ForceUpdate] Checking for updates and maintenance...');

      final client = Supabase.instance.client;
      final platform = Platform.isAndroid ? 'android' : 'ios';

      // 1. Check for Maintenance Mode
      final settingsResponse = await client
          .from('app_settings')
          .select()
          .filter(
            'key',
            'in',
            '("maintenance_mode_enabled","maintenance_message_ar","maintenance_message_en")',
          );

      final settings = {
        for (var item in settingsResponse) item['key']: item['value'],
      };
      final isMaintenance = settings['maintenance_mode_enabled'] == 'true';

      if (isMaintenance) {
        debugPrint('🚧 [ForceUpdate] Maintenance mode IS ENABLED');
        if (context.mounted) {
          final langCode = Localizations.localeOf(context).languageCode;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => MaintenanceView(
                title: 'maintenance.title'.tr(),
                message:
                    settings['maintenance_message_$langCode'] ??
                    'maintenance.message'.tr(),
              ),
            ),
            (route) => false,
          );
          return; // Stop update check if maintenance is on
        }
      }

      // 2. Check for App Updates
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

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
          final isForce = appVersion.isForceUpdate || belowMinimum;
          await show(context, appVersion: appVersion, canSkip: !isForce);
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
    // Remove any +build part if present
    final cleanV1 = v1.split('+')[0];
    final cleanV2 = v2.split('+')[0];

    final parts1 = cleanV1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = cleanV2.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    for (var i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  /// Show the update sheet
  static Future<bool> show(
    BuildContext context, {
    required AppVersion appVersion,
    bool canSkip = true,
  }) async {
    final languageCode = Localizations.localeOf(context).languageCode;
    final isArabic = languageCode == 'ar';

    final result = await BourraqBottomSheet.show<bool>(
      context: context,
      title: appVersion.getTitle(isArabic),
      showCloseButton: canSkip,
      isDismissible: canSkip,
      enableDrag: canSkip,
      child: PopScope(
        canPop: canSkip,
        child: ForceUpdateSheet(
          appVersion: appVersion,
          onSkip: canSkip ? () => Navigator.pop(context, true) : null,
        ),
      ),
    );

    return result == true || canSkip;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final canSkip = onSkip != null;
    final changelog = appVersion.getChangelog(isArabic);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        // Illustration
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child:
                appVersion.illustrationUrl != null &&
                    appVersion.illustrationUrl!.isNotEmpty
                ? Image.network(
                    appVersion.illustrationUrl!,
                    height: 90,
                    width: 90,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultIllustration(),
                  )
                : _buildDefaultIllustration(),
          ),
        ),
        const SizedBox(height: 24),

        // Message
        Text(
          appVersion.getMessage(isArabic),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),

        // Changelog
        if (changelog != null && changelog.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      color: AppColors.accentYellow,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'update.whats_new'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  changelog,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 32),

        // Update Button
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => _launchStore(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentYellow,
              foregroundColor: AppColors.deepOlive,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.rocket, size: 22),
                const SizedBox(width: 12),
                Text(
                  'update.update_now'.tr(),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Skip Button
        if (canSkip) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
              child: Text(
                'update.later'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],

        // Force update warning
        if (!canSkip) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.triangleAlert,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'update.force_update_warning'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        Text(
          'v${appVersion.versionNumber} (${appVersion.buildNumber})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.3),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _launchStore() async {
    final uri = Uri.parse(appVersion.storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildDefaultIllustration() {
    return const Icon(
      LucideIcons.rocket,
      size: 50,
      color: AppColors.accentYellow,
    );
  }
}
