import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/backend_service.dart';
import '../services/hive_helper.dart';
import '../services/money_saver_service.dart';
import '../utils/time_utils.dart';

final moneySaverProvider = ChangeNotifierProvider<MoneySaverProvider>((ref) => MoneySaverProvider());

class MoneySaverProvider extends ChangeNotifier {
  int _totalSavings = 0;
  List<Map<String, dynamic>> _dreams = [];
  bool _hasAddedMoneyToday = false;

  int get totalSavings => _totalSavings;
  List<Map<String, dynamic>> get dreams => _dreams;
  bool get hasAddedMoneyToday => _hasAddedMoneyToday;

  List<int> getAllocatedSavings() {
    List<int> allocations = List.filled(_dreams.length, 0);
    int remaining = _totalSavings;
    // Process from oldest to newest (reverse order of _dreams since index 0 is newest)
    for (int i = _dreams.length - 1; i >= 0; i--) {
      int target = _dreams[i]["target"] as int? ?? 0;
      int allocated = remaining >= target ? target : remaining;
      allocations[i] = allocated;
      remaining -= allocated;
    }
    return allocations;
  }

  bool get hasUnachievedDream {
    if (_dreams.isEmpty) return false;
    final allocations = getAllocatedSavings();
    for (int i = 0; i < _dreams.length; i++) {
      int target = _dreams[i]["target"] as int? ?? 0;
      if (allocations[i] < target) {
        return true;
      }
    }
    return false;
  }

  MoneySaverProvider() {
    loadSavingsData();
  }

  MoneySaverProvider.testable();

  void setTestData({
    required int totalSavings,
    required List<Map<String, dynamic>> dreams,
  }) {
    _totalSavings = totalSavings;
    _dreams = dreams;
  }

  Future<void> loadSavingsData() async {
    try {
      final prefs = HiveHelper();
      final userId = BackendService.userId ?? 'guest';

      _totalSavings = prefs.getInt('total_savings_$userId') ?? 0;

      final lastAddedDate = await prefs.getSetting('last_money_added_date_$userId');
      final today = TimeUtils.todayBstDateString;
      _hasAddedMoneyToday = (lastAddedDate == today);

      final dreamsStr = await prefs.getSetting('dreams_$userId');
      if (dreamsStr != null && dreamsStr.isNotEmpty) {
        final List<dynamic> decoded = json.decode(dreamsStr);
        _dreams = decoded.map((e) => {
          "title": e["title"]?.toString() ?? '',
          "icon": Icons.star,
          "target": (e["target"] as num?)?.toInt() ?? 0,
          "color": Color(e["color"] as int? ?? Colors.blue.toARGB32()),
        }).toList();
      } else {
        _dreams = [];
      }

      notifyListeners();

      // Fetch from MoneySaverService
      if (userId != 'guest' && BackendService.token != null) {
        final records = await MoneySaverService().fetchSavings();
        if (records.isNotEmpty) {
          int sum = records.fold(0, (prev, element) => prev + element.amount.toInt());
          _totalSavings = sum;
          await prefs.saveInt('total_savings_$userId', _totalSavings);
        }

        final goals = await MoneySaverService().fetchGoals();
        if (goals.isNotEmpty) {
          _dreams = goals.map((g) => {
            "title": g.title,
            "icon": Icons.star,
            "target": g.targetAmount > MoneySaverService.maxAmountLimit ? MoneySaverService.maxAmountLimit : g.targetAmount,
            "color": AppTheme.primaryBlue,
          }).toList();

          final dreamsEncoded = _dreams.map((e) => {
            "title": e["title"],
            "icon": (e["icon"] as IconData).codePoint,
            "target": e["target"],
            "color": (e["color"] as Color).toARGB32(),
          }).toList();
          await prefs.saveSetting('dreams_$userId', json.encode(dreamsEncoded));
        }
      }
    } catch (e) {
      debugPrint("Error loading savings data: $e");
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    try {
      final prefs = HiveHelper();
      final userId = BackendService.userId ?? 'guest';

      await prefs.saveInt('total_savings_$userId', _totalSavings);

      final dreamsEncoded = _dreams.map((e) => {
        "title": e["title"],
        "icon": (e["icon"] as IconData).codePoint,
        "target": e["target"],
        "color": (e["color"] as Color).toARGB32(),
      }).toList();
      await prefs.saveSetting('dreams_$userId', json.encode(dreamsEncoded));
    } catch (e) {
      debugPrint("Error saving data: $e");
    }
  }

  /// Add money with 10,000 TK limit check
  Future<bool> addMoney(int amount) async {
    if (_hasAddedMoneyToday) {
      return false;
    }
    // Cap amount at max 10,000 TK limit
    int safeAmount = amount > MoneySaverService.maxAmountLimit ? MoneySaverService.maxAmountLimit : amount;
    if (safeAmount > 0) {
      _totalSavings += safeAmount;

      final userId = BackendService.userId ?? 'guest';
      final today = TimeUtils.todayBstDateString;
      final prefs = HiveHelper();
      await prefs.saveSetting('last_money_added_date_$userId', today);
      _hasAddedMoneyToday = true;

      await MoneySaverService().addMoneySaved(safeAmount);

      await _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Add dream/goal with max 10,000 TK limit check
  Future<bool> addDream(String title, int targetAmount, Color color) async {
    if (hasUnachievedDream) {
      return false;
    }
    // Cap targetAmount at max 10,000 TK limit
    int safeTarget = targetAmount > MoneySaverService.maxAmountLimit ? MoneySaverService.maxAmountLimit : targetAmount;
    if (title.isNotEmpty && safeTarget > 0) {
      _dreams.insert(0, {
        "title": title,
        "icon": Icons.star,
        "target": safeTarget,
        "color": color,
      });

      await MoneySaverService().addGoal(title: title, targetAmount: safeTarget);

      await _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }
}
