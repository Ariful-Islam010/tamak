import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckInProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _hasCheckedInToday = false;
  bool? _usedTobacco;
  double _cravingLevel = 5;
  String? _selectedMood;

  bool get isLoading => _isLoading;
  bool get hasCheckedInToday => _hasCheckedInToday;
  bool? get usedTobacco => _usedTobacco;
  double get cravingLevel => _cravingLevel;
  String? get selectedMood => _selectedMood;

  CheckInProvider() {
    loadCheckInStatus();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut) {
        loadCheckInStatus();
      }
    });
  }

  Future<void> loadCheckInStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final lastCheckIn = prefs.getString('last_check_in_date_$userId');
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      _hasCheckedInToday = (lastCheckIn == today);
      
      if (!_hasCheckedInToday) {
        // Reset daily checkin state if not checked in today
        _usedTobacco = null;
        _cravingLevel = 5;
        _selectedMood = null;
      }
    } catch (e) {
      debugPrint("Error loading check-in status: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  void setUsedTobacco(bool? value) {
    _usedTobacco = value;
    notifyListeners();
  }

  void setCravingLevel(double value) {
    _cravingLevel = value;
    notifyListeners();
  }

  void setSelectedMood(String? mood) {
    _selectedMood = mood;
    notifyListeners();
  }

  Future<void> submitCheckIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('last_check_in_date_$userId', today);
      
      if (userId != 'guest') {
        try {
          await Supabase.instance.client.from('daily_checkins').insert({
            'user_id': userId,
            'check_in_date': DateTime.now().toIso8601String(),
            'craving_level': _cravingLevel.toInt(),
            'mood': _selectedMood ?? 'Normal',
            'used_tobacco': _usedTobacco ?? false,
          });
        } catch (e) {
          debugPrint("Error syncing check-in to Supabase: $e");
        }
      }

      _hasCheckedInToday = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving check-in status: $e");
    }
  }

  void reset() {
    _usedTobacco = null;
    _cravingLevel = 5;
    _selectedMood = null;
    notifyListeners();
  }
}
