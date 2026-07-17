import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicBadge {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final bool Function(GamificationProvider provider) unlockCondition;

  const DynamicBadge({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.unlockCondition,
  });
}

class GamificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  int _currentStreak = 0;
  int _longestStreak = 0;
  int _totalSmokeFreeDays = 0;
  int _totalCheckIns = 0;
  int _totalSavingsAmount = 0;
  int _planDuration = 7;
  int _sosCount = 0;
  int _messagesCount = 0;

  // Tree RPG states
  int _plantStage = 0; // 0 to 5
  bool _hasPestAttack = false;
  int _pestDaysClean = 0;
  int _completedTrees = 0;

  bool _isLoading = true;
  bool _hasPlan = false;
  int _completedTasksCount = 0;

  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  int get totalSmokeFreeDays => _totalSmokeFreeDays;
  int get totalCheckIns => _totalCheckIns;
  int get totalSavingsAmount => _totalSavingsAmount;
  int get planDuration => _planDuration;
  int get sosCount => _sosCount;
  int get messagesCount => _messagesCount;

  int get plantStage => _plantStage;
  bool get hasPestAttack => _hasPestAttack;
  int get pestDaysClean => _pestDaysClean;
  int get completedTrees => _completedTrees;

  bool get isLoading => _isLoading;
  bool get hasPlan => _hasPlan;
  int get completedTasksCount => _completedTasksCount;

  /// Dynamic list of badges
  List<DynamicBadge> get allBadges => [
        DynamicBadge(
          id: 'first_step',
          title: 'প্রথম কদম',
          icon: Icons.directions_walk,
          color: const Color(0xFF00A36C),
          description: 'প্রথম চেক-ইন সম্পন্ন করা',
          unlockCondition: (p) => p._totalCheckIns >= 1,
        ),
        DynamicBadge(
          id: '3_day_warrior',
          title: '৩ দিনের যোদ্ধা',
          icon: Icons.shield,
          color: const Color(0xFF00A36C),
          description: 'পরিকল্পনা অনুযায়ী ৩ দিনের টাস্ক সম্পন্ন করা',
          unlockCondition: (p) => p.hasPlan && p.completedTasksCount >= 3,
        ),
        DynamicBadge(
          id: 'plan_fresh',
          title: _planDuration == 7
              ? '১ সপ্তাহের মুক্ত বাতাস'
              : _planDuration == 14
                  ? '২ সপ্তাহের মুক্ত বাতাস'
                  : '১ মাসের মুক্ত বাতাস',
          icon: Icons.emoji_events,
          color: const Color(0xFFFBBF24),
          description: 'পরিকল্পনা অনুযায়ী $_planDuration দিনের টাস্ক সম্পন্ন করা',
          unlockCondition: (p) => p.hasPlan && p.completedTasksCount >= _planDuration,
        ),
        DynamicBadge(
          id: 'money_saver',
          title: 'টাকার খনি',
          icon: Icons.savings,
          color: const Color(0xFFF97316),
          description: 'টাকা সেভারে ৫০০ টাকা জমানো',
          unlockCondition: (p) => p._totalSavingsAmount >= 500,
        ),
        DynamicBadge(
          id: 'life_saver',
          title: 'লাইফ সেভার',
          icon: Icons.health_and_safety,
          color: const Color(0xFFEF4444),
          description: 'SOS ইমার্জেন্সি ৩ বার ব্যবহার করা',
          unlockCondition: (p) => p._sosCount >= 3,
        ),
        DynamicBadge(
          id: 'community_star',
          title: 'গ্রুপের প্রাণ',
          icon: Icons.forum,
          color: const Color(0xFF8B5CF6),
          description: 'সহায়তা গ্রুপে ১০টি মেসেজ পাঠানো',
          unlockCondition: (p) => p._messagesCount >= 10,
        ),
      ];

  List<DynamicBadge> get unlockedBadges =>
      allBadges.where((b) => b.unlockCondition(this)).toList();

  bool isBadgeUnlocked(DynamicBadge badge) => badge.unlockCondition(this);

  GamificationProvider() {
    loadGamificationData();
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut) {
        loadGamificationData();
      }
    });
  }

  Future<void> loadGamificationData() async {
    _isLoading = true;
    notifyListeners();

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _resetAll();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // 1. Fetch check-in data sorted by date ascending to build the tree state and streaks
      final checkInsData = await _supabase
          .from('daily_checkins')
          .select('check_in_date, used_tobacco')
          .eq('user_id', userId)
          .order('check_in_date', ascending: true);

      _totalCheckIns = checkInsData.length;

      // Calculate streaks and build Tree RPG State
      _calculateStreaksAndTree(checkInsData);

      // 2. Fetch total saved from money_savings table
      final savingsResponse = await _supabase
          .from('money_savings')
          .select('total_saved')
          .eq('user_id', userId)
          .maybeSingle();

      if (savingsResponse != null && savingsResponse['total_saved'] != null) {
        _totalSavingsAmount = (savingsResponse['total_saved'] as num).toInt();
      } else {
        _totalSavingsAmount = 0;
      }

      // 3. Fetch plan duration and quit_date from user profile
      final profileResponse = await _supabase
          .from('user_profiles')
          .select('plan_duration, quit_date')
          .eq('id', userId)
          .maybeSingle();

      if (profileResponse != null) {
        _planDuration = (profileResponse['plan_duration'] as num?)?.toInt() ?? 7;
        _hasPlan = profileResponse['quit_date'] != null;
      } else {
        _planDuration = 7;
        _hasPlan = false;
      }

      // Load task completions from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final completedDates = prefs.getStringList('completed_task_dates_$userId') ?? [];
      _completedTasksCount = completedDates.length;

      // 4. Fetch SOS logs count
      final sosResponse = await _supabase
          .from('sos_logs')
          .select('id')
          .eq('user_id', userId);
      _sosCount = sosResponse.length;

      // 5. Fetch message count from peer_support_messages
      final messagesResponse = await _supabase
          .from('peer_support_messages')
          .select('id')
          .eq('sender_id', userId);
      _messagesCount = messagesResponse.length;

      // 6. Sync current stats to gamification_data table
      await _syncToDatabase(userId);
    } catch (e) {
      debugPrint("Error loading gamification data: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  void _calculateStreaksAndTree(List<dynamic> checkInsData) {
    if (checkInsData.isEmpty) {
      _currentStreak = 0;
      _longestStreak = 0;
      _totalSmokeFreeDays = 0;
      _plantStage = 0;
      _hasPestAttack = false;
      _pestDaysClean = 0;
      _completedTrees = 0;
      return;
    }

    // Sort descending for current streak calculation
    List<DateTime> smokeFreeDates = [];
    int smokeFreeDays = 0;

    for (var checkIn in checkInsData) {
      final usedTobacco = checkIn['used_tobacco'] == true;
      if (!usedTobacco) {
        smokeFreeDays++;
        final dateStr = checkIn['check_in_date'].toString().split('T')[0];
        smokeFreeDates.add(DateTime.parse(dateStr));
      }
    }
    _totalSmokeFreeDays = smokeFreeDays;

    // Calculate streaks
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    smokeFreeDates.sort((a, b) => b.compareTo(a)); // Descending

    if (smokeFreeDates.isNotEmpty) {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final latestStr = smokeFreeDates[0].toIso8601String().split('T')[0];
      final daysDiff = DateTime.parse(todayStr).difference(DateTime.parse(latestStr)).inDays;

      if (daysDiff <= 1) {
        currentStreak = 1;
        for (int i = 1; i < smokeFreeDates.length; i++) {
          final diff = smokeFreeDates[i - 1].difference(smokeFreeDates[i]).inDays;
          if (diff == 1) {
            currentStreak++;
          } else {
            break;
          }
        }
      }
    }

    // Longest Streak
    if (smokeFreeDates.isNotEmpty) {
      tempStreak = 1;
      longestStreak = 1;
      // Need ascending order of smoke free dates to calculate longest streak
      final ascDates = List<DateTime>.from(smokeFreeDates).reversed.toList();
      for (int i = 1; i < ascDates.length; i++) {
        final diff = ascDates[i].difference(ascDates[i - 1]).inDays;
        if (diff == 1) {
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else {
          tempStreak = 1;
        }
      }
    }

    _currentStreak = currentStreak;
    _longestStreak = longestStreak;

    // 🌲 Build Tree RPG state from chronological check-in list (ascending)
    bool hasPestAttack = false;
    int pestDaysClean = 0;

    for (var checkIn in checkInsData) {
      final usedTobacco = checkIn['used_tobacco'] == true;

      if (!usedTobacco) {
        if (hasPestAttack) {
          pestDaysClean++;
          if (pestDaysClean >= 3) {
            hasPestAttack = false;
            pestDaysClean = 0;
          }
        }
      } else {
        // Smoked! Tree gets pest attack
        hasPestAttack = true;
        pestDaysClean = 0;
      }
    }

    // Tree grows strictly based on the progress towards the plan duration
    double progress = _planDuration > 0 ? (_totalSmokeFreeDays / _planDuration) : 0.0;
    int plantStage = 0;
    if (progress >= 1.0) {
      plantStage = 5;
    } else {
      plantStage = (progress * 5).floor();
    }

    _plantStage = plantStage;
    _hasPestAttack = hasPestAttack;
    _pestDaysClean = pestDaysClean;
    _completedTrees = 0;
  }

  Future<void> _syncToDatabase(String userId) async {
    try {
      // Sync to public.gamification_data
      await _supabase.from('gamification_data').upsert({
        'user_id': userId,
        'current_streak': _currentStreak,
        'longest_streak': _longestStreak,
        'badges': unlockedBadges.map((b) => b.id).toList(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Error syncing gamification data: $e");
    }
  }

  void _resetAll() {
    _currentStreak = 0;
    _longestStreak = 0;
    _totalSmokeFreeDays = 0;
    _totalCheckIns = 0;
    _totalSavingsAmount = 0;
    _planDuration = 7;
    _sosCount = 0;
    _messagesCount = 0;
    _plantStage = 0;
    _hasPestAttack = false;
    _pestDaysClean = 0;
    _completedTrees = 0;
    _hasPlan = false;
    _completedTasksCount = 0;
  }

  /// Convert number to Bengali numeral string
  String toBengaliNumeral(int number) {
    return number.toString()
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
}
