import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/gamification_provider.dart';

class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  /// Helper to get the tree name/emoji by stage
  Map<String, String> _getTreeInfo(int stage, bool hasPest) {
    if (hasPest) {
      return {
        "emoji": "🌵",
        "title": "পোকা আক্রান্ত গাছ",
        "desc": "গাছটিতে পোকা ধরেছে! এটি সুস্থ করতে টানা ৩ দিন তামাকমুক্ত থাকুন।",
      };
    }
    switch (stage) {
      case 0:
        return {
          "emoji": "🫙",
          "title": "শূন্য মাটির পাত্র",
          "desc": "প্রথম অঙ্কুরোদগম শুরু করতে দৈনিক চেক-ইন সম্পন্ন করুন।",
        };
      case 1:
        return {
          "emoji": "🌱",
          "title": "বীজের অঙ্কুরোদগম",
          "desc": "অভিনন্দন! আপনার প্রথম চারাগাছটি মাটি ভেদ করে উঠেছে।",
        };
      case 2:
        return {
          "emoji": "🌿",
          "title": "ছোট চারা গাছ",
          "desc": "গাছটি ধীরে ধীরে বড় হচ্ছে। জল দিতে প্রতিদিন চেক-ইন করুন।",
        };
      case 3:
        return {
          "emoji": "🪴",
          "title": "পাতা মেলছে",
          "desc": "অনেক পাতা গজিয়েছে! সুস্থ ফুসফুসের মতো আপনার গাছও সতেজ হচ্ছে।",
        };
      case 4:
        return {
          "emoji": "🌳",
          "title": "তরুণ বৃক্ষ",
          "desc": "গাছটি এখন অনেক শক্তিশালী। পূর্ণাঙ্গ রূপ পেতে আর অল্প কিছুদিন বাকি!",
        };
      case 5:
      default:
        return {
          "emoji": "🌲",
          "title": "পূর্ণাঙ্গ বৃক্ষ!",
          "desc": "অসাধারণ! আপনি একটি সফল গাছ বড় করেছেন এবং আপনার বাগান সমৃদ্ধ করেছেন।",
        };
    }
  }

  Color _stageColor(int stage, bool hasPest) {
    if (hasPest) return AppTheme.errorColor;
    switch (stage) {
      case 0: return const Color(0xFF9CA3AF);
      case 1: return const Color(0xFF34D399);
      case 2: return const Color(0xFF10B981);
      case 3: return const Color(0xFF059669);
      case 4: return const Color(0xFF047857);
      default: return const Color(0xFF065F46);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gamification = ref.watch(gamificationProvider);

    if (gamification.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text("রিওয়ার্ডস ও এচিভমেন্ট"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final treeInfo = _getTreeInfo(gamification.plantStage, gamification.hasPestAttack);
    final stageColor = _stageColor(gamification.plantStage, gamification.hasPestAttack);

    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4),
      body: CustomScrollView(
        slivers: [
          // ── Colorful Header ──
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: const Color(0xFF065F46),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF0D9488)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "গার্ডেন ও রিওয়ার্ডস",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "আপনার অর্জন ও বৃক্ষের যত্ন নিন",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text("🌲", style: TextStyle(fontSize: 56)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // ── Stats Row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "স্ট্রিক",
                          "${gamification.toBengaliNumeral(gamification.currentStreak)} দিন",
                          Icons.local_fire_department,
                          const Color(0xFFEA580C),
                          const Color(0xFFFFF7ED),
                          const Color(0xFFFFEDD5),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          "পরিকল্পনা",
                          "${gamification.toBengaliNumeral(gamification.planDuration)} দিন",
                          Icons.assignment_turned_in,
                          const Color(0xFF7C3AED),
                          const Color(0xFFF5F3FF),
                          const Color(0xFFEDE9FE),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Virtual Tree Card ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          stageColor.withValues(alpha: 0.08),
                          stageColor.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: stageColor.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: stageColor.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Title
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: stageColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "আমার তামাকমুক্ত বৃক্ষ",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: stageColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: stageColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Tree Emoji with glow
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeInOut,
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  stageColor.withValues(alpha: 0.2),
                                  stageColor.withValues(alpha: 0.05),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: stageColor.withValues(alpha: 0.5),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: stageColor.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: AnimatedVirtualTree(
                              stage: gamification.plantStage,
                              hasPest: gamification.hasPestAttack,
                              stageColor: stageColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Text(
                            treeInfo["title"]!,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: stageColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            treeInfo["desc"]!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4B5563),
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: stageColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.water_drop, color: Colors.blue.shade400, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    gamification.hasPestAttack
                                        ? "পোকা সরাতে: ৩ দিনের মধ্যে ${gamification.toBengaliNumeral(gamification.pestDaysClean)} দিন সম্পন্ন"
                                        : "প্রতিদিন চেক-ইন = গাছে জল দেওয়া 💧",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF374151),
                                      fontWeight: FontWeight.w500,
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
                ),
                const SizedBox(height: 24),

                // ── Award Journey ──
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.emoji_events, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "অ্যাওয়ার্ড জার্নি",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  "আপনার অর্জিত ব্যাজ ও ট্রফি",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Badges Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          childAspectRatio: 0.78,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    bool isUnlocked,
    String description,
  ) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUnlocked ? "✅ $title - $description" : "🔒 $description"),
            duration: const Duration(seconds: 2),
            backgroundColor: isUnlocked ? color : Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.9),
                        color.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.shade200,
                        Colors.grey.shade100,
                      ],
                    ),
              shape: BoxShape.circle,
              border: Border.all(
                color: isUnlocked ? color : Colors.grey.shade300,
                width: 2.5,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Icon(
              icon,
              color: isUnlocked ? Colors.white : Colors.grey.shade400,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isUnlocked ? const Color(0xFF111827) : Colors.grey.shade400,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 2,
          ),
          if (isUnlocked)
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text("✓", style: TextStyle(fontSize: 10, color: Color(0xFF059669))),
            ),
        ],
      ),
    );
  }
}

class AnimatedVirtualTree extends StatefulWidget {
  final int stage;
  final bool hasPest;
  final Color stageColor;

  const AnimatedVirtualTree({
    super.key,
    required this.stage,
    required this.hasPest,
    required this.stageColor,
  });

  @override
  State<AnimatedVirtualTree> createState() => _AnimatedVirtualTreeState();
}

class _AnimatedVirtualTreeState extends State<AnimatedVirtualTree> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _swayAnimation;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _swayAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String emoji = "🌱";
    if (widget.hasPest) {
      emoji = "🌵"; 
    } else {
      switch (widget.stage) {
        case 0: emoji = "🪴"; break; 
        case 1: emoji = "🌱"; break; 
        case 2: emoji = "🌿"; break; 
        case 3: emoji = "🍀"; break; 
        case 4: emoji = "🌳"; break; 
        case 5:
        default: emoji = "🌲"; break; 
      }
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.stage >= 3 && !widget.hasPest)
              ...List.generate(5, (index) {
                final double delay = index * 0.2;
                final double angle = (index * 72) * 3.14159 / 180;
                final double radius = 55 + 10 * math.sin(_controller.value * 2 * 3.14159 + delay);
                return Transform.translate(
                  offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius - 10),
                  child: Opacity(
                    opacity: 0.6 + 0.4 * math.sin(_controller.value * 2 * 3.14159 + delay),
                    child: const Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: Colors.amber,
                    ),
                  ),
                );
              }),
            
            Transform.scale(
              scale: _breathAnimation.value,
              child: Transform.rotate(
                angle: _swayAnimation.value,
                origin: const Offset(0, 40), 
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 84),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
