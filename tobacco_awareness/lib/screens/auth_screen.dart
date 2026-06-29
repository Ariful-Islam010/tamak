import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'profile_assessment_screen.dart';
import 'home_dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();

    return Scaffold(
      backgroundColor: AppTheme.demonDark,
      body: Stack(
        children: [
          // Glowing decorative cartoon backgrounds
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentPink.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accentCyan.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  // Animated Logo/Demon Shield
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            gradient: AppTheme.heroGradient,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentPink.withValues(alpha: 0.4),
                                blurRadius: 25 * _scaleAnimation.value,
                                spreadRadius: 6 * _scaleAnimation.value,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.shield_rounded, // Anti-demon shield
                            color: Colors.white,
                            size: 80,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "তামাক মুক্ত চ্যালেঞ্জ ⚔️",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "আসুন সবাই মিলে ধূমপানের ডেমনকে হারিয়ে একটি স্বাস্থ্যকর ও সুন্দর জীবন গড়ে তুলি!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      height: 1.6,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(flex: 2),

                  // Google Login Button
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentPink.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: authService.isLoading
                          ? null
                          : () async {
                              try {
                                final credential = await authService.signInWithGoogle();
                                if (credential != null && context.mounted) {
                                  await authService.refreshProfile();
                                  if (context.mounted) {
                                    final currentUser = authService.currentUser;
                                    if (currentUser != null && currentUser.planDuration != null) {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const HomeDashboardScreen(),
                                        ),
                                      );
                                    } else {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const ProfileAssessmentScreen(),
                                        ),
                                      );
                                    }
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("গুগল সাইন-ইন ব্যর্থ হয়েছে: $e"),
                                      backgroundColor: AppTheme.errorColor,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.demonDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: AppTheme.accentPink, width: 2),
                        ),
                      ),
                      child: authService.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.demonDark),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.g_mobiledata,
                                  size: 32,
                                  color: AppTheme.accentPink,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  "Google দিয়ে শুরু করুন",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
