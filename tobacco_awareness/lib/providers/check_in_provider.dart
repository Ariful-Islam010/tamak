import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/database_helper.dart';

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
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final cachedCheckIn = await DatabaseHelper().getCheckIn(userId, today);
      
      if (cachedCheckIn != null) {
        _hasCheckedInToday = true;
        _usedTobacco = cachedCheckIn['used_tobacco'] as bool?;
        _cravingLevel = cachedCheckIn['craving_level'] as double? ?? 5.0;
        _selectedMood = cachedCheckIn['mood'] as String?;
      } else {
        _hasCheckedInToday = false;
        _usedTobacco = null;
        _cravingLevel = 5.0;
        _selectedMood = null;
      }

      // Notify listeners immediately so the UI loads from cache first
      _isLoading = false;
      notifyListeners();

      final quitDateStr = await DatabaseHelper().getSetting('user_quit_date_$userId');
      final quitDate = quitDateStr != null ? DateTime.tryParse(quitDateStr) : null;
      await NotificationService().scheduleEveningCheckIn(
        quitDate: quitDate,
        forceTomorrow: _hasCheckedInToday,
      );

      // If logged in, fetch from Supabase in background to verify/sync
      if (userId != 'guest') {
        try {
          final response = await Supabase.instance.client
              .from('daily_checkins')
              .select('used_tobacco, craving_level, mood')
              .eq('user_id', userId)
              .eq('check_in_date', today)
              .maybeSingle();

          if (response != null) {
            _hasCheckedInToday = true;
            _usedTobacco = response['used_tobacco'] as bool?;
            _cravingLevel = (response['craving_level'] as num?)?.toDouble() ?? 5.0;
            _selectedMood = response['mood'] as String?;

            // Update SQLite cache
            await DatabaseHelper().saveCheckIn(
              userId,
              today,
              _selectedMood ?? 'Normal',
              _cravingLevel,
              _usedTobacco ?? false,
            );
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
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      // Save locally to SQLite first for speed
      await DatabaseHelper().saveCheckIn(
        userId,
        today,
        _selectedMood ?? 'Normal',
        _cravingLevel,
        _usedTobacco ?? false,
      );
      
      _hasCheckedInToday = true;
      notifyListeners();

      final quitDateStr = await DatabaseHelper().getSetting('user_quit_date_$userId');
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
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      final db = await DatabaseHelper().database;
      await db.delete(
        'daily_checkins',
        where: 'user_id = ? AND check_in_date = ?',
        whereArgs: [userId, today],
      );
    } catch (e) {
      debugPrint("Error resetting check-in cache: $e");
    }
    notifyListeners();
  }
}
