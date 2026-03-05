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
          _buildAppBar(isArabic),
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

  SliverAppBar _buildAppBar(bool isArabic) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      pinned: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
          color: AppColors.textPrimary,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/orders');
          }
        },
      ),
      title: Text(
        '${'orders.order_number'.tr()} #${_order!.id.substring(0, 8)}',
        style: AppTextStyles.titleLarge,
      ),
      centerTitle: true,
    );
  }

  Widget _buildStatusHeader() {
    final status = _order!.status;
    final config = _getStatusConfig(status);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            config.color.withValues(alpha: 0.15),
            config.color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: config.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: config.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.subtitle,
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
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.shoppingBag,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_order!.items.length} ${'orders.items'.tr()}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_order!.items.length, (index) {
            final item = _order!.items[index];
            final isLast = index == _order!.items.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                children: [
                  // Product Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child:
                        item.productImage != null &&
                            item.productImage!.isNotEmpty
                        ? Image.network(
                            item.productImage!,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => _imagePlaceholder(),
                          )
                        : _imagePlaceholder(),
                  ),
                  const SizedBox(width: 14),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.weightValue != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.getWeightDisplay(context.locale.languageCode),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '${item.quantity}x · ${item.price.toStringAsFixed(2)} ${'common.egp'.tr()}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        item.totalPrice.floor().toString(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      Text(
                        '.${((item.totalPrice - item.totalPrice.floor()) * 100).round().toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryGreen.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'common.egp'.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _summaryRow('orders.subtotal'.tr(), _order!.subtotal),
          _summaryRow('orders.delivery'.tr(), _order!.deliveryFee),
          if (_order!.discount > 0)
            _summaryRow(
              'orders.discount'.tr(),
              -_order!.discount,
              isDiscount: true,
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'orders.total'.tr(),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _order!.total.floor().toString(),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  Text(
                    '.${((_order!.total - _order!.total.floor()) * 100).round().toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryGreen.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'common.egp'.tr(),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
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

  Widget _summaryRow(String label, double value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(
            '${isDiscount ? '-' : ''}${value.abs().toStringAsFixed(2)} ${'common.egp'.tr()}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDiscount ? AppColors.success : null,
            ),
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
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/orders/${widget.orderId}/tracking'),
                icon: const Icon(LucideIcons.mapPinned),
                label: Text('orders.track_order'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          if (status.isActive) const SizedBox(height: 12),

          // Cancel Button
          if (status.canCancel)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isCancelling ? null : _cancelOrder,
                icon: _isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.circleX),
                label: Text('orders.cancel_order'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          // Rate + Reorder for Delivered
          if (status == OrderStatus.delivered) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push('/orders/${widget.orderId}/rating'),
                icon: const Icon(LucideIcons.star),
                label: Text('orders.rate_order'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isReordering ? null : _reorder,
                icon: _isReordering
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.refreshCw),
                label: Text('orders.reorder'.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  side: BorderSide(color: AppColors.primaryGreen),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],

          // Cancelled Message
          if (status == OrderStatus.cancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.info, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'orders.cancelled_message'.tr(),
                      style: TextStyle(color: Colors.red.shade700),
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
          color: Colors.orange,
          title: 'orders.status_title.pending'.tr(),
          subtitle: 'orders.status_subtitle.pending'.tr(),
        );
      case OrderStatus.confirmed:
        return _StatusConfig(
          icon: LucideIcons.circleCheck,
          color: Colors.blue,
          title: 'orders.status_title.confirmed'.tr(),
          subtitle: 'orders.status_subtitle.confirmed'.tr(),
        );
      case OrderStatus.preparing:
        return _StatusConfig(
          icon: LucideIcons.chefHat,
          color: Colors.purple,
          title: 'orders.status_title.preparing'.tr(),
          subtitle: 'orders.status_subtitle.preparing'.tr(),
        );
      case OrderStatus.ready:
        return _StatusConfig(
          icon: LucideIcons.package,
          color: Colors.indigo,
          title: 'orders.status_title.ready'.tr(),
          subtitle: 'orders.status_subtitle.ready'.tr(),
        );
      case OrderStatus.assigned:
      case OrderStatus.accepted:
        return _StatusConfig(
          icon: LucideIcons.userCheck,
          color: Colors.teal,
          title: 'orders.status_title.assigned'.tr(),
          subtitle: 'orders.status_subtitle.assigned'.tr(),
        );
      case OrderStatus.pickedUp:
        return _StatusConfig(
          icon: LucideIcons.box,
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
          color: Colors.red,
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
