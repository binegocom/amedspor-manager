import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class XpEventModel extends Equatable {
  final String id;
  final String userId;
  final int amount;
  final int pointsAmount;
  final String reason;
  final String eventType;
  final String sourceType;
  final String sourceId;
  final String seasonId;
  final String dedupeKey;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const XpEventModel({
    required this.id,
    required this.userId,
    required this.amount,
    this.pointsAmount = 0,
    required this.reason,
    required this.eventType,
    required this.sourceType,
    required this.sourceId,
    this.seasonId = 'global',
    this.dedupeKey = '',
    required this.createdAt,
    this.metadata = const {},
  });

  factory XpEventModel.fromMap(String id, Map<String, dynamic> map) {
    return XpEventModel(
      id: id,
      userId: map['userId'] ?? '',
      amount: map['amount'] ?? 0,
      pointsAmount: map['pointsAmount'] ?? 0,
      reason: map['reason'] ?? '',
      eventType: map['eventType'] ?? '',
      sourceType: map['sourceType'] ?? '',
      sourceId: map['sourceId'] ?? '',
      seasonId: map['seasonId'] ?? 'global',
      dedupeKey: map['dedupeKey'] ?? '',
      createdAt: _parseDate(map['createdAt']),
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'pointsAmount': pointsAmount,
      'reason': reason,
      'eventType': eventType,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'seasonId': seasonId,
      if (dedupeKey.isNotEmpty) 'dedupeKey': dedupeKey,
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
    pointsAmount,
    reason,
    eventType,
    sourceType,
    sourceId,
    seasonId,
    dedupeKey,
    createdAt,
    metadata,
  ];
}
