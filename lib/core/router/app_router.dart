import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/firebase/firebase_providers.dart';

import '../../features/admin/presentation/screens/admin_chat_rooms_screen.dart';
import '../../features/admin/presentation/screens/admin_create_match_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_matches_screen.dart';
import '../../features/admin/presentation/screens/admin_posts_screen.dart';
import '../../features/admin/presentation/screens/admin_predictions_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/admin_send_notification_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';

import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';

import '../../features/chat/presentation/screens/chat_screen.dart';

import '../../features/feed/presentation/screens/create_post_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/post_detail_screen.dart';

import '../../features/home/presentation/screens/home_screen.dart';

import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';

import '../../features/lineup/presentation/screens/lineup_builder_screen.dart';
import '../../features/lineup/presentation/screens/my_lineups_screen.dart';

import '../../features/matches/presentation/screens/matches_screen.dart';

import '../../features/moderation/presentation/screens/admin_moderation_screen.dart';
import '../../features/moderation/presentation/screens/report_screen.dart';
import '../../features/moderation/presentation/screens/reports_screen.dart';

import '../../features/notifications/presentation/screens/notifications_screen.dart';

import '../../features/onboarding/presentation/screens/onboarding_screen.dart';

import '../../features/prediction/presentation/screens/my_predictions_screen.dart';
import '../../features/prediction/presentation/screens/prediction_screen.dart';

import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/public_user_profile_screen.dart';

import '../../features/search/presentation/screens/search_screen.dart';

import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/policy_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

import '../../features/splash/presentation/screens/splash_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: SplashScreen.routePath,
  redirect: (context, state) async {
    final bool isAdminRoute = state.matchedLocation.startsWith('/admin');
    if (!isAdminRoute) return null;

    final user = authService.currentUser;
    if (user == null) {
      return LoginScreen.routePath;
    }

    try {
      // Kullanıcı rolünü Firestore'dan kontrol et
      final doc = await firestoreService.users.doc(user.uid).get();
      final role = doc.data()?['role'];

      final bool hasAccess = role == 'admin' || role == 'moderator';

      if (!hasAccess) {
        return '/'; // Yetkisizse ana sayfaya yönlendir
      }
    } catch (e) {
      return LoginScreen.routePath;
    }

    return null;
  },
  routes: [
    /// Splash
    GoRoute(
      path: SplashScreen.routePath,
      builder: (context, state) => const SplashScreen(),
    ),

    /// Onboarding
    GoRoute(
      path: OnboardingScreen.routePath,
      builder: (context, state) => const OnboardingScreen(),
    ),

    /// Login
    GoRoute(
      path: LoginScreen.routePath,
      builder: (context, state) => const LoginScreen(),
    ),

    /// Profile Setup
    GoRoute(
      path: ProfileSetupScreen.routePath,
      builder: (context, state) => const ProfileSetupScreen(),
    ),

    /// Home
    GoRoute(
      path: HomeScreen.routePath,
      builder: (context, state) => const HomeScreen(),
    ),

    /// Matches
    GoRoute(
      path: MatchesScreen.routePath,
      builder: (context, state) => const MatchesScreen(),
    ),

    /// Lineup Builder
    GoRoute(
      path: LineupBuilderScreen.routePath,
      builder: (context, state) {
        final matchId = state.pathParameters['matchId'] ?? 'match_001';
        return LineupBuilderScreen(matchId: matchId);
      },
    ),

    /// My Lineups
    GoRoute(
      path: MyLineupsScreen.routePath,
      builder: (context, state) => const MyLineupsScreen(),
    ),

    /// Chat
    GoRoute(
      path: ChatScreen.routePath,
      builder: (context, state) {
        final roomId = state.pathParameters['roomId'] ?? 'general';
        return ChatScreen(roomId: roomId);
      },
    ),

    /// Prediction
    GoRoute(
      path: PredictionScreen.routePath,
      builder: (context, state) {
        final matchId = state.pathParameters['matchId'] ?? 'match_001';
        return PredictionScreen(matchId: matchId);
      },
    ),

    /// My Predictions
    GoRoute(
      path: MyPredictionsScreen.routePath,
      builder: (context, state) => const MyPredictionsScreen(),
    ),

    /// Profile
    GoRoute(
      path: ProfileScreen.routePath,
      builder: (context, state) => const ProfileScreen(),
    ),

    /// Public User Profile
    GoRoute(
      path: PublicUserProfileScreen.routePath,
      builder: (context, state) {
        final userId = state.pathParameters['userId'] ?? 'user_001';
        return PublicUserProfileScreen(userId: userId);
      },
    ),

    /// Notifications
    GoRoute(
      path: NotificationsScreen.routePath,
      builder: (context, state) => const NotificationsScreen(),
    ),

    /// Settings
    GoRoute(
      path: SettingsScreen.routePath,
      builder: (context, state) => const SettingsScreen(),
    ),

    /// Feed
    GoRoute(
      path: FeedScreen.routePath,
      builder: (context, state) => const FeedScreen(),
    ),

    /// Create Post
    GoRoute(
      path: CreatePostScreen.routePath,
      builder: (context, state) => const CreatePostScreen(),
    ),

    /// Post Detail
    GoRoute(
      path: PostDetailScreen.routePath,
      builder: (context, state) {
        final postId = state.pathParameters['postId'] ?? 'post_001';
        return PostDetailScreen(postId: postId);
      },
    ),

    /// Search
    GoRoute(
      path: SearchScreen.routePath,
      builder: (context, state) => const SearchScreen(),
    ),

    /// Leaderboard
    GoRoute(
      path: LeaderboardScreen.routePath,
      builder: (context, state) => const LeaderboardScreen(),
    ),

    /// Report
    GoRoute(
      path: ReportScreen.routePath,
      builder: (context, state) {
        final type = state.pathParameters['type'] ?? 'post';
        final id = state.pathParameters['id'] ?? 'unknown';

        return ReportScreen(type: type, id: id);
      },
    ),

    /// Reports
    GoRoute(
      path: ReportsScreen.routePath,
      builder: (context, state) => const ReportsScreen(),
    ),

    /// Policy
    GoRoute(
      path: PolicyScreen.routePath,
      builder: (context, state) => const PolicyScreen(),
    ),

    /// About
    GoRoute(
      path: AboutScreen.routePath,
      builder: (context, state) => const AboutScreen(),
    ),

    /// Admin Moderation
    GoRoute(
      path: AdminModerationScreen.routePath,
      builder: (context, state) => const AdminModerationScreen(),
    ),

    /// Admin Dashboard
    GoRoute(
      path: AdminDashboardScreen.routePath,
      builder: (context, state) => const AdminDashboardScreen(),
    ),

    /// Admin Matches
    GoRoute(
      path: AdminMatchesScreen.routePath,
      builder: (context, state) => const AdminMatchesScreen(),
    ),

    /// Admin Create Match
    GoRoute(
      path: AdminCreateMatchScreen.routePath,
      builder: (context, state) => const AdminCreateMatchScreen(),
    ),

    /// Admin Edit Match
    GoRoute(
      path: AdminCreateMatchScreen.editRoutePath,
      builder: (context, state) {
        final matchId = state.pathParameters['matchId'] ?? '';
        return AdminCreateMatchScreen(matchId: matchId);
      },
    ),

    /// Admin Users
    GoRoute(
      path: AdminUsersScreen.routePath,
      builder: (context, state) => const AdminUsersScreen(),
    ),

    /// Admin Posts
    GoRoute(
      path: AdminPostsScreen.routePath,
      builder: (context, state) => const AdminPostsScreen(),
    ),

    /// Admin Reports
    GoRoute(
      path: AdminReportsScreen.routePath,
      builder: (context, state) => const AdminReportsScreen(),
    ),

    /// Admin Notifications
    GoRoute(
      path: AdminSendNotificationScreen.routePath,
      builder: (context, state) => const AdminSendNotificationScreen(),
    ),

    /// Admin Chat Rooms
    GoRoute(
      path: AdminChatRoomsScreen.routePath,
      builder: (context, state) => const AdminChatRoomsScreen(),
    ),

    /// Admin Predictions
    GoRoute(
      path: AdminPredictionsScreen.routePath,
      builder: (context, state) => const AdminPredictionsScreen(),
    ),

    /// Admin Settings
    GoRoute(
      path: AdminSettingsScreen.routePath,
      builder: (context, state) => const AdminSettingsScreen(),
    ),
  ],
);
