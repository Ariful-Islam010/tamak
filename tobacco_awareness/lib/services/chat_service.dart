import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import 'backend_service.dart';
import 'hive_helper.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  /// Fetch messages from server with try-catch and Hive caching
  Future<List<ChatMessageModel>> fetchMessages() async {
    try {
      if (BackendService.token == null) {
        return await loadCachedMessages();
      }

      final res = await http.get(
        Uri.parse('${BackendService.baseUrl}/api/chat/messages'),
        headers: BackendService.headers(),
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(res.body);
        final messages = rows.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
        
        // Cache to Hive
        await HiveHelper().saveSetting(
          'cached_chat_messages',
          jsonEncode(messages.map((m) => m.toJson()).toList()),
        );
        return messages;
      }
    } catch (e) {
      debugPrint("ChatService.fetchMessages error: $e");
    }
    return await loadCachedMessages();
  }

  /// Load cached messages from Hive
  Future<List<ChatMessageModel>> loadCachedMessages() async {
    try {
      final cachedStr = await HiveHelper().getSetting('cached_chat_messages');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(cachedStr);
        return list.map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint("ChatService.loadCachedMessages error: $e");
    }
    return [];
  }

  /// Fetch user profile details by ID safely
  Future<Map<String, dynamic>?> fetchUserProfileCard(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('${BackendService.baseUrl}/api/chat/user-profile/$userId'),
        headers: BackendService.headers(),
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint("ChatService.fetchUserProfileCard error: $e");
    }
    return null;
  }

  /// Report content
  Future<bool> reportContent({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('${BackendService.baseUrl}/api/chat/report'),
        headers: BackendService.headers(),
        body: jsonEncode({
          'target_type': targetType,
          'target_id': targetId,
          'reason': reason,
          'details': details ?? '',
        }),
      ).timeout(const Duration(seconds: 5));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint("ChatService.reportContent error: $e");
      return false;
    }
  }

  /// Send image message
  Future<String?> uploadChatImage(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${BackendService.baseUrl}/api/chat/upload-image'),
      );
      request.headers.addAll(BackendService.headers());
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedRes = await request.send().timeout(const Duration(seconds: 15));
      final responseData = await streamedRes.stream.bytesToString();

      if (streamedRes.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['imageUrl']?.toString() ?? data['image_url']?.toString();
      }
    } catch (e) {
      debugPrint("ChatService.uploadChatImage error: $e");
    }
    return null;
  }
}
