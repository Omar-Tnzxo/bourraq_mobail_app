import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:intl/number_symbols.dart';
import 'package:bourraq/features/favorites/data/repositories/favorites_repository.dart';
import 'package:bourraq/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/session_manager.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/cache_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/analytics_service.dart';
import 'core/notifiers/cart_badge_notifier.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/account/data/repositories/account_content_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable high refresh rate (60Hz+) on Android
  if (Platform.isAndroid) {
    await _enableHighRefreshRate();
  }

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize EasyLocalization
  await EasyLocalization.ensureInitialized();

  // Force English numbers globally for Arabic locale
  // This ensures that NumberFormat and DateFormat use Latin digits
  if (numberFormatSymbols.containsKey('ar')) {
    numberFormatSymbols['ar'] = numberFormatSymbols['en_US'] as NumberSymbols;
  }

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize ConnectivityService for network monitoring
  await ConnectivityService().initialize();

  // Initialize CacheService for local data persistence
  await CacheService().initialize();

  // Initialize SessionManager for JWT handling
  SessionManager().initialize();

  // Initialize FCM for push notifications
  await FcmService().initialize();

  // Initialize Analytics (Analytics, Crashlytics, Performance)
  await AnalyticsService().initialize();

  // Pass all uncaught Flutter errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Pass all uncaught async errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale(
        'ar',
      ), // Default to Arabic if device locale not supported
      // startLocale removed to use device locale automatically
      // If device is English -> English, otherwise -> Arabic (fallback)
      child: const BourraqApp(),
    ),
  );
}

/// Enable high refresh rate display mode on Android
Future<void> _enableHighRefreshRate() async {
  try {
    // Request highest available refresh rate
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Enable edge-to-edge display for smoother scrolling
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  } catch (e) {
    debugPrint('⚠️ High refresh rate setup failed: $e');
  }
}

class BourraqApp extends StatefulWidget {
  const BourraqApp({super.key});

  @override
  State<BourraqApp> createState() => _BourraqAppState();
}

class _BourraqAppState extends State<BourraqApp> {
  @override
  void initState() {
    super.initState();
    // Listen for session expiry and redirect to login
    SessionManager().onSessionExpired.listen((_) {
      if (!mounted) return;
      debugPrint('🔴 [APP] Session expired or user signed out');

      // Use microtask to ensure we don't navigate during a build cycle
      Future.microtask(() {
        // Prevent redundant navigation if already on login/onboarding
        final router = AppRouter.router;
        final currentLocation = router.routerDelegate.currentConfiguration.uri
            .toString();

        if (currentLocation.contains('/login') ||
            currentLocation.contains('/email-login') ||
            currentLocation.contains('/otp-verification')) {
          debugPrint('ℹ️ [APP] Already on auth screen, skipping redirect');
          return;
        }

        // Hide keyboard before redirect to avoid UI freezing
        FocusManager.instance.primaryFocus?.unfocus();

        debugPrint('➡️ [APP] Redirecting to login from $currentLocation...');
        router.go('/login');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(supabase),
        ),
        RepositoryProvider<AccountContentRepository>(
          create: (context) => AccountContentRepository(supabase: supabase),
        ),
        RepositoryProvider<FavoritesRepository>(
          create: (context) => FavoritesRepository(Supabase.instance.client),
        ),
      ],
      child: ChangeNotifierProvider<CartBadgeNotifier>(
        create: (context) => CartBadgeNotifier()..init(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>(
              create: (context) =>
                  AuthCubit(context.read<AuthRepository>())..checkAuthStatus(),
            ),
            BlocProvider<FavoritesCubit>(
              create: (context) =>
                  FavoritesCubit(context.read<FavoritesRepository>()),
            ),
          ],
          child: MaterialApp.router(
            title: 'Bourraq',
            debugShowCheckedModeBanner: false,

            // Theme
            theme: AppTheme.lightTheme,

            // Smooth scrolling behavior
            scrollBehavior: const _SmoothScrollBehavior(),

            // Localization
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,

            // Router
            routerConfig: AppRouter.router,
          ),
        ),
      ),
    );
  }
}

// Supabase client accessor
final supabase = Supabase.instance.client;

/// Custom scroll behavior for smooth 60Hz+ scrolling
class _SmoothScrollBehavior extends ScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // Use BouncingScrollPhysics for iOS-like smooth scrolling
    return const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
    );
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Remove glow effect for cleaner look
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };
}
