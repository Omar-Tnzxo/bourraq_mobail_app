import 'package:go_router/go_router.dart';
import 'package:bourraq/features/splash/presentation/splash_screen.dart';
import 'package:bourraq/features/onboarding/presentation/onboarding_screen.dart';
import 'package:bourraq/features/auth/presentation/screens/login_screen.dart';
import 'package:bourraq/features/auth/presentation/screens/email_login_screen.dart';
import 'package:bourraq/features/auth/presentation/screens/register_screen.dart';
import 'package:bourraq/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:bourraq/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:bourraq/features/auth/presentation/screens/reset_password_otp_screen.dart';
import 'package:bourraq/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:bourraq/features/home/presentation/screens/home_screen.dart';
import 'package:bourraq/features/products/presentation/screens/product_details_screen.dart';
import 'package:bourraq/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:bourraq/features/categories/presentation/screens/category_products_screen.dart';
import 'package:bourraq/features/location/presentation/screens/addresses_screen.dart';
import 'package:bourraq/features/location/presentation/screens/add_address_screen.dart';
import 'package:bourraq/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:bourraq/features/cart/presentation/screens/cart_screen.dart';
import 'package:bourraq/features/orders/presentation/screens/orders_screen.dart';
import 'package:bourraq/features/orders/presentation/screens/order_success_screen.dart';
import 'package:bourraq/features/orders/presentation/screens/order_details_screen.dart';
import 'package:bourraq/features/orders/presentation/screens/order_tracking_screen.dart';
import 'package:bourraq/features/orders/presentation/screens/order_rating_screen.dart';
import 'package:bourraq/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:bourraq/features/wallet/presentation/screens/add_balance_screen.dart';
import 'package:bourraq/features/wallet/presentation/screens/saved_cards_screen.dart';
import 'package:bourraq/features/wallet/presentation/screens/add_card_screen.dart';
import 'package:bourraq/features/account/presentation/screens/profile_settings_screen.dart';
import 'package:bourraq/features/account/presentation/screens/promo_codes_screen.dart';
import 'package:bourraq/features/account/presentation/screens/faqs_screen.dart';
import 'package:bourraq/features/account/presentation/screens/area_request_screen.dart';

import 'package:bourraq/core/errors/not_found_screen.dart';
import 'package:bourraq/core/services/analytics_service.dart';

/// App routing configuration using GoRouter
class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String emailLogin = '/email-login';
  static const String register = '/register';
  static const String otpVerification = '/otp-verification';
  static const String forgotPassword = '/forgot-password';
  static const String resetPasswordOtp = '/reset-password-otp';
  static const String home = '/home';
  static const String productDetails = '/product/:id';
  static const String favorites = '/favorites';
  static const String categoryProducts = '/category/:id';
  static const String addresses = '/addresses';
  static const String addAddress = '/add-address';
  static const String checkout = '/checkout';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String orderDetails = '/orders/:id';
  static const String orderTracking = '/orders/:id/tracking';
  static const String orderRating = '/orders/:id/rating';
  static const String wallet = '/wallet';
  static const String addBalance = '/wallet/add-balance';
  static const String savedCards = '/wallet/saved-cards';
  static const String addCard = '/wallet/add-card';
  static const String profileSettings = '/profile-settings';
  static const String promoCodes = '/promo-codes';
  static const String faqs = '/faqs';
  static const String areaRequest = '/area-request';
  static const String emailVerification = '/email-verification';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    errorBuilder: (context, state) => NotFoundScreen(path: state.uri.path),
    // Analytics observer for automatic screen tracking
    observers: [AnalyticsService().observer],
    routes: [
      // Splash Screen
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),

      // Onboarding Screen
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Login Screen
      GoRoute(path: login, builder: (context, state) => const LoginScreen()),

      // Email Login Screen
      GoRoute(
        path: emailLogin,
        builder: (context, state) => const EmailLoginScreen(),
      ),

      // Register Screen
      GoRoute(
        path: register,
        builder: (context, state) => const RegisterScreen(),
      ),

      // OTP Verification Screen
      GoRoute(
        path: otpVerification,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final name = state.uri.queryParameters['name'];
          final phone = state.uri.queryParameters['phone'];
          final password = state.uri.queryParameters['password'];
          return OtpVerificationScreen(
            email: email,
            name: name,
            phone: phone,
            password: password,
          );
        },
      ),

      // Forgot Password Screen
      GoRoute(
        path: forgotPassword,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return ForgotPasswordScreen(initialEmail: email);
        },
      ),

      // Reset Password OTP Screen
      GoRoute(
        path: resetPasswordOtp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] ?? '';
          final isProfileUpdate = extra?['isProfileUpdate'] ?? false;
          return ResetPasswordOTPScreen(
            email: email,
            isProfileUpdate: isProfileUpdate,
          );
        },
      ),

      // Email Verification Screen (for email change)
      GoRoute(
        path: emailVerification,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final email = extra?['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),

      // Home Screen
      GoRoute(path: home, builder: (context, state) => const HomeScreen()),

      // Product Details Screen
      GoRoute(
        path: productDetails,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '1';
          return ProductDetailsScreen(productId: id);
        },
      ),

      // Favorites Screen
      GoRoute(
        path: favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),

      // Cart Screen
      GoRoute(
        path: cart,
        builder: (context, state) =>
            CartScreen(onGoToHome: () => AppRouter.router.go('/home')),
      ),

      // Category Products Screen
      GoRoute(
        path: categoryProducts,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '1';
          final name = state.uri.queryParameters['name'] ?? 'فئة';
          return CategoryProductsScreen(categoryId: id, categoryName: name);
        },
      ),

      // Addresses Screen
      GoRoute(
        path: addresses,
        builder: (context, state) => const AddressesScreen(),
      ),

      // Add Address Screen
      GoRoute(
        path: addAddress,
        builder: (context, state) => const AddAddressScreen(),
      ),

      // Checkout Screen
      GoRoute(
        path: checkout,
        builder: (context, state) => const CheckoutScreen(),
      ),

      // Order Success Screen
      GoRoute(
        path: '/order-success/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderSuccessScreen(orderId: id);
        },
      ),

      // Orders Screen
      GoRoute(path: orders, builder: (context, state) => const OrdersScreen()),

      // Order Details Screen
      GoRoute(
        path: orderDetails,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderDetailsScreen(orderId: id);
        },
      ),

      // Order Tracking Screen
      GoRoute(
        path: orderTracking,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderTrackingScreen(orderId: id);
        },
      ),

      // Order Rating Screen
      GoRoute(
        path: orderRating,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return OrderRatingScreen(orderId: id);
        },
      ),

      // Wallet Screen
      GoRoute(path: wallet, builder: (context, state) => const WalletScreen()),

      // Add Balance Screen
      GoRoute(
        path: addBalance,
        builder: (context, state) => const AddBalanceScreen(),
      ),

      // Saved Cards Screen
      GoRoute(
        path: savedCards,
        builder: (context, state) => const SavedCardsScreen(),
      ),

      // Add Card Screen
      GoRoute(
        path: addCard,
        builder: (context, state) => const AddCardScreen(),
      ),

      // Profile Settings Screen
      GoRoute(
        path: profileSettings,
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: promoCodes,
        builder: (context, state) => const PromoCodesScreen(),
      ),
      GoRoute(path: faqs, builder: (context, state) => const FaqsScreen()),
      GoRoute(
        path: areaRequest,
        builder: (context, state) => const AreaRequestScreen(),
      ),
    ],
  );
}
