import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/router/app_router.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/utils/date_formatter.dart';
import 'package:bourraq/core/widgets/shimmer_skeleton.dart';
import 'package:bourraq/features/orders/data/order_model.dart';
import 'package:bourraq/features/orders/data/orders_service.dart';

/// Orders List Screen - Professional & Fully Dynamic
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  final OrdersService _ordersService = OrdersService();
  late TabController _tabController;

  List<Order> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final orders = await _ordersService.getOrders();
    if (mounted) {
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    }
  }

  List<Order> get _activeOrders => _allOrders.where((o) => o.isActive).toList();
  List<Order> get _completedOrders =>
      _allOrders.where((o) => o.status == OrderStatus.delivered).toList();
  List<Order> get _cancelledOrders =>
      _allOrders.where((o) => o.status == OrderStatus.cancelled).toList();

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _buildAppBar(isArabic, innerBoxIsScrolled),
        ],
        body: _isLoading
            ? const ShimmerList(
                itemCount: 4,
                itemBuilder: ShimmerOrderCard(),
                padding: EdgeInsets.all(16),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersList(
                    _activeOrders,
                    'orders.no_active_orders'.tr(),
                    LucideIcons.packageSearch,
                    'orders.no_active_hint'.tr(),
                  ),
                  _buildOrdersList(
                    _completedOrders,
                    'orders.no_completed_orders'.tr(),
                    LucideIcons.packageCheck,
                    'orders.no_completed_hint'.tr(),
                  ),
                  _buildOrdersList(
                    _cancelledOrders,
                    'orders.no_cancelled_orders'.tr(),
                    LucideIcons.packageX,
                    'orders.no_cancelled_hint'.tr(),
                  ),
                ],
              ),
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isArabic, bool innerBoxIsScrolled) {
    return SliverAppBar(
      backgroundColor: AppColors.deepOlive,
      expandedHeight: 140,
      pinned: true,
      floating: false,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(color: AppColors.deepOlive),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back + Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Back button row
                        GestureDetector(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                isArabic
                                    ? LucideIcons.arrowRight
                                    : LucideIcons.arrowLeft,
                                color: Colors.white.withOpacity(0.8),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'error.go_back'.tr(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Title - Large Bold
                        Text(
                          'orders.title'.tr(),
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Logo
                  Image.asset(
                    'assets/icons/white_icon_logo.png',
                    height: 64,
                    width: 64,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGreen,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            indicatorColor: AppColors.primaryGreen,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: [
              _buildTab(
                'orders.active'.tr(),
                _activeOrders.length,
                AppColors.primaryGreen,
              ),
              _buildTab(
                'orders.completed'.tr(),
                _completedOrders.length,
                AppColors.success,
              ),
              _buildTab(
                'orders.cancelled'.tr(),
                _cancelledOrders.length,
                Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count, Color badgeColor) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrdersList(
    List<Order> orders,
    String emptyTitle,
    IconData emptyIcon,
    String emptyHint,
  ) {
    if (orders.isEmpty) {
      return _buildEmptyState(emptyTitle, emptyIcon, emptyHint);
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildEmptyState(String title, IconData icon, String hint) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => AppRouter.router.go('/home'),
              icon: const Icon(LucideIcons.shoppingBag),
              label: Text('orders.browse_products'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isArabic = context.locale.languageCode == 'ar';

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        order.status,
                      ).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getStatusIcon(order.status),
                      color: _getStatusColor(order.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Order ID + Date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.id.substring(0, 8).toUpperCase()}',
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormatter.formatOrderDate(
                            order.createdAt,
                            context,
                          ),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  _buildStatusBadge(order.status, isArabic),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Address Row
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          order.addressLabel ??
                              order.addressText ??
                              'common.not_specified'.tr(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Items + Total Row
                  Row(
                    children: [
                      Icon(
                        LucideIcons.package,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${order.itemCount} ${'orders.items'.tr()}',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${order.total.toStringAsFixed(2)} ${'common.egp'.tr()}',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action Button (for active orders)
            if (order.isActive)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/orders/${order.id}/tracking'),
                  icon: const Icon(LucideIcons.mapPinned, size: 18),
                  label: Text('orders.track_order'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryGreen,
                    side: BorderSide(color: AppColors.primaryGreen),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // Reorder Button (for delivered orders)
            if (order.status == OrderStatus.delivered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/orders/${order.id}'),
                  icon: const Icon(LucideIcons.refreshCw, size: 18),
                  label: Text('orders.reorder'.tr()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: BorderSide(color: AppColors.success),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isArabic ? status.labelAr : status.labelEn,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.onTheWay:
        return AppColors.primaryGreen;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return LucideIcons.hourglass;
      case OrderStatus.confirmed:
        return LucideIcons.circleCheck;
      case OrderStatus.preparing:
        return LucideIcons.chefHat;
      case OrderStatus.onTheWay:
        return LucideIcons.bike;
      case OrderStatus.delivered:
        return LucideIcons.packageCheck;
      case OrderStatus.cancelled:
        return LucideIcons.circleX;
    }
  }
}
