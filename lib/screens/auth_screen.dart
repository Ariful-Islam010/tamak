import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'profile_assessment_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.spa, color: AppTheme.primaryBlue, size: 32),
              ),
              const SizedBox(height: 24),
              Text(
                "স্বাগতম",
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontSize: 32,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "এগিয়ে চলুন তামাকমুক্ত জীবনের দিকে",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textLight,
                    ),
              ),
              const SizedBox(height: 48),
              
              // Phone Login Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "লগইন করুন",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: "ফোন নম্বর",
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textLight),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Bypass OTP directly to Assessment for mockup purposes
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileAssessmentScreen()),
                          );
                        },
                        child: const Text("OTP পাঠান"),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              Center(
                child: Text(
                  "অথবা",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textLight,
                      ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Google Login Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileAssessmentScreen()),
                    );
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 32, color: AppTheme.primaryBlue),
                  label: const Text("Google দিয়ে লগইন করুন"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    foregroundColor: AppTheme.textColor,
                    textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
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
