import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../guards/auth_guard.dart';
import '../guards/admin_guard.dart';
import '../guards/onboarding_guard.dart';
import 'go_router_refresh_stream.dart';
import '../../data/services/firebase/firebase_providers.dart';

// Admin Screens
import '../../features/admin/presentation/screens/admin_chat_rooms_screen.dart';
import '../../features/admin/presentation/screens/admin_create_match_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_matches_screen.dart';
import '../../features/admin/presentation/screens/admin_posts_screen.dart';
import '../../features/admin/presentation/screens/admin_predictions_screen.dart';
import '../../features/admin/presentation/screens/admin_quality_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/admin_send_notification_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/admin_players_screen.dart';
import '../../features/admin/presentation/screens/admin_points_screen.dart';
import '../../features/admin/presentation/screens/admin_gamification_screen.dart';
import '../../features/admin/presentation/screens/admin_lineups_screen.dart';
import '../../features/admin/presentation/screens/admin_live_match_screen.dart';
import '../../features/admin/presentation/screens/admin_questions_screen.dart';
import '../../features/admin/presentation/screens/admin_errors_screen.dart';
import '../../features/admin/presentation/screens/admin_audit_logs_screen.dart';
import '../../features/admin/presentation/screens/admin_content_screen.dart';

// Auth Screens
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';

// Feature Screens
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/feedback/presentation/screens/feedback_screen.dart';
import '../../features/profile/presentation/screens/delete_account_screen.dart';
import '../../features/blocking/presentation/screens/blocked_users_screen.dart';
import '../../features/feed/presentation/screens/create_post_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/feed/presentation/screens/post_detail_screen.dart';

import '../../features/home/presentation/screens/manager_home_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/lineup/presentation/screens/lineup_builder_screen.dart';
import '../../features/lineup/presentation/screens/lineup_detail_screen.dart';
import '../../features/lineup/presentation/screens/my_lineups_screen.dart';
import '../../features/lineup/presentation/screens/top_lineups_screen.dart';
import '../../features/lineup/presentation/screens/weekly_best_lineups_screen.dart';
import '../../features/matches/presentation/screens/matches_screen.dart';
import '../../features/matches/presentation/screens/live_match_center_screen.dart';
import '../../features/matches/presentation/screens/match_report_screen.dart';
import '../../features/moderation/presentation/screens/report_screen.dart';
import '../../features/moderation/presentation/screens/reports_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/gamification/presentation/screens/badges_screen.dart';
import '../../features/gamification/presentation/screens/missions_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/prediction/presentation/screens/my_predictions_screen.dart';
import '../../features/prediction/presentation/screens/prediction_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/public_user_profile_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/policy_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/match_simulation/presentation/screens/scenario_screen.dart';
import '../../features/finance/presentation/screens/sponsorship_screen.dart';
import '../../features/club/presentation/screens/association_screen.dart';
import '../../features/club/presentation/screens/museum_screen.dart';
import '../../features/academy/presentation/screens/academy_screen.dart';
import '../../features/transfer/presentation/screens/transfer_market_screen.dart';
import '../../features/club/presentation/screens/facilities_screen.dart';
import '../../features/training/presentation/screens/training_screen.dart';
import '../../features/club/presentation/screens/club_hub_screen.dart';
import '../../features/squad/presentation/screens/squad_hub_screen.dart';
import '../../features/transfer/presentation/screens/transfer_hub_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/match_simulation/presentation/screens/match_simulation_screen.dart';
import '../../features/assistant/presentation/screens/ai_assistant_screen.dart';
import '../analytics/analytics_service.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  refreshListenable: GoRouterRefreshStream(authService.authStateChanges()),
  observers: [AnalyticsService.observer],
  redirect: (context, state) async {
    final location = state.matchedLocation;

    // 1. Onboarding Guard
    final onboardingRedirect = await OnboardingGuard.redirect(location);
    if (onboardingRedirect != null) return onboardingRedirect;

    // 2. Auth Guard
    final authRedirect = AuthGuard.redirect(location);
    if (authRedirect != null) return authRedirect;

    // 3. Admin Guard
    final adminRedirect = await AdminGuard.redirect(location);
    if (adminRedirect != null) return adminRedirect;

    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const ManagerHomeScreen(),
    ),
    GoRoute(
      path: '/matches',
      builder: (context, state) => const MatchesScreen(),
    ),
    GoRoute(
      path: '/match-live/:matchId',
      builder: (context, state) =>
          LiveMatchCenterScreen(matchId: state.pathParameters['matchId'] ?? ''),
    ),
    GoRoute(
      path: '/match-report/:matchId',
      builder: (context, state) =>
          MatchReportScreen(matchId: state.pathParameters['matchId'] ?? ''),
    ),
    GoRoute(
      path: '/lineup/:matchId',
      builder: (context, state) =>
          LineupBuilderScreen(matchId: state.pathParameters['matchId'] ?? ''),
    ),
    GoRoute(
      path: '/lineup-detail/:lineupId',
      builder: (context, state) =>
          LineupDetailScreen(lineupId: state.pathParameters['lineupId'] ?? ''),
    ),
    GoRoute(
      path: '/lineups/top',
      builder: (context, state) => const TopLineupsScreen(),
    ),
    GoRoute(
      path: '/lineups/weekly-best',
      builder: (context, state) => const WeeklyBestLineupsScreen(),
    ),
    GoRoute(
      path: '/lineups/me',
      builder: (context, state) => const MyLineupsScreen(),
    ),
    GoRoute(
      path: '/prediction/:matchId',
      builder: (context, state) =>
          PredictionScreen(matchId: state.pathParameters['matchId'] ?? ''),
    ),
    GoRoute(
      path: '/predictions/me',
      builder: (context, state) => const MyPredictionsScreen(),
    ),
    GoRoute(
      path: '/chat/:roomId',
      builder: (context, state) =>
          ChatScreen(roomId: state.pathParameters['roomId'] ?? 'general'),
    ),
    GoRoute(path: '/feed', builder: (context, state) => const FeedScreen()),
    GoRoute(
      path: '/create-post',
      builder: (context, state) => const CreatePostScreen(),
    ),
    GoRoute(
      path: '/post/:postId',
      builder: (context, state) =>
          PostDetailScreen(postId: state.pathParameters['postId'] ?? ''),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(path: '/badges', builder: (context, state) => const BadgesScreen()),
    GoRoute(
      path: '/missions',
      builder: (context, state) => const MissionsScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) =>
          PublicUserProfileScreen(userId: state.pathParameters['userId'] ?? ''),
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
    GoRoute(path: '/policy', builder: (context, state) => const PolicyScreen()),
    GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
    GoRoute(
      path: '/delete-account',
      builder: (context, state) => const DeleteAccountScreen(),
    ),
    GoRoute(
      path: '/blocked-users',
      builder: (context, state) => const BlockedUsersScreen(),
    ),
    GoRoute(
      path: '/training',
      builder: (context, state) => const TrainingScreen(),
    ),
    GoRoute(
      path: '/facilities',
      builder: (context, state) => const FacilitiesScreen(),
    ),
    GoRoute(
      path: '/transfers',
      builder: (context, state) => const TransferMarketScreen(),
    ),
    GoRoute(
      path: '/academy',
      builder: (context, state) => const AcademyScreen(),
    ),
    GoRoute(path: '/museum', builder: (context, state) => const MuseumScreen()),
    GoRoute(
      path: '/associations',
      builder: (context, state) => const AssociationScreen(),
    ),
    GoRoute(
      path: '/sponsorships',
      builder: (context, state) => const SponsorshipScreen(),
    ),
    GoRoute(
      path: '/scenarios',
      builder: (context, state) => const ScenarioScreen(),
    ),
    GoRoute(
      path: '/match-simulation',
      builder: (context, state) => MatchSimulationScreen(
        homeLineupId: state.uri.queryParameters['homeLineupId'],
        awayLineupId: state.uri.queryParameters['awayLineupId'],
      ),
    ),
    GoRoute(
      path: '/club-hub',
      builder: (context, state) => const ClubHubScreen(),
    ),
    GoRoute(
      path: '/squad-hub',
      builder: (context, state) => const SquadHubScreen(),
    ),
    GoRoute(
      path: '/transfer-hub',
      builder: (context, state) => const TransferHubScreen(),
    ),
    GoRoute(
      path: '/ai-assistant',
      builder: (context, state) => const AiAssistantScreen(),
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
      builder: (context, state) =>
          AdminLiveMatchScreen(matchId: state.pathParameters['matchId'] ?? ''),
    ),
    GoRoute(
      path: '/admin/players',
      builder: (context, state) => const AdminPlayersScreen(),
    ),
    GoRoute(
      path: '/admin/quality',
      builder: (context, state) => const AdminQualityScreen(),
    ),
    GoRoute(
      path: '/admin/lineups',
      builder: (context, state) => const AdminLineupsScreen(),
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
      path: '/admin/gamification',
      builder: (context, state) => const AdminGamificationScreen(),
    ),
    GoRoute(
      path: '/admin/points',
      builder: (context, state) => const AdminPointsScreen(),
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
    GoRoute(
      path: '/admin/questions',
      builder: (context, state) => const AdminQuestionsScreen(),
    ),
    GoRoute(
      path: '/admin/errors',
      builder: (context, state) => const AdminErrorsScreen(),
    ),
    GoRoute(
      path: '/admin/audit-logs',
      builder: (context, state) => const AdminAuditLogsScreen(),
    ),
    GoRoute(
      path: '/admin/content',
      builder: (context, state) => const AdminContentScreen(),
    ),
  ],
);
