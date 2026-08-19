import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/money_saving_model.dart';
import 'backend_service.dart';
import 'sync_service.dart';

class MoneySaverService {
  static final MoneySaverService _instance = MoneySaverService._internal();
  factory MoneySaverService() => _instance;
  MoneySaverService._internal();

  /// Maximum allowed amount for savings goal or money add
  static const int maxAmountLimit = 10000;

  /// Fetch savings records safely
  Future<List<MoneySavingRecord>> fetchSavings() async {
    final userId = BackendService.userId ?? 'guest';
    if (userId == 'guest' || BackendService.token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${BackendService.baseUrl}/api/savings'),
        headers: BackendService.headers(),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(response.body);
        return rows.map((e) => MoneySavingRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint("MoneySaverService.fetchSavings error: $e");
    }
    return [];
  }

  /// Fetch savings goals safely
  Future<List<SavingsGoalModel>> fetchGoals() async {
    final userId = BackendService.userId ?? 'guest';
    if (userId == 'guest' || BackendService.token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('${BackendService.baseUrl}/api/goals'),
        headers: BackendService.headers(),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> goalsData = jsonDecode(response.body);
        return goalsData.map((e) => SavingsGoalModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint("MoneySaverService.fetchGoals error: $e");
    }
    return [];
  }

  /// Post new money saved with max 10,000 TK limit check
  Future<bool> addMoneySaved(int amount) async {
    // Enforce 10,000 TK max limit rule
    final safeAmount = amount > maxAmountLimit ? maxAmountLimit : amount;
    if (safeAmount <= 0) return false;

    final userId = BackendService.userId ?? 'guest';
    if (userId != 'guest' && BackendService.token != null) {
      try {
        await http.post(
          Uri.parse('${BackendService.baseUrl}/api/savings'),
          headers: BackendService.headers(),
          body: jsonEncode({
            'user_id': userId,
            'amount': safeAmount,
          }),
        ).timeout(const Duration(seconds: 8));
      } on SocketException catch (_) {
        debugPrint("No internet. Queueing savings log for offline sync.");
        await SyncService().queueSavings(
          userId: userId,
          amount: safeAmount.toDouble(),
        );
      } on TimeoutException catch (_) {
        debugPrint("Timed out. Queueing savings log for offline sync.");
        await SyncService().queueSavings(
          userId: userId,
          amount: safeAmount.toDouble(),
        );
      } catch (e) {
        debugPrint("MoneySaverService.addMoneySaved error: $e");
      }
    }
    return true;
  }

  /// Post new savings goal with max 10,000 TK limit check
  Future<bool> addGoal({required String title, required int targetAmount}) async {
    // Enforce 10,000 TK max limit rule
    final safeTarget = targetAmount > maxAmountLimit ? maxAmountLimit : targetAmount;
    if (title.isEmpty || safeTarget <= 0) return false;

    final userId = BackendService.userId ?? 'guest';
    if (userId != 'guest' && BackendService.token != null) {
      try {
        await http.post(
          Uri.parse('${BackendService.baseUrl}/api/goals'),
          headers: BackendService.headers(),
          body: jsonEncode({
            'user_id': userId,
            'title': title,
            'target_amount': safeTarget,
            'current_amount': 0,
            'is_completed': false,
            'icon_name': 'star',
          }),
        ).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint("MoneySaverService.addGoal error: $e");
      }
    }
    return true;
  }
}
