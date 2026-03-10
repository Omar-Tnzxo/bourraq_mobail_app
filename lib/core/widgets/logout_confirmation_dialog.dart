import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';

/// Shows logout confirmation dialog using the reusable BourraqDialog
class LogoutConfirmationDialog {
  static Future<bool> show(BuildContext context) async {
    final result = await BourraqDialog.show(
      context,
      title: 'account.logout_confirm_title'.tr(),
      message: 'account.logout_confirm_message'.tr(),
      confirmLabel: 'account.logout'.tr(),
      cancelLabel: 'app.stay'.tr(),
      icon: LucideIcons.logOut,
    );

    return result ?? false;
  }
}
