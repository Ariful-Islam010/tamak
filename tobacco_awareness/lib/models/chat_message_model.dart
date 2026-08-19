class ChatMessageModel {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final String time;
  final String? type;
  final String? imageUrl;
  final bool isSystem;
  final String? replyToUser;
  final String? replyToText;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.time,
    this.type,
    this.imageUrl,
    this.isSystem = false,
    this.replyToUser,
    this.replyToText,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ChatMessageModel(
        id: '',
        userId: '',
        userName: 'Anonymous',
        text: '',
        time: '',
        createdAt: DateTime.now(),
      );
    }
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? json['userName']?.toString() ?? 'Anonymous',
      text: json['text']?.toString() ?? json['content']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      type: json['type']?.toString(),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      isSystem: json['is_system'] as bool? ?? json['isSystem'] as bool? ?? false,
      replyToUser: json['reply_to_user']?.toString() ?? json['replyToUser']?.toString(),
      replyToText: json['reply_to_text']?.toString() ?? json['replyToText']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'text': text,
      'time': time,
      'type': type,
      'image_url': imageUrl,
      'is_system': isSystem,
      'reply_to_user': replyToUser,
      'reply_to_text': replyToText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
