import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuitPlanProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool _isGoalStarted = false;
  List<dynamic> _dailyPlans = [];

  bool get isLoading => _isLoading;
  bool get isGoalStarted => _isGoalStarted;
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
      final lastStarted = prefs.getString('last_plan_started_date_$userId');
      
      _isGoalStarted = (lastStarted == today);

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
              await prefs.setString('ai_quit_plan_$userId', storedPlan!);
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
          // Update user_profiles
          await Supabase.instance.client.from('user_profiles').update({
            'ai_quit_plan': jsonDecode(jsonPlan),
          }).eq('id', userId);

          // Save to quit_plans table
          final plansList = jsonDecode(jsonPlan);
          await Supabase.instance.client.from('quit_plans').delete().eq('user_id', userId);
          await Supabase.instance.client.from('quit_plans').insert({
            'user_id': userId,
            'strategy': 'AI Generated Quit Plan',
            'milestones': plansList,
          });

          // *** SAVE EACH TASK TO ai_tasks TABLE ***
          if (plansList is List) {
            // Delete old AI tasks for this user
            await Supabase.instance.client.from('ai_tasks').delete().eq('user_id', userId);
            
            // Insert each day's task
            for (var plan in plansList) {
              final title = plan['title'] ?? 'AI Task';
              final desc = plan['desc'] ?? '';
              final userTask = plan['user_task'] ?? '';
              final aiTask = plan['ai_task'] ?? '';
              final dailyTarget = plan['daily_target'] ?? '';
              final day = plan['day']?.toString() ?? '';

              await Supabase.instance.client.from('ai_tasks').insert({
                'user_id': userId,
                'task_title': '$day - $title',
                'task_description': desc,
                'task_details': jsonEncode({
                  'user_task': userTask,
                  'ai_task': aiTask,
                  'daily_target': dailyTarget,
                }),
              });
            }
            debugPrint("✅ AI tasks saved to ai_tasks table: ${plansList.length} tasks");
          }
        } catch (e) {
          debugPrint("Error syncing plan to Supabase: $e");
        }
      }
      
      _dailyPlans = jsonDecode(jsonPlan);
      notifyListeners();
    } catch (e) {
      debugPrint("Error saving AI plan: $e");
    }
  }

  Future<void> startGoal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = Supabase.instance.client.auth.currentUser?.id ?? 'guest';
      final today = DateTime.now().toIso8601String().split('T')[0];
      await prefs.setString('last_plan_started_date_$userId', today);
      
      _isGoalStarted = true;
      notifyListeners();
    } catch (e) {
      debugPrint("Error starting goal: $e");
    }
  }
}
