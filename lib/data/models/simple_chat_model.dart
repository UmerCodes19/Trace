// lib/data/models/simple_chat_model.dart
import 'dart:convert';

class SimpleChatModel {
  final String id;
  final String postId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final String status;
  final DateTime createdAt;
  final String? otherUserName;
  final String? otherUserAvatar;
  final String? postTitle;

  SimpleChatModel({
    required this.id,
    required this.postId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.status = 'active',
    required this.createdAt,
    this.otherUserName,
    this.otherUserAvatar,
    this.postTitle,
  });

  factory SimpleChatModel.fromMap(Map<String, dynamic> map) {
    return SimpleChatModel(
      id: map['id']?.toString() ?? '',
      postId: map['postId']?.toString() ?? '',
      participants: map['participants'] is String
          ? (jsonDecode(map['participants']) as List).cast<String>()
          : (map['participants'] as List?)?.cast<String>() ?? [],
      lastMessage: map['lastMessage'] as String? ?? '',
      lastMessageTime: DateTime.fromMillisecondsSinceEpoch(
        map['lastMessageTime'] as int? ?? map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      unreadCount: map['unreadCount'] is String
          ? (jsonDecode(map['unreadCount']) as Map).cast<String, int>()
          : (map['unreadCount'] as Map?)?.cast<String, int>() ?? {},
      status: map['status'] as String? ?? 'active',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      otherUserName: map['otherUserName'] as String?,
      otherUserAvatar: map['otherUserAvatar'] as String?,
      postTitle: map['postTitle'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'otherUserName': otherUserName,
      'otherUserAvatar': otherUserAvatar,
      'postTitle': postTitle,
    };
  }
}

class SimpleMessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final DateTime timestamp;
  final bool isRead;
  final String status;

  SimpleMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.timestamp,
    this.isRead = false,
    this.status = 'sent',
  });

  factory SimpleMessageModel.fromMap(Map<String, dynamic> map) {
    return SimpleMessageModel(
      id: map['id']?.toString() ?? '',
      chatId: map['chatId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        map['timestamp'] is String 
            ? DateTime.parse(map['timestamp']).millisecondsSinceEpoch
            : (map['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      ),
      isRead: map['isRead'] == true || map['isRead'] == 1,
      status: map['status'] as String? ?? 'sent',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead ? 1 : 0,
      'status': status,
    };
  }

  SimpleMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? text,
    String? imageUrl,
    DateTime? timestamp,
    bool? isRead,
    String? status,
  }) {
    return SimpleMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }
}