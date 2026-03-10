import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:bourraq/features/wallet/data/wallet_service.dart';
import 'package:bourraq/features/wallet/data/saved_card_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  final WalletService _walletService = WalletService();

  List<SavedCard> _savedCards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final cards = await _walletService.getSavedCards();
    if (!mounted) return;
    setState(() {
      _savedCards = cards;
      _isLoading = false;
    });
  }

  Future<void> _deleteCard(SavedCard card) async {
    final confirm = await BourraqDialog.show(
      context,
      title: 'wallet.delete_card'.tr(),
      message: 'wallet.delete_card_confirm'.tr(),
      confirmLabel: 'common.delete'.tr(),
      cancelLabel: 'common.cancel'.tr(),
      icon: LucideIcons.trash2,
      isDangerous: true,
    );

    if (confirm == true) {
      final success = await _walletService.deleteCard(card.id);
      if (success) {
        _loadCards();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('wallet.card_deleted'.tr()),
              backgroundColor: AppColors.primaryGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _setDefault(SavedCard card) async {
    final success = await _walletService.setDefaultCard(card.id);
    if (success) {
      _loadCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BourraqScaffold(
      title: 'wallet.saved_cards'.tr(),
      isLoading: _isLoading,
      actions: [
        // Add Button (Top Right)
        GestureDetector(
          onTap: () => context.push('/wallet/add-card'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentYellow.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              LucideIcons.plus,
              color: AppColors.accentYellow,
              size: 20,
            ),
          ),
        ),
      ],
      body: _savedCards.isEmpty && !_isLoading
          ? _buildEmptyState()
          : _buildCardsList(),
    );
  }

  Widget _buildEmptyState() {
    return BourraqEmptyState(
      title: 'wallet.no_saved_cards'.tr(),
      subtitle: 'wallet.no_saved_cards_desc'.tr(),
      icon: LucideIcons.creditCard,
      action: BourraqButton(
        width: 220,
        label: 'wallet.add_card'.tr(),
        onPressed: () => context.push('/wallet/add-card'),
      ),
    );
  }

  Widget _buildCardsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _savedCards.length,
      itemBuilder: (context, index) {
        return BourraqListItem(
          index: index,
          child: _buildCardItem(_savedCards[index]),
        );
      },
    );
  }

  Widget _buildCardItem(SavedCard card) {
    return BourraqCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      borderSide: card.isDefault
          ? const BorderSide(color: AppColors.primaryGreen, width: 1.5)
          : null,
      child: Row(
        children: [
          // Card icon/brand
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              LucideIcons.creditCard,
              color: AppColors.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Card details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      card.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (card.isDefault) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'wallet.default'.tr(),
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  card.maskedNumber,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          // Menu
          PopupMenuButton<String>(
            icon: Icon(
              LucideIcons.ellipsisVertical,
              color: AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'default') {
                _setDefault(card);
              } else if (value == 'delete') {
                _deleteCard(card);
              }
            },
            itemBuilder: (context) => [
              if (!card.isDefault)
                PopupMenuItem(
                  value: 'default',
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.circleCheck,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text('wallet.set_default'.tr()),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'common.delete'.tr(),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
