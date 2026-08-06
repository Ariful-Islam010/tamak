import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text("প্রাইভেসি ও সিকিউরিটি"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: AppTheme.primaryPurple,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              "তথ্য নিরাপত্তা",
              "আপনার সমস্ত ব্যক্তিগত তথ্য এবং তামাক বর্জনের ইতিহাস আমাদের সুরক্ষিত সার্ভারে (Secure Server) সম্পূর্ণ এনক্রিপ্ট অবস্থায় সুরক্ষিত থাকে। আপনার অনুমতি ছাড়া এই ডেটা তৃতীয় কোনো পক্ষের সাথে শেয়ার করা হয় না।",
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              "লোকাল স্টোরেজ পলিসি",
              "অ্যাপটির গতি বাড়ানোর জন্য কিছু সাধারণ প্রোগ্রেস ডেটা আপনার ডিভাইসের লোকাল স্টোরেজে (Hive) ক্যাশ হিসেবে রাখা হয়। লগআউট করার সাথে সাথে এই লোকাল ক্যাশ ডেটা মুছে ফেলা হয়।",
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              "গুগল সাইন-ইন",
              "গুগল সাইন-ইন এর ক্ষেত্রে আমরা শুধুমাত্র আপনার ডিসপ্লে নাম, ইমেইল এবং প্রোফাইল ফটোর লিংক ব্যবহার করি যা অ্যাকাউন্ট ভেরিফিকেশনের জন্য প্রয়োজন।",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textLight,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
