import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/utils/date_formatter.dart';
import 'package:bourraq/features/orders/data/order_model.dart';
import 'package:bourraq/features/orders/data/orders_service.dart';
import 'package:bourraq/features/orders/presentation/widgets/cancel_reason_sheet.dart';
import 'package:bourraq/features/cart/data/cart_service.dart';
import 'package:bourraq/features/cart/domain/models/cart_item.dart';
import 'package:bourraq/core/widgets/app_price_display.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';

/// Order Details Screen - Professional & Fully Dynamic
/// Displays complete order information with translations
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrdersService _ordersService = OrdersService();
  Order? _order;
  bool _isLoading = true;
  bool _isCancelling = false;
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final order = await _ordersService.getOrderDetails(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelOrder() async {
    final reasonId = await CancelReasonSheet.show(context);
    if (reasonId == null || !mounted) return;

    setState(() => _isCancelling = true);
    final success = await _ordersService.cancelOrder(
      widget.orderId,
      reasonId: reasonId,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('orders.cancel_success'.tr()),
            backgroundColor: Colors.orange,
          ),
        );
        _loadOrder();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('orders.cannot_cancel'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isCancelling = false);
    }
  }

  Future<void> _reorder() async {
    if (_order == null || _order!.items.isEmpty) return;
    setState(() => _isReordering = true);

    try {
      final cartService = CartService.instance;
      int addedCount = 0;

      for (final orderItem in _order!.items) {
        final cartItem = CartItem(
          id: 'reorder_${orderItem.productId}_${DateTime.now().millisecondsSinceEpoch}',
          productId: orderItem.productId,
          nameAr: orderItem.productName,
          nameEn: orderItem.productName,
          price: orderItem.price,
          quantity: orderItem.quantity,
          imageUrl: orderItem.productImage,
        );
        await cartService.addToCart(cartItem);
        addedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'orders.reorder_success'.tr(args: [addedCount.toString()]),
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.push('/cart');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('orders.reorder_error'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isReordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGreen),
        ),
      );
    }

    if (_order == null) {
      return _buildErrorState(isArabic);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(isArabic)),
          SliverToBoxAdapter(child: _buildStatusHeader()),
          if (_order!.status != OrderStatus.cancelled)
            SliverToBoxAdapter(child: _buildProgressSteps()),
          SliverToBoxAdapter(child: _buildOrderInfo()),
          SliverToBoxAdapter(child: _buildAddressSection()),
          SliverToBoxAdapter(child: _buildItemsSection()),
          SliverToBoxAdapter(child: _buildPriceSummary()),
          SliverToBoxAdapter(child: _buildActions()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isArabic) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.packageX, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('orders.not_found'.tr(), style: AppTextStyles.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isArabic) {
    return BourraqHeader(
      padding: const EdgeInsets.only(top: 16, bottom: 40, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/orders');
              }
            },
            child: Padding(
              padding: EdgeInsets.only(
                right: isArabic ? 0 : 12,
                left: isArabic ? 12 : 0,
              ),
              child: Icon(
                isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                color: AppColors.accentYellow,
                size: 28,
              ),
            ),
          ),

          // Title
          Text(
            '${'orders.order_number'.tr()} #${_order!.id.substring(0, 8)}',
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.accentYellow,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader() {
    final status = _order!.status;
    final config = _getStatusConfig(status);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accentYellow,
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: AppColors.primaryGreen, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentYellow,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps() {
    final steps = [
      (0, 'orders.step_review'.tr(), LucideIcons.hourglass),
      (1, 'orders.step_confirm'.tr(), LucideIcons.circleCheck),
      (2, 'orders.step_prepare'.tr(), LucideIcons.chefHat),
      (3, 'orders.step_delivery'.tr(), LucideIcons.bike),
      (4, 'orders.step_done'.tr(), LucideIcons.packageCheck),
    ];

    final currentStep = _order!.status.stepIndex;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'orders.order_status'.tr(),
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Line connector
                final stepIndex = index ~/ 2;
                final isCompleted = stepIndex < currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.primaryGreen
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }

              // Step circle
              final stepIndex = index ~/ 2;
              final (_, label, icon) = steps[stepIndex];
              final isCompleted = stepIndex <= currentStep;
              final isCurrent = stepIndex == currentStep;

              return Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.primaryGreen
                            : Colors.grey.shade100,
                        border: isCurrent
                            ? Border.all(
                                color: AppColors.primaryGreen,
                                width: 3,
                              )
                            : null,
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isCompleted
                            ? Colors.white
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isCurrent
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isCompleted
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _infoRow(
            LucideIcons.calendar,
            'orders.order_date'.tr(),
            _formatDate(_order!.createdAt),
          ),
          const Divider(height: 20),
          _infoRow(
            LucideIcons.wallet,
            'orders.payment_method'.tr(),
            _order!.paymentMethod.translationKey.tr(),
          ),
          if (_order!.isScheduled && _order!.scheduledTime != null) ...[
            const Divider(height: 20),
            _infoRow(
              LucideIcons.clock,
              'orders.scheduled_time'.tr(),
              _formatDate(_order!.scheduledTime!),
            ),
          ],
          if (_order!.notes != null && _order!.notes!.isNotEmpty) ...[
            const Divider(height: 20),
            _infoRow(
              LucideIcons.messageSquare,
              'orders.customer_notes'.tr(),
              _order!.notes!,
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryGreen),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(LucideIcons.mapPin, color: AppColors.primaryGreen),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _order!.addressLabel ?? 'orders.delivery_address'.tr(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_order!.addressText != null &&
                    _order!.addressText!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _order!.addressText!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.shoppingBasket,
                    size: 18,
                    color: AppColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '\u200E${_order!.itemCount % 1 == 0 ? _order!.itemCount.toInt() : _order!.itemCount}\u200E ${'orders.items'.tr()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.border),

          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _order!.items.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: AppColors.border,
            ),
            itemBuilder: (context, index) {
              final item = _order!.items[index];
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image with Frame
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.border.withOpacity(0.5),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child:
                            item.productImage != null &&
                                item.productImage!.isNotEmpty
                            ? Image.network(
                                item.productImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.getName(context.locale.languageCode),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (item.weightValue != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.getWeightDisplay(
                                      context.locale.languageCode,
                                    ),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],

                              // Quantity Tag
                              Text(
                                '\u200E${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity}\u200E \u00D7',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              const SizedBox(width: 6),
                              AppPriceDisplay(
                                price: item.price,
                                textColor: AppColors.textLight,
                                scale: 0.65,
                                showCurrency: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Total for this item
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          textDirection: ui.TextDirection.ltr,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            AppPriceDisplay(
                              price: item.totalPrice,
                              textColor: AppColors.textPrimary,
                              scale: 0.88,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(LucideIcons.image, color: Colors.grey.shade400),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('orders.subtotal'.tr(), _order!.subtotal),
          _summaryRow('orders.delivery'.tr(), _order!.deliveryFee),
          if (_order!.serviceFee > 0)
            _summaryRow('checkout.service_fee'.tr(), _order!.serviceFee),
          if (_order!.discount > 0)
            _summaryRow(
              'orders.discount'.tr(),
              -_order!.discount,
              isDiscount: true,
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'orders.total'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              AppPriceDisplay(
                price: _order!.total,
                textColor: AppColors.primaryGreen,
                scale: 1.25,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Row(
            textDirection: ui.TextDirection.ltr,
            children: [
              if (isDiscount)
                Text(
                  '-',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              AppPriceDisplay(
                price: value.abs(),
                textColor: isDiscount
                    ? AppColors.success
                    : AppColors.textPrimary,
                scale: 0.85,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    final status = _order!.status;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Track Order Button
          if (status.isActive)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/orders/${widget.orderId}/tracking'),
                icon: const Icon(LucideIcons.mapPinned),
                label: Text('orders.track_order'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primaryGreen.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

          if (status.isActive) const SizedBox(height: 14),

          // Cancel Button
          if (status.canCancel)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton.icon(
                onPressed: _isCancelling ? null : _cancelOrder,
                icon: _isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : Icon(
                        LucideIcons.circleX,
                        size: 20,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                label: Text(
                  'orders.cancel_order'.tr(),
                  style: TextStyle(
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.textSecondary.withOpacity(0.1),
                    ),
                  ),
                ),
              ),
            ),

          // Rate + Reorder for Delivered
          if (status == OrderStatus.delivered) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/orders/${widget.orderId}/rating'),
                icon: const Icon(
                  LucideIcons.star,
                  color: AppColors.primaryGreen,
                ),
                label: Text('orders.rate_order'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentYellow,
                  foregroundColor: AppColors.primaryGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _isReordering ? null : _reorder,
                icon: _isReordering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryGreen,
                        ),
                      )
                    : const Icon(LucideIcons.refreshCw, size: 20),
                label: Text('orders.reorder'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: const BorderSide(
                    color: AppColors.primaryGreen,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],

          // Cancelled Message
          if (status == OrderStatus.cancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.circleAlert,
                    color: AppColors.error,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'orders.cancelled_message'.tr(),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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

  _StatusConfig _getStatusConfig(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return _StatusConfig(
          icon: LucideIcons.hourglass,
          color: const Color(0xFFF59E0B),
          title: 'orders.status_title.pending'.tr(),
          subtitle: 'orders.status_subtitle.pending'.tr(),
        );
      case OrderStatus.confirmed:
        return _StatusConfig(
          icon: LucideIcons.circleCheck,
          color: const Color(0xFF3B82F6),
          title: 'orders.status_title.confirmed'.tr(),
          subtitle: 'orders.status_subtitle.confirmed'.tr(),
        );
      case OrderStatus.preparing:
        return _StatusConfig(
          icon: LucideIcons.chefHat,
          color: const Color(0xFF8B5CF6),
          title: 'orders.status_title.preparing'.tr(),
          subtitle: 'orders.status_subtitle.preparing'.tr(),
        );
      case OrderStatus.ready:
        return _StatusConfig(
          icon: LucideIcons.shoppingBasket,
          color: const Color(0xFF10B981),
          title: 'orders.status_title.ready'.tr(),
          subtitle: 'orders.status_subtitle.ready'.tr(),
        );
      case OrderStatus.assigned:
      case OrderStatus.accepted:
        return _StatusConfig(
          icon: LucideIcons.userCheck,
          color: AppColors.primaryGreen,
          title: 'orders.status_title.assigned'.tr(),
          subtitle: 'orders.status_subtitle.assigned'.tr(),
        );
      case OrderStatus.pickedUp:
        return _StatusConfig(
          icon: LucideIcons.shoppingBasket,
          color: AppColors.primaryGreen,
          title: 'orders.status_title.picked_up'.tr(),
          subtitle: 'orders.status_subtitle.picked_up'.tr(),
        );
      case OrderStatus.onTheWay:
        return _StatusConfig(
          icon: LucideIcons.bike,
          color: AppColors.primaryGreen,
          title: 'orders.status_title.on_the_way'.tr(),
          subtitle: 'orders.status_subtitle.on_the_way'.tr(),
        );
      case OrderStatus.delivered:
        return _StatusConfig(
          icon: LucideIcons.packageCheck,
          color: AppColors.success,
          title: 'orders.status_title.delivered'.tr(),
          subtitle: 'orders.status_subtitle.delivered'.tr(),
        );
      case OrderStatus.cancelled:
        return _StatusConfig(
          icon: LucideIcons.circleX,
          color: AppColors.error,
          title: 'orders.status_title.cancelled'.tr(),
          subtitle: 'orders.status_subtitle.cancelled'.tr(),
        );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormatter.formatFullDateTime(date, context);
  }
}

class _StatusConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
