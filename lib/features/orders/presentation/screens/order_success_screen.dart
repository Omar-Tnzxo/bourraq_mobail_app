import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/widgets/contact_options_sheet.dart';
import 'package:bourraq/features/orders/data/order_model.dart';
import 'package:bourraq/features/orders/data/orders_service.dart';
import 'package:bourraq/features/orders/data/cancel_reason_service.dart';
import 'package:bourraq/features/orders/presentation/widgets/cancel_order_sheets.dart';

/// Order Success Screen - Breadfast-style design
/// Displays all order details after successful placement
class OrderSuccessScreen extends StatefulWidget {
  final String orderId;

  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  final OrdersService _ordersService = OrdersService();
  Order? _order;
  bool _isLoading = true;
  bool _isCancelling = false;
  String _areaEta = '30-45';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _loadOrder();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    final order = await _ordersService.getOrderDetails(widget.orderId);
    setState(() {
      _order = order;
    });

    // Fetch ETA if area available
    if (order != null) {
      try {
        final addressRes = await Supabase.instance.client
            .from('user_addresses')
            .select('area_id')
            .eq('id', order.addressId)
            .maybeSingle();

        if (addressRes != null && addressRes['area_id'] != null) {
          final areaRes = await Supabase.instance.client
              .from('areas')
              .select('estimated_delivery_time')
              .eq('id', addressRes['area_id'])
              .maybeSingle();

          if (areaRes != null && areaRes['estimated_delivery_time'] != null) {
            _areaEta = areaRes['estimated_delivery_time'];
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
    _animationController.forward();
  }

  Future<void> _cancelOrder() async {
    if (_order == null || _isCancelling) return;

    // Step 1: Show cancel confirmation bottom sheet
    final shouldProceed = await CancelOrderConfirmSheet.show(context);
    if (shouldProceed != true) return;

    // Step 2: Get cancel reasons from Supabase
    final cancelReasonService = CancelReasonService();
    final reasons = await cancelReasonService.getCancelReasons();

    if (!mounted) return;

    // Step 3: Show why cancel reasons bottom sheet
    String? selectedReasonId;
    if (reasons.isNotEmpty) {
      selectedReasonId = await WhyCancelReasonsSheet.show(context, reasons);
      if (selectedReasonId == null) return; // User cancelled
    }

    setState(() => _isCancelling = true);

    try {
      await _ordersService.cancelOrder(
        widget.orderId,
        reasonId: selectedReasonId,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('order_success.cancelled_success'.tr()),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      context.go('/orders');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCancelling = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('order_success.cancel_error'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatOrderNumber(String id) {
    return '#${id.substring(0, 8).toUpperCase()}';
  }

  String _getEstimatedArrival() {
    if (_order?.isScheduled == true && _order?.scheduledTime != null) {
      return DateFormat(
        'h:mm a',
        context.locale.languageCode,
      ).format(_order!.scheduledTime!);
    }
    // Use area ETA if available
    final parts = _areaEta.split('-');
    int minutes = 45;
    if (parts.isNotEmpty) {
      minutes = int.tryParse(parts.last) ?? 45;
    }
    final arrival = DateTime.now().add(Duration(minutes: minutes));
    return DateFormat('h:mm a', context.locale.languageCode).format(arrival);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Success Header
            _buildSuccessHeader(),

            _buildSectionDivider(),

            // Address Card
            _buildAddressCard(),

            _buildSectionDivider(),

            // Payment Card
            _buildPaymentCard(),

            _buildSectionDivider(),

            // Items Card
            _buildItemsCard(),

            _buildSectionDivider(),

            // Order Summary
            _buildOrderSummary(),

            _buildSectionDivider(),

            // Cancel Section
            if (_order?.status.canCancel == true) _buildCancelSection(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(LucideIcons.arrowRight, color: AppColors.textPrimary),
        onPressed: () => context.go('/home'),
      ),
      title: Text(
        'order_success.title'.tr(),
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () {
            // Open help/support bottom sheet
            ContactOptionsSheet.show(context);
          },
          child: Text(
            'order_success.help'.tr(),
            style: TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDivider() {
    return Container(height: 8, color: AppColors.background);
  }

  Widget _buildSuccessHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          // Success Icon with Animation
          ScaleTransition(
            scale: _scaleAnimation,
            child: Image.asset(
              'assets/icons/high-five--bro.png',
              width: 120,
              height: 120,
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'order_success.placed_successfully'.tr(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Arrival Time
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'order_success.arrives_at'.tr(),
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                _getEstimatedArrival(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.mapPin,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Address Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _order?.addressLabel ?? 'order_success.address'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _order?.addressText ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.banknote,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          // Payment Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_order?.total.toStringAsFixed(2)} ${'common.currency'.tr()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _order?.paymentMethod == PaymentMethod.cash
                      ? 'checkout.cash_on_delivery'.tr()
                      : 'checkout.credit_card'.tr(),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard() {
    final items = _order?.items ?? [];
    final itemCount = _order?.itemCount ?? 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                LucideIcons.shoppingCart,
                color: AppColors.textPrimary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'order_success.items_count'.tr(args: [itemCount.toString()]),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Items List
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: item.productImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              item.productImage!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                LucideIcons.package,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                          )
                        : Icon(
                            LucideIcons.package,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Product Details
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.productName}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Price
                  Text(
                    '${item.totalPrice.toStringAsFixed(2)} ${'common.currency'.tr()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
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

  Widget _buildOrderSummary() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(LucideIcons.receipt, color: AppColors.textPrimary, size: 22),
              const SizedBox(width: 10),
              Text(
                'order_success.order_summary'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Order Number
          _buildSummaryRow(
            'order_success.order_number'.tr(),
            _formatOrderNumber(widget.orderId),
            isOrderNumber: true,
          ),

          const SizedBox(height: 12),

          // Subtotal
          _buildSummaryRow(
            'checkout.subtotal'.tr(),
            '${_order?.subtotal.toStringAsFixed(2)} ${'common.currency'.tr()}',
          ),

          // Savings
          if (_order != null && _order!.discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow(
              'order_success.you_saved'.tr(),
              '-${_order!.discount.toStringAsFixed(2)} ${'common.currency'.tr()}',
              isDiscount: true,
            ),
          ],

          const SizedBox(height: 8),

          // Delivery Fee
          _buildSummaryRow(
            'checkout.delivery_fee'.tr(),
            '${_order?.deliveryFee.toStringAsFixed(2)} ${'common.currency'.tr()}',
          ),

          const SizedBox(height: 16),
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
                '${_order?.total.toStringAsFixed(2)} ${'common.currency'.tr()}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isOrderNumber = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isOrderNumber ? FontWeight.w600 : FontWeight.w400,
            color: isDiscount ? AppColors.primaryGreen : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Hint Text
          Text(
            'order_success.cancel_hint'.tr(),
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Cancel Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isCancelling ? null : _cancelOrder,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCancelling
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red.shade300,
                      ),
                    )
                  : Text(
                      'order_success.cancel_order'.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade400,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
