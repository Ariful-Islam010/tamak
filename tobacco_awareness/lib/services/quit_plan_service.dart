import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'backend_service.dart';
import 'hive_helper.dart';

class QuitPlanService {
  static final QuitPlanService _instance = QuitPlanService._internal();
  factory QuitPlanService() => _instance;
  QuitPlanService._internal();

  /// Submit quit plan response safely
  Future<bool> submitQuitPlanResponse(bool isAccepted) async {
    final userId = BackendService.userId ?? 'guest';
    final prefs = HiveHelper();

    try {
      await prefs.saveBool('quit_plan_accepted_$userId', isAccepted);

      if (userId != 'guest' && BackendService.token != null) {
        final res = await http.post(
          Uri.parse('${BackendService.baseUrl}/api/profile/quit-plan-response'),
          headers: BackendService.headers(),
          body: jsonEncode({
            'user_id': userId,
            'is_accepted': isAccepted,
          }),
        ).timeout(const Duration(seconds: 5));

        return res.statusCode == 200 || res.statusCode == 201;
      }
      return true;
    } catch (e) {
      debugPrint("QuitPlanService.submitQuitPlanResponse error: $e");
      return false;
    }
  }

  /// Sync task completion date
  Future<void> syncCompletedTaskDates(List<String> dates) async {
    final userId = BackendService.userId ?? 'guest';
    try {
      final prefs = HiveHelper();
      await prefs.saveSetting('completed_task_dates_$userId', jsonEncode(dates));

      if (userId != 'guest' && BackendService.token != null) {
        await http.post(
          Uri.parse('${BackendService.baseUrl}/api/profile/completed-tasks'),
          headers: BackendService.headers(),
          body: jsonEncode({
            'user_id': userId,
            'completed_dates': dates,
          }),
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint("QuitPlanService.syncCompletedTaskDates error: $e");
    }
  }
}
