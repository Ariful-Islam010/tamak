import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class EducationInfoScreen extends StatelessWidget {
  const EducationInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Curved Coral Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: const BoxDecoration(
                color: Color(0xFFD67375), // Coral pink
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.menu_book, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        "সচেতনতা",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          "তামাক সম্পর্কে জানুন\nও ধূমপান মুক্ত জীবন গড়ুন",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.psychology, color: Colors.white, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Content Area
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  _buildMythFactCard(
                    context,
                    myth: "ধূমপান মানসিক চাপ বা স্ট্রেস কমায় এবং মনোযোগ বাড়ায়।",
                    fact: "ভুল! নিকোটিনের প্রভাব শেষ হয়ে গেলে স্ট্রেস এবং অস্থিরতা আরও বহুগুণ বেড়ে যায়। এটি একটি সাময়িক বিভ্রান্তি মাত্র।",
                  ),
                  _buildMythFactCard(
                    context,
                    myth: "হালকা (Light) বা ফিল্টারযুক্ত সিগারেট সাধারণ সিগারেটের চেয়ে নিরাপদ।",
                    fact: "ভুল! গবেষণায় দেখা গেছে লাইট সিগারেটের ব্যবহারেও ফুসফুসের ক্যান্সার ও হৃদরোগের ঝুঁকি একটুও কমে না।",
                  ),
                  _buildMythFactCard(
                    context,
                    myth: "হুক্কা বা শিশা (Shisha) সেবন সিগারেটের চেয়ে কম ক্ষতিকর।",
                    fact: "ভুল! হুক্কার পানি ধোঁয়াকে ফিল্টার করতে পারে না। মাত্র এক ঘণ্টার হুক্কা সেশন ১০০টি সিগারেটের সমান ধোঁয়া ছড়ায়।",
                  ),
                  
                  const SizedBox(height: 32),

                  // Harmful Effects Section
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "তামাকের ক্ষতিকর প্রভাব",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildArticleCard(
                    context,
                    "ফুসফুসের ক্যান্সার ও হৃদরোগ",
                    "ধূমপান ফুসফুসের ক্যান্সারের প্রধান কারণ। এছাড়া এটি রক্তনালী সংকুচিত করে, যা হার্ট অ্যাটাক এবং স্ট্রোকের ঝুঁকি বাড়িয়ে দেয়।",
                    Icons.favorite,
                    AppTheme.errorColor,
                  ),
                  _buildArticleCard(
                    context,
                    "প্যাসিভ স্মোকিং (পরোক্ষ ধূমপান)",
                    "আপনাদের ধূমপানের ধোঁয়া আপনার চারপাশের প্রিয়জনদেরও সমানভাবে ক্ষতি করে। শিশুদের শ্বাসকষ্ট ও নিউমোনিয়ার ঝুঁকি বাড়ে।",
                    Icons.family_restroom,
                    AppTheme.primaryBlue,
                  ),
                  _buildArticleCard(
                    context,
                    "ত্বকের অকাল বার্ধক্য ও দাঁতের ক্ষয়",
                    "তামাক সেবনে ত্বকের ইলাস্টিসিটি নষ্ট হয়, ফলে দ্রুত বয়সের ছাপ পড়ে। দাঁতে স্থায়ী কালো দাগ এবং মুখের দুর্গন্ধের প্রধান কারণ তামাকের ব্যবহার।",
                    Icons.face,
                    Colors.teal,
                  ),
                  _buildArticleCard(
                    context,
                    "আর্থিক ক্ষতি ও অপচয়",
                    "সিগারেট কেনা শুধু স্বাস্থ্যের জন্যই নয়, আপনার পকেটের জন্যও ক্ষতিকর। হিসাব করে দেখুন, এই টাকা জমিয়ে আপনি কত আকর্ষণীয় স্বপ্ন পূরণ করতে পারতেন!",
                    Icons.money_off,
                    AppTheme.accentOrange,
                  ),
                  _buildArticleCard(
                    context,
                    "রোগ প্রতিরোধ ক্ষমতা হ্রাস",
                    "নিকোটিন আমাদের ইমিউন সিস্টেমকে দুর্বল করে দেয়। ফলে ক্ষত শুকাতে বা সাধারণ অসুখ থেকে সেরে উঠতে অনেক বেশি সময় লাগে।",
                    Icons.health_and_safety,
                    Colors.purple,
                  ),
                  _buildArticleCard(
                    context,
                    "মস্তিষ্কের ক্ষতি ও স্মৃতিশক্তি হ্রাস",
                    "দীর্ঘমেয়াদী তামাক সেবন মস্তিষ্কের কর্টেক্স বা চিন্তাশক্তি সৃষ্টিকারী অংশকে পাতলা করে দেয়, যা মনোযোগ ও সিদ্ধান্ত নেওয়ার ক্ষমতা কমিয়ে ফেলে।",
                    Icons.psychology,
                    Colors.brown,
                  ),
                ],
              ),
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
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored top bar
            Container(
              height: 5,
              width: double.infinity,
              color: color,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
