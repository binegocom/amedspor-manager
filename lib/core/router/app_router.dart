import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/firebase/firebase_providers.dart';

// Admin Screens
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
import '../../features/admin/presentation/screens/admin_players_screen.dart';
import '../../features/admin/presentation/screens/admin_live_match_screen.dart';

// Auth Screens
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';

// Feature Screens
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/feed/presentation/screens/create_post_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/post_detail_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/lineup/presentation/screens/lineup_builder_screen.dart';
import '../../features/lineup/presentation/screens/lineup_detail_screen.dart';
import '../../features/lineup/presentation/screens/my_lineups_screen.dart';
import '../../features/lineup/presentation/screens/top_lineups_screen.dart';
import '../../features/matches/presentation/screens/matches_screen.dart';
import '../../features/match/presentation/screens/live_match_center_screen.dart';
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

final List<String> authRequiredRoutes = [
  '/profile-setup',
  '/lineups/me',
  '/predictions/me',
  '/create-post',
  '/profile',
  '/notifications',
  '/reports',
  '/settings',
];

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final bool isAdminRoute = state.matchedLocation.startsWith('/admin');
    final bool isAuthRequired = authRequiredRoutes.any((r) => state.matchedLocation.startsWith(r));
    final bool isLoginRoute = state.matchedLocation == '/login';
    final user = authService.currentUser;

    // Login screen protection (logged in users shouldn't see it)
    if (isLoginRoute && user != null) {
      return '/home';
    }

    // Admin Panel Protection
    if (isAdminRoute) {
      if (!kIsWeb) return '/home'; // Admin is Web-Only
      if (user == null) return '/login'; // Must be logged in

      try {
        final doc = await firestoreService.users.doc(user.uid).get();
        final role = doc.data()?['role'];
        if (role != 'admin' && role != 'moderator') {
          return '/home';
        }
      } catch (e) {
        return '/login';
      }
    }

    // Standard Auth Protection
    if (isAuthRequired && user == null) {
      return '/login';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/matches',
      builder: (context, state) => const MatchesScreen(),
    ),
    GoRoute(
      path: '/match-live/:matchId',
      builder: (context, state) => LiveMatchCenterScreen(
        matchId: state.pathParameters['matchId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/lineup/:matchId',
      builder: (context, state) => LineupBuilderScreen(
        matchId: state.pathParameters['matchId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/lineup-detail/:lineupId',
      builder: (context, state) => LineupDetailScreen(
        lineupId: state.pathParameters['lineupId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/lineups/top',
      builder: (context, state) => const TopLineupsScreen(),
    ),
    GoRoute(
      path: '/lineups/me',
      builder: (context, state) => const MyLineupsScreen(),
    ),
    GoRoute(
      path: '/prediction/:matchId',
      builder: (context, state) => PredictionScreen(
        matchId: state.pathParameters['matchId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/predictions/me',
      builder: (context, state) => const MyPredictionsScreen(),
    ),
    GoRoute(
      path: '/chat/:roomId',
      builder: (context, state) => ChatScreen(
        roomId: state.pathParameters['roomId'] ?? 'general',
      ),
    ),
    GoRoute(
      path: '/feed',
      builder: (context, state) => const FeedScreen(),
    ),
    GoRoute(
      path: '/create-post',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/post/:postId',
      builder: (context, state) => PostDetailScreen(
        postId: state.pathParameters['postId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) => PublicUserProfileScreen(
        userId: state.pathParameters['userId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/report/:targetType/:targetId',
      builder: (context, state) => ReportScreen(
        type: state.pathParameters['targetType'] ?? 'post',
        id: state.pathParameters['targetId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/policy',
      builder: (context, state) => const PolicyScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),

    // ADMIN ROUTES
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/matches',
      builder: (context, state) => const AdminMatchesScreen(),
    ),
    GoRoute(
      path: '/admin/matches/create',
      builder: (context, state) => const AdminCreateMatchScreen(),
    ),
    GoRoute(
      path: '/admin/matches/edit/:matchId',
      builder: (context, state) => AdminCreateMatchScreen(
        matchId: state.pathParameters['matchId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/admin/matches/live/:matchId',
      builder: (context, state) => AdminLiveMatchScreen(
        matchId: state.pathParameters['matchId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/admin/players',
      builder: (context, state) => const AdminPlayersScreen(),
    ),
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => const AdminUsersScreen(),
    ),
    GoRoute(
      path: '/admin/posts',
      builder: (context, state) => const AdminPostsScreen(),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const AdminReportsScreen(),
    ),
    GoRoute(
      path: '/admin/notifications',
      builder: (context, state) => const AdminSendNotificationScreen(),
    ),
    GoRoute(
      path: '/admin/chats',
      builder: (context, state) => const AdminChatRoomsScreen(),
    ),
    GoRoute(
      path: '/admin/predictions',
      builder: (context, state) => const AdminPredictionsScreen(),
    ),
    GoRoute(
      path: '/admin/settings',
      builder: (context, state) => const AdminSettingsScreen(),
    ),
  ],
);
