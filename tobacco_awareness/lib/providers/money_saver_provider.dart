import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/backend_service.dart';
import '../utils/time_utils.dart';

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
      int target = _dreams[i]["target"];
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
      if (allocations[i] < _dreams[i]["target"]) {
        return true;
      }
    }
    return false;
  }

  MoneySaverProvider() {
    loadSavingsData();
  }

  Future<void> loadSavingsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = BackendService.userId ?? 'guest';

      _totalSavings = prefs.getInt('total_savings_$userId') ?? 0;

      final lastAddedDate = prefs.getString('last_money_added_date_$userId');
      final today = TimeUtils.todayBstDateString;
      _hasAddedMoneyToday = (lastAddedDate == today);

      final dreamsStr = prefs.getString('dreams_$userId');
      if (dreamsStr != null) {
        final List<dynamic> decoded = json.decode(dreamsStr);
        _dreams = decoded.map((e) => {
          "title": e["title"],
          "icon": Icons.star,
          "target": e["target"],
          "color": Color(e["color"]),
        }).toList();
      } else {
        _dreams = [];
      }

      // Notify listeners immediately with cached local data
      notifyListeners();

      // Sync from backend if online
      if (userId != 'guest' && BackendService.token != null) {
        try {
          // Select amount from savings_logs via backend
          final savingsRes = await http
              .get(
                Uri.parse('${BackendService.baseUrl}/api/savings'),
                headers: BackendService.headers(),
              )
              .timeout(const Duration(seconds: 10));

          if (savingsRes.statusCode == 200) {
            final List<dynamic> rows = jsonDecode(savingsRes.body);
            int sum = 0;
            for (var row in rows) {
              sum += (row['amount'] as num).toInt();
            }
            _totalSavings = sum;
            await prefs.setInt('total_savings_$userId', _totalSavings);
          }

          final goalsRes = await http
              .get(
                Uri.parse('${BackendService.baseUrl}/api/goals'),
                headers: BackendService.headers(),
              )
              .timeout(const Duration(seconds: 10));

          if (goalsRes.statusCode == 200) {
            final List<dynamic> goalsData = jsonDecode(goalsRes.body);
            if (goalsData.isNotEmpty) {
              _dreams = goalsData.map((e) => {
                "title": e["title"],
                "icon": Icons.star,
                "target": (e["target_amount"] as num).toInt(),
                "color": AppTheme.primaryBlue,
              }).toList();

              final dreamsEncoded = _dreams.map((e) => {
                "title": e["title"],
                "icon": (e["icon"] as IconData).codePoint,
                "target": e["target"],
                "color": (e["color"] as Color).toARGB32(),
              }).toList();
              await prefs.setString('dreams_$userId', json.encode(dreamsEncoded));
            }
          }
        } catch (e) {
          debugPrint("Error syncing savings data from backend: $e");
        }
      }
    } catch (e) {
      debugPrint("Error loading savings data: $e");
    }
    notifyListeners();
  }

  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = BackendService.userId ?? 'guest';

      await prefs.setInt('total_savings_$userId', _totalSavings);

      final dreamsEncoded = _dreams.map((e) => {
        "title": e["title"],
        "icon": (e["icon"] as IconData).codePoint,
        "target": e["target"],
        "color": (e["color"] as Color).toARGB32(),
      }).toList();
      await prefs.setString('dreams_$userId', json.encode(dreamsEncoded));
    } catch (e) {
      debugPrint("Error saving data: $e");
    }
  }

  Future<bool> addMoney(int amount) async {
    if (_hasAddedMoneyToday) {
      return false;
    }
    if (amount > 0) {
      _totalSavings += amount;

      final userId = BackendService.userId ?? 'guest';
      final today = TimeUtils.todayBstDateString;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_money_added_date_$userId', today);
      _hasAddedMoneyToday = true;

      if (userId != 'guest' && BackendService.token != null) {
        try {
          await http
              .post(
                Uri.parse('${BackendService.baseUrl}/api/savings'),
                headers: BackendService.headers(),
                body: jsonEncode({
                  'user_id': userId,
                  'amount': amount,
                }),
              )
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint("Error syncing savings to backend: $e");
        }
      }

      await _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> addDream(String title, int targetAmount, Color color) async {
    if (hasUnachievedDream) {
      return false;
    }
    if (title.isNotEmpty && targetAmount > 0) {
      _dreams.insert(0, {
        "title": title,
        "icon": Icons.star,
        "target": targetAmount,
        "color": color,
      });

      final userId = BackendService.userId ?? 'guest';
      if (userId != 'guest' && BackendService.token != null) {
        try {
          await http
              .post(
                Uri.parse('${BackendService.baseUrl}/api/goals'),
                headers: BackendService.headers(),
                body: jsonEncode({
                  'user_id': userId,
                  'title': title,
                  'target_amount': targetAmount,
                  'current_amount': 0,
                  'is_completed': false,
                  'icon_name': 'star',
                }),
              )
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint("Error syncing goal to backend: $e");
        }
      }

      await _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }
}
