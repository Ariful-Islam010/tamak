import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'quit_plan_screen.dart';
import 'daily_check_in_screen.dart';
import 'sos_emergency_screen.dart';
import 'money_saver_screen.dart';
import 'gamification_screen.dart';
import 'peer_support_screen.dart';
import 'profile_screen.dart';
import 'education_info_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final userName = user?.displayName ?? "ব্যবহারকারী";

    // Calculate smoke-free days based on quitDate
    int smokeFreeDays = 0;
    if (user?.quitDate != null) {
      final now = DateTime.now();
      final diff = now.difference(user!.quitDate!).inDays;
      if (diff >= 0) {
        smokeFreeDays = diff;
      }
    }

    // Example translation to Bengali numerals
    final String smokeFreeDaysStr = smokeFreeDays.toString().replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২').replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫').replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮').replaceAll('9', '৯');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "সুপ্রভাত,",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
                      ),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const GamificationScreen()));
                        },
                        icon: const Icon(Icons.stars, color: AppTheme.accentYellow, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryBlue.withOpacity(0.2),
                          backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                          child: user?.photoUrl == null ? const Icon(Icons.person, color: AppTheme.primaryBlue) : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Motivational Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlue, Color(0xFF5A92FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration, color: AppTheme.accentYellow),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "আজ তুমি অসাধারণ করছো!",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(context, "ধূমপানমুক্ত দিন", smokeFreeDaysStr, Icons.calendar_month, AppTheme.primaryGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(context, "টাকা সেভ", "৳০", Icons.account_balance_wallet, AppTheme.primaryBlue),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Features Grid (bKash Style)
              Text("সার্ভিস সমূহ", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildGridItem(context, "পরিকল্পনা", Icons.map, AppTheme.primaryBlue, const QuitPlanScreen()),
                  _buildGridItem(context, "দৈনিক চেক-ইন", Icons.check_circle, AppTheme.primaryGreen, const DailyCheckInScreen()),
                  _buildGridItem(context, "এস.ও.এস", Icons.warning_rounded, AppTheme.errorColor, const SosEmergencyScreen(), isSos: true),
                  _buildGridItem(context, "টাকা সেভার", Icons.savings, AppTheme.accentYellow, const MoneySaverScreen()),
                  _buildGridItem(context, "সহায়তা গ্রুপ", Icons.group, Colors.purple, const PeerSupportScreen()),
                  _buildGridItem(context, "সচেতনতা", Icons.menu_book, Colors.teal, const EducationInfoScreen()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: color,
                  fontSize: 28,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, Color color, Widget destination, {bool isSos = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      },
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: isSos ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSos
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Icon(icon, color: isSos ? AppTheme.white : color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
