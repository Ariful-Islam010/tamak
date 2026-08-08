import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'backend_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  static const String _syncQueueBox = 'offline_sync_queue';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isProcessing = false;

  Future<void> init() async {
    await Hive.openBox(_syncQueueBox);
    _startConnectivityListener();
    processSyncQueue();
  }

  void _startConnectivityListener() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        debugPrint('🌐 Internet connection restored. Triggering offline sync queue...');
        processSyncQueue();
      }
    });
  }

  /// Queue a pending check-in payload for background sync
  Future<void> queueCheckIn({
    required String userId,
    required String checkInDate,
    required int cravingLevel,
    required String mood,
    required bool usedTobacco,
    String? note,
  }) async {
    final box = Hive.box(_syncQueueBox);
    final key = 'checkin_${userId}_$checkInDate';
    final payload = {
      'type': 'checkin',
      'user_id': userId,
      'check_in_date': checkInDate,
      'craving_level': cravingLevel,
      'mood': mood,
      'used_tobacco': usedTobacco,
      'note': note,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.put(key, jsonEncode(payload));
    debugPrint('📥 Queued offline check-in for $checkInDate');
  }

  /// Queue a pending savings payload for background sync
  Future<void> queueSavings({
    required String userId,
    required double amount,
  }) async {
    final box = Hive.box(_syncQueueBox);
    final key = 'savings_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'type': 'savings',
      'user_id': userId,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.put(key, jsonEncode(payload));
    debugPrint('📥 Queued offline savings log of ৳$amount');
  }

  /// Process all items in the offline queue and send to backend
  Future<void> processSyncQueue() async {
    if (_isProcessing) return;
    if (BackendService.token == null || BackendService.userId == null) return;

    _isProcessing = true;
    try {
      final box = Hive.box(_syncQueueBox);
      if (box.isEmpty) {
        _isProcessing = false;
        return;
      }

      final keys = List.from(box.keys);
      debugPrint('🔄 Processing ${keys.length} queued offline items...');

      for (final key in keys) {
        final String? rawJson = box.get(key) as String?;
        if (rawJson == null) {
          await box.delete(key);
          continue;
        }

        try {
          final data = jsonDecode(rawJson) as Map<String, dynamic>;
          final type = data['type'] as String?;

          bool success = false;
          if (type == 'checkin') {
            success = await _sendCheckIn(data);
          } else if (type == 'savings') {
            success = await _sendSavings(data);
          }

          if (success) {
            await box.delete(key);
            debugPrint('✅ Successfully synced and removed queued item: $key');
          }
        } catch (e) {
          debugPrint('⚠️ Error processing sync item $key: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in processSyncQueue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _sendCheckIn(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('${BackendService.baseUrl}/api/checkins'),
            headers: BackendService.headers(),
            body: jsonEncode({
              'user_id': data['user_id'],
              'check_in_date': data['check_in_date'],
              'craving_level': data['craving_level'],
              'mood': data['mood'],
              'used_tobacco': data['used_tobacco'],
              'note': data['note'],
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _sendSavings(Map<String, dynamic> data) async {
    try {
      final response = await http
          .post(
            Uri.parse('${BackendService.baseUrl}/api/savings'),
            headers: BackendService.headers(),
            body: jsonEncode({
              'user_id': data['user_id'],
              'amount': data['amount'],
            }),
          )
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
