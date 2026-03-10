import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/app_price_display.dart';
import 'package:bourraq/features/wallet/data/wallet_model.dart';
import 'package:bourraq/features/orders/data/order_model.dart';

class WalletPaymentOption extends StatelessWidget {
  final Wallet? wallet;
  final double totalBeforeWallet;
  final PaymentMethod selectedPayment;
  final ValueChanged<PaymentMethod> onPaymentSelected;
  final ValueChanged<bool> onUseWalletBalanceChanged;

  const WalletPaymentOption({
    super.key,
    required this.wallet,
    required this.totalBeforeWallet,
    required this.selectedPayment,
    required this.onPaymentSelected,
    required this.onUseWalletBalanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBalance = (wallet?.balance ?? 0) >= totalBeforeWallet;
    final bool isSelected = selectedPayment == PaymentMethod.wallet;

    return Container(
      decoration: BoxDecoration(
        color: !hasBalance
            ? Colors.grey.shade50
            : (isSelected
                  ? AppColors.primaryGreen.withValues(alpha: 0.08)
                  : AppColors.background),
        borderRadius: BorderRadius.circular(14),
        border: isSelected
            ? Border.all(
                color: AppColors.primaryGreen.withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: !hasBalance
              ? null
              : () {
                  onPaymentSelected(PaymentMethod.wallet);
                  // Disable partial wallet use if paying fully with wallet
                  onUseWalletBalanceChanged(false);
                },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: !hasBalance
                        ? Colors.grey.shade200
                        : (isSelected
                              ? AppColors.primaryGreen.withValues(alpha: 0.12)
                              : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    LucideIcons.wallet,
                    color: !hasBalance
                        ? Colors.grey
                        : (isSelected
                              ? AppColors.primaryGreen
                              : AppColors.textSecondary),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'wallet.title'.tr(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: !hasBalance
                                  ? Colors.grey
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (!hasBalance && wallet != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'checkout.insufficient_wallet'.tr(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      wallet != null
                          ? AppPriceDisplay(
                              price: wallet!.balance,
                              textColor: !hasBalance
                                  ? Colors.grey
                                  : (isSelected
                                        ? AppColors.primaryGreen
                                        : AppColors.textSecondary),
                              scale: 0.72,
                            )
                          : Text(
                              'checkout.no_balance'.tr(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                    ],
                  ),
                ),
                // Radio Indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: !hasBalance
                          ? Colors.grey.shade300
                          : (isSelected
                                ? AppColors.primaryGreen
                                : Colors.grey.shade400),
                      width: 2,
                    ),
                    color: isSelected && hasBalance
                        ? AppColors.primaryGreen
                        : Colors.transparent,
                  ),
                  child: isSelected && hasBalance
                      ? const Icon(
                          LucideIcons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
