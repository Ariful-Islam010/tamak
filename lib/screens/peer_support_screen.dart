import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class PeerSupportScreen extends StatefulWidget {
  const PeerSupportScreen({super.key});

  @override
  State<PeerSupportScreen> createState() => _PeerSupportScreenState();
}

class _PeerSupportScreenState extends State<PeerSupportScreen> {
  bool _isAnonymous = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {
      "isMe": false,
      "sender": "রহিম উদ্দিন",
      "level": "Warrior",
      "isCounselor": false,
      "text": "আজ আমার ৪র্থ দিন তামাক ছাড়া! বেশ ভালো লাগছে।",
      "time": "১০:৩০ এএম"
    },
    {
      "isMe": true,
      "sender": "রাকিব হোসেন",
      "level": "Beginner",
      "isCounselor": false,
      "text": "অভিনন্দন ভাই! আমার কেবল দ্বিতীয় দিন। একটু কষ্ট হচ্ছে।",
      "time": "১০:৩৫ এএম"
    },
    {
      "isMe": false,
      "sender": "পিয়ার কাউন্সেলর (অ্যাডমিন)",
      "level": "Expert",
      "isCounselor": true,
      "text": "রাকিব, প্রথম কয়েকদিন একটু কঠিন হয়। প্রচুর পানি পান করুন আর এস.ও.এস (SOS) ফিচারটি ব্যবহার করুন। আমরা আপনার সাথে আছি!",
      "time": "১০:৪০ এএম"
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    final userName = user?.displayName ?? "ব্যবহারকারী";

    // Format time in Bengali
    final now = DateTime.now();
    final formatter = DateFormat('hh:mm a');
    String formattedTime = formatter.format(now)
        .replaceAll('AM', 'এএম')
        .replaceAll('PM', 'পিএম')
        .replaceAll('0', '০').replaceAll('1', '১').replaceAll('2', '২')
        .replaceAll('3', '৩').replaceAll('4', '৪').replaceAll('5', '৫')
        .replaceAll('6', '৬').replaceAll('7', '৭').replaceAll('8', '৮')
        .replaceAll('9', '৯');

    setState(() {
      _messages.add({
        "isMe": true,
        "sender": userName,
        "level": "Beginner", // Or dynamic based on user profile
        "isCounselor": false,
        "text": _messageController.text.trim(),
        "time": formattedTime,
      });
    });

    _messageController.clear();
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5), // WhatsApp style background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54), // WhatsApp primary green
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("সহায়তা গ্রুপ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("৪ জন অনলাইন", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70)),
          ],
        ),
        actions: [
          Row(
            children: [
              const Text(
                "অজ্ঞাত",
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
              Switch(
                value: _isAnonymous,
                activeColor: AppTheme.accentYellow,
                inactiveThumbColor: Colors.grey.shade300,
                inactiveTrackColor: Colors.grey.shade600,
                onChanged: (val) {
                  setState(() {
                    _isAnonymous = val;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_isAnonymous ? "আপনি এখন অজ্ঞাত হিসেবে চ্যাট করছেন" : "আপনার নাম দৃশ্যমান")),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Emergency Help Button (Big, Prominent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("কাউন্সেলরকে জানানো হয়েছে, দ্রুতই কেউ যোগাযোগ করবে!")),
                );
              },
              icon: const Icon(Icons.support_agent, size: 28),
              label: const Text(
                "সরাসরি সাহায্য নিন (Ask for Help Now)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildChatBubble(
                  context,
                  msg["text"],
                  msg["sender"],
                  msg["time"],
                  msg["isMe"],
                  msg["isCounselor"],
                );
              },
            ),
          ),
          
          // Message Input Field (WhatsApp Style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: Colors.transparent,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                            onPressed: () {},
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: "মেসেজ লিখুন...",
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.attach_file, color: Colors.grey),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      height: 48,
                      width: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF075E54), // WhatsApp primary green
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, String text, String sender, String time, bool isMe, bool isCounselor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: isCounselor ? AppTheme.accentYellow : Colors.grey.shade300,
              child: Icon(
                isCounselor ? Icons.verified_user : Icons.person,
                size: 20,
                color: isCounselor ? Colors.white : Colors.grey.shade600,
              ),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCounselor 
                    ? const Color(0xFFFFF8DC) // Light yellow for counselor
                    : (isMe ? const Color(0xFFDCF8C6) : Colors.white), // WhatsApp chat bubble colors
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        _isAnonymous && !isCounselor ? "অজ্ঞাত ব্যবহারকারী" : sender,
                        style: TextStyle(
                          fontSize: 13,
                          color: isCounselor ? AppTheme.accentOrange : const Color(0xFF075E54),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (isMe) const SizedBox(width: 4),
                        if (isMe) const Icon(Icons.done_all, size: 14, color: Colors.blue), // Read receipt
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
