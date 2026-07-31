import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tamak_local.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Create chat_messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        is_me INTEGER,
        sender TEXT,
        sender_photo TEXT,
        is_counselor INTEGER,
        text TEXT,
        image_url TEXT,
        time TEXT,
        user_id TEXT
      )
    ''');

    // 2. Create daily_checkins table
    await db.execute('''
      CREATE TABLE daily_checkins (
        user_id TEXT,
        check_in_date TEXT,
        mood TEXT,
        craving_level REAL,
        used_tobacco INTEGER,
        PRIMARY KEY (user_id, check_in_date)
      )
    ''');

    // 3. Create gamification_progress table
    await db.execute('''
      CREATE TABLE gamification_progress (
        user_id TEXT PRIMARY KEY,
        points INTEGER,
        streak INTEGER,
        quit_date TEXT,
        badges TEXT
      )
    ''');

    // 4. Create ai_quit_plans table
    await db.execute('''
      CREATE TABLE ai_quit_plans (
        user_id TEXT PRIMARY KEY,
        ai_plan TEXT,
        last_answered_date TEXT,
        last_answered_status INTEGER,
        completed_task_dates TEXT,
        last_started_date TEXT
      )
    ''');

    // 5. Create app_settings table
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    
    debugPrint('🎉 SQLite tables created successfully');
  }

  // ─── CHAT MESSAGES HELPERS ───
  Future<void> saveChatMessages(String userId, List<Map<String, dynamic>> messages) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete old cached messages for this user first
      await txn.delete('chat_messages', where: 'user_id = ?', whereArgs: [userId]);
      for (var msg in messages) {
        await txn.insert('chat_messages', {
          'id': msg['id']?.toString() ?? UniqueKey().toString(),
          'is_me': (msg['isMe'] == true) ? 1 : 0,
          'sender': msg['sender'],
          'sender_photo': msg['senderPhoto'],
          'is_counselor': (msg['isCounselor'] == true) ? 1 : 0,
          'text': msg['text'],
          'image_url': msg['imageUrl'],
          'time': msg['time'],
          'user_id': userId,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_messages',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return maps.map((map) {
      return {
        'id': map['id'],
        'isMe': map['is_me'] == 1,
        'sender': map['sender'],
        'senderPhoto': map['sender_photo'],
        'isCounselor': map['is_counselor'] == 1,
        'text': map['text'],
        'imageUrl': map['image_url'],
        'time': map['time'],
      };
    }).toList();
  }

  // ─── DAILY CHECK-INS HELPERS ───
  Future<void> saveCheckIn(String userId, String date, String mood, double craving, bool usedTobacco) async {
    final db = await database;
    await db.insert('daily_checkins', {
      'user_id': userId,
      'check_in_date': date,
      'mood': mood,
      'craving_level': craving,
      'used_tobacco': usedTobacco ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getCheckIn(String userId, String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_checkins',
      where: 'user_id = ? AND check_in_date = ?',
      whereArgs: [userId, date],
    );
    if (maps.isEmpty) return null;
    final map = maps.first;
    return {
      'mood': map['mood'],
      'craving_level': map['craving_level'],
      'used_tobacco': map['used_tobacco'] == 1,
    };
  }

  // ─── GAMIFICATION HELPERS ───
  Future<void> saveGamification(String userId, int points, int streak, String? quitDate, String badgesJson) async {
    final db = await database;
    await db.insert('gamification_progress', {
      'user_id': userId,
      'points': points,
      'streak': streak,
      'quit_date': quitDate,
      'badges': badgesJson,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getGamification(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'gamification_progress',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;
    return maps.first;
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
    final db = await database;
    await db.insert('ai_quit_plans', {
      'user_id': userId,
      'ai_plan': aiPlanJson,
      'last_answered_date': lastAnsweredDate,
      'last_answered_status': lastAnsweredStatus ? 1 : 0,
      'completed_task_dates': completedTaskDatesJson,
      'last_started_date': lastStartedDate,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, dynamic>?> getQuitPlanState(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ai_quit_plans',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  // ─── APP SETTINGS HELPERS ───
  Future<void> saveSetting(String key, String value) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> removeSetting(String key) async {
    final db = await database;
    await db.delete(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
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
}
