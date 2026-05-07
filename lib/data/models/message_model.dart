import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String userId;
  final String username;
  final String text;
  final int likes;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.likes,
    required this.createdAt,
  });

  factory MessageModel.fromMap(String id, Map<String, dynamic> map) {
    return MessageModel(
      id: id,
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      text: map['text'] ?? '',
      likes: map['likes'] ?? 0,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'text': text,
      'likes': likes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
