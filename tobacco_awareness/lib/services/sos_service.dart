import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'backend_service.dart';

class SosService {
  static final SosService _instance = SosService._internal();
  factory SosService() => _instance;
  SosService._internal();

  /// Log SOS emergency event safely to backend
  Future<bool> logSosEvent(String mode, {String? distraction}) async {
    if (BackendService.token == null) return false;

    try {
      final res = await http.post(
        Uri.parse('${BackendService.baseUrl}/api/profile/sos-log'),
        headers: BackendService.headers(),
        body: jsonEncode({
          'selected_mode': mode,
          'distraction_clicked': distraction,
        }),
      ).timeout(const Duration(seconds: 5));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("SosService.logSosEvent error: $e");
      return false;
    }
  }
}
