class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String targetRoute;
  final bool read;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.targetRoute,
    required this.read,
    required this.createdAt,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) {
    return NotificationModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      targetRoute: map['targetRoute'] ?? '/notifications',
      read: map['read'] ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'targetRoute': targetRoute,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}