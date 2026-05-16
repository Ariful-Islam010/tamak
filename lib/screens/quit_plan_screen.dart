import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuitPlanScreen extends StatelessWidget {
  const QuitPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("আপনার পরিকল্পনা"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("আজকের লক্ষ্য", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
              const SizedBox(height: 32),
              
              // Focus only on today's task
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.self_improvement, color: AppTheme.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "মানসিক চাপ নিয়ন্ত্রণ",
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: AppTheme.primaryBlue,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "আজ আপনার মূল ফোকাস হবে স্ট্রেস বা মানসিক চাপ কমানো। যখনই ধূমপান করতে ইচ্ছা করবে, লম্বা শ্বাস নিন এবং অন্য কাজে মনোযোগ দিন।",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("দারুণ! আজকের লক্ষ্য শুরু হয়েছে।")),
                        );
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text("আমি প্রস্তুত"),
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
