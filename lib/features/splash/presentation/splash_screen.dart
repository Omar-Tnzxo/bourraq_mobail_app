import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/core/constants/app_colors.dart';
import 'package:bourraq/core/services/user_sync_service.dart';
import 'package:bourraq/core/widgets/force_update_sheet.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Fade/Scale controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Gentle floating animation - slower and smoother
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Start animations
    _fadeController.forward();

    // Start floating after fade
    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _floatController.repeat(reverse: true);
      }
    });

    // Navigate after delay
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Check for updates & maintenance mode before proceeding
    if (mounted) {
      await ForceUpdateSheet.checkForUpdate(context);
    }

    // Check if still mounted after potential navigation (e.g., to MaintenanceView)
    if (!mounted) return;

    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final session = Supabase.instance.client.auth.currentSession;

    // مزامنة بيانات المستخدم إذا كان مسجل دخول
    if (session != null) {
      await UserSyncService().syncCurrentUser();
    }

    if (!mounted) return;

    if (!onboardingComplete) {
      context.go('/onboarding');
    } else if (session != null) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryGreen, // Deep Olive
              Color(0xFF1B4D1B), // Slightly lighter deep green
              Color(0xFF0D250D), // Almost black green
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative Stars & Crescent
            _buildDecorations(),

            Center(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _fadeController,
                  _floatController,
                ]),
                builder: (context, child) {
                  final float = math.sin(_floatController.value * math.pi) * 12;

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Floating Ramadan Logo
                          Transform.translate(
                            offset: Offset(0, -float),
                            child: Image.asset(
                              'assets/images/ramadan_logo.png',
                              width: 240,
                              height: 240,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Ramadan Greeting Arabic
                          const Text(
                            'رمضانك أسهل مع بُراق',
                            style: TextStyle(
                              fontFamily: 'PingAR',
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentYellow, // Lime Gold
                              shadows: [
                                Shadow(
                                  blurRadius: 15.0,
                                  color: Colors.black54,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 4), // Reduced spacing
                          // Original Tagline
                          const Text(
                            'طلباتك، بين إيديك',
                            style: TextStyle(
                              fontFamily: 'PingAR',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorations() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.25,
        child: Stack(
          children: [
            // Crescent Moon
            Positioned(
              top: 80,
              right: 50,
              child: Transform.rotate(
                angle: -math.pi / 6,
                child: const Icon(
                  Icons.dark_mode_rounded,
                  size: 60,
                  color: AppColors.accentYellow,
                ),
              ),
            ),
            // Stars
            for (var i = 0; i < 30; i++)
              Positioned(
                top: math.Random().nextDouble() * 800,
                left: math.Random().nextDouble() * 500,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.3, end: 1.0),
                  duration: Duration(milliseconds: 1000 + (i * 100)),
                  builder: (context, opacity, _) {
                    return Icon(
                      Icons.star_rounded,
                      size: math.Random().nextDouble() * 6 + 3,
                      color: Colors.white.withOpacity(opacity * 0.6),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
