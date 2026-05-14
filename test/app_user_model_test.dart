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

      expect(
        user.toMap(),
        allOf([
          containsPair('username', 'amedli'),
          containsPair('email', 'user@example.com'),
          containsPair('avatarUrl', 'https://example.com/avatar.jpg'),
          containsPair('points', 12),
          containsPair('badges', ['Yeni Taraftar']),
          containsPair('createdAt', createdAt.toIso8601String()),
          containsPair('city', 'Diyarbakir'),
          containsPair('supportYear', '2024'),
          containsPair('role', 'user'),
          containsPair('disabled', false),
          containsPair('notificationPrefs', {
            'match': true,
            'matchStart': true,
            'goal': true,
            'lineup': true,
            'prediction': true,
            'chat': true,
            'comment': true,
            'like': true,
            'mission': true,
          }),
          containsPair('followersCount', 0),
          containsPair('followingCount', 0),
          containsPair('xp', 0),
          containsPair('level', 1),
          containsPair('levelTitle', 'Yeni Taraftar'),
          containsPair('badgesCount', 0),
          containsPair('missionsCompleted', 0),
          containsPair('currentLoginStreak', 0),
          containsPair('bestLoginStreak', 0),
          containsPair('seasonXp', 0),
          containsPair('seasonPoints', 0),
          containsPair('gamificationEnabled', true),
          containsPair('fcmToken', 'fcm-token'),
        ]),
      );
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
      expect(user.notificationPrefs['matchStart'], isTrue);
      expect(user.notificationPrefs['goal'], isTrue);
      expect(user.notificationPrefs['lineup'], isTrue);
      expect(user.notificationPrefs['prediction'], isTrue);
      expect(user.notificationPrefs['comment'], isTrue);
      expect(user.notificationPrefs['mission'], isTrue);
      expect(user.xp, 0);
      expect(user.level, 1);
      expect(user.levelTitle, 'Yeni Taraftar');
      expect(user.gamificationEnabled, isTrue);
    });
  });
}
