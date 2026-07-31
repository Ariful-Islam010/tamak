import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'backend_service.dart';

class GroqAiService {
  static String get _baseUrl => BackendService.baseUrl;

  static Future<String?> generateQuitPlan({
    required int durationInDays,
    required int cigarettesPerDay,
    required String age,
    required String gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-plan'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'durationInDays': durationInDays,
          'cigarettesPerDay': cigarettesPerDay,
          'age': age,
          'gender': gender,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // The backend returns a JSON object with a "plans" array
        dynamic plansArray;
        if (data is Map<String, dynamic> && data.containsKey('plans')) {
          plansArray = data['plans'];
        } else if (data is List) {
           plansArray = data;
        } else {
          // If the model returned a single object, wrap it in a list
          plansArray = [data];
        }
        
        return jsonEncode(plansArray);
      } else {
        debugPrint('Python Backend Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error generating plan: $e');
      return null;
    }
  }

  static Future<String?> getSosAdvice(String triggerReason) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/get-sos-advice'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'triggerReason': triggerReason,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['advice'].toString().trim();
      } else {
        debugPrint('Python Backend Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting SOS advice: $e');
      return null;
    }
  }
}
