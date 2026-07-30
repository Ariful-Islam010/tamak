import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';

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
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut) {
        loadSavingsData();
      }
    });
  }

  Future<void> loadSavingsData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      
      _totalSavings = prefs.getInt('total_savings_$userId') ?? 0;
      
      final lastAddedDate = prefs.getString('last_money_added_date_$userId');
      final today = DateTime.now().toIso8601String().split('T')[0];
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

      // Sync from Supabase if online
      if (userId != 'guest') {
        try {
          // Select amount from savings_logs table
          final response = await Supabase.instance.client
              .from('savings_logs')
              .select('amount')
              .eq('user_id', userId);
              
          int sum = 0;
          for (var row in response) {
            sum += (row['amount'] as num).toInt();
          }
          _totalSavings = sum;
          await prefs.setInt('total_savings_$userId', _totalSavings);

          final goalsData = await Supabase.instance.client
              .from('money_saver_goals')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false);
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
        } catch (e) {
          debugPrint("Error syncing savings data from Supabase: $e");
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
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      
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
      
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_money_added_date_$userId', today);
      _hasAddedMoneyToday = true;

      if (userId != 'guest') {
        try {
          // Insert a new log entry to savings_logs table
          await Supabase.instance.client.from('savings_logs').insert({
            'user_id': userId,
            'amount': amount,
          });
        } catch (e) {
          debugPrint("Error syncing savings to Supabase: $e");
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

      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      if (userId != 'guest') {
        try {
          await Supabase.instance.client.from('money_saver_goals').insert({
            'user_id': userId,
            'title': title,
            'target_amount': targetAmount,
            'current_amount': 0,
            'is_completed': false,
            'icon_name': 'star',
          });
        } catch (e) {
          debugPrint("Error syncing goal to Supabase: $e");
        }
      }

      await _saveData();
      notifyListeners();
      return true;
    }
    return false;
  }
}
