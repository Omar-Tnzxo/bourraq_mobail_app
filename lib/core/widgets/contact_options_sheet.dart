import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable Contact Options Bottom Sheet
/// Shows contact options: Facebook, WhatsApp, Email
class ContactOptionsSheet {
  /// Shows the contact options bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'account.contact_us'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(LucideIcons.facebook, color: Colors.blue[700]),
              title: const Text('Facebook'),
              onTap: () {
                Navigator.pop(ctx);
                _launchUrl('https://www.facebook.com/Bourraq');
              },
            ),
            ListTile(
              leading: const Icon(LucideIcons.phone, color: Colors.green),
              title: const Text('WhatsApp'),
              onTap: () {
                Navigator.pop(ctx);
                _launchUrl('https://wa.me/+20102450471');
              },
            ),
            ListTile(
              leading: Icon(LucideIcons.mail, color: Colors.orange[700]),
              title: const Text('bourraq.com@gmail.com'),
              onTap: () {
                Navigator.pop(ctx);
                _launchUrl('mailto:bourraq.com@gmail.com');
              },
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
