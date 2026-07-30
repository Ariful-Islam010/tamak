import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/cloudinary_service.dart';
import '../services/database_helper.dart';

class ChatProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  RealtimeChannel? _channel;

  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;

  ChatProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadMessagesFromCache();
    await fetchAndSubscribeMessages();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.event == AuthChangeEvent.signedIn || data.event == AuthChangeEvent.signedOut) {
        await _loadMessagesFromCache();
        await loadMessages();
      }
    });
  }

  Future<void> _loadMessagesFromCache() async {
    try {
      final user = _supabase.auth.currentUser;
      final userId = user?.id ?? 'guest';
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
      final user = _supabase.auth.currentUser;
      final userId = user?.id ?? 'guest';
      await DatabaseHelper().saveChatMessages(userId, _messages);
    } catch (e) {
      debugPrint("Error saving messages to cache: $e");
    }
  }

  Future<void> fetchAndSubscribeMessages() async {
    if (_messages.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    await loadMessages();

    // Subscribe to realtime updates on peer_support_messages
    try {
      _channel = _supabase.channel('public:peer_support_messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'peer_support_messages',
          callback: (payload) async {
            // Re-fetch messages when database updates to get the sender profiles
            await loadMessages();
          },
        )
        .subscribe();
    } catch (e) {
      debugPrint("Realtime subscription error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMessages() async {
    try {
      final response = await _supabase
          .from('peer_support_messages')
          .select('id, sender_id, content, image_url, created_at, sender:user_profiles(display_name, photo_url)')
          .order('created_at', ascending: true);

      final List<Map<String, dynamic>> fetchedMessages = [];

      for (var row in response) {
        final senderData = row['sender'] as Map<String, dynamic>?;
        final createdAtStr = row['created_at'] != null 
            ? DateTime.parse(row['created_at'])
            : DateTime.now();
        
        final formatter = DateFormat('hh:mm a');
        String formattedTime = formatter.format(createdAtStr)
            .replaceAll('AM', 'এএম')
            .replaceAll('PM', 'পিএম')
            .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
            .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
            .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
            .replaceAll('9', '৯');

        final user = _supabase.auth.currentUser;
        final isMe = row['sender_id'] == user?.id;

        fetchedMessages.add({
          "id": row['id'],
          "isMe": isMe,
          "sender": senderData?['display_name'] ?? "অজ্ঞাত ব্যবহারকারী",
          "senderPhoto": senderData?['photo_url'],
          "isCounselor": senderData?['display_name']?.toString().contains("কাউন্সেলর") ?? false,
          "text": row['content'] ?? "",
          "imageUrl": row['image_url'],
          "time": formattedTime,
        });
      }

      // Fallback to local default messages if database is empty
      if (fetchedMessages.isEmpty) {
        _messages = [
          {
            "isMe": false,
            "sender": "রহিম উদ্দিন",
            "senderPhoto": null,
            "isCounselor": false,
            "text": "আজ আমার ৪র্থ দিন তামাক ছাড়া! বেশ ভালো লাগছে।",
            "imageUrl": null,
            "time": "১০:৩০ এএম"
          },
          {
            "isMe": false,
            "sender": "পিয়ার কাউন্সেলর (অ্যাডমিন)",
            "senderPhoto": null,
            "isCounselor": true,
            "text": "অভিনন্দন ভাই! প্রথম কয়েকদিন একটু কঠিন হয়। প্রচুর পানি পান করুন আর এস.ও.এস (SOS) ফিচারটি ব্যবহার করুন। আমরা আপনার সাথে আছি!",
            "imageUrl": null,
            "time": "১০:৪০ এএম"
          },
        ];
      } else {
        _messages = fetchedMessages;
      }
      
      // Save messages to local cache
      await _saveMessagesToCache();
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading messages: $e");
    }
  }

  Future<void> sendMessage(String text, String userName, {String? imageUrl}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    if (text.trim().isEmpty && imageUrl == null) return;

    try {
      // First ensure the user has a profile in public.user_profiles
      final profileExists = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileExists == null) {
        await _supabase.from('user_profiles').insert({
          'id': user.id,
          'email': user.email,
          'display_name': userName,
        });
      }

      await _supabase.from('peer_support_messages').insert({
        'sender_id': user.id,
        'content': text.trim(),
        'image_url': imageUrl,
      });
      
      // Load messages locally as well
      await loadMessages();
    } catch (e) {
      debugPrint("Error sending message: $e");
      rethrow;
    }
  }

  Future<void> sendImage(File file, String userName) async {
    try {
      final String? secureUrl = await CloudinaryService.uploadImage(file);
      if (secureUrl != null) {
        await sendMessage("", userName, imageUrl: secureUrl);
      } else {
        throw Exception("Cloudinary upload failed");
      }
    } catch (e) {
      debugPrint("Error sending image: $e");
      rethrow;
    }
  }

  Future<void> deleteMessage(dynamic messageId) async {
    try {
      if (messageId == null) return;
      await _supabase
          .from('peer_support_messages')
          .delete()
          .eq('id', messageId);
      await loadMessages();
    } catch (e) {
      debugPrint("Error deleting message: $e");
      rethrow;
    }
  }

  Future<void> editMessage(dynamic messageId, String newContent) async {
    try {
      if (messageId == null) return;
      await _supabase
          .from('peer_support_messages')
          .update({'content': newContent.trim()})
          .eq('id', messageId);
      await loadMessages();
    } catch (e) {
      debugPrint("Error editing message: $e");
      rethrow;
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      _supabase.removeChannel(_channel!);
    }
    super.dispose();
  }
}
