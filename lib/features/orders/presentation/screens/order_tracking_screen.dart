import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/orders/data/order_model.dart';
import 'package:bourraq/features/orders/data/orders_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrdersService _ordersService = OrdersService();
  Order? _order;
  bool _isLoading = true;

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
      return Scaffold(
        appBar: AppBar(
          title: Text('orders.tracking'.tr()),
          backgroundColor: Colors.white,
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

    // Check if order is cancelled
    if (_order!.status == OrderStatus.cancelled) {
      return _buildCancelledState(isArabic);
    }

    // Check if order is delivered
    if (_order!.status == OrderStatus.delivered) {
      return _buildDeliveredState(isArabic);
    }

    // Active order - show tracking
    return _buildTrackingState(isArabic);
  }

  /// === CANCELLED ORDER STATE ===
  Widget _buildCancelledState(bool isArabic) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isArabic),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cancelled Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      LucideIcons.circleX,
                      size: 40,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'orders.status_title.cancelled'.tr(),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'orders.cancelled_message'.tr(),
                    style: TextStyle(color: Colors.red.shade700),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Order Info
            _buildOrderInfo(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// === DELIVERED ORDER STATE ===
  Widget _buildDeliveredState(bool isArabic) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isArabic),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Delivered Header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      LucideIcons.packageCheck,
                      size: 40,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'orders.status_title.delivered'.tr(),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'orders.status_subtitle.delivered'.tr(),
                    style: TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Completed Steps
            _buildCompletedSteps(),

            // Order Info
            _buildOrderInfo(),

            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Rate Order Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push('/orders/${widget.orderId}/rating'),
                      icon: const Icon(LucideIcons.star),
                      label: Text('orders.rate_order'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Reorder Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate back to order details for reorder
                        context.pop();
                      },
                      icon: const Icon(LucideIcons.refreshCw),
                      label: Text('orders.reorder'.tr()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGreen,
                        side: BorderSide(color: AppColors.primaryGreen),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// === ACTIVE TRACKING STATE ===
  Widget _buildTrackingState(bool isArabic) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(isArabic),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Placeholder
            _buildMapPlaceholder(),

            // Tracking Steps
            _buildTrackingSteps(),

            // Order Info
            _buildOrderInfo(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(bool isArabic) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          isArabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
          color: AppColors.textPrimary,
          size: 20,
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/orders');
          }
        },
      ),
      title: Text('orders.tracking'.tr(), style: AppTextStyles.titleLarge),
      centerTitle: true,
      actions: [
        TextButton(
          onPressed: () {
            // TODO: Open help sheet
          },
          child: Text(
            'common.help'.tr(),
            style: TextStyle(color: AppColors.primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.map, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'orders.live_tracking_soon'.tr(),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingSteps() {
    final steps = _getTrackingSteps();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'orders.order_status'.tr(),
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted =
                step.granularIndex <= _order!.status.granularIndex;
            final isCurrent =
                step.granularIndex == _order!.status.granularIndex;
            final isLast = index == steps.length - 1;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? AppColors.primaryGreen
                            : Colors.grey.shade200,
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
                        step.icon,
                        size: 20,
                        color: isCompleted ? Colors.white : Colors.grey,
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 3,
                        height: 50,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.primaryGreen
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isCompleted
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: isCurrent ? 16 : 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isCurrent &&
                            _order!.status != OrderStatus.delivered)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'orders.current'.tr(),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompletedSteps() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.checkCheck, color: AppColors.success, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'orders.all_steps_completed'.tr(),
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_TrackingStep> _getTrackingSteps() {
    return [
      _TrackingStep(
        granularIndex: OrderStatus.pending.granularIndex,
        title: 'orders.status.pending'.tr(),
        subtitle: 'orders.status_subtitle.pending'.tr(),
        icon: LucideIcons.hourglass,
      ),
      _TrackingStep(
        granularIndex: OrderStatus.confirmed.granularIndex,
        title: 'orders.status.confirmed'.tr(),
        subtitle: 'orders.status_subtitle.confirmed'.tr(),
        icon: LucideIcons.circleCheck,
      ),
      _TrackingStep(
        granularIndex: OrderStatus.preparing.granularIndex,
        title: 'orders.status.preparing'.tr(),
        subtitle: 'orders.status_subtitle.preparing'.tr(),
        icon: LucideIcons.chefHat,
      ),
      _TrackingStep(
        granularIndex: OrderStatus.ready.granularIndex,
        title: 'orders.status.ready'.tr(),
        subtitle: 'orders.status_subtitle.ready'.tr(),
        icon: LucideIcons.package,
      ),
      _TrackingStep(
        granularIndex: OrderStatus.assigned.granularIndex,
        title: 'orders.status.assigned'.tr(),
        subtitle: 'orders.status_subtitle.assigned'.tr(),
        icon: LucideIcons.userCheck,
      ),
      _TrackingStep(
        granularIndex: OrderStatus.pickedUp.granularIndex,
        title: 'orders.status.picked_up'.tr(),
        subtitle: 'orders.status_subtitle.picked_up'.tr(),
        icon: LucideIcons.box,
      ),
      _TrackingStep(
        granularIndex: OrderStatus.onTheWay.granularIndex,
        title: 'orders.status.on_the_way'.tr(),
        subtitle: 'orders.status_subtitle.on_the_way'.tr(),
        icon: LucideIcons.bike,
      ),
      _TrackingStep(
        granularIndex: OrderStatus.delivered.granularIndex,
        title: 'orders.status.delivered'.tr(),
        subtitle: 'orders.status_subtitle.delivered'.tr(),
        icon: LucideIcons.packageCheck,
      ),
    ];
  }

  Widget _buildOrderInfo() {
    final isArabic = context.locale.languageCode == 'ar';

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
            LucideIcons.receipt,
            'orders.order_number'.tr(),
            '#${_order!.id.substring(0, 8)}',
          ),
          const Divider(height: 20),
          _infoRow(
            LucideIcons.mapPin,
            'orders.delivery_address'.tr(),
            _order!.addressLabel ?? 'common.not_specified'.tr(),
          ),
          const Divider(height: 20),
          _infoRow(
            LucideIcons.creditCard,
            'checkout.payment_method'.tr(),
            isArabic
                ? _order!.paymentMethod.labelAr
                : _order!.paymentMethod.labelEn,
          ),
          const Divider(height: 20),
          _infoRow(
            LucideIcons.banknote,
            'orders.total'.tr(),
            '${_order!.total.toStringAsFixed(0)} ${'common.egp'.tr()}',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _TrackingStep {
  final int granularIndex;
  final String title;
  final String subtitle;
  final IconData icon;

  const _TrackingStep({
    required this.granularIndex,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
