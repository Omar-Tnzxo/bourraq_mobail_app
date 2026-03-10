import 'package:bourraq/core/widgets/bourraq_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';

/// صفحة إضافة بطاقة جديدة
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _cardLabelController = TextEditingController();

  bool _saveCard = true;
  final bool _isLoading = false;
  String _detectedBrand = '';

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _holderNameController.dispose();
    _cardLabelController.dispose();
    super.dispose();
  }

  String _detectCardBrand(String number) {
    final cleaned = number.replaceAll(' ', '');
    if (cleaned.startsWith('4')) return 'visa';
    if (cleaned.startsWith('5') || cleaned.startsWith('2')) return 'mastercard';
    if (cleaned.startsWith('3')) return 'amex';
    return '';
  }

  void _onCardNumberChanged(String value) {
    final brand = _detectCardBrand(value);
    if (brand != _detectedBrand) {
      setState(() => _detectedBrand = brand);
    }
  }

  bool get _isFormValid {
    final cardNum = _cardNumberController.text.replaceAll(' ', '');
    final expiry = _expiryController.text;
    final cvv = _cvvController.text;
    final holder = _holderNameController.text.trim();

    return cardNum.length >= 15 &&
        expiry.length == 5 &&
        cvv.length >= 3 &&
        holder.isNotEmpty;
  }

  Future<void> _addCard() async {
    if (!_formKey.currentState!.validate()) return;

    await BourraqDialog.show(
      context,
      title: 'wallet.coming_soon'.tr(),
      message: 'wallet.payment_integration_coming'.tr(),
      confirmLabel: 'common.confirm'.tr(),
      cancelLabel: 'common.close'.tr(),
      icon: LucideIcons.construction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BourraqScaffold(
      title: 'wallet.add_card'.tr(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardPreview(),
              const SizedBox(height: 32),

              BourraqTextField(
                label: 'wallet.card_number'.tr(),
                controller: _cardNumberController,
                hintText: '0000 0000 0000 0000',
                prefixIcon: const Icon(
                  LucideIcons.creditCard,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                onChanged: _onCardNumberChanged,
                suffixIcon: _detectedBrand.isNotEmpty
                    ? _buildCardBrandIcon()
                    : null,
                validator: (v) =>
                    (v == null || v.replaceAll(' ', '').length < 15)
                    ? 'wallet.field_required'.tr()
                    : null,
              ),

              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: BourraqTextField(
                      label: 'wallet.expiry_date'.tr(),
                      controller: _expiryController,
                      hintText: 'MM/YY',
                      prefixIcon: const Icon(
                        LucideIcons.calendar,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ExpiryDateFormatter(),
                      ],
                      validator: (v) => (v == null || v.length < 5)
                          ? 'wallet.field_required'.tr()
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: BourraqTextField(
                      label: 'CVV',
                      controller: _cvvController,
                      hintText: '***',
                      prefixIcon: const Icon(
                        LucideIcons.lock,
                        color: AppColors.primaryGreen,
                        size: 20,
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      validator: (v) => (v == null || v.length < 3)
                          ? 'wallet.field_required'.tr()
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              BourraqTextField(
                label: 'wallet.card_holder'.tr(),
                controller: _holderNameController,
                hintText: 'wallet.card_holder_hint'.tr(),
                prefixIcon: const Icon(
                  LucideIcons.user,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'wallet.field_required'.tr()
                    : null,
              ),

              const SizedBox(height: 20),
              BourraqTextField(
                label: 'wallet.card_label'.tr(),
                controller: _cardLabelController,
                hintText: 'wallet.card_label_hint'.tr(),
                prefixIcon: const Icon(
                  LucideIcons.tag,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),

              const SizedBox(height: 32),
              _buildSaveCardToggle(),
              const SizedBox(height: 20),
              _buildSecurityNote(),
            ],
          ),
        ),
      ),
      footer: _buildFooterAction(),
    );
  }

  Widget _buildCardPreview() {
    final cardNumber = _cardNumberController.text.isEmpty
        ? '•••• •••• •••• ••••'
        : _cardNumberController.text;
    final expiry = _expiryController.text.isEmpty
        ? 'MM/YY'
        : _expiryController.text;
    final holder = _holderNameController.text.isEmpty
        ? 'wallet.your_name'.tr()
        : _holderNameController.text;

    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(LucideIcons.creditCard, color: Colors.white, size: 36),
              if (_detectedBrand.isNotEmpty) _buildCardBrandIconWhite(),
            ],
          ),
          Text(
            cardNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardDetail('wallet.card_holder'.tr(), holder),
              _buildCardDetail('wallet.expiry'.tr(), expiry),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCardBrandIcon() {
    Color color = Colors.grey;
    if (_detectedBrand == 'visa') color = Colors.blue;
    if (_detectedBrand == 'mastercard') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _detectedBrand.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildCardBrandIconWhite() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _detectedBrand.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSaveCardToggle() {
    return BourraqCard(
      onTap: () => setState(() => _saveCard = !_saveCard),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Checkbox(
            value: _saveCard,
            onChanged: (v) => setState(() => _saveCard = v!),
            activeColor: AppColors.primaryGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'wallet.save_card'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'wallet.save_card_desc'.tr(),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.shieldCheck,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'wallet.security_note'.tr(),
              style: const TextStyle(
                color: AppColors.primaryGreen,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: BourraqButton(
          label: 'wallet.add_card'.tr(),
          isLoading: _isLoading,
          onPressed: _isFormValid ? _addCard : null,
          icon: LucideIcons.plus,
        ),
      ),
    );
  }
}

/// Card Number Formatter (adds spaces every 4 digits)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

/// Expiry Date Formatter (MM/YY)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (var i = 0; i < text.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(text[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
