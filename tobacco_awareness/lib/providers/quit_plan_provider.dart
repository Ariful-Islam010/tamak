import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../services/notification_service.dart';
import '../services/hive_helper.dart';
import '../services/backend_service.dart';
import '../utils/time_utils.dart';
import '../utils/fallback_constants.dart';

final quitPlanProvider = ChangeNotifierProvider<QuitPlanProvider>((ref) => QuitPlanProvider());

class QuitPlanProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isGoalStarted = false;
  bool _hasAnsweredToday = false;
  bool _isCompletedToday = false;
  List<dynamic> _dailyPlans = [];

  bool get isLoading => _isLoading;
  bool get isGoalStarted => _isGoalStarted;
  bool get hasAnsweredToday => _hasAnsweredToday;
  bool get isCompletedToday => _isCompletedToday;
  List<dynamic> get dailyPlans => _dailyPlans;

  QuitPlanProvider() {
    loadGoalStatus();
  }

  Future<void> loadGoalStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = BackendService.userId ?? 'guest';
      final today = TimeUtils.todayBstDateString;

      final planState = await HiveHelper().getQuitPlanState(userId);

      List<String> completedDates = [];
      String? lastAnsweredDate;
      bool lastAnsweredStatus = false;
      String? lastStartedDate;
      String? storedPlan;

      if (planState != null) {
        lastAnsweredDate = planState['last_answered_date'] as String?;
        final rawStatus = planState['last_answered_status'];
        if (rawStatus is bool) {
          lastAnsweredStatus = rawStatus;
        } else if (rawStatus is int) {
          lastAnsweredStatus = (rawStatus == 1);
        } else {
          lastAnsweredStatus = false;
        }
        lastStartedDate = planState['last_started_date'] as String?;
        storedPlan = planState['ai_plan'] as String?;

        final completedDatesJson = planState['completed_task_dates'] as String?;
        if (completedDatesJson != null) {
          try {
            completedDates = List<String>.from(jsonDecode(completedDatesJson));
          } catch (_) {}
        }
      }

      _hasAnsweredToday = (lastAnsweredDate == today);
      _isCompletedToday = _hasAnsweredToday && lastAnsweredStatus;
      _isGoalStarted = _isCompletedToday;

      // Reschedule reminders
      await NotificationService()
          .schedulePlanCompletionReminder(hasAnsweredToday: _hasAnsweredToday);
      await NotificationService()
          .scheduleViewPlanReminder(hasAnsweredToday: _hasAnsweredToday);

      // Try fetching fresh plan from backend in the background
      if (userId != 'guest' && BackendService.token != null) {
        try {
          final response = await http
              .get(
                Uri.parse('${BackendService.baseUrl}/api/profile'),
                headers: BackendService.headers(),
              )
              .timeout(const Duration(seconds: 10));
          if (response.statusCode == 200 && response.body != 'null') {
            final profileData = jsonDecode(response.body);
            if (profileData != null && profileData['ai_quit_plan'] != null) {
              final fetchedPlan = profileData['ai_quit_plan'];
              final String freshPlanJson = (fetchedPlan is String)
                  ? fetchedPlan
                  : jsonEncode(fetchedPlan);
              if (freshPlanJson != storedPlan) {
                storedPlan = freshPlanJson;
                await HiveHelper().saveQuitPlanState(
                  userId: userId,
                  aiPlanJson: freshPlanJson,
                  lastAnsweredDate: lastAnsweredDate,
                  lastAnsweredStatus: lastAnsweredStatus,
                  completedTaskDatesJson: jsonEncode(completedDates),
                  lastStartedDate: lastStartedDate,
                );
              }
            }
          }
        } catch (e) {
          debugPrint("Error fetching plan from backend: $e");
        }
      }

      if (storedPlan != null) {
        _dailyPlans = jsonDecode(storedPlan);
      } else {
        _dailyPlans = List.from(FallbackConstants.quitPlans);
      }
    } catch (e) {
      debugPrint("Error loading goal status: $e");
      _dailyPlans = List.from(FallbackConstants.quitPlans);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveAiPlan(String jsonPlan) async {
    try {
      _dailyPlans = jsonDecode(jsonPlan);
      notifyListeners();

      final userId = BackendService.userId ?? 'guest';
      final planState = await HiveHelper().getQuitPlanState(userId);

      List<String> completedDates = [];
      String? lastAnsweredDate;
      bool lastAnsweredStatus = false;
      String? lastStartedDate;

      if (planState != null) {
        lastAnsweredDate = planState['last_answered_date'] as String?;
        lastAnsweredStatus =
            (planState['last_answered_status'] as int? ?? 0) == 1;
        lastStartedDate = planState['last_started_date'] as String?;
        final completedDatesJson = planState['completed_task_dates'] as String?;
        if (completedDatesJson != null) {
          completedDates = List<String>.from(jsonDecode(completedDatesJson));
        }
      }

      await HiveHelper().saveQuitPlanState(
        userId: userId,
        aiPlanJson: jsonPlan,
        lastAnsweredDate: lastAnsweredDate,
        lastAnsweredStatus: lastAnsweredStatus,
        completedTaskDatesJson: jsonEncode(completedDates),
        lastStartedDate: lastStartedDate,
      );

      if (userId != 'guest' && BackendService.token != null) {
        try {
          await http
              .post(
                Uri.parse('${BackendService.baseUrl}/api/profile'),
                headers: BackendService.headers(),
                body: jsonEncode({
                  'id': userId,
                  'ai_quit_plan': jsonPlan,
                }),
              )
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint("Error saving AI plan to backend: $e");
        }
      }
    } catch (e) {
      debugPrint("Error saving AI plan: $e");
    }
  }

  Future<void> submitPlanResponse(bool completed) async {
    try {
      final userId = BackendService.userId ?? 'guest';
      final today = TimeUtils.todayBstDateString;

      final planState = await HiveHelper().getQuitPlanState(userId);
      List<String> completedDates = [];
      String? lastStartedDate;
      String? storedPlan;

      if (planState != null) {
        storedPlan = planState['ai_plan'] as String?;
        lastStartedDate = planState['last_started_date'] as String?;
        final completedDatesJson = planState['completed_task_dates'] as String?;
        if (completedDatesJson != null) {
          completedDates = List<String>.from(jsonDecode(completedDatesJson));
        }
      }

      if (completed) {
        if (!completedDates.contains(today)) {
          completedDates.add(today);
        }
        lastStartedDate = today;
        _isGoalStarted = true;
      } else {
        _isGoalStarted = false;
      }

      _hasAnsweredToday = true;
      _isCompletedToday = completed;

      await HiveHelper().saveQuitPlanState(
        userId: userId,
        aiPlanJson: storedPlan ?? jsonEncode(_dailyPlans),
        lastAnsweredDate: today,
        lastAnsweredStatus: completed,
        completedTaskDatesJson: jsonEncode(completedDates),
        lastStartedDate: lastStartedDate,
      );

      // Reschedule reminders
      await NotificationService()
          .schedulePlanCompletionReminder(hasAnsweredToday: true);
      await NotificationService()
          .scheduleViewPlanReminder(hasAnsweredToday: true);

      notifyListeners();
    } catch (e) {
      debugPrint("Error submitting plan response: $e");
    }
  }
}
