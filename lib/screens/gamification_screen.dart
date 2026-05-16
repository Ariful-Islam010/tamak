import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GamificationScreen extends StatelessWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("রিওয়ার্ডস ও এচিভমেন্ট"),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Gradient Header (bKash Rewards style)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A11CB).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "আপনার লেভেল",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                          Text(
                            "Warrior (যোদ্ধা)",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: AppTheme.white,
                                  fontSize: 22,
                                ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "1250 XP",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Progress Bar
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.accentYellow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("বর্তমান লেভেল", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                      Text("পরবর্তী লেভেল: Champion", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),

            // Daily Missions (bKash Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text("আজকের মিশন", style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            _buildMissionCard(context, "দৈনিক চেক-ইন সম্পন্ন করুন", "10 XP", true),
            _buildMissionCard(context, "সহায়তা গ্রুপে একটি মেসেজ দিন", "20 XP", false),
            _buildMissionCard(context, "টানা ৩ দিন ধূমপানমুক্ত থাকুন", "50 XP", false),
            
            const SizedBox(height: 16),

            // Trophies / Badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Text("আপনার ব্যাজসমূহ", style: Theme.of(context).textTheme.titleLarge),
                ],
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _buildBadgeItem(context, "প্রথম পদক্ষেপ", Icons.directions_walk, AppTheme.primaryBlue, true),
                _buildBadgeItem(context, "৩ দিনের যোদ্ধা", Icons.shield, AppTheme.primaryGreen, true),
                _buildBadgeItem(context, "১ সপ্তাহ মুক্ত", Icons.emoji_events, AppTheme.accentYellow, false),
                _buildBadgeItem(context, "সাহায্যকারী", Icons.favorite, AppTheme.accentOrange, false),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context, String title, String reward, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.task_alt,
              color: isCompleted ? AppTheme.primaryGreen : AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        color: isCompleted ? AppTheme.textLight : AppTheme.textColor,
                      ),
                ),
                Text(
                  "পুরস্কার: $reward",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accentOrange,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          if (!isCompleted)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("ক্লেম"),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(BuildContext context, String title, IconData icon, Color color, bool isUnlocked) {
    return Column(
      children: [
        Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: isUnlocked ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: isUnlocked ? color : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isUnlocked ? color : Colors.grey,
            size: 36,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: isUnlocked ? AppTheme.textColor : AppTheme.textLight,
                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
              ),
          maxLines: 2,
        ),
      ],
    );
  }
}
