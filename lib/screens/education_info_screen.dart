import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EducationInfoScreen extends StatelessWidget {
  const EducationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("সচেতনতা ও তথ্য"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("জানুন, সচেতন হোন", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
            const SizedBox(height: 8),
            Text("তামাক সম্পর্কে সঠিক তথ্য জানুন এবং নিজেকে অনুপ্রাণিত রাখুন।", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
            const SizedBox(height: 32),
            
            // Myth vs Fact Section
            Text("ভ্রান্ত ধারণা বনাম সত্য", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            _buildMythFactCard(
              context,
              myth: "ই-সিগারেট বা ভ্যাপিং সম্পূর্ণ নিরাপদ।",
              fact: "ভুল! ই-সিগারেটেও নিকোটিন থাকে যা আসক্তি তৈরি করে এবং ফুসফুসের জন্য ক্ষতিকর।",
            ),
            _buildMythFactCard(
              context,
              myth: "আমি অনেক বছর ধরে ধূমপান করছি, এখন ছেড়ে দিয়ে কোনো লাভ নেই।",
              fact: "ভুল! ধূমপান ছাড়ার সাথে সাথেই শরীর নিজেকে মেরামত করতে শুরু করে, বয়স বা ধূমপানের মেয়াদ যাই হোক না কেন।",
            ),
            
            const SizedBox(height: 32),

            // Harmful Effects Section
            Text("তামাকের ক্ষতিকর প্রভাব", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            _buildArticleCard(
              context,
              "ফুসফুসের ক্যান্সার ও হৃদরোগ",
              "ধূমপান ফুসফুসের ক্যান্সারের প্রধান কারণ। এছাড়া এটি রক্তনালী সংকুচিত করে, যা হার্ট অ্যাটাক এবং স্ট্রোকের ঝুঁকি বহুগুণ বাড়িয়ে দেয়।",
              Icons.favorite,
              AppTheme.errorColor,
            ),
            _buildArticleCard(
              context,
              "প্যাসিভ স্মোকিং (পরোক্ষ ধূমপান)",
              "আপনার ধূমপানের ধোঁয়া আপনার চারপাশের প্রিয়জনদেরও সমানভাবে ক্ষতি করে। শিশুদের শ্বাসকষ্ট ও নিউমোনিয়ার ঝুঁকি বাড়ে।",
              Icons.family_restroom,
              AppTheme.primaryBlue,
            ),
            _buildArticleCard(
              context,
              "আর্থিক ক্ষতি",
              "সিগারেট কেনা শুধু স্বাস্থ্যের জন্যই নয়, আপনার পকেটের জন্যও ক্ষতিকর। হিসাব করে দেখুন, এই টাকা দিয়ে আপনি কত ভালো কিছু করতে পারতেন!",
              Icons.money_off,
              AppTheme.accentOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMythFactCard(BuildContext context, {required String myth, required String fact}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.cancel, color: AppTheme.errorColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ভ্রান্ত ধারণা:", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.errorColor)),
                    const SizedBox(height: 4),
                    Text(myth, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("সত্য:", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryGreen)),
                    const SizedBox(height: 4),
                    Text(fact, style: Theme.of(context).textTheme.bodyMedium),
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
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
