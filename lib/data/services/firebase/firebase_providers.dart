// Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Services
import 'auth_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';
import 'fcm_service.dart';
import 'push_navigation_service.dart';
import 'foreground_notification_service.dart';
import 'seed_service.dart';
import '../local/app_state_service.dart';
import '../../repositories/user_repository.dart';

final authService = AuthService(FirebaseAuth.instance);

final firestoreService = FirestoreService(FirebaseFirestore.instance);

final storageService = StorageService(FirebaseStorage.instance);

final fcmService = FcmService(FirebaseMessaging.instance);

final pushNavigationService = PushNavigationService();

final foregroundNotificationService = ForegroundNotificationService();

final seedService = SeedService(FirebaseFirestore.instance);

final appStateService = AppStateService();

final userRepository = UserRepository();
