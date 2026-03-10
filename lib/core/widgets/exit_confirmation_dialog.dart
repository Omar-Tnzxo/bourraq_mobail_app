import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:bourraq/core/widgets/bourraq_widgets.dart';

/// Shows exit confirmation dialog when user tries to exit the app
/// Returns true if user wants to exit, false otherwise.
/// Now uses [BourraqDialog] for premium consistency.
class ExitConfirmationDialog {
  /// Show exit confirmation dialog and handle app exit
  /// Call this in PopScope's onPopInvokedWithResult callback
  static Future<bool> show(BuildContext context) async {
    final result = await BourraqDialog.show(
      context,
      title: 'app.exit_confirm_title'.tr(),
      message: 'app.exit_confirm_message'.tr(),
      confirmLabel: 'app.exit'.tr(),
      cancelLabel: 'app.stay'.tr(),
      icon: LucideIcons.logOut,
    );

    return result ?? false;
  }

  /// Handle back button press with exit confirmation
  /// Use this with PopScope widget
  static Future<void> handleBackPress(BuildContext context, bool didPop) async {
    if (didPop) return;

    final shouldExit = await show(context);
    if (shouldExit && context.mounted) {
      // Exit the app
      if (Platform.isAndroid) {
        SystemNavigator.pop();
      } else if (Platform.isIOS) {
        exit(0);
      }
    }
  }
}
