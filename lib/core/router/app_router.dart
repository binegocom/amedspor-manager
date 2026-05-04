import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  routes: [
    GoRoute(
      path: SplashScreen.routePath,
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: OnboardingScreen.routePath,
      builder: (context, state) => const OnboardingScreen(),
    ),

    GoRoute(
      path: HomeScreen.routePath,
      builder: (context, state) => const HomeScreen(),
    ),

    GoRoute(
      path: MatchesScreen.routePath,
      builder: (context, state) => const MatchesScreen(),
    ),

    GoRoute(
      path: LineupBuilderScreen.routePath,
      builder: (context, state) {
        final matchId = state.pathParameters['matchId'] ?? 'match_001';
        return LineupBuilderScreen(matchId: matchId);
      },
    ),

    GoRoute(
      path: MyLineupsScreen.routePath,
      builder: (context, state) => const MyLineupsScreen(),
    ),

    GoRoute(
      path: ChatScreen.routePath,
      builder: (context, state) {
        final roomId = state.pathParameters['roomId'] ?? 'general';
        return ChatScreen(roomId: roomId);
      },
    ),

    GoRoute(
      path: PredictionScreen.routePath,
      builder: (context, state) {
        final matchId = state.pathParameters['matchId'] ?? 'match_001';
        return PredictionScreen(matchId: matchId);
      },
    ),

    GoRoute(
      path: MyPredictionsScreen.routePath,
      builder: (context, state) => const MyPredictionsScreen(),
    ),

    GoRoute(
      path: ProfileScreen.routePath,
      builder: (context, state) => const ProfileScreen(),
    ),

    GoRoute(
      path: PublicUserProfileScreen.routePath,
      builder: (context, state) {
        final userId = state.pathParameters['userId'] ?? 'user_001';
        return PublicUserProfileScreen(userId: userId);
      },
    ),

    GoRoute(
      path: NotificationsScreen.routePath,
      builder: (context, state) => const NotificationsScreen(),
    ),

    GoRoute(
      path: LoginScreen.routePath,
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: ProfileSetupScreen.routePath,
      builder: (context, state) => const ProfileSetupScreen(),
    ),

    GoRoute(
      path: SettingsScreen.routePath,
      builder: (context, state) => const SettingsScreen(),
    ),

    GoRoute(
      path: FeedScreen.routePath,
      builder: (context, state) => const FeedScreen(),
    ),

    GoRoute(
      path: CreatePostScreen.routePath,
      builder: (context, state) => const CreatePostScreen(),
    ),

    GoRoute(
      path: PostDetailScreen.routePath,
      builder: (context, state) {
        final postId = state.pathParameters['postId'] ?? 'post_001';
        return PostDetailScreen(postId: postId);
      },
    ),

    GoRoute(
      path: SearchScreen.routePath,
      builder: (context, state) => const SearchScreen(),
    ),

    GoRoute(
      path: LeaderboardScreen.routePath,
      builder: (context, state) => const LeaderboardScreen(),
    ),

    GoRoute(
      path: ReportScreen.routePath,
      builder: (context, state) {
        final type = state.pathParameters['type'] ?? 'post';
        final id = state.pathParameters['id'] ?? 'unknown';

        return ReportScreen(
          type: type,
          id: id,
        );
      },
    ),

    GoRoute(
      path: ReportsScreen.routePath,
      builder: (context, state) => const ReportsScreen(),
    ),

    GoRoute(
      path: PolicyScreen.routePath,
      builder: (context, state) => const PolicyScreen(),
    ),

    GoRoute(
      path: AboutScreen.routePath,
      builder: (context, state) => const AboutScreen(),
    ),

    GoRoute(
      path: AdminModerationScreen.routePath,
      builder: (context, state) => const AdminModerationScreen(),
    ),
  ],
);