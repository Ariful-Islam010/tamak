import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/money_saver_provider.dart';
import '../providers/check_in_provider.dart';
import '../providers/gamification_provider.dart';
import 'quit_plan_screen.dart';
import 'daily_check_in_screen.dart';
import 'sos_emergency_screen.dart';
import 'money_saver_screen.dart';
import 'gamification_screen.dart';
import 'peer_support_screen.dart';
import 'profile_screen.dart';
import 'education_info_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  Future<void> _refreshAllData() async {
    context.read<MoneySaverProvider>().loadSavingsData();
    context.read<CheckInProvider>().loadCheckInStatus();
    context.read<GamificationProvider>().loadGamificationData();
  }

  String _toBengali(int number) {
    return number.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "সুপ্রভাত, ☀️";
    if (hour < 17) return "শুভ দুপুর, 🌤️";
    if (hour < 20) return "শুভ সন্ধ্যা, 🌇";
    return "শুভ রাত্রি, 🌙";
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;
    final moneyProvider = context.watch<MoneySaverProvider>();
    final gamification = context.watch<GamificationProvider>();
    final userName = user?.displayName ?? "ব্যবহারকারী";

    int smokeFreeDays = 0;
    if (user?.quitDate != null) {
      final diff = DateTime.now().difference(user!.quitDate!).inDays;
      if (diff >= 0) smokeFreeDays = diff;
    }

    final int totalSaved = moneyProvider.totalSavings;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.demonDark,
              AppTheme.backgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.25, 0.45],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshAllData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 24, 
                                      color: Colors.white, 
                                      fontWeight: FontWeight.w900,
                                    ),
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.flash_on_rounded, color: AppTheme.accentYellow, size: 24),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen())),
                            icon: const Icon(Icons.stars_rounded, color: AppTheme.accentYellow, size: 30),
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.demonMid,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: AppTheme.accentYellow, width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.accentPink, width: 2.5),
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                                child: user?.photoUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                              ),
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
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: gamification.currentStreak > 0 ? AppTheme.fireGradient : AppTheme.pinkGradient,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: AppTheme.glowShadow(AppTheme.accentOrange),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            gamification.currentStreak > 0
                                ? "দারুণ! ${_toBengali(gamification.currentStreak)} দিন ধরে ডেমনকে পরাস্ত করে তামাকমুক্ত আছেন! 🔥👾"
                                : "আজই হোক তামাকমুক্ত জীবনের প্রথম দিন! ডেমনকে হারাতে প্রস্তুত হোন! ⚔️👾",
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 16,
                              height: 1.4,
                            ),
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
                        child: _buildStatCard(
                          context, 
                          "তামাকমুক্ত দিন", 
                          _toBengali(smokeFreeDays), 
                          Icons.air_rounded, 
                          AppTheme.accentLime,
                          AppTheme.greenGradient,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context, 
                          "টাকা সেভ", 
                          "৳${_toBengali(totalSaved)}", 
                          Icons.savings_rounded, 
                          AppTheme.accentYellow,
                          AppTheme.fireGradient,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Features Grid
                  const Text(
                    "সার্ভিস সমূহ 🛠️", 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    childAspectRatio: 0.82,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildGridItem(context, "পরিকল্পনা", Icons.map_rounded, AppTheme.accentCyan, AppTheme.cyanGradient, const QuitPlanScreen()),
                      _buildGridItem(context, "দৈনিক চেক-ইন", Icons.check_circle_rounded, AppTheme.accentLime, AppTheme.greenGradient, const DailyCheckInScreen()),
                      _buildSosGridItem(context),
                      _buildGridItem(context, "টাকা সেভার", Icons.monetization_on_rounded, AppTheme.accentYellow, AppTheme.fireGradient, const MoneySaverScreen()),
                      _buildGridItem(context, "সহায়তা গ্রুপ", Icons.forum_rounded, AppTheme.accentPink, AppTheme.pinkGradient, const PeerSupportScreen()),
                      _buildGridItem(context, "সচেতনতা", Icons.auto_stories_rounded, AppTheme.primaryPurple, AppTheme.cardGradient, const EducationInfoScreen()),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color accentColor, LinearGradient gradient) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.demonMid.withValues(alpha: 0.1), width: 3),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textColor, 
              fontSize: 26, 
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textLight, 
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSosGridItem(BuildContext context) {
    const color = AppTheme.errorColor;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SosEmergencyScreen()));
        if (mounted) _refreshAllData();
      },
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.warning_rounded, color: AppTheme.white, size: 36),
          ),
          const SizedBox(height: 8),
          const Text(
            "এস.ও.এস",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 13,
              color: AppTheme.textColor,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, Color color, LinearGradient gradient, Widget destination) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        if (mounted) _refreshAllData();
      },
      child: Column(
        children: [
          Container(
            height: 68,
            width: 68,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900, 
              fontSize: 13,
              color: AppTheme.textColor,
            ),
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
