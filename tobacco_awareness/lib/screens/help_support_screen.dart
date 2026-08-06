import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text("সাহায্য ও সাপোর্ট"),
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
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: AppTheme.primaryGreen,
                  size: 64,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // App Usage Guide Section
            Text(
              "অ্যাপটি যেভাবে ব্যবহার করবেন",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
            ),
            const SizedBox(height: 16),
            _buildGuideItem(
              context,
              "১. কুইট প্ল্যান (Quit Plan)",
              "আপনার লক্ষ্য ও প্রয়োজনীয় তথ্য দিয়ে একটি এআই কুইট প্ল্যান (AI Quit Plan) তৈরি করুন এবং প্রতিদিনের ছোট ছোট টাস্কগুলো সম্পন্ন করুন।",
              Icons.map_outlined,
              AppTheme.primaryBlue,
            ),
            const SizedBox(height: 12),
            _buildGuideItem(
              context,
              "২. দৈনিক চেক-ইন (Daily Check-in)",
              "প্রতিদিন আপনার ক্রেভিংয়ের তীব্রতা, মুড এবং তামাক ব্যবহারের তথ্য ট্র্যাক করুন। এটি আপনার ট্র্যাক রেকর্ড বজায় রাখতে সাহায্য করবে।",
              Icons.check_circle_outline,
              AppTheme.primaryGreen,
            ),
            const SizedBox(height: 12),
            _buildGuideItem(
              context,
              "৩. টাকা সেভার (Money Saver)",
              "তামাক ব্যবহার না করে বাঁচানো টাকা দিয়ে আপনার স্বপ্ন বা ইচ্ছেগুলো যোগ করুন এবং জমানো টাকার প্রোগ্রেস ট্র্যাক করুন।",
              Icons.savings_outlined,
              AppTheme.accentYellow,
            ),
            const SizedBox(height: 12),
            _buildGuideItem(
              context,
              "৪. সহায়তা গ্রুপ (Group Chat)",
              "আমাদের সহায়ক চ্যাট গ্রুপে অন্যান্য বন্ধুদের সাথে অভিজ্ঞতা শেয়ার করুন এবং কাউন্সেলরদের জরুরি নির্দেশনা ও অনুপ্রেরণা নিন।",
              Icons.group_outlined,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildGuideItem(
              context,
              "৫. এস.ও.এস ইমার্জেন্সি (SOS)",
              "তামাক ব্যবহার করার তীব্র ইচ্ছে বা ক্রেভিং হলে এস.ও.এস বাটন চাপুন। ৫ মিনিটের ডিপ-ব্রিথিং বা পানি পানের উপদেশ মেনে নিজের মনকে শান্ত রাখুন।",
              Icons.warning_amber_rounded,
              AppTheme.errorColor,
            ),
            
            const SizedBox(height: 32),
            
            // FAQs Section
            Text(
              "সাধারণ জিজ্ঞাসা (FAQs)",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              context,
              "কিভাবে আমার কুইট ডেট পরিবর্তন করব?",
              "আপনার কুইট ডেট পরিবর্তন করতে প্রোফাইল সম্পাদনা অপশনে যান অথবা প্রাথমিক তথ্য রিসেট করতে আমাদের সাথে ইমেইলে যোগাযোগ করুন।",
            ),
            const SizedBox(height: 12),
            _buildFAQItem(
              context,
              "আমার প্রোগ্রেস ডেটা কি মুছে যাবে?",
              "না, আপনি গুগল সাইন-ইন দিয়ে লগইন করে থাকলে আপনার ডেটা সার্ভারে সংরক্ষিত থাকবে। নতুন ডিভাইসে লগইন করলেও আগের ডেটা ফিরে পাবেন।",
            ),
            
            const SizedBox(height: 32),
            
            // Contact Section (Email-only)
            Text(
              "যোগাযোগ করুন",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
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
              child: const Row(
                children: [
                  Icon(Icons.email_outlined, color: AppTheme.primaryGreen, size: 28),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ইমেল সাপোর্ট",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "ariful010@gmail.com",
                          style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(
    BuildContext context, 
    String title, 
    String description, 
    IconData icon, 
    Color color
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: AppTheme.textLight, height: 1.4, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(color: AppTheme.textLight, height: 1.4),
          ),
        ],
      ),
    );
  }
}
