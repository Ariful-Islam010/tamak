import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'profile_assessment_screen.dart';
import 'home_dashboard_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> with SingleTickerProviderStateMixin {
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
    final authService = ref.watch(authServiceProvider);

    return Scaffold(
      backgroundColor: AppTheme.loginBackgroundColor,
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                shape: BoxShape.circle,
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
                  // Animated Logo/Tree
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          height: 140,
                          width: 140,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                                blurRadius: 20 * _scaleAnimation.value,
                                spreadRadius: 5 * _scaleAnimation.value,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.park_rounded, // Tree icon
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "নতুন যাত্রা",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "এগিয়ে চলুন তামাকমুক্ত সুন্দর জীবনের দিকে, যেখানে প্রতিটি দিন একটি নতুন সাফল্য।",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textLight,
                      height: 1.5,
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
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          blurRadius: 15,
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
                                  final String errorMessage = _getNetworkErrorMessage(e);
                                  _showErrorDialog(context, errorMessage, rawError: e.toString());
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: authService.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.g_mobiledata,
                                    size: 24,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Text(
                                  'Google দিয়ে শুরু করুন',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const Spacer(flex: 3),
                  Text(
                    'সাইন-ইন করার মাধ্যমে আমাদের প্রাইভেসি পলিসিতে সম্মতি দিচ্ছেন',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Network error detection & user friendly message
  String _getNetworkErrorMessage(dynamic error) {
    final String errorStr = error.toString().toLowerCase();

    // Offline / No internet connection
    if (errorStr.contains('socketexception') ||
        errorStr.contains('clientexception') ||
        errorStr.contains('connection failed') ||
        errorStr.contains('network_error') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('handshakeexception')) {
      return 'ইন্টারনেট কানেকশন পাওয়া যায়নি।\n\nঅনুগ্রহ করে ওয়াইফাই বা মোবাইল ডাটা চালু আছে কিনা পরীক্ষা করুন এবং আবার চেষ্টা করুন।';
    }

    // Google sign in specific errors
    if (errorStr.contains('sign_in_failed') ||
        errorStr.contains('google') ||
        errorStr.contains('platformexception') ||
        errorStr.contains('api-exception')) {
      // DEVELOPER_ERROR (code 10) = SHA-1 certificate mismatch in Firebase
      if (errorStr.contains(': 10:') || errorStr.contains('developer_error')) {
        return 'গুগল সাইন-ইন কনফিগারেশন সমস্যা।\n\nঅ্যাপটি পুনরায় ইনস্টল করে চেষ্টা করুন।';
      }
      return 'গুগল সাইন-ইন সম্পন্ন করা সম্ভব হয়নি।\n\nনিচে কারিগরি ত্রুটির বিস্তারিত দেওয়া হলো:';
    }

    // Timeout
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return 'সার্ভারের সাথে সংযোগ সময় শেষ হয়ে গেছে।\n\nঅনুগ্রহ করে আপনার ইন্টারনেট চেক করে আবার চেষ্টা করুন।';
    }

    // Server/API errors
    if (errorStr.contains('server') ||
        errorStr.contains('500') ||
        errorStr.contains('503') ||
        errorStr.contains('502')) {
      return 'সার্ভার সাময়িকভাবে ব্যস্ত আছে।\n\nকিছুক্ষণ পর আবার চেষ্টা করুন।';
    }

    // Default message
    return 'লগইন করতে সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন। 🙏';
  }

  /// Detailed Diagnostic Error Dialog
  void _showErrorDialog(BuildContext context, String message, {String? rawError}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red.shade400,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'সংযোগ সমস্যা',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
