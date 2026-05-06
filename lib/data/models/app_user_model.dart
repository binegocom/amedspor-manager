import 'package:cloud_firestore/cloud_firestore.dart';

class AppUserModel {
  final String id;
  final String username;
  final String email;
  final String avatarUrl;
  final int points;
  final List<String> badges;
  final DateTime createdAt;
  final String city;
  final String supportYear;
  final String role;
  final String? fcmToken;

  const AppUserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarUrl,
    required this.points,
    required this.badges,
    required this.createdAt,
    required this.city,
    required this.supportYear,
    required this.role,
    this.fcmToken,
  });

  factory AppUserModel.fromMap(String id, Map<String, dynamic> map) {
    return AppUserModel(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      points: map['points'] ?? 0,
      badges: (map['badges'] as List?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: _parseDate(map['createdAt']),
      city: map['city'] ?? '',
      supportYear: map['supportYear'] ?? '2024',
      role: map['role'] ?? 'user',
      fcmToken: map['fcmToken'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'avatarUrl': avatarUrl,
      'points': points,
      'badges': badges,
      'createdAt': createdAt.toIso8601String(),
      'city': city,
      'supportYear': supportYear,
      'role': role,
      if (fcmToken != null) 'fcmToken': fcmToken,
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
}
