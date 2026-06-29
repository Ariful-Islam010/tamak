import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/gamification_provider.dart';
import '../providers/money_saver_provider.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  /// Helper to get the tree name/emoji by stage
  Map<String, String> _getTreeInfo(int stage, bool hasPest) {
    if (hasPest) {
      return {
        "emoji": "🥀👾",
        "title": "ডেমন আক্রান্ত চারাগাছ",
        "desc": "নিকোটিন ডেমন আপনার চারাগাছটিকে আক্রমণ করেছে! এটি তাড়াতে টানা ৩ দিন সম্পূর্ণ তামাকমুক্ত থাকুন।",
      };
    }
    switch (stage) {
      case 0:
        return {
          "emoji": "🫙✨",
          "title": "খালি জাদুকরী পাত্র",
          "desc": "আপনার বাগানের প্রথম জাদুকরী বীজের অঙ্কুরোদগম শুরু করতে দৈনিক টাস্ক ও চেক-ইন সম্পন্ন করুন।",
        };
      case 1:
        return {
          "emoji": "🌱💖",
          "title": "প্রথম অঙ্কুরোদগম",
          "desc": "অভিনন্দন! আপনার সতেজ ইচ্ছাশক্তির চারাগাছটি মাটি ভেদ করে জেগে উঠেছে।",
        };
      case 2:
        return {
          "emoji": "🌿💫",
          "title": "ছোট সবুজ চারা",
          "desc": "গাছটি ধীরে ধীরে বড় হচ্ছে। জল দিয়ে চারাটিকে বড় করতে প্রতিদিন চেক-ইন করুন।",
        };
      case 3:
        return {
          "emoji": "🪴🌟",
          "title": "সতেজ পাতা",
          "desc": "অনেক সুন্দর পাতা গজিয়েছে! সুস্থ ফুসফুসের মতো আপনার গাছও এখন সতেজ হচ্ছে।",
        };
      case 4:
        return {
          "emoji": "🌳🔥",
          "title": "তরুণ শক্তিশালী বৃক্ষ",
          "desc": "গাছটি এখন অনেক শক্তিশালী রূপ নিয়েছে। পূর্ণাঙ্গ রূপ পেতে আর অল্প কিছুদিন বাকি!",
        };
      case 5:
      default:
        return {
          "emoji": "🌲🏆",
          "title": "পূর্ণাঙ্গ জাদুকরী বৃক্ষ!",
          "desc": "অসাধারণ! আপনি একটি সফল গাছ বড় করেছেন এবং আপনার তামাকমুক্ত বাগানকে সমৃদ্ধ করেছেন।",
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamification = context.watch<GamificationProvider>();
    final moneySaver = context.watch<MoneySaverProvider>();

    if (gamification.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.demonDark,
        appBar: AppBar(
          title: const Text("রিওয়ার্ডস ও এচিভমেন্ট"),
          backgroundColor: AppTheme.demonDark,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPink),
        ),
      );
    }

    final treeInfo = _getTreeInfo(gamification.plantStage, gamification.hasPestAttack);

    return Scaffold(
      backgroundColor: AppTheme.demonDark,
      appBar: AppBar(
        title: const Text("গার্ডেন ও রিওয়ার্ডস 🌲🏆", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.demonDark,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.demonDark, AppTheme.demonMid],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // 🌲 ভার্চুয়াল "তামাকমুক্ত বাগান" (Virtual Quit-Forest)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.demonLight,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: gamification.hasPestAttack ? AppTheme.accentOrange : AppTheme.accentLime,
                      width: 3.5,
                    ),
                    boxShadow: AppTheme.glowShadow(
                      gamification.hasPestAttack ? AppTheme.accentOrange : AppTheme.accentLime,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Center(
                        child: Text(
                          "আমার তামাকমুক্ত বৃক্ষ 🌳",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Visual Tree display
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: Text(
                            treeInfo["emoji"]!,
                            key: ValueKey<String>(treeInfo["emoji"]!),
                            style: const TextStyle(fontSize: 60),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Text(
                        treeInfo["title"]!,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: gamification.hasPestAttack ? AppTheme.accentOrange : AppTheme.accentLime,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        treeInfo["desc"]!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const Divider(height: 32, color: Colors.white24),
                      
                      // Watering logic explanation
                      Row(
                        children: [
                          Icon(
                            gamification.hasPestAttack ? Icons.bug_report_rounded : Icons.water_drop_rounded, 
                            color: gamification.hasPestAttack ? AppTheme.accentOrange : Colors.cyanAccent, 
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              gamification.hasPestAttack
                                  ? "পোকা তাড়াতে প্রগতি: ৩ দিনের মধ্যে ${gamification.toBengaliNumeral(gamification.pestDaysClean)} দিন সম্পন্ন"
                                  : "প্রতিদিনের টাস্ক সম্পন্ন করার মাধ্যমে গাছে জল দিন ও সেটিকে বৃক্ষে রূপান্তর করুন!",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 🏅 অর্জনের ব্যাজ এবং ট্রফি (Badges & Milestones)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "অ্যাওয়ার্ড জার্নি 🏅", 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textColor),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "তামাকমুক্ত জীবনের পথে আপনার অর্জিত ব্যাজ ও ট্রফি সমূহ:", 
                      style: TextStyle(color: AppTheme.textLight, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    
                    // Plan & Stats indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatBadge(
                          context,
                          "স্ট্রিক 🔥",
                          "${gamification.toBengaliNumeral(gamification.currentStreak)} দিন",
                          AppTheme.accentOrange,
                        ),
                        _buildStatBadge(
                          context,
                          "পরিকল্পনা 📋",
                          "${gamification.toBengaliNumeral(gamification.planDuration)} দিন",
                          AppTheme.accentCyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Badges list
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: gamification.allBadges.map((badge) {
                        final isUnlocked = gamification.isBadgeUnlocked(badge);
                        return _buildBadgeItem(
                          context,
                          badge.title,
                          badge.icon,
                          badge.color,
                          isUnlocked,
                          badge.description,
                        );
                      }).toList(),
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

  Widget _buildStatBadge(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textLight, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(BuildContext context, String title, IconData icon, Color color, bool isUnlocked, String description) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUnlocked ? "✅ $title - $description" : "🔒 $description"),
            duration: const Duration(seconds: 2),
            backgroundColor: isUnlocked ? AppTheme.accentLime : AppTheme.demonLight,
          ),
        );
      },
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: isUnlocked ? color.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? color : Colors.grey.withValues(alpha: 0.3),
                width: 3.5,
              ),
              boxShadow: isUnlocked 
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isUnlocked ? color : Colors.grey,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isUnlocked ? AppTheme.textColor : AppTheme.textLight,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
