import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/features/wallet/data/wallet_service.dart';

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

  final WalletService _walletService = WalletService();

  bool _saveCard = true;
  bool _isLoading = false;
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

    // ⚠️ PAYMENT INTEGRATION NOT YET IMPLEMENTED
    // Show "Coming Soon" dialog instead of fake card saving
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.construction,
            color: AppColors.primaryGreen,
            size: 32,
          ),
        ),
        title: Text('wallet.coming_soon'.tr()),
        content: Text(
          'wallet.payment_integration_coming'.tr(),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'common.confirm'.tr(),
              style: TextStyle(color: AppColors.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Premium Curved Header
          BourraqHeader(
            child: Row(
              children: [
                // Back Button
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Title
                Expanded(
                  child: Text(
                    'wallet.add_card'.tr(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Card Preview ===
                    _buildCardPreview(),

                    const SizedBox(height: 32),

                    // === Card Number ===
                    _buildTextField(
                      controller: _cardNumberController,
                      label: 'wallet.card_number'.tr(),
                      hint: '0000 0000 0000 0000',
                      icon: LucideIcons.creditCard,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _CardNumberFormatter(),
                      ],
                      maxLength: 19,
                      onChanged: _onCardNumberChanged,
                      suffix: _detectedBrand.isNotEmpty
                          ? _buildCardBrandIcon()
                          : null,
                    ),

                    const SizedBox(height: 20),

                    // === Expiry & CVV Row ===
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _expiryController,
                            label: 'wallet.expiry_date'.tr(),
                            hint: 'MM/YY',
                            icon: LucideIcons.calendar,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              _ExpiryDateFormatter(),
                            ],
                            maxLength: 5,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _cvvController,
                            label: 'CVV',
                            hint: '***',
                            icon: LucideIcons.lock,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            maxLength: 4,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // === Card Holder Name ===
                    _buildTextField(
                      controller: _holderNameController,
                      label: 'wallet.card_holder'.tr(),
                      hint: 'wallet.card_holder_hint'.tr(),
                      icon: LucideIcons.user,
                      textCapitalization: TextCapitalization.characters,
                    ),

                    const SizedBox(height: 20),

                    // === Card Label (Optional) ===
                    _buildTextField(
                      controller: _cardLabelController,
                      label: 'wallet.card_label'.tr(),
                      hint: 'wallet.card_label_hint'.tr(),
                      icon: LucideIcons.tag,
                      required: false,
                    ),

                    const SizedBox(height: 24),

                    // === Save Card Checkbox ===
                    GestureDetector(
                      onTap: () => setState(() => _saveCard = !_saveCard),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _saveCard
                                    ? AppColors.primaryGreen
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _saveCard
                                      ? AppColors.primaryGreen
                                      : AppColors.border,
                                  width: 2,
                                ),
                              ),
                              child: _saveCard
                                  ? const Icon(
                                      LucideIcons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'wallet.save_card'.tr(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'wallet.save_card_desc'.tr(),
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // === Security Note ===
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.shieldCheck,
                            color: AppColors.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'wallet.security_note'.tr(),
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // === Add Button ===
          _buildAddButton(),
        ],
      ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(LucideIcons.creditCard, color: Colors.white, size: 32),
              if (_detectedBrand.isNotEmpty) _buildCardBrandIconWhite(),
            ],
          ),

          // Card number
          Text(
            cardNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),

          // Bottom row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'wallet.card_holder'.tr().toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    holder.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'wallet.expiry'.tr().toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expiry,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBrandIcon() {
    IconData icon;
    Color color;

    switch (_detectedBrand) {
      case 'visa':
        icon = LucideIcons.creditCard;
        color = Colors.blue[700]!;
        break;
      case 'mastercard':
        icon = LucideIcons.creditCard;
        color = Colors.orange[700]!;
        break;
      case 'amex':
        icon = LucideIcons.creditCard;
        color = Colors.green[700]!;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildCardBrandIconWhite() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _detectedBrand.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    bool obscureText = false,
    bool required = true,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffix,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            if (!required)
              Text(
                ' (${'wallet.optional'.tr()})',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          obscureText: obscureText,
          textCapitalization: textCapitalization,
          onChanged: (value) {
            setState(() {});
            onChanged?.call(value);
          },
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffix,
                  )
                : null,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'wallet.field_required'.tr();
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isFormValid && !_isLoading ? _addCard : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.plus, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'wallet.add_card'.tr(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
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
