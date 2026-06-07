import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/education/presentation/education_screen.dart';
import '../../features/education/presentation/article_detail_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../presentation/main_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

// Route constants
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String profileSetup = '/profile-setup';
  static const String dashboard = '/dashboard';
  static const String education = '/education';
  static const String educationDetail = '/education/:id';
  static const String settings = '/settings';
  static const String progress = '/progress';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (context, state) {
          final isEdit = state.uri.queryParameters['edit'] == 'true';
          return ProfileScreen(isEditing: isEdit);
        },
      ),
      GoRoute(
        path: AppRoutes.educationDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final articleId = state.pathParameters['id'] ?? '';
          return ArticleDetailScreen(articleId: articleId);
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) =>
                _buildFadeTransitionPage(state, const DashboardScreen()),
          ),
          GoRoute(
            path: AppRoutes.progress,
            pageBuilder: (context, state) =>
                _buildFadeTransitionPage(state, const ProgressScreen()),
          ),
          GoRoute(
            path: AppRoutes.education,
            pageBuilder: (context, state) =>
                _buildFadeTransitionPage(state, const EducationScreen()),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) =>
                _buildFadeTransitionPage(state, const SettingsScreen()),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage<void> _buildFadeTransitionPage(
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}
