import 'package:amedspor_app/data/models/app_user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUserModel', () {
    test('serializes all profile fields used by profile setup', () {
      final createdAt = DateTime.utc(2026, 5, 5);
      final user = AppUserModel(
        id: 'user_1',
        username: 'amedli',
        email: 'user@example.com',
        avatarUrl: 'https://example.com/avatar.jpg',
        points: 12,
        badges: const ['Yeni Taraftar'],
        createdAt: createdAt,
        city: 'Diyarbakir',
        supportYear: '2024',
        role: 'user',
        fcmToken: 'fcm-token',
      );

      expect(user.toMap(), {
        'username': 'amedli',
        'email': 'user@example.com',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'points': 12,
        'badges': ['Yeni Taraftar'],
        'createdAt': createdAt.toIso8601String(),
        'city': 'Diyarbakir',
        'supportYear': '2024',
        'role': 'user',
        'fcmToken': 'fcm-token',
      });
    });

    test('uses defaults for optional Firestore fields', () {
      final user = AppUserModel.fromMap('user_2', const {'username': 'guest'});

      expect(user.id, 'user_2');
      expect(user.username, 'guest');
      expect(user.email, isEmpty);
      expect(user.avatarUrl, isEmpty);
      expect(user.points, 0);
      expect(user.badges, isEmpty);
      expect(user.city, isEmpty);
      expect(user.supportYear, '2024');
      expect(user.role, 'user');
      expect(user.fcmToken, isNull);
    });
  });
}
