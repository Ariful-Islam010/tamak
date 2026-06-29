import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EducationInfoScreen extends StatelessWidget {
  const EducationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("সচেতনতা ও তথ্য 📚✨", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.demonDark,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "জানুন, সচেতন হোন 💡", 
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textColor),
            ),
            const SizedBox(height: 6),
            const Text(
              "তামাক সম্পর্কে সঠিক তথ্য জানুন এবং নিজেকে অনুপ্রাণিত রাখুন।", 
              style: TextStyle(color: AppTheme.textLight, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            
            // Myth vs Fact Section
            const Text(
              "ভ্রান্ত ধারণা বনাম সত্য 💭⚔️", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textColor),
            ),
            const SizedBox(height: 16),
            _buildMythFactCard(
              context,
              myth: "ই-সিগারেট বা ভ্যাপিং সম্পূর্ণ নিরাপদ।",
              fact: "ভুল! ই-সিগারেটেও निकোটিন থাকে যা আসক্তি তৈরি করে এবং ফুসফুসের জন্য ক্ষতিকর।",
              accentColor: AppTheme.accentPink,
            ),
            _buildMythFactCard(
              context,
              myth: "আমি অনেক বছর ধরে ধূমপান করছি, এখন ছেড়ে দিয়ে কোনো লাভ নেই।",
              fact: "ভুল! ধূমপান ছাড়ার সাথে সাথেই শরীর নিজেকে মেরামত করতে শুরু করে, বয়স বা ধূমপানের মেয়াদ যাই হোক না কেন।",
              accentColor: AppTheme.accentCyan,
            ),
            _buildMythFactCard(
              context,
              myth: "ধূমপান মানসিক চাপ বা স্ট্রেস কমায় এবং মনোযোগ বাড়ায়।",
              fact: "ভুল! নিকোটিনের প্রভাব শেষ হয়ে গেলে স্ট্রেস এবং অস্থিরতা আরও বহুগুণ বেড়ে যায়। এটি একটি সাময়িক বিভ্রান্তি মাত্র।",
              accentColor: AppTheme.accentYellow,
            ),
            _buildMythFactCard(
              context,
              myth: "হালকা (Light) বা ফিল্টারযুক্ত সিগারেট সাধারণ সিগারেটের চেয়ে নিরাপদ।",
              fact: "ভুল! গবেষণায় দেখা গেছে লাইট সিগারেটের ব্যবহারেও ফুসফুসের ক্যান্সার ও হৃদরোগের ঝুঁকি একটুও কমে না।",
              accentColor: AppTheme.accentPink,
            ),
            _buildMythFactCard(
              context,
              myth: "হুক্কা বা শিশা (Shisha) সেবন সিগারেটের চেয়ে কম ক্ষতিকর।",
              fact: "ভুল! হুক্কার পানি ধোঁয়াকে ফিল্টার করতে পারে না। মাত্র এক ঘণ্টার হুক্কা সেশন ১০০টি সিগারেটের সমান ধোঁয়া ছড়ায়।",
              accentColor: AppTheme.accentCyan,
            ),
            
            const SizedBox(height: 28),

            // Harmful Effects Section
            const Text(
              "তামাকের ক্ষতিকর প্রভাব 👾💀", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textColor),
            ),
            const SizedBox(height: 16),
            _buildArticleCard(
              context,
              "ফুসফুসের ক্যান্সার ও হৃদরোগ",
              "ধূমপান ফুসফুসের ক্যান্সারের প্রধান কারণ। এছাড়া এটি রক্তনালী সংকুচিত করে, যা হার্ট অ্যাটাক এবং স্ট্রোকের ঝুঁকি বহুগুণ বাড়িয়ে দেয়।",
              Icons.favorite_rounded,
              AppTheme.errorColor,
            ),
            _buildArticleCard(
              context,
              "প্যাসিভ স্মোকিং (পরোক্ষ ধূমপান)",
              "আপনার ধূমপানের ধোঁয়া আপনার চারপাশের প্রিয়জনদেরও সমানভাবে ক্ষতি করে। শিশুদের শ্বাসকষ্ট ও নিউমোনিয়ার ঝুঁকি বাড়ে।",
              Icons.family_restroom_rounded,
              AppTheme.accentCyan,
            ),
            _buildArticleCard(
              context,
              "ত্বকের অকাল বার্ধক্য ও দাঁতের ক্ষয়",
              "তামাক সেবনে ত্বকের ইলাস্টিসিটি নষ্ট হয়, ফলে দ্রুত বয়সের ছাপ পড়ে। দাঁতে স্থায়ী কালো দাগ এবং মুখের দুর্গন্ধের প্রধান কারণ তামাকের ব্যবহার।",
              Icons.face_rounded,
              AppTheme.accentYellow,
            ),
            _buildArticleCard(
              context,
              "আর্থিক ক্ষতি ও অপচয়",
              "সিগারেট কেনা শুধু স্বাস্থ্যের জন্যই নয়, আপনার পকেটের জন্যও ক্ষতিকর। হিসাব করে দেখুন, এই টাকা জমিয়ে আপনি কত আকর্ষণীয় স্বপ্ন পূরণ করতে পারতেন!",
              Icons.money_off_rounded,
              AppTheme.accentOrange,
            ),
            _buildArticleCard(
              context,
              "রোগ প্রতিরোধ ক্ষমতা হ্রাস",
              "নিকোটিন আমাদের ইমিউন সিস্টেমকে দুর্বল করে দেয়। ফলে ক্ষত শুকাতে বা সাধারণ অসুখ থেকে সেরে উঠতে অনেক বেশি সময় লাগে।",
              Icons.health_and_safety_rounded,
              AppTheme.accentPink,
            ),
            _buildArticleCard(
              context,
              "মস্তিষ্কের ক্ষতি ও স্মৃতিশক্তি হ্রাস",
              "ধূমপান মস্তিষ্কের কর্টেক্স বা চিন্তাশক্তি সৃষ্টিকারী অংশকে পাতলা করে দেয়, যা মনোযোগ ও সিদ্ধান্ত নেওয়ার ক্ষমতা কমিয়ে ফেলে।",
              Icons.psychology_rounded,
              Colors.deepPurpleAccent,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMythFactCard(BuildContext context, {required String myth, required String fact, required Color accentColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accentColor, width: 3),
        boxShadow: AppTheme.glowShadow(accentColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cancel_rounded, color: AppTheme.errorColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ভ্রান্ত ধারণা:", 
                      style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      myth, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: accentColor.withValues(alpha: 0.2), thickness: 1.5),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.accentLime, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "সত্য:", 
                      style: TextStyle(color: AppTheme.accentLime, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fact, 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textColor),
                ),
                const SizedBox(height: 8),
                Text(
                  description, 
                  style: const TextStyle(height: 1.5, fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
