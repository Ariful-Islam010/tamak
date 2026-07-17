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
    if (hour < 12) return "সুপ্রভাত,";
    if (hour < 17) return "শুভ দুপুর,";
    if (hour < 20) return "শুভ সন্ধ্যা,";
    return "শুভ রাত্রি,";
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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAllData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
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
                          Text(_getGreeting(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
                          Row(
                            children: [
                              Flexible(
                                child: Text(userName,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, color: AppTheme.primaryGreen),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.eco, color: AppTheme.primaryGreen, size: 20),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen())),
                          icon: const Icon(Icons.stars, color: AppTheme.accentYellow, size: 28),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.cardBackgroundColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.2),
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
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00C6A7), AppTheme.primaryGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.eco, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          gamification.currentStreak > 0
                              ? "দারুণ! ${_toBengali(gamification.currentStreak)} দিন ধরে তামাকমুক্ত! 🌿"
                              : "আজই হোক তামাকমুক্ত জীবনের প্রথম দিন! 🌿",
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.white, fontWeight: FontWeight.bold, height: 1.4,
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
                    Expanded(child: _buildStatCard(context, "তামাকমুক্ত দিন", _toBengali(smokeFreeDays), Icons.air, AppTheme.primaryGreen)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(context, "টাকা সেভ", "৳${_toBengali(totalSaved)}", Icons.account_balance_wallet, AppTheme.primaryBlue)),
                  ],
                ),
                const SizedBox(height: 32),

                // Features Grid
                Text("সার্ভিস সমূহ", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildGridItem(context, "পরিকল্পনা", Icons.map, AppTheme.primaryBlue, const QuitPlanScreen()),
                    _buildGridItem(context, "দৈনিক চেক-ইন", Icons.check_circle, AppTheme.primaryGreen, const DailyCheckInScreen()),
                    _buildSosGridItem(context),
                    _buildGridItem(context, "টাকা সেভার", Icons.savings, AppTheme.accentYellow, const MoneySaverScreen()),
                    _buildGridItem(context, "সহায়তা গ্রুপ", Icons.group, Colors.purple, const PeerSupportScreen()),
                    _buildGridItem(context, "সচেতনতা", Icons.menu_book, Colors.teal, const EducationInfoScreen()),
                  ],
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color, fontSize: 28)),
          const SizedBox(height: 4),
          Text(title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textLight)),
        ],
      ),
    );
  }

  // Original-style SOS grid item (same as before)
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
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.warning_rounded, color: AppTheme.white, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            "এস.ও.এস",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, IconData icon, Color color, Widget destination) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        if (mounted) _refreshAllData();
      },
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 12),
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
