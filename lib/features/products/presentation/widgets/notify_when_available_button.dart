import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/services/stock_alert_service.dart';
import 'package:bourraq/core/utils/guest_restriction_helper.dart';

/// Button for "Notify me when available" - Stock Alerts
class NotifyWhenAvailableButton extends StatefulWidget {
  final String productId;
  final bool isOutOfStock;

  const NotifyWhenAvailableButton({
    super.key,
    required this.productId,
    required this.isOutOfStock,
  });

  @override
  State<NotifyWhenAvailableButton> createState() =>
      _NotifyWhenAvailableButtonState();
}

class _NotifyWhenAvailableButtonState extends State<NotifyWhenAvailableButton> {
  final StockAlertService _alertService = StockAlertService();
  bool _isSubscribed = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    if (!widget.isOutOfStock) return;

    final subscribed = await _alertService.isSubscribed(widget.productId);
    if (mounted) {
      setState(() => _isSubscribed = subscribed);
    }
  }

  Future<void> _toggleSubscription() async {
    if (GuestRestrictionHelper.checkAndPromptLogin(context)) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    bool success;
    if (_isSubscribed) {
      success = await _alertService.unsubscribeFromAlert(widget.productId);
    } else {
      success = await _alertService.subscribeToAlert(widget.productId);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (success) {
          _isSubscribed = !_isSubscribed;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isSubscribed
                  ? 'product.notify_subscribed'.tr()
                  : 'product.notify_unsubscribed'.tr(),
            ),
            backgroundColor: _isSubscribed
                ? AppColors.primaryGreen
                : Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only show if product is out of stock
    if (!widget.isOutOfStock) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _toggleSubscription,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                _isSubscribed ? LucideIcons.bellOff : LucideIcons.bell,
                size: 20,
              ),
        label: Text(
          _isSubscribed
              ? 'product.notify_cancel'.tr()
              : 'product.notify_when_available'.tr(),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _isSubscribed ? Colors.grey : AppColors.primaryGreen,
          side: BorderSide(
            color: _isSubscribed ? Colors.grey : AppColors.primaryGreen,
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
