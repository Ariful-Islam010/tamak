import 'dart:async';
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

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
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

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // Trigger navigation check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    final authService = context.read<AuthService>();

    // Listen to changes until initial session is checked
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
    // Wait at least 1.5 seconds for a premium feel
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      final user = context.read<AuthService>().currentUser;
      if (user == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
        return;
      }

      if (user.planDuration == null ||
          user.age == null ||
          user.gender == null ||
          user.quitDate == null) {
        // Profile incomplete - sign out and redirect to Auth screen
        context.read<AuthService>().signOut();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Glowing background circles
              Positioned(
                top: -50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                right: -80,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Centered branding (Facebook-style simple clean setup)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.park_rounded,
                        color: AppTheme.primaryGreen,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "তামাকমুক্ত জীবন",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              // Motivational message at the bottom
              Positioned(
                left: 24,
                right: 24,
                bottom: 40,
                child: Column(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _randomQuote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
