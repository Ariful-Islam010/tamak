import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quit_plan_provider.dart';
import '../services/auth_service.dart';

class QuitPlanScreen extends StatelessWidget {
  const QuitPlanScreen({super.key});

  String _toBengali(int number) {
    return number
        .toString()
        .replaceAll('0', '০')
        .replaceAll('1', '১')
        .replaceAll('2', '২')
        .replaceAll('3', '৩')
        .replaceAll('4', '৪')
        .replaceAll('5', '৫')
        .replaceAll('6', '৬')
        .replaceAll('7', '৭')
        .replaceAll('8', '৮')
        .replaceAll('9', '৯');
  }

  @override
  Widget build(BuildContext context) {
    final quitPlanProvider = context.watch<QuitPlanProvider>();
    final authService = context.watch<AuthService>();

    if (quitPlanProvider.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE8325A),
          foregroundColor: Colors.white,
          title: const Text("আপনার পরিকল্পনা"),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (quitPlanProvider.dailyPlans.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE8325A),
          foregroundColor: Colors.white,
          title: const Text("আপনার পরিকল্পনা"),
          elevation: 0,
        ),
        body: const Center(
          child: Text("কোনো পরিকল্পনা পাওয়া যায়নি। দয়া করে পুনরায় সাইন আপ করুন।"),
        ),
      );
    }

    // ── Calculate days relative to quitDate ──
    final quitDate = authService.currentUser?.quitDate;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // Days until plan starts (positive = future, 0 = today, negative = past)
    int daysUntilStart = 0;
    int dayIndex = 0;

    if (quitDate != null) {
      final quitDay = DateTime(quitDate.year, quitDate.month, quitDate.day);
      final diff = today.difference(quitDay).inDays;
      if (diff < 0) {
        // Plan hasn't started yet
        daysUntilStart = -diff;
        dayIndex = 0;
      } else {
        daysUntilStart = 0;
        dayIndex = diff;
      }
    }

    if (dayIndex >= quitPlanProvider.dailyPlans.length) {
      dayIndex = quitPlanProvider.dailyPlans.length - 1;
    }
    if (dayIndex < 0) dayIndex = 0;

    final plan = quitPlanProvider.dailyPlans[dayIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // ── Header Section ──
          _HeaderSection(
            dayIndex: dayIndex,
            daysUntilStart: daysUntilStart,
            toBengali: _toBengali,
          ),

          // ── Body (Scrollable) ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── PRE-PLAN COUNTDOWN BANNER ──
                  if (daysUntilStart > 0) ...[
                    _CountdownBanner(
                      daysLeft: daysUntilStart,
                      toBengali: _toBengali,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Today's Goal Card
                  _TodayGoalCard(
                    plan: plan,
                    isPending: daysUntilStart > 0,
                  ),

                  const SizedBox(height: 20),

                  // Description text
                  Text(
                    plan["desc"] ?? "",
                    style: TextStyle(
                      fontSize: 15,
                      color: daysUntilStart > 0
                          ? const Color(0xFF888888)
                          : const Color(0xFF333333),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFDDDDDD), thickness: 1),
                  const SizedBox(height: 16),

                  // "আপনাকে যা করতে হবে" Section
                  _TaskSection(
                    userTask: plan["user_task"] ?? "",
                    isPending: daysUntilStart > 0,
                  ),

                  // Show completion buttons only if plan has started and not answered today yet
                  if (daysUntilStart == 0 && !quitPlanProvider.hasAnsweredToday) ...[
                    const SizedBox(height: 28),

                    // Completion Question
                    const Text(
                      "আজকের পরিকল্পনা কি সম্পন্ন করেছেন?",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Yes / No Buttons
                    _CompletionButtons(
                      isGoalStarted: quitPlanProvider.isGoalStarted,
                      onYes: () async {
                        await quitPlanProvider.submitPlanResponse(true);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("দারুণ! আজকের লক্ষ্য সফলভাবে সম্পন্ন হয়েছে।"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      onNo: () async {
                        await quitPlanProvider.submitPlanResponse(false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("ধন্যবাদ! আপনার উত্তরটি রেকর্ড করা হয়েছে। আগামীকাল চেষ্টা করুন।"),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────
// Header Section Widget
// ─────────────────────────────────────────────────
class _HeaderSection extends StatelessWidget {
  final int dayIndex;
  final int daysUntilStart;
  final String Function(int) toBengali;

  const _HeaderSection({
    required this.dayIndex,
    required this.daysUntilStart,
    required this.toBengali,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = daysUntilStart > 0;
    return ClipPath(
      clipper: _HeaderClipper(),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          left: 20,
          right: 20,
          bottom: 0,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPending
                ? [const Color(0xFF6B7280), const Color(0xFF4B5563)]
                : [const Color(0xFFE8325A), const Color(0xFFCC2050)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button row
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  SizedBox(width: 6),
                  Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 6),
                  Text(
                    "Guide",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Image (Left) + Text (Right) Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Icon/Hero Image on Left
                Image.asset(
                  'assets/images/quit_plan_hero.png',
                  height: 110,
                  width: 90,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: 90,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isPending ? Icons.hourglass_top_rounded : Icons.self_improvement,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Text Column on Right
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "আপনার পরিকল্পনা",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isPending
                              ? "শুরু হবে ${toBengali(daysUntilStart)} দিন পরে"
                              : "এআই দ্বারা তৈরি — ${toBengali(dayIndex + 1)} তম দিন",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Countdown Banner Widget (shown before plan starts)
// ─────────────────────────────────────────────────
class _CountdownBanner extends StatelessWidget {
  final int daysLeft;
  final String Function(int) toBengali;

  const _CountdownBanner({
    required this.daysLeft,
    required this.toBengali,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "পরিকল্পনা শুরু হতে বাকি",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: toBengali(daysLeft),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const TextSpan(
                        text: " দিন",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "প্রস্তুত থাকুন! নিচে দেখুন কী করতে হবে।",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Custom Clipper for curved bottom
// ─────────────────────────────────────────────────
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_HeaderClipper oldClipper) => false;
}

// ─────────────────────────────────────────────────
// Today Goal Card Widget
// ─────────────────────────────────────────────────
class _TodayGoalCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isPending;

  const _TodayGoalCard({required this.plan, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPending
              ? [const Color(0xFF94A3B8), const Color(0xFF64748B)]
              : [const Color(0xFFE8325A), const Color(0xFFBB1A48)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isPending ? const Color(0xFF94A3B8) : const Color(0xFFE8325A))
                .withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPending ? Icons.lock_clock : Icons.auto_awesome,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isPending ? "১ম দিনের লক্ষ্য (প্রিভিউ)" : "আজকের লক্ষ্য",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              plan["title"] ?? "লক্ষ্য",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// Task Section Widget
// ─────────────────────────────────────────────────
class _TaskSection extends StatelessWidget {
  final String userTask;
  final bool isPending;

  const _TaskSection({required this.userTask, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: const Color(0xFFE8325A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.check_box,
                color: Color(0xFFE8325A),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "আপনাকে যা করতে হবে:",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Task box with left red border
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE8325A).withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Text(
            userTask,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF333333),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────
// Completion Buttons Widget
// ─────────────────────────────────────────────────
class _CompletionButtons extends StatelessWidget {
  final bool isGoalStarted;
  final VoidCallback onYes;
  final VoidCallback onNo;

  const _CompletionButtons({
    required this.isGoalStarted,
    required this.onYes,
    required this.onNo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // হ্যাঁ বাটন
        Expanded(
          child: GestureDetector(
            onTap: isGoalStarted ? null : onYes,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isGoalStarted
                    ? const Color(0xFFEEEEEE)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isGoalStarted
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFFDDDDDD),
                  width: 1,
                ),
                boxShadow: isGoalStarted
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "হ্যাঁ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isGoalStarted
                          ? const Color(0xFFAAAAAA)
                          : const Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text("✅", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 14),

        // না বাটন
        Expanded(
          child: GestureDetector(
            onTap: onNo,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFDDDDDD),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "না",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF222222),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text("❌", style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
