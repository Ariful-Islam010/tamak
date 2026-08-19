import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/badge_model.dart';
import 'backend_service.dart';
import 'hive_helper.dart';

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  /// Fetch stats from backend with Hive fallback and try-catch protection
  Future<GamificationStatsModel> fetchGamificationStats() async {
    final prefs = HiveHelper();
    final userId = BackendService.userId ?? 'guest';

    if (userId != 'guest' && BackendService.token != null) {
      try {
        final res = await http.get(
          Uri.parse('${BackendService.baseUrl}/api/gamification/stats'),
          headers: BackendService.headers(),
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final stats = GamificationStatsModel.fromJson(data);
          
          // Cache locally
          await prefs.saveSetting('cached_gamification_stats_$userId', jsonEncode(stats.toJson()));
          return stats;
        }
      } catch (e) {
        debugPrint("GamificationService.fetchGamificationStats error: $e");
      }
    }

    return await loadCachedStats();
  }

  /// Load cached stats from Hive
  Future<GamificationStatsModel> loadCachedStats() async {
    try {
      final prefs = HiveHelper();
      final userId = BackendService.userId ?? 'guest';
      final raw = await prefs.getSetting('cached_gamification_stats_$userId');

      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        return GamificationStatsModel.fromJson(data);
      }
    } catch (e) {
      debugPrint("GamificationService.loadCachedStats error: $e");
    }
    return GamificationStatsModel();
  }

  /// Save local gamification state to Hive and sync to backend
  Future<void> syncGamificationState(GamificationStatsModel stats) async {
    try {
      final prefs = HiveHelper();
      final userId = BackendService.userId ?? 'guest';

      await prefs.saveSetting('cached_gamification_stats_$userId', jsonEncode(stats.toJson()));

      if (userId != 'guest' && BackendService.token != null) {
        await http.post(
          Uri.parse('${BackendService.baseUrl}/api/gamification/sync'),
          headers: BackendService.headers(),
          body: jsonEncode(stats.toJson()),
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint("GamificationService.syncGamificationState error: $e");
    }
  }
}
