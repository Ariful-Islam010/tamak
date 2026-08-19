import 'dart:io';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../utils/network_retry_helper.dart';

abstract class IChatRepository {
  Future<List<ChatMessageModel>> getMessages();
  Future<Map<String, dynamic>?> getUserProfile(String userId);
  Future<bool> reportMessage({required String targetId, required String reason, String? details});
  Future<String?> uploadImage(File file);
}

class ChatRepositoryImpl implements IChatRepository {
  final ChatService _chatService;

  ChatRepositoryImpl({ChatService? chatService}) : _chatService = chatService ?? ChatService();

  @override
  Future<List<ChatMessageModel>> getMessages() async {
    try {
      return await NetworkRetryHelper.executeWithRetry(
        () => _chatService.fetchMessages(),
        maxAttempts: 2,
      );
    } catch (_) {
      return await _chatService.loadCachedMessages();
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      return await NetworkRetryHelper.executeWithRetry(
        () => _chatService.fetchUserProfileCard(userId),
        maxAttempts: 2,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> reportMessage({required String targetId, required String reason, String? details}) async {
    return await _chatService.reportContent(
      targetType: 'message',
      targetId: targetId,
      reason: reason,
      details: details,
    );
  }

  @override
  Future<String?> uploadImage(File file) async {
    return await _chatService.uploadChatImage(file);
  }
}
