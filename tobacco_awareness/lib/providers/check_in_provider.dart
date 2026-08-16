import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/notification_service.dart';
import '../services/hive_helper.dart';
import '../services/backend_service.dart';
import '../services/sync_service.dart';
import '../utils/time_utils.dart';

final checkInProvider = ChangeNotifierProvider<CheckInProvider>((ref) => CheckInProvider());

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
  }

  Future<void> loadCheckInStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = BackendService.userId ?? 'guest';
      final today = TimeUtils.todayBstDateString;

      final cachedCheckIn = await HiveHelper().getCheckIn(userId, today);

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

      try {
        final quitDateStr =
            await HiveHelper().getSetting('user_quit_date_$userId');
        final quitDate =
            quitDateStr != null ? DateTime.tryParse(quitDateStr) : null;
        await NotificationService().scheduleEveningCheckIn(
          quitDate: quitDate,
          forceTomorrow: _hasCheckedInToday,
        );
      } catch (e) {
        debugPrint("Error scheduling evening check-in notification: $e");
      }

      // If logged in, fetch from backend in background to verify/sync
      if (userId != 'guest' && BackendService.token != null) {
        try {
          final response = await http
              .get(
                Uri.parse('${BackendService.baseUrl}/api/checkins/today'),
                headers: BackendService.headers(),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200 && response.body != 'null') {
            final data = jsonDecode(response.body);
            if (data != null) {
              _hasCheckedInToday = true;
              _usedTobacco = data['used_tobacco'] as bool?;
              _cravingLevel =
                  (data['craving_level'] as num?)?.toDouble() ?? 5.0;
              _selectedMood = data['mood'] as String?;

              // Update SQLite cache
              await HiveHelper().saveCheckIn(
                userId,
                today,
                _selectedMood ?? 'Normal',
                _cravingLevel,
                _usedTobacco ?? false,
              );
              notifyListeners();
            }
          }
        } catch (e) {
          debugPrint("Error syncing check-in from backend: $e");
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

  Future<void> submitCheckIn({String? note}) async {
    final userId = BackendService.userId ?? 'guest';
    final today = TimeUtils.todayBstDateString;

    if (userId != 'guest' && BackendService.token != null) {
      try {
        final response = await http
            .post(
              Uri.parse('${BackendService.baseUrl}/api/checkins'),
              headers: BackendService.headers(),
              body: jsonEncode({
                'user_id': userId,
                'check_in_date': today,
                'craving_level': _cravingLevel.toInt(),
                'mood': _selectedMood ?? 'Normal',
                'used_tobacco': _usedTobacco ?? false,
                'note': note,
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 401 || response.statusCode == 404) {
          debugPrint("Check-in failed with 401/404. User session invalid or deleted.");
          throw Exception("অ্যাকাউন্টটি আর সক্রিয় নেই। অনুগ্রহ করে আবার লগইন করুন।");
        } else if (response.statusCode != 200) {
          debugPrint("Check-in failed with status ${response.statusCode}: ${response.body}");
          await SyncService().queueCheckIn(
            userId: userId,
            checkInDate: today,
            cravingLevel: _cravingLevel.toInt(),
            mood: _selectedMood ?? 'Normal',
            usedTobacco: _usedTobacco ?? false,
            note: note,
          );
        }
      } on SocketException catch (_) {
        debugPrint("No internet. Queueing check-in for offline sync.");
        await SyncService().queueCheckIn(
          userId: userId,
          checkInDate: today,
          cravingLevel: _cravingLevel.toInt(),
          mood: _selectedMood ?? 'Normal',
          usedTobacco: _usedTobacco ?? false,
          note: note,
        );
      } on TimeoutException catch (_) {
        debugPrint("Connection timed out. Queueing check-in for offline sync.");
        await SyncService().queueCheckIn(
          userId: userId,
          checkInDate: today,
          cravingLevel: _cravingLevel.toInt(),
          mood: _selectedMood ?? 'Normal',
          usedTobacco: _usedTobacco ?? false,
          note: note,
        );
      } catch (e) {
        if (e is Exception && e.toString().contains("অ্যাকাউন্টটি আর সক্রিয় নেই")) {
          rethrow;
        }
        debugPrint("General error in submitCheckIn: $e. Queueing check-in for offline sync.");
        await SyncService().queueCheckIn(
          userId: userId,
          checkInDate: today,
          cravingLevel: _cravingLevel.toInt(),
          mood: _selectedMood ?? 'Normal',
          usedTobacco: _usedTobacco ?? false,
          note: note,
        );
      }
    }

    // Save locally to Hive after server confirmation (or for guest / queued)
    await HiveHelper().saveCheckIn(
      userId,
      today,
      _selectedMood ?? 'Normal',
      _cravingLevel,
      _usedTobacco ?? false,
    );

    _hasCheckedInToday = true;
    notifyListeners();

    try {
      final quitDateStr =
          await HiveHelper().getSetting('user_quit_date_$userId');
      final quitDate =
          quitDateStr != null ? DateTime.tryParse(quitDateStr) : null;
      await NotificationService().scheduleEveningCheckIn(
        quitDate: quitDate,
        forceTomorrow: true,
      );
    } catch (e) {
      debugPrint("Error scheduling notification after submitCheckIn: $e");
    }
  }

  void clearDraft() {
    if (!_hasCheckedInToday) {
      _usedTobacco = null;
      _cravingLevel = 5.0;
      _selectedMood = null;
      notifyListeners();
    }
  }
}
