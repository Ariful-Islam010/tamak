import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import '../services/database_helper.dart';

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
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut) {
        loadGoalStatus();
      }
    });
  }

  static const List<Map<String, String>> _fallbackPlans = [
    {
      "title": "মানসিক চাপ নিয়ন্ত্রণ",
      "desc": "আপনার প্রোফাইলের তথ্য অনুযায়ী, আজ আপনার মূল ফোকাস হবে স্ট্রেস বা মানসিক চাপ কমানো। যখনই ধূমপান করতে ইচ্ছা করবে, লম্বা শ্বাস নিন এবং অন্য কাজে মনোযোগ দিন।",
      "user_task": "যখনই ধূমপান করার ইচ্ছা হবে, তখন এক গ্লাস পানি পান করুন এবং ১০ বার লম্বা করে শ্বাস নিন।",
      "ai_task": "আমি আপনার জন্য ৫ মিনিটের একটি মানসিক শান্তির অডিও গাইড সাজিয়েছি।"
    },
    {
      "title": "ট্রিগার এড়িয়ে চলা",
      "desc": "আজকের লক্ষ্য হলো আপনার ধূমপানের ট্রিগারগুলো চিহ্নিত করা এবং সেগুলো এড়িয়ে চলা। চা বা কফির বদলে আজ পানি বা ফলের রস পান করুন।",
      "user_task": "আপনার ধূমপানের ট্রিগারগুলো চিহ্নিত করে একটি লিস্ট করুন এবং সেগুলো থেকে দূরে থাকুন।",
      "ai_task": "আমি আপনার জন্য বিকল্প স্বাস্থ্যকর পনীয়ের একটি তালিকা তৈরি করেছি।"
    },
    {
      "title": "নতুন অভ্যাস তৈরি",
      "desc": "ধূমপানের বদলে একটি নতুন স্বাস্থ্যকর অভ্যাস শুরু করুন। যেমন: হাঁটা, বই পড়া বা গান শোনা।",
      "user_task": "আজ অন্তত ২০ মিনিট হাঁটাহাঁটি করুন বা পছন্দের একটি গান শুনুন।",
      "ai_task": "আপনার জন্য কিছু স্ট্রেস রিলিভিং মিউজিকের সাজেসন প্রস্তুত করা হয়েছে।"
    },
  ];

  Future<void> loadGoalStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final planState = await DatabaseHelper().getQuitPlanState(userId);

      List<String> completedDates = [];
      String? lastAnsweredDate;
      bool lastAnsweredStatus = false;
      String? lastStartedDate;
      String? storedPlan;

      if (planState != null) {
        lastAnsweredDate = planState['last_answered_date'] as String?;
        lastAnsweredStatus = (planState['last_answered_status'] as int? ?? 0) == 1;
        lastStartedDate = planState['last_started_date'] as String?;
        storedPlan = planState['ai_plan'] as String?;
        
        final completedDatesJson = planState['completed_task_dates'] as String?;
        if (completedDatesJson != null) {
          completedDates = List<String>.from(jsonDecode(completedDatesJson));
        }
      }

      _hasAnsweredToday = (lastAnsweredDate == today);
      _isCompletedToday = _hasAnsweredToday && lastAnsweredStatus;
      _isGoalStarted = _isCompletedToday;

      // Reschedule reminders
      await NotificationService().schedulePlanCompletionReminder(hasAnsweredToday: _hasAnsweredToday);
      await NotificationService().scheduleViewPlanReminder(hasAnsweredToday: _hasAnsweredToday);

      // Try fetching fresh plan from Supabase in the background
      if (userId != 'guest') {
        try {
          final profileData = await Supabase.instance.client
              .from('user_profiles')
              .select('ai_quit_plan')
              .eq('id', userId)
              .maybeSingle();
          if (profileData != null && profileData['ai_quit_plan'] != null) {
            final fetchedPlan = profileData['ai_quit_plan'];
            final String freshPlanJson = (fetchedPlan is String) ? fetchedPlan : jsonEncode(fetchedPlan);
            if (freshPlanJson != storedPlan) {
              storedPlan = freshPlanJson;
              // Save updated plan to SQLite
              await DatabaseHelper().saveQuitPlanState(
                userId: userId,
                aiPlanJson: freshPlanJson,
                lastAnsweredDate: lastAnsweredDate,
                lastAnsweredStatus: lastAnsweredStatus,
                completedTaskDatesJson: jsonEncode(completedDates),
                lastStartedDate: lastStartedDate,
              );
            }
          }
        } catch (e) {
          debugPrint("Error fetching plan from Supabase: $e");
        }
      }

      if (storedPlan != null) {
        _dailyPlans = jsonDecode(storedPlan);
      } else {
        _dailyPlans = List.from(_fallbackPlans);
      }
    } catch (e) {
      debugPrint("Error loading goal status: $e");
      _dailyPlans = List.from(_fallbackPlans);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveAiPlan(String jsonPlan) async {
    try {
      _dailyPlans = jsonDecode(jsonPlan);
      notifyListeners();
      
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final planState = await DatabaseHelper().getQuitPlanState(userId);
      
      List<String> completedDates = [];
      String? lastAnsweredDate;
      bool lastAnsweredStatus = false;
      String? lastStartedDate;

      if (planState != null) {
        lastAnsweredDate = planState['last_answered_date'] as String?;
        lastAnsweredStatus = (planState['last_answered_status'] as int? ?? 0) == 1;
        lastStartedDate = planState['last_started_date'] as String?;
        final completedDatesJson = planState['completed_task_dates'] as String?;
        if (completedDatesJson != null) {
          completedDates = List<String>.from(jsonDecode(completedDatesJson));
        }
      }

      await DatabaseHelper().saveQuitPlanState(
        userId: userId,
        aiPlanJson: jsonPlan,
        lastAnsweredDate: lastAnsweredDate,
        lastAnsweredStatus: lastAnsweredStatus,
        completedTaskDatesJson: jsonEncode(completedDates),
        lastStartedDate: lastStartedDate,
      );

      if (userId != 'guest') {
        try {
          await Supabase.instance.client.from('user_profiles').update({
            'ai_quit_plan': jsonPlan,
          }).eq('id', userId);
        } catch (e) {
          debugPrint("Error saving AI plan to Supabase: $e");
        }
      }
    } catch (e) {
      debugPrint("Error saving AI plan: $e");
    }
  }

  Future<void> submitPlanResponse(bool completed) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final planState = await DatabaseHelper().getQuitPlanState(userId);
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

      await DatabaseHelper().saveQuitPlanState(
        userId: userId,
        aiPlanJson: storedPlan ?? jsonEncode(_dailyPlans),
        lastAnsweredDate: today,
        lastAnsweredStatus: completed,
        completedTaskDatesJson: jsonEncode(completedDates),
        lastStartedDate: lastStartedDate,
      );

      // Reschedule reminders
      await NotificationService().schedulePlanCompletionReminder(hasAnsweredToday: true);
      await NotificationService().scheduleViewPlanReminder(hasAnsweredToday: true);

      notifyListeners();
    } catch (e) {
      debugPrint("Error submitting plan response: $e");
    }
  }
}
