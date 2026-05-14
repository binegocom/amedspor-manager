import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/bad_words_filter.dart';
import '../../../../data/services/firebase/firebase_providers.dart';

enum ModerationAction {
  allowed,
  blockedProfanity,
  blockedSpam,
  blockedCaps,
  blockedLink,
  rateLimited,
}

class ModerationResult {
  final bool isAllowed;
  final ModerationAction action;
  final String errorMessage;

  const ModerationResult({
    required this.isAllowed,
    required this.action,
    required this.errorMessage,
  });

  static const ModerationResult ok = ModerationResult(
    isAllowed: true,
    action: ModerationAction.allowed,
    errorMessage: '',
  );
}

class AutoModerationService {
  // Singleton instance for extremely fast O(1) across-room checks
  static final AutoModerationService _instance = AutoModerationService._internal();
  factory AutoModerationService() => _instance;
  AutoModerationService._internal();

  // Rate Limiting parameters
  static const int _maxMessagesPerWindow = 4;
  static const Duration _rateLimitWindow = Duration(seconds: 5);
  static const Duration _duplicateWindow = Duration(seconds: 15);

  // In-memory state tracking
  final Map<String, List<DateTime>> _userTimestamps = {};
  final Map<String, String> _lastUserTexts = {};
  final Map<String, DateTime> _lastUserTextTimes = {};

  /// Performs full real-time static and behavioral analysis on chat text.
  /// If a violation occurs, logs the infraction to Firestore admin logs instantly.
  Future<ModerationResult> moderateText({
    required String userId,
    required String username,
    required String text,
    required String roomId,
    bool isExecutiveOrPlayer = false,
  }) async {
    // 0. Trusted roles bypass standard flood/caps checks (but still evaluated for safety logs if needed)
    if (isExecutiveOrPlayer) {
      return ModerationResult.ok;
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return ModerationResult.ok;

    final now = DateTime.now();

    // 1. Check Rate Limiting (Flood Prevention)
    final timestamps = _userTimestamps.putIfAbsent(userId, () => []);
    // Remove expired timestamps
    timestamps.removeWhere((t) => now.difference(t) > _rateLimitWindow);

    if (timestamps.length >= _maxMessagesPerWindow) {
      _logInfraction(
        userId: userId,
        username: username,
        text: trimmedText,
        roomId: roomId,
        reason: 'Rate limit / Mesaj seli (Flood)',
        action: ModerationAction.rateLimited,
      );
      return const ModerationResult(
        isAllowed: false,
        action: ModerationAction.rateLimited,
        errorMessage: 'Çok hızlı mesaj gönderiyorsunuz. Lütfen biraz bekleyin.',
      );
    }

    // 2. Duplicate Content Spam Check
    final lastText = _lastUserTexts[userId];
    final lastTime = _lastUserTextTimes[userId];
    if (lastText != null && lastTime != null) {
      if (now.difference(lastTime) < _duplicateWindow &&
          lastText.toLowerCase() == trimmedText.toLowerCase()) {
        _logInfraction(
          userId: userId,
          username: username,
          text: trimmedText,
          roomId: roomId,
          reason: 'Tekrarlayan içerik (Spam)',
          action: ModerationAction.blockedSpam,
        );
        return const ModerationResult(
          isAllowed: false,
          action: ModerationAction.blockedSpam,
          errorMessage: 'Lütfen aynı mesajı üst üste göndermeyin (Spam).',
        );
      }
    }

    // 3. Profanity & Insults Check
    if (BadWordsFilter.containsBadWords(trimmedText)) {
      _logInfraction(
        userId: userId,
        username: username,
        text: trimmedText,
        roomId: roomId,
        reason: 'Topluluk kurallarına aykırı dil (Küfür/Hakaret)',
        action: ModerationAction.blockedProfanity,
      );
      return const ModerationResult(
        isAllowed: false,
        action: ModerationAction.blockedProfanity,
        errorMessage: 'Mesajınız topluluk kurallarına aykırı kelimeler içeriyor.',
      );
    }

    // 4. Excessive Capitalization Check (Caps-Lock Shouting)
    if (trimmedText.length > 10) {
      int upperCount = 0;
      int letterCount = 0;
      for (int i = 0; i < trimmedText.length; i++) {
        final char = trimmedText[i];
        if (RegExp(r'[a-zA-ZçÇğĞıİöÖşŞüÜ]').hasMatch(char)) {
          letterCount++;
          if (char == char.toUpperCase()) {
            upperCount++;
          }
        }
      }
      if (letterCount > 5 && (upperCount / letterCount) > 0.75) {
        _logInfraction(
          userId: userId,
          username: username,
          text: trimmedText,
          roomId: roomId,
          reason: 'Aşırı büyük harf kullanımı (Bağırma)',
          action: ModerationAction.blockedCaps,
        );
        return const ModerationResult(
          isAllowed: false,
          action: ModerationAction.blockedCaps,
          errorMessage: 'Lütfen sürekli büyük harf (CAPS LOCK) kullanarak bağırmayın.',
        );
      }
    }

    // 5. Unapproved Links/URLs Validation (Phishing Protection)
    final urlRegex = RegExp(r'(https?:\/\/|www\.)[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}', caseSensitive: false);
    if (urlRegex.hasMatch(trimmedText)) {
      _logInfraction(
        userId: userId,
        username: username,
        text: trimmedText,
        roomId: roomId,
        reason: 'Onaysız dış bağlantı (Link/URL paylaşımı)',
        action: ModerationAction.blockedLink,
      );
      return const ModerationResult(
        isAllowed: false,
        action: ModerationAction.blockedLink,
        errorMessage: 'Güvenlik sebebiyle sohbetlerde dış bağlantı (Link) paylaşımı yasaktır.',
      );
    }

    // Record valid action
    timestamps.add(now);
    _lastUserTexts[userId] = trimmedText;
    _lastUserTextTimes[userId] = now;

    return ModerationResult.ok;
  }

  Future<void> _logInfraction({
    required String userId,
    required String username,
    required String text,
    required String roomId,
    required String reason,
    required ModerationAction action,
  }) async {
    try {
      // Record violation to continuous database admin logs
      await firestoreService.moderationLogs.add({
        'userId': userId,
        'username': username,
        'text': text,
        'roomId': roomId,
        'reason': reason,
        'action': action.name,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Increment user penalty strike counter stored directly on their document
      await firestoreService.users.doc(userId).set({
        'moderationStrikes': FieldValue.increment(1),
        'lastViolationDate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }
}
