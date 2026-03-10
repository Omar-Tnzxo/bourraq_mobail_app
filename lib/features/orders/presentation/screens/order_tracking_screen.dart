import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/features/orders/data/order_model.dart';
import 'package:bourraq/features/orders/data/orders_service.dart';
import 'package:bourraq/core/widgets/app_price_display.dart';
import 'package:bourraq/core/widgets/bourraq_header.dart';
import 'package:bourraq/core/widgets/contact_options_sheet.dart';

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
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            _buildHeader(isArabic),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.packageX,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'orders.not_found'.tr(),
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isArabic),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.circleX,
                      size: 36,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'orders.status_title.cancelled'.tr(),
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.red,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'orders.cancelled_message'.tr(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isArabic),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.packageCheck,
                      size: 36,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'orders.status_title.delivered'.tr(),
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.success,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'orders.status_subtitle.delivered'.tr(),
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isArabic),
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
            'orders.tracking'.tr(),
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.accentYellow,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),

          const Spacer(),

          // Help Button
          GestureDetector(
            onTap: () => ContactOptionsSheet.show(context),
            child: Text(
              'common.help'.tr(),
              style: const TextStyle(
                color: AppColors.accentYellow,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 220,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Pattern/Image
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/images/map_placeholder.png', // Assuming this might exist or use a pattern
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: AppColors.deepOlive.withOpacity(0.1)),
                ),
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.mapPin,
                      size: 32,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'orders.live_tracking'.tr(),
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'orders.live_tracking_soon'.tr(),
                      style: const TextStyle(
                        color: AppColors.deepOlive,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.listTodo,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'orders.order_status'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isCompleted =
                step.granularIndex <= _order!.status.granularIndex;
            final isCurrent =
                step.granularIndex == _order!.status.granularIndex;
            final isLast = index == steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.primaryGreen
                              : Colors.grey.shade100,
                          border: isCurrent
                              ? Border.all(
                                  color: AppColors.primaryGreen,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Icon(
                          isCompleted ? LucideIcons.check : step.icon,
                          size: 16,
                          color: isCompleted ? Colors.white : Colors.grey,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: isCompleted
                                ? AppColors.primaryGreen
                                : Colors.grey.shade200,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isCompleted
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: isCurrent ? 15 : 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                              height: 1.4,
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
                                color: AppColors.primaryGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'orders.current'.tr(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primaryGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompletedSteps() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCheck,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'orders.all_steps_completed'.tr(),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'orders.delivered_successfully'
                      .tr(), // Fallback or new key? Assuming fallback
                  style: TextStyle(
                    color: AppColors.success.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
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
                'orders.order_summary'.tr(),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: AppColors.border),
          ),
          _infoRow(
            LucideIcons.receipt,
            'orders.order_number'.tr(),
            '#${_order!.id.substring(0, 8)}',
          ),
          const SizedBox(height: 16),
          _infoRow(
            LucideIcons.mapPin,
            'orders.delivery_address'.tr(),
            _order!.addressLabel ?? 'common.not_specified'.tr(),
          ),
          const SizedBox(height: 16),
          _infoRow(
            LucideIcons.creditCard,
            'checkout.payment_method'.tr(),
            _order!.paymentMethod.translationKey.tr(),
          ),
          const SizedBox(height: 16),
          _infoRow(
            LucideIcons.banknote,
            'orders.total'.tr(),
            'total',
            numericValue: _order!.total,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    double? numericValue,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ),
        if (numericValue != null)
          AppPriceDisplay(
            price: numericValue,
            textColor: AppColors.textPrimary,
            scale: 0.88,
          )
        else
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
