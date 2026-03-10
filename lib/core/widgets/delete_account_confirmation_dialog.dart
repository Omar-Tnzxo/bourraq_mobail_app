import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';

/// Shows delete account confirmation dialog using the reusable BourraqDialog
class DeleteAccountConfirmationDialog {
  static Future<bool> show(BuildContext context) async {
    final result = await BourraqDialog.show(
      context,
      title: 'account.delete_confirm_title'.tr(),
      message: 'account.delete_confirm_message'.tr(),
      warningMessage: 'account.delete_warning'.tr(),
      confirmLabel: 'account.delete_account'.tr(),
      cancelLabel: 'app.stay'.tr(),
      icon: LucideIcons.trash2,
      isDangerous: true,
    );

    return result ?? false;
  }
}
