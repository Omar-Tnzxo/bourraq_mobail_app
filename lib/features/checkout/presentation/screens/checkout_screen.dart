import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/services/analytics_service.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/cart/data/cart_repository.dart';
import 'package:bourraq/features/cart/data/delivery_settings.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';
import 'package:bourraq/features/checkout/data/promo_code_service.dart';
import 'package:bourraq/features/location/data/address_model.dart';
import 'package:bourraq/features/location/data/address_service.dart';
import 'package:bourraq/features/orders/data/order_model.dart';
import 'package:bourraq/features/orders/data/orders_service.dart';
import 'package:bourraq/features/wallet/data/wallet_service.dart';
import 'package:bourraq/features/wallet/data/wallet_model.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final AddressService _addressService = AddressService();
  final OrdersService _ordersService = OrdersService();
  final CartRepository _cartRepository = CartRepository();
  final PromoCodeService _promoCodeService = PromoCodeService();
  final WalletService _walletService = WalletService();
  late CartService _cartService;

  List<CartItem> _cartItems = [];
  List<Address> _addresses = [];
  Address? _selectedAddress;
  PaymentMethod _selectedPayment = PaymentMethod.cash;

  bool _isLoading = true;
  bool _isPlacingOrder = false;

  // Promo code
  final TextEditingController _promoController = TextEditingController();
  bool _isApplyingPromo = false;
  PromoCode? _appliedPromo;
  double _promoDiscount = 0.0;

  // Delivery settings (dynamic from Supabase)
  DeliverySettings _deliverySettings = const DeliverySettings();
  double _deliveryFee = 0.0;

  // Delivery Schedule
  DateTime? _selectedDeliveryTime; // null = As soon as possible

  // Wallet
  Wallet? _wallet;
  bool _useWalletBalance = false;
  bool _walletEnabled = true; // Controlled by app_settings
  double get _walletDeduction => _useWalletBalance && _wallet != null
      ? (_wallet!.balance >= _totalBeforeWallet
            ? _totalBeforeWallet
            : _wallet!.balance)
      : 0.0;

  // Service Fee
  double _serviceFee = 0.0;

  // Delivery Note
  final TextEditingController _deliveryNoteController = TextEditingController();

  double get _discount => _promoDiscount;
  bool get _isFreeShipping => _appliedPromo?.isFreeShipping ?? false;
  double get _effectiveDeliveryFee => _isFreeShipping ? 0.0 : _deliveryFee;
  double get _totalBeforeWallet =>
      _subtotal + _effectiveDeliveryFee + _serviceFee - _discount;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _promoController.dispose();
    _deliveryNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _cartService = CartService(prefs);
    await _cartService.init();

    final addresses = await _addressService.getAddresses();
    final defaultAddress = await _addressService.getDefaultAddress();
    final selectedAddress =
        defaultAddress ?? (addresses.isNotEmpty ? addresses.first : null);

    // Load delivery settings - if address has areaId, load its specific settings
    DeliverySettings deliverySettings;
    if (selectedAddress?.areaId != null) {
      deliverySettings = await _cartRepository.getDeliverySettings(
        selectedAddress!.areaId,
      );
    } else {
      deliverySettings = await _cartRepository.getDeliverySettings(null);
    }

    // Calculate initial fee based on subtotal and settings
    double fee = deliverySettings.getDeliveryFee(_subtotal);

    // Load wallet balance
    final wallet = await _walletService.getWallet();

    // Load service fee settings from app_settings
    double serviceFeeValue = 0.0;
    String serviceFeeType = 'fixed';
    bool serviceFeeEnabled = true;
    bool walletEnabled = true;

    try {
      final settings = await Supabase.instance.client
          .from('app_settings')
          .select('key, value')
          .inFilter('key', [
            'service_fee',
            'service_fee_type',
            'service_fee_enabled',
            'wallet_enabled',
          ]);

      for (final setting in settings) {
        final key = setting['key'] as String;
        final value = setting['value'] as String;
        if (key == 'service_fee') {
          serviceFeeValue = double.tryParse(value) ?? 0.0;
        } else if (key == 'service_fee_type') {
          serviceFeeType = value.toLowerCase();
        } else if (key == 'service_fee_enabled') {
          serviceFeeEnabled = value.toLowerCase() == 'true';
        } else if (key == 'wallet_enabled') {
          walletEnabled = value.toLowerCase() == 'true';
        }
      }
    } catch (_) {}

    double finalServiceFee = 0.0;
    if (serviceFeeEnabled) {
      if (serviceFeeType == 'percentage') {
        finalServiceFee = _subtotal * (serviceFeeValue / 100);
      } else {
        finalServiceFee = serviceFeeValue;
      }
    }

    if (!mounted) return;
    setState(() {
      _cartItems = _cartService.getCartItems();
      _addresses = addresses;
      _selectedAddress = selectedAddress;
      _deliverySettings = deliverySettings;
      _deliveryFee = fee;
      _wallet = wallet;
      _serviceFee = finalServiceFee;
      _walletEnabled = walletEnabled;
      _isLoading = false;
    });

    // Track checkout started
    AnalyticsService().trackBeginCheckout(
      cartTotal: _subtotal,
      itemCount: _cartItems.length,
    );
  }

  double get _subtotal => _cartService.getCartTotal();
  double get _total => _totalBeforeWallet - _walletDeduction;

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      _showError('checkout.select_delivery_address'.tr());
      return;
    }

    // التحقق من أن العنوان داخل منطقة مدعومة
    if (_selectedAddress!.areaId == null) {
      _showError('location.area_not_supported'.tr());
      return;
    }

    if (_cartItems.isEmpty) {
      _showError('checkout.cart_empty'.tr());
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final order = await _ordersService.createOrder(
        addressId: _selectedAddress!.id,
        addressLabel: _selectedAddress!.addressLabel,
        addressText: _selectedAddress!.fullAddress,
        paymentMethod: _selectedPayment,
        subtotal: _subtotal,
        deliveryFee: _deliveryFee,
        serviceFee: _serviceFee,
        discount: _discount,
        total: _total,
        isScheduled: _selectedDeliveryTime != null,
        scheduledTime: _selectedDeliveryTime,
        notes: _deliveryNoteController.text.trim().isNotEmpty
            ? _deliveryNoteController.text.trim()
            : null,
        cartItems: _cartItems
            .map(
              (item) => {
                'id': item.productId,
                'name': item.getName('ar'),
                'image': item.imageUrl,
                'price': item.price,
                'quantity': item.quantity,
              },
            )
            .toList(),
      );

      if (order != null) {
        // Deduct wallet balance if used
        if (_useWalletBalance && _walletDeduction > 0) {
          await _walletService.payFromWallet(_walletDeduction, order.id);
        }

        // Track purchase analytics
        AnalyticsService().trackPurchase(
          orderId: order.id,
          total: _total,
          subtotal: _subtotal,
          discount: _discount,
          deliveryFee: _deliveryFee,
          paymentMethod: _selectedPayment == PaymentMethod.cash
              ? 'cash'
              : 'card',
          itemCount: _cartItems.length,
        );

        // مسح السلة بعد الطلب الناجح
        await _cartService.clearCart();

        if (mounted) {
          // الانتقال لشاشة النجاح
          context.go('/order-success/${order.id}');
        }
      } else {
        _showError('checkout.order_error'.tr());
      }
    } catch (e) {
      _showError('حدث خطأ غير متوقع');
    } finally {
      setState(() => _isPlacingOrder = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.deepOlive,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'checkout.title'.tr(),
          style: AppTextStyles.titleLarge.copyWith(color: Colors.white),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === عنوان التوصيل ===
                  _buildAddressSection(),
                  _buildSectionDivider(),

                  // === وقت التوصيل ===
                  _buildDeliveryTimeSection(),
                  _buildSectionDivider(),

                  // === طريقة الدفع ===
                  _buildPaymentSection(),
                  _buildSectionDivider(),

                  // === كود الخصم ===
                  _buildPromoCodeSection(),
                  _buildSectionDivider(),

                  // === ملاحظة للتوصيل ===
                  _buildDeliveryNoteSection(),
                  _buildSectionDivider(),

                  // === ملخص الطلب ===
                  _buildOrderSummary(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // === زر تأكيد الطلب ===
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.mapPin,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'checkout.delivery_address'.tr(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (_addresses.isNotEmpty)
                GestureDetector(
                  onTap: _showAddressPicker,
                  child: Text(
                    'checkout.change'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Address Content
          if (_selectedAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Address Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAddressIcon(_selectedAddress!.addressLabel),
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Address Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedAddress!.addressLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedAddress!.fullAddress,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // ETA Badge if available
                  if (_selectedAddress?.areaId != null)
                    FutureBuilder(
                      future: Supabase.instance.client
                          .from('areas')
                          .select('estimated_delivery_time')
                          .eq('id', _selectedAddress!.areaId!)
                          .maybeSingle(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            snapshot.data?['estimated_delivery_time'] != null) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 14,
                                  color: AppColors.primaryGreen,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${snapshot.data!['estimated_delivery_time']} ${'common.min'.tr()}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  // Arrow
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.chevronLeft,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            )
          else
            // Add Address Button
            GestureDetector(
              onTap: () => context.push('/add-address'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryGreen.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.plus,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'checkout.add_delivery_address'.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Section divider for visual separation
  Widget _buildSectionDivider() {
    return Container(height: 8, color: AppColors.background);
  }

  Widget _buildPaymentSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(
                LucideIcons.creditCard,
                color: AppColors.primaryGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'checkout.payment_method'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Payment Options
          _buildPaymentOption(
            method: PaymentMethod.cash,
            icon: LucideIcons.banknote,
            title: 'checkout.cash_on_delivery'.tr(),
            subtitle: 'checkout.cash_to_pilot'.tr(),
          ),

          const SizedBox(height: 12),

          _buildPaymentOption(
            method: PaymentMethod.card,
            icon: LucideIcons.creditCard,
            title: 'checkout.credit_card'.tr(),
            subtitle: 'checkout.coming_soon'.tr(),
            isDisabled: true,
          ),

          // Wallet Balance Toggle
          if (_walletEnabled && _wallet != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _useWalletBalance
                    ? AppColors.primaryGreen.withValues(alpha: 0.08)
                    : AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: _useWalletBalance
                    ? Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.4),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.wallet,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'checkout.use_wallet'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _wallet!.balance > 0
                              ? '${_wallet!.balance.toStringAsFixed(2)} ${'common.currency_short'.tr()}'
                              : 'checkout.no_balance'.tr(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _wallet!.balance > 0
                                ? AppColors.primaryGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _useWalletBalance,
                    activeColor: AppColors.primaryGreen,
                    onChanged: _wallet!.balance > 0
                        ? (value) => setState(() => _useWalletBalance = value)
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    bool isDisabled = false,
  }) {
    final isSelected = _selectedPayment == method && !isDisabled;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () => setState(() => _selectedPayment = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDisabled
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
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDisabled
                    ? Colors.grey.shade200
                    : (isSelected
                          ? AppColors.primaryGreen.withValues(alpha: 0.12)
                          : Colors.white),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDisabled
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
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDisabled ? Colors.grey : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDisabled ? Colors.grey : AppColors.textSecondary,
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
                  color: isDisabled
                      ? Colors.grey.shade300
                      : (isSelected
                            ? AppColors.primaryGreen
                            : AppColors.textSecondary.withValues(alpha: 0.4)),
                  width: isSelected ? 2 : 1.5,
                ),
                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(LucideIcons.ticket, color: AppColors.primaryGreen, size: 22),
              const SizedBox(width: 10),
              Text(
                'checkout.promo_code'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_appliedPromo != null)
            // Applied promo code chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.badgeCheck,
                      color: AppColors.primaryGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _appliedPromo!.code,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isFreeShipping
                              ? 'checkout.free_shipping_applied'.tr()
                              : 'checkout.promo_applied'.tr(
                                  args: [_discount.toStringAsFixed(2)],
                                ),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryGreen.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _removePromoCode,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.x,
                        color: AppColors.primaryGreen,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Inline input with button
            Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'checkout.enter_promo'.tr(),
                        hintStyle: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TextButton(
                      onPressed: _isApplyingPromo ? null : _applyPromoCode,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isApplyingPromo
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'checkout.apply'.tr(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      _showError('checkout.enter_promo'.tr());
      return;
    }

    setState(() => _isApplyingPromo = true);

    // Validate promo code from Supabase
    final result = await _promoCodeService.validatePromoCode(code, _subtotal);

    if (!mounted) return;

    if (result.isSuccess) {
      // Check if this is a free shipping promo and delivery is already free
      if (result.promoCode!.isFreeShipping && _deliveryFee == 0) {
        setState(() => _isApplyingPromo = false);
        _showError('checkout.delivery_already_free'.tr());
        return;
      }

      final calculatedDiscount = result.promoCode!.calculateDiscount(_subtotal);
      setState(() {
        _appliedPromo = result.promoCode;
        _promoDiscount = calculatedDiscount;
        _promoController.clear();
        _isApplyingPromo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('checkout.promo_success'.tr()),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
    } else {
      setState(() => _isApplyingPromo = false);
      _showError(result.errorMessage ?? 'checkout.promo_invalid'.tr());
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromo = null;
      _promoDiscount = 0.0;
    });
  }

  Widget _buildOrderSummary() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(
                LucideIcons.receipt,
                color: AppColors.primaryGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'checkout.order_summary'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Products List (expandable in future)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: _cartItems
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.getName(context.locale.languageCode)} × ${item.quantity}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(item.price * item.quantity).toStringAsFixed(2)} ج.م',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Invoice Lines
          _buildSummaryRow('checkout.subtotal'.tr(), _subtotal),

          _buildSummaryRow(
            'checkout.delivery_fee'.tr(),
            _effectiveDeliveryFee,
            isFreeShipping: _isFreeShipping,
            originalDeliveryFee: _deliveryFee,
          ),

          if (_serviceFee > 0)
            _buildSummaryRow('checkout.service_fee'.tr(), _serviceFee),

          if (_discount > 0)
            _buildSummaryRow(
              'checkout.discount'.tr(),
              -_discount,
              isDiscount: true,
            ),

          if (_useWalletBalance && _walletDeduction > 0)
            _buildSummaryRow(
              'checkout.wallet_deduction'.tr(),
              -_walletDeduction,
              isDiscount: true,
            ),

          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'checkout.total'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${_total.toStringAsFixed(2)} ج.م',
                style: const TextStyle(
                  fontSize: 22,
                  color: AppColors.primaryGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryNoteSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(
                LucideIcons.messageSquare,
                color: AppColors.primaryGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'checkout.delivery_note'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Note Input
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TextField(
              controller: _deliveryNoteController,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'checkout.delivery_note_hint'.tr(),
                hintStyle: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
    bool isFreeShipping = false,
    double? originalDeliveryFee,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (isFreeShipping &&
              originalDeliveryFee != null &&
              originalDeliveryFee > 0)
            Row(
              children: [
                Text(
                  '${originalDeliveryFee.toStringAsFixed(2)} ج.م',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'checkout.free'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          else
            Text(
              '${isDiscount ? '-' : ''}${amount.abs().toStringAsFixed(2)} ج.م',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDiscount
                    ? AppColors.primaryGreen
                    : AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    // تعطيل الزر إذا كان العنوان بدون منطقة مدعومة
    final bool canPlaceOrder =
        !_isPlacingOrder &&
        _selectedAddress != null &&
        _selectedAddress!.areaId != null &&
        _cartItems.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canPlaceOrder ? _placeOrder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canPlaceOrder
                  ? AppColors.primaryGreen
                  : Colors.grey.shade400,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'checkout.confirm_order'.tr(),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: canPlaceOrder
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: canPlaceOrder
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_total.toStringAsFixed(2)} ج.م',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: canPlaceOrder
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateDeliveryFee() async {
    if (_selectedAddress == null) return;

    // أولاً: تحقق من شرط التوصيل المجاني
    if (_deliverySettings.isFreeDelivery(_subtotal)) {
      if (mounted) {
        setState(() => _deliveryFee = 0);
      }
      return;
    }

    // ثانياً: إذا لم يتحقق التوصيل المجاني، استخدم رسوم المنطقة
    double fee = _deliverySettings.deliveryFee;

    if (_selectedAddress!.areaId != null) {
      final areaFee = await _cartRepository.getAreaDeliveryFee(
        _selectedAddress!.areaId!,
      );
      if (areaFee != null) {
        fee = areaFee;
      }
    }

    if (mounted) {
      setState(() => _deliveryFee = fee);
    }
  }

  void _showAddressPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'checkout.select_delivery_address'.tr(),
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._addresses.map(
              (a) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _getAddressIcon(a.addressLabel),
                  color: _selectedAddress?.id == a.id
                      ? AppColors.primaryGreen
                      : Colors.grey,
                ),
                title: Text(a.addressLabel, style: AppTextStyles.bodyLarge),
                subtitle: Text(
                  a.fullAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: _selectedAddress?.id == a.id
                    ? const Icon(
                        LucideIcons.check,
                        color: AppColors.primaryGreen,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedAddress = a);
                  _updateDeliveryFee();
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/add-address');
                },
                icon: const Icon(LucideIcons.plus),
                label: Text('checkout.add_delivery_address'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryTimeSection() {
    final isScheduled = _selectedDeliveryTime != null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    color: AppColors.primaryGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'checkout.delivery_time'.tr(),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showDeliveryTimePicker,
                child: Text(
                  'checkout.change'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Delivery Time Content
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Time Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isScheduled ? LucideIcons.calendarClock : LucideIcons.zap,
                    color: AppColors.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                // Time Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isScheduled
                            ? 'checkout.delivery_schedule'.tr()
                            : 'checkout.delivery_now'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isScheduled
                            ? DateFormat(
                                'EEEE, d MMM - h:mm a',
                                context.locale.languageCode,
                              ).format(_selectedDeliveryTime!)
                            : 'checkout.delivery_now'.tr(),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  LucideIcons.chevronLeft,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryTimePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _DeliveryTimePicker(
        onTimeSelected: (time) {
          setState(() => _selectedDeliveryTime = time);
          Navigator.pop(context);
        },
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    if (label.contains('Home') || label.contains('منزل')) {
      return LucideIcons.house;
    } else if (label.contains('Work') || label.contains('عمل')) {
      return LucideIcons.briefcase;
    }
    return LucideIcons.mapPin;
  }
}

class _DeliveryTimePicker extends StatefulWidget {
  final Function(DateTime?) onTimeSelected;

  const _DeliveryTimePicker({required this.onTimeSelected});

  @override
  State<_DeliveryTimePicker> createState() => _DeliveryTimePickerState();
}

class _DeliveryTimePickerState extends State<_DeliveryTimePicker> {
  int _selectedDayIndex = 0; // 0 = Today, 1 = Tomorrow
  int? _selectedSlotIndex;

  // Generate time slots (1-hour intervals from 9 AM to 11 PM)
  List<String> _generateTimeSlots() {
    final slots = <String>[];
    final now = DateTime.now();
    final isToday = _selectedDayIndex == 0;

    for (int hour = 9; hour < 23; hour++) {
      // Skip past slots for today
      if (isToday && hour <= now.hour) continue;

      final startHour = hour > 12 ? hour - 12 : hour;
      final endHour = (hour + 1) > 12 ? (hour + 1) - 12 : (hour + 1);
      final startPeriod = hour >= 12 ? 'PM' : 'AM';
      final endPeriod = (hour + 1) >= 12 ? 'PM' : 'AM';

      slots.add('$startHour:00 $startPeriod - $endHour:00 $endPeriod');
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = _generateTimeSlots();

    return Container(
      padding: const EdgeInsets.all(20),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'checkout.select_time'.tr(),
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(LucideIcons.x, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Day Selector (Today / Tomorrow)
          Row(
            children: [
              Expanded(child: _buildDayChip(0, 'checkout.today'.tr())),
              const SizedBox(width: 12),
              Expanded(child: _buildDayChip(1, 'checkout.tomorrow'.tr())),
            ],
          ),
          const SizedBox(height: 20),

          // Instant Delivery Option
          _buildInstantOption(),
          const SizedBox(height: 16),

          // Time Slots Grid
          Flexible(
            child: timeSlots.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'لا توجد فترات متاحة اليوم',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: timeSlots.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedSlotIndex == index;
                      return _buildSlotTile(
                        timeSlots[index],
                        isSelected,
                        () => setState(() => _selectedSlotIndex = index),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          // Confirm Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedSlotIndex != null || _selectedSlotIndex == -1
                  ? () {
                      if (_selectedSlotIndex == -1) {
                        // Instant delivery
                        widget.onTimeSelected(null);
                      } else {
                        // Calculate scheduled time
                        final baseDate = _selectedDayIndex == 0
                            ? DateTime.now()
                            : DateTime.now().add(const Duration(days: 1));
                        final slots = _generateTimeSlots();
                        final slotStr = slots[_selectedSlotIndex!];
                        final hourStr = slotStr.split(':')[0];
                        final isPM = slotStr.contains('PM');
                        int hour = int.parse(hourStr);
                        if (isPM && hour != 12) hour += 12;
                        if (!isPM && hour == 12) hour = 0;

                        final scheduledTime = DateTime(
                          baseDate.year,
                          baseDate.month,
                          baseDate.day,
                          hour,
                          0,
                        );
                        widget.onTimeSelected(scheduledTime);
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'checkout.confirm_time'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayChip(int index, String label) {
    final isSelected = _selectedDayIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDayIndex = index;
        _selectedSlotIndex = null; // Reset slot selection
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen
              : AppColors.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.titleSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstantOption() {
    final isSelected = _selectedSlotIndex == -1;
    return GestureDetector(
      onTap: () => setState(() => _selectedSlotIndex = -1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryGreen : Colors.grey,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'checkout.delivery_now'.tr(),
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'خلال 45-60 دقيقة',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Text('⚡', style: TextStyle(fontSize: 22)),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotTile(String slot, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              slot,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.textPrimary,
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryGreen
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(LucideIcons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
