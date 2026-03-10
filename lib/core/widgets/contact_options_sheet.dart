import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/core/utils/error_handler.dart';
import '../../features/account/data/models/contact_option_model.dart';

/// Reusable Contact Options Bottom Sheet
/// Now uses [BourraqBottomSheet] for premium consistency.
class ContactOptionsSheet {
  /// Shows the contact options bottom sheet
  static void show(BuildContext context) {
    BourraqBottomSheet.show(
      context: context,
      title: 'account.contact_us'.tr(),
      child: const _ContactOptionsContent(),
    );
  }
}

class _ContactOptionsContent extends StatefulWidget {
  const _ContactOptionsContent();

  @override
  State<_ContactOptionsContent> createState() => _ContactOptionsContentState();
}

class _ContactOptionsContentState extends State<_ContactOptionsContent> {
  List<ContactOption> _options = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    try {
      final response = await Supabase.instance.client
          .from('contact_options')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true);

      if (mounted) {
        setState(() {
          _options = (response as List)
              .map((json) => ContactOption.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getErrorKey(e);
          _isLoading = false;
        });
      }
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      // Contact Types
      case 'phone':
        return LucideIcons.phone;
      case 'whatsapp':
        return LucideIcons.messageCircle;
      case 'email':
        return LucideIcons.mail;
      case 'website':
        return LucideIcons.globe;
      // Social Media
      case 'facebook':
        return LucideIcons.facebook;
      case 'instagram':
        return LucideIcons.instagram;
      case 'twitter':
      case 'x':
        return LucideIcons.twitter;
      case 'tiktok':
        return LucideIcons.music2; // Changed from music
      case 'snapchat':
        return LucideIcons.ghost;
      case 'youtube':
        return LucideIcons.youtube;
      case 'telegram':
        return LucideIcons.send;
      case 'linkedin':
        return LucideIcons.linkedin;
      case 'threads':
        return LucideIcons.atSign;
      case 'discord':
        return LucideIcons.gamepad2;
      case 'reddit':
        return LucideIcons.messageSquareOff;
      case 'twitch':
        return LucideIcons.twitch;
      case 'spotify':
        return LucideIcons.music2;
      case 'pinterest':
        return LucideIcons.pin;
      case 'github':
        return LucideIcons.github;
      case 'behance':
      case 'dribbble':
        return LucideIcons.palette;
      case 'medium':
        return LucideIcons.bookOpen;
      default:
        return LucideIcons.link;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      // Contact Types
      case 'phone':
        return Colors.green;
      case 'whatsapp':
        return const Color(0xFF25D366);
      case 'email':
        return Colors.orange.shade700;
      case 'website':
        return Colors.blue;
      // Social Media
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'instagram':
        return const Color(0xFFE4405F);
      case 'twitter':
      case 'x':
        return const Color(0xFF1DA1F2);
      case 'tiktok':
        return const Color(0xFF000000);
      case 'snapchat':
        return const Color(0xFFFFFC00);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'telegram':
        return const Color(0xFF0088CC);
      case 'linkedin':
        return const Color(0xFF0A66C2);
      case 'threads':
        return const Color(0xFF000000);
      case 'discord':
        return const Color(0xFF5865F2);
      case 'reddit':
        return const Color(0xFFFF4500);
      case 'twitch':
        return const Color(0xFF9146FF);
      case 'spotify':
        return const Color(0xFF1DB954);
      case 'pinterest':
        return const Color(0xFFE60023);
      case 'github':
        return const Color(0xFF181717);
      case 'behance':
        return const Color(0xFF1769FF);
      case 'dribbble':
        return const Color(0xFFEA4C89);
      case 'medium':
        return const Color(0xFF000000);
      default:
        return Colors.grey;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = context.locale.languageCode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CircularProgressIndicator(color: AppColors.accentYellow),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.circleAlert,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'common.error_occurred'.tr(),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          )
        else if (_options.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.messageSquareOff,
                  color: Colors.white24,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  'account.no_contact_options'.tr(),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          )
        else
          ...(_options.map(
            (option) => Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  hoverColor: Colors.white.withValues(alpha: 0.05),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getColorForType(
                        option.type,
                      ).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconForType(option.type),
                      color: _getColorForType(option.type),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    option.getTitle(languageCode),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(
                    LucideIcons.chevronRight,
                    color: Colors.white24,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _launchUrl(option.getLaunchUrl());
                  },
                ),
                if (_options.indexOf(option) < _options.length - 1)
                  Divider(
                    height: 1,
                    indent: 64,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
              ],
            ),
          )),
        const SizedBox(height: 24),
      ],
    );
  }
}
