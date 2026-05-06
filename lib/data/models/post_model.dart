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
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
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
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
