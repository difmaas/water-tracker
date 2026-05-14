import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../features/dashboard/presentation/dashboard_screen.dart';
import '../../../features/education/presentation/education_screen.dart';
import '../../../features/gamification/presentation/achievements_screen.dart';
import '../../../features/onboarding/presentation/onboarding_screen.dart';
import '../../../features/profile/presentation/profile_screen.dart';
import '../../../features/progress/presentation/progress_screen.dart';

/// Application router using go_router.
///
/// All routes are stubbed with placeholder screens for F-01.
/// Actual navigation guards (splash logic, onboarding check) will be
/// implemented in F-00.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: kRouteSplash,
    debugLogDiagnostics: true,
    routes: [
      // Splash — will be replaced with actual splash screen in F-00
      GoRoute(
        path: kRouteSplash,
        builder: (context, state) => const _StubScreen(title: 'Splash'),
      ),
      GoRoute(
        path: kRouteOnboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: kRouteProfileSetup,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: kRouteDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: kRouteEducation,
        builder: (context, state) => const EducationScreen(),
      ),
      GoRoute(
        path: kRouteProgress,
        builder: (context, state) => const ProgressScreen(),
      ),
      GoRoute(
        path: kRouteAchievements,
        builder: (context, state) => const AchievementsScreen(),
      ),
    ],
  );
});

/// Temporary stub screen used for routes not yet implemented.
class _StubScreen extends StatelessWidget {
  const _StubScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
