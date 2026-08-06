import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../services/hive_helper.dart';
import '../services/backend_service.dart';
import '../utils/time_utils.dart';

final gamificationProvider = ChangeNotifierProvider<GamificationProvider>((ref) => GamificationProvider());

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
          description: 'পরিকল্পনা অনুযায়ী ৩ দিনের টাস্ক সম্পন্ন করা',
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
          description: 'পরিকল্পনা অনুযায়ী $_planDuration দিনের টাস্ক সম্পন্ন করা',
          unlockCondition: (p) =>
              p.hasPlan && p.completedTasksCount >= _planDuration,
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
          description: 'সহায়তা গ্রুপে ১০টি মেসেজ পাঠানো',
          unlockCondition: (p) => p._messagesCount >= 10,
        ),
      ];

  List<DynamicBadge> get unlockedBadges =>
      allBadges.where((b) => b.unlockCondition(this)).toList();

  bool isBadgeUnlocked(DynamicBadge badge) => badge.unlockCondition(this);

  GamificationProvider() {
    loadGamificationData();
  }

  Future<void> _loadFromDatabaseCache(String userId) async {
    try {
      if (Hive.isBoxOpen('daily_checkins')) {
        final box = Hive.box('daily_checkins');
        final String? userJson = box.get(userId);
        if (userJson != null) {
          try {
            final Map<String, dynamic> records = Map<String, dynamic>.from(jsonDecode(userJson));
            List<dynamic> localCheckIns = [];
            records.forEach((dateStr, val) {
              final data = Map<String, dynamic>.from(val);
              data['check_in_date'] = dateStr;
              localCheckIns.add(data);
            });
            if (localCheckIns.isNotEmpty) {
              _totalCheckIns = localCheckIns.length;
              _calculateStreaksAndTree(localCheckIns);
            }
          } catch (_) {}
        }
      }

      final cached = await HiveHelper().getGamification(userId);
      if (cached != null) {
        _currentStreak = cached['streak'] as int? ?? _currentStreak;

        final badgesJsonStr = cached['badges'] as String?;
        if (badgesJsonStr != null && badgesJsonStr.isNotEmpty) {
          final Map<String, dynamic> stats = jsonDecode(badgesJsonStr);
          _longestStreak = stats['longest_streak'] as int? ?? _longestStreak;
          _totalSmokeFreeDays = stats['total_smoke_free_days'] as int? ?? _totalSmokeFreeDays;
          if (stats['total_checkins'] != null && (stats['total_checkins'] as int) > _totalCheckIns) {
            _totalCheckIns = stats['total_checkins'] as int;
          }
          _totalSavingsAmount = stats['total_savings'] as int? ?? _totalSavingsAmount;
          _planDuration = stats['plan_duration'] as int? ?? _planDuration;
          _hasPlan = stats['has_plan'] as bool? ?? _hasPlan;
          _completedTasksCount = stats['completed_tasks'] as int? ?? _completedTasksCount;
          _sosCount = stats['sos_count'] as int? ?? _sosCount;
          _messagesCount = stats['messages_count'] as int? ?? _messagesCount;
          _plantStage = stats['plant_stage'] as int? ?? _plantStage;
          _hasPestAttack = stats['has_pest'] as bool? ?? _hasPestAttack;
          _pestDaysClean = stats['pest_days_clean'] as int? ?? _pestDaysClean;
          _completedTrees = stats['completed_trees'] as int? ?? _completedTrees;
        }
      }
    } catch (e) {
      debugPrint("Error loading gamification cache from SQLite: $e");
    }
  }

  Future<void> _saveToDatabaseCache(String userId) async {
    try {
      final Map<String, dynamic> stats = {
        'longest_streak': _longestStreak,
        'total_smoke_free_days': _totalSmokeFreeDays,
        'total_checkins': _totalCheckIns,
        'total_savings': _totalSavingsAmount,
        'plan_duration': _planDuration,
        'has_plan': _hasPlan,
        'completed_tasks': _completedTasksCount,
        'sos_count': _sosCount,
        'messages_count': _messagesCount,
        'plant_stage': _plantStage,
        'has_pest': _hasPestAttack,
        'pest_days_clean': _pestDaysClean,
        'completed_trees': _completedTrees,
      };

      await HiveHelper().saveGamification(
        userId,
        _currentStreak * 10, // points
        _currentStreak,
        null,
        jsonEncode(stats),
      );
    } catch (e) {
      debugPrint("Error saving gamification cache to SQLite: $e");
    }
  }

  Future<void> loadGamificationData() async {
    _isLoading = true;
    notifyListeners();

    final userId = BackendService.userId;
    final cachedUserId = userId ?? 'guest';

    // 1. Load cached values from SQLite immediately for fast startup
    await _loadFromDatabaseCache(cachedUserId);

    _isLoading = false;
    notifyListeners();

    if (userId == null || BackendService.token == null) {
      return;
    }

    // 2. Fetch fresh stats from backend in the background
    try {
      final statsRes = await http
          .get(
            Uri.parse('${BackendService.baseUrl}/api/gamification/stats'),
            headers: BackendService.headers(),
          )
          .timeout(const Duration(seconds: 15));

      if (statsRes.statusCode == 200) {
        final stats = jsonDecode(statsRes.body) as Map<String, dynamic>;

        final checkInsData =
            (stats['checkins'] as List<dynamic>?) ?? [];
        _totalCheckIns = checkInsData.length;
        _calculateStreaksAndTree(checkInsData);

        _totalSavingsAmount = (stats['total_savings'] as num?)?.toInt() ?? 0;
        _planDuration = (stats['plan_duration'] as num?)?.toInt() ?? 7;
        _hasPlan = stats['quit_date'] != null;
        _sosCount = (stats['sos_count'] as num?)?.toInt() ?? 0;
        _messagesCount = (stats['messages_count'] as num?)?.toInt() ?? 0;

        // Load task completions from SQLite
        final planState = await HiveHelper().getQuitPlanState(userId);
        if (planState != null && planState['completed_task_dates'] != null) {
          final List<dynamic> completedDates =
              jsonDecode(planState['completed_task_dates']);
          _completedTasksCount = completedDates.length;
        } else {
          _completedTasksCount = 0;
        }

        // Cache fresh data to SQLite
        await _saveToDatabaseCache(userId);

        // Sync progress to backend gamification_progress table
        String? lastCheckInDate;
        if (checkInsData.isNotEmpty) {
          lastCheckInDate = checkInsData.last['check_in_date']
              .toString()
              .split('T')[0];
        }
        await _syncToBackend(userId, lastCheckInDate: lastCheckInDate);
      }
    } catch (e) {
      debugPrint("Error loading gamification data: $e");
    }

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

    // Deduplicate smokeFreeDates by calendar date (YYYY-MM-DD)
    final Map<String, DateTime> uniqueMap = {};
    for (var checkIn in checkInsData) {
      final usedTobacco = checkIn['used_tobacco'] == true;
      if (!usedTobacco && checkIn['check_in_date'] != null) {
        final dateStr = checkIn['check_in_date'].toString().split('T')[0];
        final dt = DateTime.parse(dateStr);
        final key = TimeUtils.getBstDateString(dt);
        uniqueMap[key] = DateTime(dt.year, dt.month, dt.day);
      }
    }

    _totalSmokeFreeDays = uniqueMap.length;
    final smokeFreeDates = uniqueMap.values.toList()..sort((a, b) => b.compareTo(a)); // Descending

    // Calculate streaks
    int currentStreak = 0;
    int longestStreak = 0;

    if (smokeFreeDates.isNotEmpty) {
      final todayStr = TimeUtils.todayBstDateString;
      final todayDt = DateTime.parse(todayStr);
      final daysDiffFromToday = TimeUtils.daysDifferenceBst(todayDt, smokeFreeDates[0]);

      if (daysDiffFromToday <= 1) {
        currentStreak = 1;
        for (int i = 1; i < smokeFreeDates.length; i++) {
          final diff = TimeUtils.daysDifferenceBst(smokeFreeDates[i - 1], smokeFreeDates[i]);
          if (diff == 1) {
            currentStreak++;
          } else if (diff > 1) {
            break;
          }
        }
      }
    }

    // Longest Streak
    if (smokeFreeDates.isNotEmpty) {
      int tempStreak = 1;
      longestStreak = 1;
      final ascDates = smokeFreeDates.reversed.toList();
      for (int i = 1; i < ascDates.length; i++) {
        final diff = TimeUtils.daysDifferenceBst(ascDates[i], ascDates[i - 1]);
        if (diff == 1) {
          tempStreak++;
          if (tempStreak > longestStreak) {
            longestStreak = tempStreak;
          }
        } else if (diff > 1) {
          tempStreak = 1;
        }
      }
    }

    _currentStreak = currentStreak;
    _longestStreak = longestStreak;

    // Build Tree RPG state from chronological check-in list (ascending)
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
        hasPestAttack = true;
        pestDaysClean = 0;
      }
    }

    // Tree grows strictly based on progress towards plan duration
    double progress =
        _planDuration > 0 ? (_totalSmokeFreeDays / _planDuration) : 0.0;
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

  Future<void> _syncToBackend(String userId, {String? lastCheckInDate}) async {
    try {
      final Map<String, dynamic> dataToSync = {
        'user_id': userId,
        'current_streak': _currentStreak,
        'longest_streak': _longestStreak,
        'badges': unlockedBadges.map((b) => b.id).toList(),
        'updated_at': TimeUtils.nowBst.toIso8601String(),
      };
      if (lastCheckInDate != null) {
        dataToSync['last_check_in_date'] = lastCheckInDate;
      }
      await http
          .post(
            Uri.parse('${BackendService.baseUrl}/api/gamification'),
            headers: BackendService.headers(),
            body: jsonEncode(dataToSync),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Error syncing gamification data to backend: $e");
    }
  }

  /// Convert number to Bengali numeral string
  String toBengaliNumeral(int number) {
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
}
