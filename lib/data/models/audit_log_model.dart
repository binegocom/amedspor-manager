import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String adminId;
  final String adminEmail;
  final String action;
  final String targetType;
  final String targetId;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime createdAt;
  final String platform;

  const AuditLogModel({
    required this.id,
    required this.adminId,
    required this.adminEmail,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.before,
    this.after,
    required this.createdAt,
    required this.platform,
  });

  factory AuditLogModel.fromMap(String id, Map<String, dynamic> map) {
    return AuditLogModel(
      id: id,
      adminId: map['adminId'] ?? '',
      adminEmail: map['adminEmail'] ?? '',
      action: map['action'] ?? '',
      targetType: map['targetType'] ?? '',
      targetId: map['targetId'] ?? '',
      before: map['before'] as Map<String, dynamic>?,
      after: map['after'] as Map<String, dynamic>?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      platform: map['platform'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminEmail': adminEmail,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      if (before != null) 'before': before,
      if (after != null) 'after': after,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': platform,
    };
  }
}
