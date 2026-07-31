import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../services/database_helper.dart';
import '../services/backend_service.dart';

class ChatProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  Timer? _pollTimer;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadMessagesFromCache();
    await loadMessages();
    // Poll every 4 seconds for new messages (replaces Supabase Realtime)
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      loadMessages();
    });
  }

  Future<void> _loadMessagesFromCache() async {
    try {
      final userId = BackendService.userId ?? 'guest';
      final cachedMessages = await DatabaseHelper().getChatMessages(userId);
      if (cachedMessages.isNotEmpty) {
        _messages = cachedMessages;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading messages from cache: $e");
    }
  }

  Future<void> _saveMessagesToCache() async {
    try {
      final userId = BackendService.userId ?? 'guest';
      await DatabaseHelper().saveChatMessages(userId, _messages);
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

          fetchedMessages.add({
            "id": row['id'],
            "isMe": isMe,
            "sender": senderData?['display_name'] ?? "অজ্ঞাত ব্যবহারকারী",
            "senderPhoto": senderData?['photo_url'],
            "isCounselor": senderData?['display_name']
                    ?.toString()
                    .contains("কাউন্সেলর") ??
                false,
            "text": row['content'] ?? "",
            "imageUrl": row['image_url'],
            "time": formattedTime,
            "createdAt": createdAtStr,
          });
        }

        // Fallback to local default messages if database is empty
        if (fetchedMessages.isEmpty) {
          final now = DateTime.now();
          _messages = [
            {
              "id": "fallback-1",
              "isMe": false,
              "sender": "রহিম উদ্দিন",
              "senderPhoto": null,
              "isCounselor": false,
              "text": "আজ আমার ৪র্থ দিন তামাক ছাড়া! বেশ ভালো লাগছে।",
              "imageUrl": null,
              "time": "১০:৩০ এএম",
              "createdAt": now.subtract(const Duration(minutes: 30)),
            },
            {
              "id": "fallback-2",
              "isMe": false,
              "sender": "পিয়ার কাউন্সেলর (অ্যাডমিন)",
              "senderPhoto": null,
              "isCounselor": true,
              "text":
                  "অভিনন্দন ভাই! প্রথম কয়েকদিন একটু কঠিন হয়। প্রচুর পানি পান করুন আর এস.ও.এস (SOS) ফিচারটি ব্যবহার করুন। আমরা আপনার সাথে আছি!",
              "imageUrl": null,
              "time": "১০:৪০ এএম",
              "createdAt": now.subtract(const Duration(minutes: 20)),
            },
          ];
        } else {
          _messages = fetchedMessages;
        }

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
      
      // Optimistically remove from local state
      _messages.removeWhere((msg) => msg["id"] == messageId);
      notifyListeners();
      await _saveMessagesToCache();

      if (BackendService.token != null) {
        final response = await http
            .delete(
              Uri.parse(
                  '${BackendService.baseUrl}/api/chat/messages/$messageId'),
              headers: BackendService.headers(),
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode >= 400) {
          debugPrint("Failed to delete message on backend: ${response.statusCode} - ${response.body}");
          await loadMessages(); // Reload from backend if failed
          throw Exception("মেসেজ ডিলিট করা যায়নি (${response.statusCode})");
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
      final response = await http
          .put(
            Uri.parse(
                '${BackendService.baseUrl}/api/chat/messages/$messageId'),
            headers: BackendService.headers(),
            body: jsonEncode({'content': newContent.trim()}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 400) {
        throw Exception("মেসেজ এডিট করা যায়নি (${response.statusCode})");
      }
      await loadMessages();
    } catch (e) {
      debugPrint("Error editing message: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
