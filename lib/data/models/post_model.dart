import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String username;
  final String title;
  final String content;
  final String category;
  final int likes;
  final int commentsCount;
  final String lineupId;
  final String? imageUrl;
  final bool hidden;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.title,
    required this.content,
    required this.category,
    required this.likes,
    required this.commentsCount,
    required this.lineupId,
    this.imageUrl,
    this.hidden = false,
    required this.createdAt,
  });

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      userId: map['userId'] ?? '',
      username: map['username'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? '',
      likes: map['likes'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      lineupId: map['lineupId'] ?? '',
      imageUrl: map['imageUrl'] as String?,
      hidden: map['hidden'] ?? false,
      createdAt: _parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'title': title,
      'content': content,
      'category': category,
      'likes': likes,
      'commentsCount': commentsCount,
      'lineupId': lineupId,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'hidden': hidden,
      'createdAt': createdAt.toIso8601String(),
    };
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

  PostModel copyWith({
    String? id,
    String? userId,
    String? username,
    String? title,
    String? content,
    String? category,
    int? likes,
    int? commentsCount,
    String? lineupId,
    String? imageUrl,
    bool? hidden,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      likes: likes ?? this.likes,
      commentsCount: commentsCount ?? this.commentsCount,
      lineupId: lineupId ?? this.lineupId,
      imageUrl: imageUrl ?? this.imageUrl,
      hidden: hidden ?? this.hidden,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
