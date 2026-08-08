import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveHelper {
  static final HiveHelper _instance = HiveHelper._internal();
  factory HiveHelper() => _instance;
  HiveHelper._internal();

  // Box names
  static const String _settingsBox = 'app_settings';
  static const String _chatBox = 'chat_messages';
  static const String _checkInBox = 'daily_checkins';
  static const String _gamificationBox = 'gamification_progress';
  static const String _quitPlanBox = 'ai_quit_plans';

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_chatBox);
    await Hive.openBox(_checkInBox);
    await Hive.openBox(_gamificationBox);
    await Hive.openBox(_quitPlanBox);
    _isInitialized = true;
    debugPrint('🎉 Hive boxes opened successfully');
  }

  // ─── CHAT MESSAGES HELPERS ───
  Future<void> saveChatMessages(String userId, List<Map<String, dynamic>> messages) async {
    final box = Hive.box(_chatBox);
    final String jsonStr = jsonEncode(messages);
    await box.put(userId, jsonStr);
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String userId) async {
    final box = Hive.box(_chatBox);
    final String? jsonStr = box.get(userId);
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ─── DAILY CHECK-INS HELPERS ───
  Future<void> saveCheckIn(String userId, String date, String mood, double craving, bool usedTobacco) async {
    final box = Hive.box(_checkInBox);
    
    // Structure: userId -> { date1: data, date2: data }
    final String? userJson = box.get(userId);
    Map<String, dynamic> userRecords = {};
    if (userJson != null) {
      try {
        userRecords = Map<String, dynamic>.from(jsonDecode(userJson));
      } catch (_) {}
    }
    
    userRecords[date] = {
      'mood': mood,
      'craving_level': craving,
      'used_tobacco': usedTobacco,
    };
    
    await box.put(userId, jsonEncode(userRecords));
  }

  Future<Map<String, dynamic>?> getCheckIn(String userId, String date) async {
    final box = Hive.box(_checkInBox);
    final String? userJson = box.get(userId);
    if (userJson == null) return null;
    
    try {
      final Map<String, dynamic> userRecords = Map<String, dynamic>.from(jsonDecode(userJson));
      if (userRecords.containsKey(date)) {
        return Map<String, dynamic>.from(userRecords[date]);
      }
    } catch (_) {}
    return null;
  }

  // ─── GAMIFICATION HELPERS ───
  Future<void> saveGamification(String userId, int points, int streak, String? quitDate, String badgesJson) async {
    final box = Hive.box(_gamificationBox);
    final data = {
      'points': points,
      'streak': streak,
      'quit_date': quitDate,
      'badges': badgesJson,
    };
    await box.put(userId, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getGamification(String userId) async {
    final box = Hive.box(_gamificationBox);
    final String? jsonStr = box.get(userId);
    if (jsonStr == null) return null;
    
    try {
      return Map<String, dynamic>.from(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  // ─── AI QUIT PLANS HELPERS ───
  Future<void> saveQuitPlanState({
    required String userId,
    required String aiPlanJson,
    required String? lastAnsweredDate,
    required bool lastAnsweredStatus,
    required String completedTaskDatesJson,
    required String? lastStartedDate,
  }) async {
    final box = Hive.box(_quitPlanBox);
    final data = {
      'ai_plan': aiPlanJson,
      'last_answered_date': lastAnsweredDate,
      'last_answered_status': lastAnsweredStatus ? 1 : 0, // Keep 1/0 for backwards compatibility if needed, or just bool. Hive supports bool natively, let's use bool.
      'completed_task_dates': completedTaskDatesJson,
      'last_started_date': lastStartedDate,
    };
    // Fix: the boolean was stored as 1/0 in SQLite, let's just store as bool in Hive.
    data['last_answered_status'] = lastAnsweredStatus;
    
    await box.put(userId, jsonEncode(data));
  }

  Future<Map<String, dynamic>?> getQuitPlanState(String userId) async {
    final box = Hive.box(_quitPlanBox);
    final String? jsonStr = box.get(userId);
    if (jsonStr == null) return null;
    
    try {
      final map = Map<String, dynamic>.from(jsonDecode(jsonStr));
      // In SQLite it was 1 or 0, here it's already a bool if we save it as bool, but let's handle if it comes back differently just in case
      return map;
    } catch (_) {
      return null;
    }
  }

  // ─── APP SETTINGS HELPERS (SharedPreferences Replacement) ───
  Future<void> saveSetting(String key, String value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  Future<String?> getSetting(String key) async {
    final box = Hive.box(_settingsBox);
    return box.get(key) as String?;
  }

  Future<void> removeSetting(String key) async {
    final box = Hive.box(_settingsBox);
    await box.delete(key);
  }

  // Helper for boolean settings
  Future<void> saveBool(String key, bool value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  bool? getBool(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key) as bool?;
  }
  
  // Helper for int settings
  Future<void> saveInt(String key, int value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  int? getInt(String key) {
    final box = Hive.box(_settingsBox);
    return box.get(key) as int?;
  }

  // ─── DELETED CHAT MESSAGES HELPERS ───
  Future<void> saveDeletedMessageIds(Set<String> ids) async {
    await saveSetting('deleted_chat_message_ids', jsonEncode(ids.toList()));
  }

  Future<Set<String>> getDeletedMessageIds() async {
    final raw = await getSetting('deleted_chat_message_ids');
    if (raw == null || raw.isEmpty) return {};
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }

  // ─── BLOCKED USER HELPERS ───
  Future<void> saveBlockedUserIds(Set<String> userIds) async {
    await saveSetting('blocked_user_ids', jsonEncode(userIds.toList()));
  }

  Future<Set<String>> getBlockedUserIds() async {
    final raw = await getSetting('blocked_user_ids');
    if (raw == null || raw.isEmpty) return {};
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => e.toString()).toSet();
    } catch (_) {
      return {};
    }
  }
}
