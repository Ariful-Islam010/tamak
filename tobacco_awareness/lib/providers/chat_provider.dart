import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/hive_helper.dart';
import '../services/backend_service.dart';

final chatProvider = ChangeNotifierProvider<ChatProvider>((ref) => ChatProvider());

class ChatProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  final Set<String> _deletedMessageIds = {};
  bool _isLoading = false;
  Timer? _fallbackTimer;
  RealtimeChannel? _realtimeChannel;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _init();
  }

  Future<void> _init() async {
    final savedDeleted = await HiveHelper().getDeletedMessageIds();
    _deletedMessageIds.addAll(savedDeleted);
    await _loadMessagesFromCache();
    await loadMessages();

    _setupRealtimeSubscription();

    // Secondary fallback timer every 15s in case connection drops briefly
    _fallbackTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      loadMessages();
    });
  }

  void _setupRealtimeSubscription() {
    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client
          .channel('public:peer_support_messages')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'peer_support_messages',
            callback: (payload) {
              debugPrint('⚡ Realtime event received: ${payload.eventType}');
              loadMessages();
            },
          )
          .subscribe();
      debugPrint('⚡ Subscribed to Supabase Realtime channel: peer_support_messages');
    } catch (e) {
      debugPrint('Error setting up Realtime subscription: $e');
    }
  }

  Future<void> _loadMessagesFromCache() async {
    try {
      final userId = BackendService.userId ?? 'guest';
      final cachedMessages = await HiveHelper().getChatMessages(userId);
      if (cachedMessages.isNotEmpty) {
        _messages = cachedMessages.where((m) => !_deletedMessageIds.contains(m["id"].toString())).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading messages from cache: $e");
    }
  }

  Future<void> _saveMessagesToCache() async {
    try {
      final userId = BackendService.userId ?? 'guest';
      await HiveHelper().saveChatMessages(userId, _messages);
    } catch (e) {
      debugPrint("Error saving messages to cache: $e");
    }
  }

  Future<void> loadMessages() async {
    if (BackendService.token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${BackendService.baseUrl}/api/chat/messages'),
            headers: BackendService.headers(),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(response.body);
        final List<Map<String, dynamic>> fetchedMessages = [];

        final userId = BackendService.userId;

        for (var row in rows) {
          final idStr = row['id'].toString();
          if (_deletedMessageIds.contains(idStr)) continue;

          final senderData = row['sender'] as Map<String, dynamic>?;
          final createdAtStr = row['created_at'] != null
              ? DateTime.parse(row['created_at'])
              : DateTime.now();

          final formatter = DateFormat('hh:mm a');
          String formattedTime = formatter
              .format(createdAtStr)
              .replaceAll('AM', 'এএম')
              .replaceAll('PM', 'পিএম')
              .replaceAll('0', '০')
              .replaceAll('1', '১')
              .replaceAll('2', '২')
              .replaceAll('3', '৩')
              .replaceAll('4', '৪')
              .replaceAll('5', '৫')
              .replaceAll('6', '৬')
              .replaceAll('7', '৭')
              .replaceAll('8', '৮')
              .replaceAll('9', '৯');

          final isMe = row['sender_id'] == userId;

          // Resolve sender name from multiple possible field names
          final senderName = senderData?['display_name']
              ?? senderData?['name']
              ?? senderData?['username']
              ?? senderData?['full_name']
              ?? (isMe ? null : "ব্যবহারকারী");

          final isCounselor = (senderData?['display_name'] ?? senderData?['name'] ?? '')
              .toString()
              .contains("কাউন্সেলর");

          fetchedMessages.add({
            "id": row['id'],
            "isMe": isMe,
            "sender": senderName ?? "ব্যবহারকারী",
            "senderPhoto": senderData?['photo_url'] ?? senderData?['avatar_url'],
            "isCounselor": isCounselor,
            "text": row['content'] ?? "",
            "imageUrl": row['image_url'],
            "time": formattedTime,
            "createdAt": createdAtStr,
          });
        }

        // No fallback: show real messages only (empty list if no messages yet)
        _messages = fetchedMessages;

        await _saveMessagesToCache();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading messages: $e");
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> sendMessage(String text, String userName,
      {String? imageUrl}) async {
    final userId = BackendService.userId;
    if (userId == null || BackendService.token == null) return;

    if (text.trim().isEmpty && imageUrl == null) return;

    try {
      await http
          .post(
            Uri.parse('${BackendService.baseUrl}/api/chat/messages'),
            headers: BackendService.headers(),
            body: jsonEncode({
              'sender_id': userId,
              'content': text.trim(),
              'image_url': imageUrl,
            }),
          )
          .timeout(const Duration(seconds: 10));

      // Immediately reload messages
      await loadMessages();
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  Future<void> sendImage(File file, String userName) async {
    if (BackendService.token == null) return;
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${BackendService.baseUrl}/api/upload'),
      );
      request.headers['Authorization'] = 'Bearer ${BackendService.token}';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      final streamed =
          await request.send().timeout(const Duration(seconds: 30));
      final responseData = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200) {
        final data = jsonDecode(responseData);
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null) {
          await sendMessage("", userName, imageUrl: secureUrl);
        } else {
          throw Exception("Upload returned no URL");
        }
      } else {
        throw Exception("Cloudinary upload via backend failed: ${streamed.statusCode}");
      }
    } catch (e) {
      debugPrint("Error sending image: $e");
      rethrow;
    }
  }

  Future<void> deleteMessage(dynamic messageId) async {
    try {
      if (messageId == null) return;
      final targetIdStr = messageId.toString();

      _deletedMessageIds.add(targetIdStr);
      await HiveHelper().saveDeletedMessageIds(_deletedMessageIds);
      
      // Optimistically remove from local state
      _messages.removeWhere((msg) => msg["id"].toString() == targetIdStr);
      notifyListeners();
      await _saveMessagesToCache();

      if (!targetIdStr.startsWith("fallback") && BackendService.token != null) {
        final response = await http
            .delete(
              Uri.parse(
                  '${BackendService.baseUrl}/api/chat/messages/$targetIdStr'),
              headers: BackendService.headers(),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode >= 400) {
          debugPrint("Failed to delete message on backend: ${response.statusCode} - ${response.body}");
        }
      }
    } catch (e) {
      debugPrint("Error deleting message: $e");
      rethrow;
    }
  }

  Future<void> editMessage(dynamic messageId, String newContent) async {
    try {
      if (messageId == null || BackendService.token == null) return;

      final targetIdStr = messageId.toString();
      final trimmedContent = newContent.trim();

      // Optimistic local update — update UI immediately
      final idx = _messages.indexWhere((m) => m['id'].toString() == targetIdStr);
      if (idx != -1) {
        _messages[idx] = Map<String, dynamic>.from(_messages[idx])
          ..['text'] = trimmedContent;
        notifyListeners();
        await _saveMessagesToCache();
      }

      final response = await http
          .put(
            Uri.parse(
                '${BackendService.baseUrl}/api/chat/messages/$targetIdStr'),
            headers: BackendService.headers(),
            body: jsonEncode({'content': trimmedContent}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 400) {
        // Revert optimistic update on failure by reloading from server
        await loadMessages();
        throw Exception("মেসেজ এডিট করা যায়নি (${response.statusCode})");
      }
      // Optimistic update is sufficient — poll timer will sync in ~4s
    } catch (e) {
      debugPrint("Error editing message: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
