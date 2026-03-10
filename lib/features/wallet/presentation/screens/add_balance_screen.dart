import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/features/wallet/data/wallet_service.dart';
import 'package:bourraq/features/wallet/data/saved_card_model.dart';

class AddBalanceScreen extends StatefulWidget {
  const AddBalanceScreen({super.key});

  @override
  State<AddBalanceScreen> createState() => _AddBalanceScreenState();
}

class _AddBalanceScreenState extends State<AddBalanceScreen> {
  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();

  List<SavedCard> _savedCards = [];
  SavedCard? _selectedCard;
  bool _isLoading = false;
  bool _isLoadingCards = true;

  final List<int> _quickAmounts = [100, 200, 500, 1000];

  @override
  void initState() {
    super.initState();
    _loadSavedCards();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCards() async {
    final cards = await _walletService.getSavedCards();
    setState(() {
      _savedCards = cards;
      _selectedCard = cards.isNotEmpty
          ? cards.firstWhere((c) => c.isDefault, orElse: () => cards.first)
          : null;
      _isLoadingCards = false;
    });
  }

  void _selectQuickAmount(int amount) {
    _amountController.text = amount.toString();
    setState(() {});
  }

  double get _enteredAmount => double.tryParse(_amountController.text) ?? 0.0;
  bool get _canProceed => _enteredAmount >= 10 && _selectedCard != null;
  bool get _hasNoCards => _savedCards.isEmpty && !_isLoadingCards;

  Future<void> _processPayment() async {
    if (!_canProceed) return;
    setState(() => _isLoading = true);

    // TODO: Implement PayMob payment
    await Future.delayed(const Duration(seconds: 2));

    final success = await _walletService.addBalance(
      _enteredAmount,
      description: 'wallet.add_balance_desc'.tr(),
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('wallet.add_balance_success'.tr()),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('wallet.add_balance_error'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BourraqScaffold(
      title: 'wallet.add_balance'.tr(),
      isLoading: _isLoadingCards,
      footer: _buildFooter(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountInput(),
            const SizedBox(height: 32),
            _buildQuickAddSection(),
            const SizedBox(height: 48),
            _buildPaymentMethodSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return BourraqTextField(
      label: 'wallet.enter_amount'.tr(),
      controller: _amountController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      hintText: '0',
      onChanged: (_) => setState(() {}),
      prefixIcon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'common.currency_short'.tr(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wallet.quick_add'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 16),
        Row(
          children: _quickAmounts.map((amount) {
            final isSelected = _enteredAmount == amount;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: amount != _quickAmounts.last ? 8 : 0,
                ),
                child: BourraqButton(
                  label: '${amount.toString()} ${'common.currency_short'.tr()}',
                  isSecondary: !isSelected,
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                  ), // Reduce horizontal padding inside the button
                  onPressed: () => _selectQuickAmount(amount),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'wallet.payment_method'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 20),
        if (_hasNoCards)
          _buildNoCardsWarning()
        else
          ..._savedCards.map((card) => _buildCardOption(card)),
        const SizedBox(height: 12),
        _buildAddNewCard(),
      ],
    );
  }

  Widget _buildNoCardsWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.circleAlert, color: Colors.orange, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'wallet.add_card_first'.tr(),
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardOption(SavedCard card) {
    final isSelected = _selectedCard?.id == card.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: BourraqCard(
        onTap: () => setState(() => _selectedCard = card),
        borderSide: isSelected
            ? const BorderSide(color: AppColors.primaryGreen, width: 2)
            : null,
        backgroundColor: isSelected
            ? AppColors.primaryGreen.withValues(alpha: 0.02)
            : Colors.white,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withValues(alpha: 0.1)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                LucideIcons.creditCard,
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? AppColors.primaryGreen
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    card.maskedNumber,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            _buildSelectionIndicator(isSelected),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionIndicator(bool isSelected) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primaryGreen : Colors.transparent,
        border: isSelected
            ? null
            : Border.all(color: AppColors.border, width: 2),
      ),
      child: isSelected
          ? const Icon(LucideIcons.check, size: 16, color: Colors.white)
          : null,
    );
  }

  Widget _buildAddNewCard() {
    return BourraqCard(
      onTap: () => context.push('/wallet/add-card'),
      borderSide: BorderSide(
        color: AppColors.primaryGreen.withValues(alpha: 0.3),
        style: BorderStyle.none,
      ), // Custom dashed or dotted border would be nice here
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.plus,
              color: AppColors.primaryGreen,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'wallet.new_card'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: BourraqButton(
          label: 'wallet.add'.tr(),
          isLoading: _isLoading,
          onPressed: _canProceed ? _processPayment : null,
        ),
      ),
    );
  }
}
