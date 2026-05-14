/// Riverpod providers for Firebase services, repositories, and auth state.
///
/// This file replaces the old global singletons in firebase_providers.dart
/// with proper Riverpod dependency injection. Old globals remain functional
/// during incremental migration — screens can adopt Riverpod one at a time.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/app_user_model.dart';
import '../../data/models/match_model.dart';
import '../../data/models/player_model.dart';
import '../../data/services/firebase/auth_service.dart';
import '../../data/services/firebase/firestore_service.dart';
import '../../data/services/firebase/storage_service.dart';
import '../../data/services/firebase/fcm_service.dart';
import '../../data/services/local/app_state_service.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/lineup_repository.dart';
import '../../data/repositories/prediction_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/report_repository.dart';
import '../../data/repositories/gamification_repository.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/search_repository.dart';
import '../../data/repositories/block_repository.dart';
import '../../data/repositories/question_repository.dart';
import '../../data/repositories/error_report_repository.dart';
import '../../data/repositories/audit_log_repository.dart';

// ─── Firebase Instance Providers ────────────────────────────────────────────

final firestoreInstanceProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);

final firebaseAuthInstanceProvider = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);

final firebaseStorageInstanceProvider = Provider<FirebaseStorage>(
  (_) => FirebaseStorage.instance,
);

final firebaseMessagingInstanceProvider = Provider<FirebaseMessaging>(
  (_) => FirebaseMessaging.instance,
);

// ─── Service Providers ──────────────────────────────────────────────────────

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(ref.watch(firestoreInstanceProvider)),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(firebaseAuthInstanceProvider)),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(ref.watch(firebaseStorageInstanceProvider)),
);

final fcmServiceProvider = Provider<FcmService>(
  (ref) => FcmService(ref.watch(firebaseMessagingInstanceProvider)),
);

final appStateServiceProvider = Provider<AppStateService>(
  (_) => AppStateService(),
);

// ─── Auth State Providers ───────────────────────────────────────────────────

/// Streams Firebase Auth state changes (login/logout).
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

/// Fetches the full AppUserModel for the currently authenticated user.
/// Returns null if not logged in or user document doesn't exist.
final currentUserProvider = FutureProvider<AppUserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  final repo = ref.watch(userRepositoryProvider);
  return repo.getUser(user.uid);
});

// ─── Repository Providers ───────────────────────────────────────────────────

final userRepositoryProvider = Provider<UserRepository>(
  (_) => UserRepository(),
);

final postRepositoryProvider = Provider<PostRepository>(
  (_) => PostRepository(),
);

final matchRepositoryProvider = Provider<MatchRepository>(
  (_) => MatchRepository(),
);

final lineupRepositoryProvider = Provider<LineupRepository>(
  (_) => LineupRepository(),
);

final predictionRepositoryProvider = Provider<PredictionRepository>(
  (_) => PredictionRepository(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (_) => NotificationRepository(),
);

final chatRepositoryProvider = Provider<ChatRepository>(
  (_) => ChatRepository(),
);

final reportRepositoryProvider = Provider<ReportRepository>(
  (_) => ReportRepository(),
);

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (_) => GamificationRepository(),
);

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (_) => FeedbackRepository(),
);

final playerRepositoryProvider = Provider<PlayerRepository>(
  (_) => PlayerRepository(),
);

final searchRepositoryProvider = Provider<SearchRepository>(
  (_) => SearchRepository(),
);

final blockRepositoryProvider = Provider<BlockRepository>(
  (_) => BlockRepository(),
);

final questionRepositoryProvider = Provider<QuestionRepository>(
  (_) => QuestionRepository(),
);

final errorReportRepositoryProvider = Provider<ErrorReportRepository>(
  (_) => ErrorReportRepository(),
);

final auditLogRepositoryProvider = Provider<AuditLogRepository>(
  (_) => AuditLogRepository(),
);

// ─── Cached Providers for Performance ───────────────────────────────────────

/// Cached match list to avoid redundant Firestore reads
final matchesCacheProvider = Provider.autoDispose<List<MatchModel>>(
  (ref) => [],
);

/// Cached player list
final playersCacheProvider = Provider.autoDispose<List<PlayerModel>>(
  (ref) => [],
);
