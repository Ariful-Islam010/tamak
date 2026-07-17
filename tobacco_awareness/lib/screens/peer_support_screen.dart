import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../providers/chat_provider.dart';

class PeerSupportScreen extends StatefulWidget {
  const PeerSupportScreen({super.key});

  @override
  State<PeerSupportScreen> createState() => _PeerSupportScreenState();
}

class _PeerSupportScreenState extends State<PeerSupportScreen> {
  bool _isAnonymous = false;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final user = context.read<AuthService>().currentUser;
    final userName = user?.displayName ?? "ব্যবহারকারী";
    final text = _messageController.text;

    _messageController.clear();
    _scrollToBottom();

    try {
      await context.read<ChatProvider>().sendMessage(text, userName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("মেসেজ পাঠাতে ব্যর্থ হয়েছে: $e")),
        );
      }
    }
  }

  Future<void> _pickAndSendImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ছবি আপলোড ও পাঠানো হচ্ছে...")),
        );
      }

      if (!mounted) return;
      final user = context.read<AuthService>().currentUser;
      final userName = user?.displayName ?? "ব্যবহারকারী";

      await context.read<ChatProvider>().sendImage(File(pickedFile.path), userName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("ছবি পাঠাতে ব্যর্থ হয়েছে: $e")),
        );
      }
    }
  }

  void _scrollToBottom() {
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
    // Scroll to bottom when screen loads or updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("সহায়তা গ্রুপ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("অনলাইন গ্রুপ চ্যাট", style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70)),
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
                activeThumbColor: AppTheme.accentYellow,
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
          // Emergency Help Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundColor,
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
            child: Consumer2<ChatProvider, AuthService>(
              builder: (context, chatProvider, authService, child) {
                final messages = chatProvider.messages;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    String text = msg["text"] ?? "";
                    String sender = msg["sender"] ?? "ব্যবহারকারী";
                    String? senderPhoto = msg["senderPhoto"];
                    String? imageUrl = msg["imageUrl"];
                    bool isMe = msg["isMe"] ?? false;
                    bool isCounselor = msg["isCounselor"] ?? false;
                
                    if (isMe) {
                      final currentUser = authService.currentUser;
                      sender = currentUser?.displayName ?? "আমি";
                      senderPhoto = currentUser?.photoUrl;
                    }
                    
                    if (imageUrl != null && text.trim().isEmpty) {
                      text = "📷 একটি ছবি শেয়ার করেছেন";
                    }
                    
                    return _buildChatBubble(
                      context,
                      msg["id"],
                      text,
                      sender,
                      senderPhoto,
                      imageUrl,
                      msg["time"] ?? "",
                      isMe,
                      isCounselor,
                    );
                  },
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
                        color: AppTheme.cardBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, color: Colors.grey),
                            onPressed: _pickAndSendImage,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: const TextStyle(color: Color(0xFF111827)),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: "মেসেজ লিখুন...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey),
                                contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                              ),
                            ),
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

  Widget _buildChatBubble(
    BuildContext context, 
    dynamic messageId,
    String text, 
    String sender, 
    String? senderPhoto,
    String? imageUrl,
    String time, 
    bool isMe, 
    bool isCounselor
  ) {
    // WhatsApp light theme chat bubble colors
    final bubbleColor = isCounselor 
        ? const Color(0xFFFFF9C4) // Light yellow
        : (isMe ? const Color(0xFFDCF8C6) : Colors.white); // WhatsApp green / white
    
    final borderRadius = BorderRadius.only(
      topRight: isMe ? Radius.zero : const Radius.circular(12),
      topLeft: isMe ? const Radius.circular(12) : Radius.zero,
      bottomLeft: const Radius.circular(12),
      bottomRight: const Radius.circular(12),
    );

    final isOnlyImage = imageUrl != null && (text.isEmpty || text == "📷 একটি ছবি শেয়ার করেছেন");

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
              backgroundImage: senderPhoto != null ? NetworkImage(senderPhoto) : null,
              child: senderPhoto == null
                  ? Icon(
                      isCounselor ? Icons.verified_user : Icons.person,
                      size: 20,
                      color: isCounselor ? Colors.white : Colors.grey.shade600,
                    )
                  : null,
            ),
          if (!isMe) const SizedBox(width: 6),
          
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                _showMessageOptions(context, messageId, text, isMe, imageUrl);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side tail (Received message)
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: CustomPaint(
                        size: const Size(6, 10),
                        painter: BubbleTailPainter(isMe: false, color: bubbleColor),
                      ),
                    ),
                  
                  Flexible(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: isMe ? 50 : 0,
                        right: isMe ? 0 : 50,
                      ),
                      padding: isOnlyImage 
                          ? const EdgeInsets.all(3) 
                          : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: borderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            offset: const Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: isOnlyImage
                          ? Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    imageUrl,
                                    height: 250,
                                    width: 250,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 250,
                                        width: 250,
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                // Time & done icon overlay on bottom right
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          time,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.done_all,
                                            size: 14,
                                            color: Colors.lightBlueAccent,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
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
                                
                                if (imageUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6, top: 4),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            height: 150,
                                            width: double.infinity,
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
              
                                if (text.isNotEmpty && text != "📷 একটি ছবি শেয়ার করেছেন")
                                  Text(
                                    text,
                                    style: const TextStyle(
                                      color: Colors.black87,
                                      fontSize: 15,
                                    ),
                                  ),
                                const SizedBox(height: 4),
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
                                      if (isMe) const Icon(Icons.done_all, size: 16, color: Colors.blue), // Read receipt
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  
                  // Right side tail (Sent message)
                  if (isMe)
                    Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: CustomPaint(
                        size: const Size(6, 10),
                        painter: BubbleTailPainter(isMe: true, color: bubbleColor),
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

  void _showMessageOptions(BuildContext context, dynamic messageId, String text, bool isMe, String? imageUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (text.isNotEmpty && text != "📷 একটি ছবি শেয়ার করেছেন")
                ListTile(
                  leading: const Icon(Icons.copy_rounded, color: Color(0xFF075E54)),
                  title: const Text("কপি করুন", style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("মেসেজ কপি করা হয়েছে!")),
                    );
                  },
                ),
              if (isMe && imageUrl == null)
                ListTile(
                  leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                  title: const Text("সম্পাদনা করুন (Edit)", style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditMessageDialog(context, messageId, text);
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.red),
                  title: const Text("ডিলিট করুন", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeleteMessage(context, messageId);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showEditMessageDialog(BuildContext context, dynamic messageId, String oldText) {
    final editController = TextEditingController(text: oldText);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("মেসেজ সম্পাদনা করুন", style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: editController,
            maxLines: null,
            style: const TextStyle(color: Colors.black87),
            decoration: const InputDecoration(
              hintText: "নতুন মেসেজ...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("বাতিল", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newText = editController.text.trim();
                if (newText.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await context.read<ChatProvider>().editMessage(messageId, newText);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("মেসেজ সফলভাবে আপডেট করা হয়েছে!")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("সম্পাদনা করতে সমস্যা হয়েছে: $e")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF075E54)),
              child: const Text("সংরক্ষণ করুন", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteMessage(BuildContext context, dynamic messageId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("মেসেজ ডিলিট করবেন?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text("এই মেসেজটি গ্রুপ চ্যাট থেকে চিরতরে ডিলিট হয়ে যাবে।"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("বাতিল", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await context.read<ChatProvider>().deleteMessage(messageId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("মেসেজটি ডিলিট করা হয়েছে!")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("ডিলিট করতে সমস্যা হয়েছে: $e")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("ডিলিট করুন", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

class BubbleTailPainter extends CustomPainter {
  final bool isMe;
  final Color color;

  BubbleTailPainter({required this.isMe, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isMe) {
      // Triangle for right side (Sent message tail)
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
      path.close();
    } else {
      // Triangle for left side (Received message tail)
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(size.width, size.height);
      path.close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
