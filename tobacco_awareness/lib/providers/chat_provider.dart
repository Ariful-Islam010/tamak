import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../services/hive_helper.dart';
import '../services/backend_service.dart';

final chatProvider = ChangeNotifierProvider<ChatProvider>((ref) => ChatProvider());

class ChatProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  final Set<String> _deletedMessageIds = {};
  final Set<String> _blockedUserIds = {};
  bool _isLoading = false;
  socket_io.Socket? _socket;

  List<Map<String, dynamic>> get messages => _messages;
  Set<String> get blockedUserIds => _blockedUserIds;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _init();
  }

  Future<void> _init() async {
    final savedDeleted = await HiveHelper().getDeletedMessageIds();
    _deletedMessageIds.addAll(savedDeleted);
    final savedBlocked = await HiveHelper().getBlockedUserIds();
    _blockedUserIds.addAll(savedBlocked);

    await _loadMessagesFromCache();
    await loadMessages();

    _initSocket();
  }

  void _initSocket() {
    try {
      _socket = socket_io.io(BackendService.baseUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
      });

      _socket?.onConnect((_) {
        debugPrint('⚡ Connected to WebSocket Server');
      });

      _socket?.on('new_message', (data) {
        debugPrint('⚡ Received new message via WebSocket');
        if (data != null) {
          try {
            Map<String, dynamic>? row;
            if (data is List && data.isNotEmpty && data.first is Map) {
              row = Map<String, dynamic>.from(data.first);
            } else if (data is Map) {
              row = Map<String, dynamic>.from(data);
            }

            if (row != null) {
              final idStr = row['id']?.toString();
              if (idStr != null && !_deletedMessageIds.contains(idStr)) {
                final existingIndex = _messages.indexWhere((m) => m['id']?.toString() == idStr);
                if (existingIndex == -1) {
                  final senderData = row['sender'] as Map<String, dynamic>?;
                  final userId = BackendService.userId;
                  DateTime createdAtStr;
                  if (row['created_at'] != null) {
                    final str = row['created_at'].toString();
                    final parsed = DateTime.tryParse(str.endsWith('Z') || str.contains('+') ? str : '${str}Z');
                    createdAtStr = parsed != null ? parsed.toLocal() : DateTime.now();
                  } else {
                    createdAtStr = DateTime.now();
                  }

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

                  final senderName = senderData?['display_name']
                      ?? senderData?['name']
                      ?? senderData?['username']
                      ?? senderData?['full_name']
                      ?? (isMe ? null : "ব্যবহারকারী");

                  final isCounselor = (senderData?['display_name'] ?? senderData?['name'] ?? '')
                      .toString()
                      .contains("কাউন্সেলর");

                  _messages.add({
                    "id": row['id'],
                    "sender_id": row['sender_id'],
                    "isMe": isMe,
                    "sender": senderName ?? "ব্যবহারকারী",
                    "senderPhoto": senderData?['photo_url'] ?? senderData?['avatar_url'],
                    "isCounselor": isCounselor,
                    "text": row['content'] ?? "",
                    "imageUrl": row['image_url'],
                    "time": formattedTime,
                    "createdAt": createdAtStr,
                  });
                  _saveMessagesToCache();
                  notifyListeners();
                  return;
                }
              }
            }
          } catch (e) {
            debugPrint("Error parsing websocket message: $e");
          }
        }
        loadMessages();
      });

      _socket?.on('delete_message', (data) {
        if (data != null && data['id'] != null) {
          final delId = data['id'].toString();
          _deletedMessageIds.add(delId);
          _messages.removeWhere((m) => m["id"].toString() == delId);
          notifyListeners();
        }
      });

      _socket?.onDisconnect((_) => debugPrint('⚡ Disconnected from WebSocket Server'));
    } catch (e) {
      debugPrint('Error setting up Socket.io: $e');
    }
  }



  Future<void> _loadMessagesFromCache() async {
    try {
      final userId = BackendService.userId ?? 'community_chat_messages';
      var cachedMessages = await HiveHelper().getChatMessages(userId);
      if (cachedMessages.isEmpty && userId != 'community_chat_messages') {
        cachedMessages = await HiveHelper().getChatMessages('community_chat_messages');
      }
      if (cachedMessages.isNotEmpty) {
        final List<Map<String, dynamic>> restored = [];
        for (var m in cachedMessages) {
          final idStr = m["id"]?.toString();
          if (idStr != null && _deletedMessageIds.contains(idStr)) continue;

          final map = Map<String, dynamic>.from(m);
          if (map['createdAt'] is String) {
            map['createdAt'] = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
          }
          // Ensure isMe is accurately evaluated for current user
          if (BackendService.userId != null && map['sender_id'] != null) {
            map['isMe'] = map['sender_id'] == BackendService.userId;
          }
          restored.add(map);
        }
        _messages = restored;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading messages from cache: $e");
    }
  }

  Future<void> _saveMessagesToCache() async {
    try {
      final userId = BackendService.userId ?? 'community_chat_messages';
      final serializable = _messages.map((m) {
        final map = Map<String, dynamic>.from(m);
        if (map['createdAt'] is DateTime) {
          map['createdAt'] = (map['createdAt'] as DateTime).toIso8601String();
        }
        return map;
      }).toList();

      await HiveHelper().saveChatMessages('community_chat_messages', serializable);
      if (userId != 'community_chat_messages') {
        await HiveHelper().saveChatMessages(userId, serializable);
      }
    } catch (e) {
      debugPrint("Error saving messages to cache: $e");
    }
  }

  Future<void> loadMessages() async {
    if (BackendService.token == null) {
      _isLoading = false;
      await _loadMessagesFromCache();
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
          DateTime createdAtStr;
          if (row['created_at'] != null) {
            final str = row['created_at'].toString();
            final parsed = DateTime.tryParse(str.endsWith('Z') || str.contains('+') ? str : '${str}Z');
            createdAtStr = parsed != null ? parsed.toLocal() : DateTime.now();
          } else {
            createdAtStr = DateTime.now();
          }

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
            "sender_id": row['sender_id'],
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
      if (_messages.isEmpty) {
        await _loadMessagesFromCache();
      }
    }
    _isLoading = false;
    notifyListeners();
  }


  Future<void> blockUser(String userId) async {
    _blockedUserIds.add(userId);
    await HiveHelper().saveBlockedUserIds(_blockedUserIds);
    notifyListeners();
  }

  Future<void> unblockUser(String userId) async {
    _blockedUserIds.remove(userId);
    await HiveHelper().saveBlockedUserIds(_blockedUserIds);
    notifyListeners();
  }

  Future<void> reportContent({
    dynamic messageId,
    String? reportedUserId,
    required String reason,
  }) async {
    if (BackendService.token == null) return;
    try {
      final response = await http
          .post(
            Uri.parse('${BackendService.baseUrl}/api/chat/report'),
            headers: BackendService.headers(),
            body: jsonEncode({
              'message_id': messageId,
              'reported_user_id': reportedUserId,
              'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 400) {
        throw Exception("রিপোর্ট পাঠাতে সমস্যা হয়েছে (${response.statusCode})");
      }
    } catch (e) {
      debugPrint("Error reporting content: $e");
      rethrow;
    }
  }

  Future<void> sendMessage(String text, String userName,
      {String? imageUrl}) async {
    var userId = BackendService.userId;
    var token = BackendService.token;
    if (userId == null || token == null) {
      token = await HiveHelper().getSetting('auth_access_token');
      userId = await HiveHelper().getSetting('auth_user_id');
      if (token != null && userId != null) {
        BackendService.setAuth(token, userId);
      } else {
        throw Exception("মেসেজ পাঠাতে অনুগ্রহ করে পুনরায় লগইন করুন");
      }
    }

    if (text.trim().isEmpty && imageUrl == null) return;

    try {
      final response = await http
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

      if (response.statusCode >= 400) {
        final err = jsonDecode(response.body);
        final detail = err is Map ? err['detail'] ?? response.body : response.body;
        throw Exception("মেসেজ পাঠাতে ব্যর্থ: $detail");
      }

      // Immediately reload messages
      await loadMessages();
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  Future<void> sendImage(File file, String userName) async {
    if (BackendService.token == null) return;

    // Optimistic UI update
    final fallbackId = "fallback_${DateTime.now().millisecondsSinceEpoch}";
    final now = DateTime.now();
    _messages.add({
      "id": fallbackId,
      "isMe": true,
      "sender": userName,
      "senderPhoto": null,
      "isCounselor": false,
      "text": "📷 একটি ছবি শেয়ার করেছেন",
      "imageUrl": null,
      "localImagePath": file.path,
      "time": DateFormat('hh:mm a').format(now),
      "createdAt": now,
      "isUploading": true,
    });
    notifyListeners();

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
      
      _messages.removeWhere((msg) => msg["id"] == fallbackId);

      if (streamed.statusCode == 200) {
        final data = jsonDecode(responseData);
        final secureUrl = data['secure_url'] as String?;
        if (secureUrl != null) {
          await sendMessage("", userName, imageUrl: secureUrl);
        } else {
          notifyListeners();
          throw Exception("Upload returned no URL");
        }
      } else {
        notifyListeners();
        throw Exception("Image upload via backend failed: ${streamed.statusCode}");
      }
    } catch (e) {
      _messages.removeWhere((msg) => msg["id"] == fallbackId);
      notifyListeners();
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
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
