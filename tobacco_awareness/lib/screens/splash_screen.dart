import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';
import 'home_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _quoteFade;

  bool _navigationStarted = false;

  final List<String> _quotes = [
    "তামাকমুক্ত প্রতিটি নিঃশ্বাস হোক এক নতুন জীবনের আশ্বাস। 🌿",
    "ধূমপান ত্যাগ করুন, আপনার ফুসফুসকে মুক্ত বাতাসে শ্বাস নিতে দিন। 🍃",
    "প্রতিটি দিন একটি নতুন সুযোগ তামাকমুক্ত জীবন গড়ার। ✨",
    "আপনার স্বাস্থ্য আপনার সেরা সম্পদ, তামাকমুক্ত থাকুন। 💖",
    "আজকের সিদ্ধান্ত হোক সুস্থ ও সুন্দর আগামীর নিশ্চয়তা। 🌟",
  ];
  late String _randomQuote;

  @override
  void initState() {
    super.initState();
    _randomQuote = (_quotes..shuffle()).first;

    // Main entrance animations (staggered)
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _quoteFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Continuous breathing/pulse animation for the logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Gentle background rotation
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    _mainController.forward();

    // Trigger navigation check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    final authService = context.read<AuthService>();

    void listener() {
      if (authService.initialSessionChecked && !_navigationStarted) {
        authService.removeListener(listener);
        _navigateAfterDelay();
      }
    }

    if (authService.initialSessionChecked) {
      _navigateAfterDelay();
    } else {
      authService.addListener(listener);
    }
  }

  void _navigateAfterDelay() {
    _navigationStarted = true;
    Timer(const Duration(milliseconds: 2400), () {
      if (!mounted) return;

      final user = context.read<AuthService>().currentUser;
      if (user == null) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => const AuthScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
        return;
      }

      if (user.planDuration == null ||
          user.age == null ||
          user.gender == null ||
          user.quitDate == null) {
        context.read<AuthService>().signOut();
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (_, __, ___) => const AuthScreen(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (_, __, ___) => const HomeDashboardScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F5132),
              Color(0xFF198754),
              Color(0xFF0A3622),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Rotating background decorative elements
              AnimatedBuilder(
                animation: _rotateController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotateController.value * 2 * math.pi,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -60,
                          left: -40,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -80,
                          right: -50,
                          child: Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.emerald.shade300.withValues(alpha: 0.2),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Centered branding with pulse & scale animations
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo Icon
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulseScale = 1.0 + (_pulseController.value * 0.06);
                        return ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: Transform.scale(
                              scale: pulseScale,
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 30 + (_pulseController.value * 15),
                                      spreadRadius: 8 + (_pulseController.value * 4),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.park_rounded,
                                  color: Color(0xFF198754),
                                  size: 72,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Animated App Title
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _quoteFade,
                        child: Column(
                          children: [
                            const Text(
                              "তামাকমুক্ত জীবন",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black38,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Text(
                                "AI-Powered Quit Tobacco Assistant",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Animated Pulsing Dots & Motivational Quote at Bottom
              Positioned(
                left: 24,
                right: 24,
                bottom: 40,
                child: FadeTransition(
                  opacity: _quoteFade,
                  child: Column(
                    children: [
                      // Sleek Animated Loading Bar / Dots
                      const _AnimatedLoadingIndicator(),
                      const SizedBox(height: 28),

                      // Quote Container with Glassmorphism
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Text(
                          _randomQuote,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Animated Wave / Dot Loading Indicator
class _AnimatedLoadingIndicator extends StatefulWidget {
  const _AnimatedLoadingIndicator();

  @override
  State<_AnimatedLoadingIndicator> createState() => _AnimatedLoadingIndicatorState();
}

class _AnimatedLoadingIndicatorState extends State<_AnimatedLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final double value = math.sin((_animController.value * 2 * math.pi) - (delay * math.pi));
            final double opacity = (value + 1) / 2; // Normalize to 0.0 - 1.0
            final double scale = 0.8 + (opacity * 0.4);

            return Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.3 + (opacity * 0.7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: opacity * 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

