import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      final lastAnsweredDate = prefs.getString('last_plan_answered_date_$userId');
      final lastAnsweredStatus = prefs.getBool('last_plan_answered_status_$userId') ?? false;

      _hasAnsweredToday = (lastAnsweredDate == today);
      _isCompletedToday = _hasAnsweredToday && lastAnsweredStatus;
      _isGoalStarted = _isCompletedToday;

      // Reschedule plan completion reminder notification dynamically
      await NotificationService().schedulePlanCompletionReminder(hasAnsweredToday: _hasAnsweredToday);
      await NotificationService().scheduleViewPlanReminder(hasAnsweredToday: _hasAnsweredToday);

      final storedPlanLocal = prefs.getString('ai_quit_plan_$userId');
      String? storedPlan = storedPlanLocal;

      // Try fetching from Supabase if not guest
      if (userId != 'guest') {
        try {
          final profileData = await Supabase.instance.client
              .from('user_profiles')
              .select('ai_quit_plan')
              .eq('id', userId)
              .maybeSingle();
          if (profileData != null && profileData['ai_quit_plan'] != null) {
            final fetchedPlan = profileData['ai_quit_plan'];
            if (fetchedPlan is String) {
              storedPlan = fetchedPlan;
            } else {
              storedPlan = jsonEncode(fetchedPlan);
            }
            // Sync locally
            if (storedPlan != storedPlanLocal) {
              await prefs.setString('ai_quit_plan_$userId', storedPlan);
            }
          }
        } catch (e) {
          debugPrint("Error fetching from Supabase: $e");
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
      final prefs = await SharedPreferences.getInstance();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      await prefs.setString('ai_quit_plan_$userId', jsonPlan);
      
      if (userId != 'guest') {
        try {
          // Update user_profiles (ai_quit_plan is TEXT type in user_profiles)
          await Supabase.instance.client.from('user_profiles').update({
            'ai_quit_plan': jsonPlan,
          }).eq('id', userId);
        } catch (e) {
          debugPrint("Error syncing plan to Supabase user_profiles: $e");
        }
      }
      
      _dailyPlans = jsonDecode(jsonPlan);
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving AI plan: $e");
    }
  }

  Future<void> submitPlanResponse(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      
      await prefs.setString('last_plan_answered_date_$userId', today);
      await prefs.setBool('last_plan_answered_status_$userId', completed);

      if (completed) {
        // Save today's date in completed task dates list
        List<String> completedDates = prefs.getStringList('completed_task_dates_$userId') ?? [];
        if (!completedDates.contains(today)) {
          completedDates.add(today);
          await prefs.setStringList('completed_task_dates_$userId', completedDates);
        }
        await prefs.setString('last_plan_started_date_$userId', today);
        _isGoalStarted = true;
      } else {
        _isGoalStarted = false;
      }
      
      _hasAnsweredToday = true;
      _isCompletedToday = completed;

      // Reschedule plan completion reminder notification dynamically
      await NotificationService().schedulePlanCompletionReminder(hasAnsweredToday: true);
      await NotificationService().scheduleViewPlanReminder(hasAnsweredToday: true);

      notifyListeners();
    } catch (e) {
      debugPrint("Error submitting plan response: $e");
    }
  }
}
