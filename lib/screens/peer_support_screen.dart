import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PeerSupportScreen extends StatefulWidget {
  const PeerSupportScreen({super.key});

  @override
  State<PeerSupportScreen> createState() => _PeerSupportScreenState();
}

class _PeerSupportScreenState extends State<PeerSupportScreen> {
  bool _isAnonymous = false;

  final List<Map<String, dynamic>> _messages = [
    {
      "isMe": false,
      "sender": "রহিম উদ্দিন",
      "level": "Warrior",
      "text": "আজ আমার ৪র্থ দিন তামাক ছাড়া! বেশ ভালো লাগছে।",
      "time": "১০:৩০ এএম"
    },
    {
      "isMe": true,
      "sender": "রাকিব হোসেন",
      "level": "Beginner",
      "text": "অভিনন্দন ভাই! আমার কেবল দ্বিতীয় দিন। একটু কষ্ট হচ্ছে।",
      "time": "১০:৩৫ এএম"
    },
    {
      "isMe": false,
      "sender": "পিয়ার কাউন্সেলর (অ্যাডমিন)",
      "level": "Champion",
      "text": "রাকিব, প্রথম কয়েকদিন একটু কঠিন হয়। প্রচুর পানি পান করুন আর এস.ও.এস (SOS) ফিচারটি ব্যবহার করুন।",
      "time": "১০:৪০ এএম"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("সহায়তা গ্রুপ"),
        actions: [
          Row(
            children: [
              Text(
                "অজ্ঞাত",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textColor),
              ),
              Switch(
                value: _isAnonymous,
                activeColor: AppTheme.primaryBlue,
                onChanged: (val) {
                  setState(() {
                    _isAnonymous = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Emergency Help Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.white,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.support_agent),
              label: const Text("সরাসরি সাহায্য নিন (Ask for Help Now)"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
                foregroundColor: AppTheme.white,
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
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
                  msg["level"],
                );
              },
            ),
          ),
          
          // Message Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "মেসেজ লিখুন...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: AppTheme.white),
                      onPressed: () {},
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

  Widget _buildChatBubble(BuildContext context, String text, String sender, String time, bool isMe, String level) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: level == "Champion" ? AppTheme.accentYellow : AppTheme.primaryBlue.withOpacity(0.2),
              child: Icon(
                level == "Champion" ? Icons.verified_user : Icons.person,
                size: 20,
                color: level == "Champion" ? AppTheme.white : AppTheme.primaryBlue,
              ),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryBlue : AppTheme.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
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
                        _isAnonymous ? "অজ্ঞাত ব্যবহারকারী" : "$sender ($level)",
                        style: TextStyle(
                          fontSize: 12,
                          color: level == "Champion" ? AppTheme.accentOrange : AppTheme.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    text,
                    style: TextStyle(
                      color: isMe ? AppTheme.white : AppTheme.textColor,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? AppTheme.white.withOpacity(0.7) : AppTheme.textLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
              child: const Icon(Icons.person, size: 20, color: AppTheme.primaryGreen),
            ),
        ],
      ),
    );
  }
}
