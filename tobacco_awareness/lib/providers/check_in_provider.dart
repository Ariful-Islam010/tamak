import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';

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
      
      if (_hasCheckedInToday) {
        _usedTobacco = prefs.getBool('check_in_used_tobacco_$userId');
        _cravingLevel = prefs.getDouble('check_in_craving_level_$userId') ?? 5.0;
        _selectedMood = prefs.getString('check_in_mood_$userId');
      } else {
        // Reset daily checkin state if not checked in today
        _usedTobacco = null;
        _cravingLevel = 5.0;
        _selectedMood = null;
      }

      // Notify listeners immediately so the UI loads from cache first
      _isLoading = false;
      notifyListeners();

      final quitDateStr = prefs.getString('user_quit_date_$userId');
      final quitDate = quitDateStr != null ? DateTime.tryParse(quitDateStr) : null;
      await NotificationService().scheduleEveningCheckIn(
        quitDate: quitDate,
        forceTomorrow: _hasCheckedInToday,
      );

      // If logged in, fetch from Supabase in background to verify/sync
      if (userId != 'guest') {
        try {
          final todayStr = DateTime.now().toIso8601String().split('T')[0];
          final response = await Supabase.instance.client
              .from('daily_checkins')
              .select('used_tobacco, craving_level, mood')
              .eq('user_id', userId)
              .eq('check_in_date', todayStr)
              .maybeSingle();

          if (response != null) {
            _hasCheckedInToday = true;
            _usedTobacco = response['used_tobacco'] as bool?;
            _cravingLevel = (response['craving_level'] as num?)?.toDouble() ?? 5.0;
            _selectedMood = response['mood'] as String?;

            // Update SharedPreferences cache
            await prefs.setString('last_check_in_date_$userId', todayStr);
            if (_usedTobacco != null) {
              await prefs.setBool('check_in_used_tobacco_$userId', _usedTobacco!);
            } else {
              await prefs.remove('check_in_used_tobacco_$userId');
            }
            await prefs.setDouble('check_in_craving_level_$userId', _cravingLevel);
            if (_selectedMood != null) {
              await prefs.setString('check_in_mood_$userId', _selectedMood!);
            } else {
              await prefs.remove('check_in_mood_$userId');
            }
            notifyListeners();
          }
        } catch (e) {
          debugPrint("Error syncing check-in from Supabase: $e");
        }
      }
    } catch (e) {
      debugPrint("Error loading check-in status: $e");
    }
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
      
      // Save locally first for speed
      await prefs.setString('last_check_in_date_$userId', today);
      if (_usedTobacco != null) {
        await prefs.setBool('check_in_used_tobacco_$userId', _usedTobacco!);
      }
      await prefs.setDouble('check_in_craving_level_$userId', _cravingLevel);
      if (_selectedMood != null) {
        await prefs.setString('check_in_mood_$userId', _selectedMood!);
      }
      
      _hasCheckedInToday = true;
      notifyListeners();

      final quitDateStr = prefs.getString('user_quit_date_$userId');
      final quitDate = quitDateStr != null ? DateTime.tryParse(quitDateStr) : null;
      await NotificationService().scheduleEveningCheckIn(
        quitDate: quitDate,
        forceTomorrow: true,
      );
      
      if (userId != 'guest') {
        try {
          await Supabase.instance.client.from('daily_checkins').insert({
            'user_id': userId,
            'check_in_date': today,
            'craving_level': _cravingLevel.toInt(),
            'mood': _selectedMood ?? 'Normal',
            'used_tobacco': _usedTobacco ?? false,
          });
        } catch (e) {
          debugPrint("Error syncing check-in to Supabase: $e");
        }
      }
    } catch (e) {
      debugPrint("Error saving check-in status: $e");
    }
  }

  void reset() async {
    _usedTobacco = null;
    _cravingLevel = 5.0;
    _selectedMood = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      await prefs.remove('last_check_in_date_$userId');
      await prefs.remove('check_in_used_tobacco_$userId');
      await prefs.remove('check_in_craving_level_$userId');
      await prefs.remove('check_in_mood_$userId');
    } catch (e) {
      debugPrint("Error resetting check-in cache: $e");
    }
    notifyListeners();
  }
}
