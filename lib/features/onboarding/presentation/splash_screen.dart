import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/onboarding_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../../core/services/sync_service.dart';
import '../../reminder/reminder_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // 1. Minimum delay for branding
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1500)),
      _performStartupTasks(),
    ]);

    if (!mounted) return;

    // 2. Check Onboarding
    final isOnboarded = ref.read(onboardingProvider);
    if (!isOnboarded) {
      context.go('/onboarding');
      return;
    }

    // 3. Check Profile
    final hasProfile = ref.read(profileStatusProvider);

    if (!hasProfile) {
      context.go('/profile-setup');
    } else {
      context.go('/dashboard');
    }

    // 4. Fire and forget background tasks
    _runBackgroundTasks();
  }

  Future<void> _performStartupTasks() async {
    try {
      final profileRepository = ref.read(profileRepositoryProvider);
      await profileRepository.reconcileDailyData();
    } catch (e) {
      debugPrint('Startup reconciliation failed: $e');
    }
  }

  void _runBackgroundTasks() {
    // Fire and forget
    ref.read(syncServiceProvider).pushUnsyncedRecords();
    ref.read(reminderServiceProvider).rescheduleIfNeeded();
    ref.read(profileRepositoryProvider).updateLastOpenedAt(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Placeholder for Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  size: 60,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'HYDRO',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hydration Tracker',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      letterSpacing: 1.2,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
