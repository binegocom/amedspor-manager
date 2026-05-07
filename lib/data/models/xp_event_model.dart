import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class XpEventModel extends Equatable {
  final String id;
  final String userId;
  final int amount;
  final String reason;
  final String eventType;
  final String sourceType;
  final String sourceId;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const XpEventModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.eventType,
    required this.sourceType,
    required this.sourceId,
    required this.createdAt,
    this.metadata = const {},
  });

  factory XpEventModel.fromMap(String id, Map<String, dynamic> map) {
    return XpEventModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: map['amount'] ?? 0,
      reason: map['reason'] ?? '',
      eventType: map['eventType'] ?? '',
      sourceType: map['sourceType'] ?? '',
      sourceId: map['sourceId'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'reason': reason,
      'eventType': eventType,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        reason,
        eventType,
        sourceType,
        sourceId,
        createdAt,
        metadata,
      ];
}
