import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../utils/time_utils.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAllData();
    });
  }

  // ✅ OPTIMIZED: সব ৩টি API এখন একসাথে (Parallel) রান হয়, একে একে নয়
  Future<void> _refreshAllData() async {
    await Future.wait([
      ref.read(moneySaverProvider).loadSavingsData(),
      ref.read(checkInProvider).loadCheckInStatus(),
      ref.read(gamificationProvider).loadGamificationData(),
    ]);
  }

  String _toBengali(int number) {
    return number.toString()
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');
  }

  String _toBengaliOrdinal(int day) {
    if (day == 1) return "১ম";
    if (day == 2) return "২য়";
    if (day == 3) return "৩য়";
    if (day == 4) return "৪র্থ";
    if (day == 5) return "৫ম";
    if (day == 6) return "৬ষ্ঠ";
    return "${_toBengali(day)}ম";
  }

  String _getGreeting() {
    final hour = TimeUtils.nowBst.hour;
    if (hour < 12) return "সুপ্রভাত,";
    if (hour < 17) return "শুভ দুপুর,";
    if (hour < 20) return "শুভ সন্ধ্যা,";
    return "শুভ রাত্রি,";
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    final moneyProvider = ref.watch(moneySaverProvider);
    final userName = user?.displayName ?? "ব্যবহারকারী";

    int smokeFreeDays = 0;
    if (user?.quitDate != null) {
      final diff = TimeUtils.daysDifferenceBst(TimeUtils.nowBst, user!.quitDate!) + 1;
      if (diff >= 1) smokeFreeDays = diff;
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
                          user?.quitDate != null
                              ? "দারুণ! আপনি তামাকমুক্ত জীবনের ${_toBengaliOrdinal(TimeUtils.daysDifferenceBst(TimeUtils.nowBst, user!.quitDate!) + 1)} দিনে আছেন! 🌿"
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

                // Stats Row — ✅ OPTIMIZED: আলাদা StatelessWidget
                Row(
                  children: [
                    Expanded(
                      child: _DashboardStatCard(
                        title: "তামাকমুক্ত দিন",
                        value: _toBengali(smokeFreeDays),
                        icon: Icons.air,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DashboardStatCard(
                        title: "টাকা সেভ",
                        value: "৳${_toBengali(totalSaved)}",
                        icon: Icons.account_balance_wallet,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Features Grid — ✅ OPTIMIZED: আলাদা StatelessWidget
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
                    _DashboardGridItem(
                      title: "পরিকল্পনা",
                      icon: Icons.map,
                      color: AppTheme.primaryBlue,
                      destination: const QuitPlanScreen(),
                      onReturn: _refreshAllData,
                    ),
                    _DashboardGridItem(
                      title: "দৈনিক চেক-ইন",
                      icon: Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      destination: const DailyCheckInScreen(),
                      onReturn: _refreshAllData,
                    ),
                    _SosGridItem(onReturn: _refreshAllData),
                    _DashboardGridItem(
                      title: "টাকা সেভার",
                      icon: Icons.savings,
                      color: AppTheme.accentYellow,
                      destination: const MoneySaverScreen(),
                      onReturn: _refreshAllData,
                    ),
                    _DashboardGridItem(
                      title: "সহায়তা গ্রুপ",
                      icon: Icons.group,
                      color: Colors.purple,
                      destination: const PeerSupportScreen(),
                      onReturn: _refreshAllData,
                    ),
                    _DashboardGridItem(
                      title: "সচেতনতা",
                      icon: Icons.menu_book,
                      color: Colors.teal,
                      destination: const EducationInfoScreen(),
                      onReturn: _refreshAllData,
                    ),
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
}

// ✅ OPTIMIZED: আলাদা StatelessWidget — Stat Card
class _DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _DashboardStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
}

// ✅ OPTIMIZED: আলাদা StatelessWidget — Grid Item
class _DashboardGridItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget destination;
  final Future<void> Function() onReturn;

  const _DashboardGridItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.destination,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        await onReturn();
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

// ✅ OPTIMIZED: SOS বাটন আলাদা Widget
class _SosGridItem extends StatelessWidget {
  final Future<void> Function() onReturn;

  const _SosGridItem({required this.onReturn});

  @override
  Widget build(BuildContext context) {
    const color = AppTheme.errorColor;
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const SosEmergencyScreen()));
        await onReturn();
      },
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66F44336),
                  blurRadius: 12,
                  offset: Offset(0, 4),
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
}
