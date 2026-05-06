import 'package:cloud_firestore/cloud_firestore.dart';

class UserFeedbackModel {
  final String id;
  final String userId;
  final String email;
  final String type; // bug, suggestion, account, other
  final String message;
  final String? screenshotUrl;
  final String platform;
  final String appVersion;
  final String status; // open, reviewing, resolved, rejected
  final DateTime createdAt;

  const UserFeedbackModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.type,
    required this.message,
    this.screenshotUrl,
    required this.platform,
    required this.appVersion,
    this.status = 'open',
    required this.createdAt,
  });

  factory UserFeedbackModel.fromMap(String id, Map<String, dynamic> map) {
    return UserFeedbackModel(
      id: id,
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      type: map['type'] ?? 'bug',
      message: map['message'] ?? '',
      screenshotUrl: map['screenshotUrl'] as String?,
      platform: map['platform'] ?? '',
      appVersion: map['appVersion'] ?? '',
      status: map['status'] ?? 'open',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'type': type,
      'message': message,
      'screenshotUrl': screenshotUrl,
      'platform': platform,
      'appVersion': appVersion,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
