import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bourraq/core/constants/app_colors.dart';

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
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
    final session = Supabase.instance.client.auth.currentSession;

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
      backgroundColor: const Color(0xFF113511),
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_fadeController, _floatController]),
          builder: (context, child) {
            // Gentle float - smooth sine wave
            final float = math.sin(_floatController.value * math.pi) * 10;

            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Floating Logo
                    Transform.translate(
                      offset: Offset(0, -float),
                      child: Image.asset(
                        'assets/icons/white_icon_logo.png',
                        width: 200,
                        height: 200,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Text Logo
                    Image.asset(
                      'assets/images/white_text_logo.png',
                      width: 140,
                    ),

                    const SizedBox(height: 12),

                    // Tagline
                    const Text(
                      'طلباتك، بين إيديك',
                      style: TextStyle(
                        fontFamily: 'PingAR',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
