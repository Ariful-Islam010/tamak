import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'hive_helper.dart';
import 'sync_service.dart';

class DurableSyncQueue {
  static final DurableSyncQueue _instance = DurableSyncQueue._internal();
  factory DurableSyncQueue() => _instance;
  DurableSyncQueue._internal();

  bool _isProcessing = false;

  /// Ensures pending offline items are safely committed on app launch or reconnect
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      final prefs = HiveHelper();
      final rawQueue = await prefs.getSetting('durable_offline_queue');

      if (rawQueue != null && rawQueue.isNotEmpty) {
        final List<dynamic> items = jsonDecode(rawQueue);
        if (items.isNotEmpty) {
          debugPrint('⚡ [DurableSyncQueue] Migrating ${items.length} pending transactional items to SyncService...');
          for (var item in items) {
            if (item is Map<String, dynamic>) {
              final type = item['type'] as String?;
              final data = item['data'] as Map<String, dynamic>?;
              if (type == 'checkin' && data != null) {
                await SyncService().queueCheckIn(
                  userId: data['user_id'] ?? '',
                  checkInDate: data['check_in_date'] ?? '',
                  cravingLevel: (data['craving_level'] as num?)?.toInt() ?? 5,
                  mood: data['mood'] ?? 'Normal',
                  usedTobacco: data['used_tobacco'] == true,
                  note: data['note'],
                );
              } else if (type == 'savings' && data != null) {
                await SyncService().queueSavings(
                  userId: data['user_id'] ?? '',
                  amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
                );
              }
            }
          }
          await prefs.removeSetting('durable_offline_queue');
        }
      }
      await SyncService().processSyncQueue();
    } catch (e) {
      debugPrint('⚡ [DurableSyncQueue] Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Add durable transactional action item to offline queue
  Future<void> enqueueAction({required String type, required Map<String, dynamic> data}) async {
    try {
      if (type == 'checkin') {
        await SyncService().queueCheckIn(
          userId: data['user_id'] ?? '',
          checkInDate: data['check_in_date'] ?? '',
          cravingLevel: (data['craving_level'] as num?)?.toInt() ?? 5,
          mood: data['mood'] ?? 'Normal',
          usedTobacco: data['used_tobacco'] == true,
          note: data['note'],
        );
      } else if (type == 'savings') {
        await SyncService().queueSavings(
          userId: data['user_id'] ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
        );
      }
      debugPrint('⚡ [DurableSyncQueue] Enqueued transaction: $type via SyncService');
    } catch (e) {
      debugPrint('⚡ [DurableSyncQueue] Enqueue error: $e');
    }
  }
}
