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
          debugPrint('⚡ [DurableSyncQueue] Processing ${items.length} pending transactional items...');
          await SyncService().processSyncQueue();
        }
      }
    } catch (e) {
      debugPrint('⚡ [DurableSyncQueue] Error processing queue: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Add durable transactional action item to offline queue
  Future<void> enqueueAction({required String type, required Map<String, dynamic> data}) async {
    try {
      final prefs = HiveHelper();
      final rawQueue = await prefs.getSetting('durable_offline_queue');
      List<dynamic> queue = [];

      if (rawQueue != null && rawQueue.isNotEmpty) {
        queue = jsonDecode(rawQueue);
      }

      queue.add({
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });

      await prefs.saveSetting('durable_offline_queue', jsonEncode(queue));
      debugPrint('⚡ [DurableSyncQueue] Enqueued transaction: $type');
    } catch (e) {
      debugPrint('⚡ [DurableSyncQueue] Enqueue error: $e');
    }
  }
}
