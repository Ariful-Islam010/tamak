import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/quit_plan_provider.dart';
import '../services/auth_service.dart';

class QuitPlanScreen extends StatelessWidget {
  const QuitPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final quitPlanProvider = context.watch<QuitPlanProvider>();
    final authService = context.watch<AuthService>();

    if (quitPlanProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.demonDark,
        appBar: AppBar(
          title: const Text("আপনার পরিকল্পনা 📋"),
          backgroundColor: AppTheme.demonDark,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.accentPink),
        ),
      );
    }

    if (quitPlanProvider.dailyPlans.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text("আপনার পরিকল্পনা 📋"),
          backgroundColor: AppTheme.demonDark,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "কোনো পরিকল্পনা পাওয়া যায়নি। দয়া করে পুনরায় সাইন আপ করুন।",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      );
    }

    // Calculate today's day index from quitDate
    final quitDate = authService.currentUser?.quitDate;
    int dayIndex = 0;
    if (quitDate != null) {
      final difference = DateTime.now().difference(quitDate).inDays;
      if (difference >= 0) {
        dayIndex = difference;
      }
    }

    if (dayIndex >= quitPlanProvider.dailyPlans.length) {
      dayIndex = quitPlanProvider.dailyPlans.length - 1;
    }
    if (dayIndex < 0) dayIndex = 0;

    final plan = quitPlanProvider.dailyPlans[dayIndex];

    final String dayStr = (dayIndex + 1).toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("আপনার পরিকল্পনা 📋✨", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.demonDark,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: AppTheme.accentCyan, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "এআই (AI) দ্বারা আপনার জন্য তৈরি - $dayStr তম দিন",
                      style: const TextStyle(
                        color: AppTheme.accentCyan,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "আজকের লক্ষ্য 🎯", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textColor),
              ),
              const SizedBox(height: 16),

              // Today's plan card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppTheme.accentCyan, width: 3.5),
                  boxShadow: AppTheme.glowShadow(AppTheme.accentCyan),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.self_improvement, color: AppTheme.accentCyan, size: 44),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      plan["title"] ?? "লক্ষ্য",
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (plan["daily_target"] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.errorColor, width: 2),
                        ),
                        child: Text(
                          "আজকের টার্গেট: ${plan["daily_target"]}",
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      plan["desc"] ?? "",
                      style: const TextStyle(
                        color: AppTheme.textLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Task Information Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.primaryPurple.withValues(alpha: 0.1), width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: AppTheme.accentLime, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                "আপনাকে যা করতে হবে:",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textColor,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan["user_task"] ?? "", 
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textColor),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: AppTheme.primaryPurple.withValues(alpha: 0.1), thickness: 1.5),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.smart_toy, color: AppTheme.accentOrange, size: 22),
                              const SizedBox(width: 8),
                              const Text(
                                "আমি আপনার জন্য যা করেছি:",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textColor,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            plan["ai_task"] ?? "", 
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textColor),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: quitPlanProvider.isGoalStarted
                            ? null
                            : () async {
                                await quitPlanProvider.startGoal();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("দারুণ! আজকের লক্ষ্য শুরু হয়েছে। 🚀"),
                                      backgroundColor: AppTheme.accentLime,
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              },
                        icon: const Icon(Icons.check_circle_rounded, size: 24),
                        label: Text(
                          quitPlanProvider.isGoalStarted
                              ? "আজকের লক্ষ্য শুরু হয়েছে"
                              : "আমি প্রস্তুত 🚀",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: quitPlanProvider.isGoalStarted
                            ? ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade300,
                                foregroundColor: Colors.grey.shade600,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              )
                            : ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentLime,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: AppTheme.accentLime.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                      ),
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
