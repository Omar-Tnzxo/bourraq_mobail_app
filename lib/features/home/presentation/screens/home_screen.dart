import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/constants/app_text_styles.dart';
import 'package:bourraq/core/notifiers/cart_badge_notifier.dart';
import 'package:bourraq/core/widgets/exit_confirmation_dialog.dart';
import 'package:bourraq/features/home/presentation/screens/home_tab_screen.dart';
import 'package:bourraq/features/cart/presentation/screens/cart_screen.dart';
import 'package:bourraq/features/search/presentation/screens/search_screen.dart';
import 'package:bourraq/features/account/presentation/screens/account_screen.dart';

/// Main Home Screen with Bottom Navigation Bar
/// Contains 4 tabs: Home, Cart, Search, Account
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late CartBadgeNotifier _cartBadgeNotifier;

  @override
  void initState() {
    super.initState();
    _cartBadgeNotifier = CartBadgeNotifier();
    _cartBadgeNotifier.init();
  }

  @override
  void dispose() {
    _cartBadgeNotifier.dispose();
    super.dispose();
  }

  List<Widget> get _pages => [
    const HomeTabScreen(), // Modular home tab
    CartScreen(onGoToHome: () => setState(() => _selectedIndex = 0)),
    const SearchScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ExitConfirmationDialog.handleBackPress(context, didPop);
        }
      },
      child: ChangeNotifierProvider<CartBadgeNotifier>.value(
        value: _cartBadgeNotifier,
        child: Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: Consumer<CartBadgeNotifier>(
            builder: (context, cartNotifier, child) {
              return BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (index) {
                  setState(() => _selectedIndex = index);
                  // Refresh cart count when cart tab is selected
                  if (index == 1) {
                    cartNotifier.refresh();
                  }
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.bottomNavBackground,
                selectedItemColor: AppColors.bottomNavActive,
                unselectedItemColor: AppColors.bottomNavInactive,
                selectedLabelStyle: AppTextStyles.labelSmall,
                unselectedLabelStyle: AppTextStyles.labelSmall,
                items: [
                  // Home
                  BottomNavigationBarItem(
                    icon: const Icon(LucideIcons.house, size: 24),
                    activeIcon: Icon(
                      LucideIcons.house,
                      color: AppColors.bottomNavActive,
                      size: 26,
                    ),
                    label: 'home.home_tab'.tr(),
                  ),
                  // Cart - using shoppingBasket
                  BottomNavigationBarItem(
                    icon: _buildCartIcon(cartNotifier.count),
                    activeIcon: _buildCartIcon(
                      cartNotifier.count,
                      isActive: true,
                    ),
                    label: 'home.cart_tab'.tr(),
                  ),
                  // Search
                  BottomNavigationBarItem(
                    icon: const Icon(LucideIcons.search, size: 24),
                    activeIcon: Icon(
                      LucideIcons.search,
                      color: AppColors.bottomNavActive,
                      size: 26,
                    ),
                    label: 'home.search_tab'.tr(),
                  ),
                  // Account
                  BottomNavigationBarItem(
                    icon: const Icon(LucideIcons.user, size: 24),
                    activeIcon: Icon(
                      LucideIcons.user,
                      color: AppColors.bottomNavActive,
                      size: 26,
                    ),
                    label: 'home.account_tab'.tr(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCartIcon(int count, {bool isActive = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          LucideIcons.shoppingBasket,
          color: isActive ? AppColors.bottomNavActive : null,
          size: isActive ? 26 : 24,
        ),
        if (count > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
