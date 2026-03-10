import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bourraq/features/auth/presentation/cubit/auth_state.dart';

/// Helper class for handling guest mode restrictions
class GuestRestrictionHelper {
  /// Check if user is guest and show login dialog if true
  /// Returns true if user IS a guest (action should be blocked)
  /// Returns false if user is authenticated (action can proceed)
  static bool checkAndPromptLogin(BuildContext context) {
    final authState = context.read<AuthCubit>().state;

    if (authState is AuthGuest) {
      showLoginRequiredDialog(context);
      return true; // Block the action
    }

    if (authState is! AuthAuthenticated) {
      showLoginRequiredDialog(context);
      return true; // Block the action
    }

    return false; // Allow the action
  }

  /// Show login required bottom sheet dialog
  static void showLoginRequiredDialog(BuildContext context) {
    BourraqBottomSheet.show(
      context: context,
      title: 'guest.login_required'.tr(),
      actions: [
        BourraqButton(
          label: 'guest.login_to_continue'.tr(),
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/login');
          },
          backgroundColor: AppColors.accentYellow,
          foregroundColor: AppColors.deepOlive,
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.logIn,
              size: 32,
              color: AppColors.accentYellow,
            ),
          ),
          const SizedBox(height: 20),

          // Message
          Text(
            'guest.login_required_message'.tr(),
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
