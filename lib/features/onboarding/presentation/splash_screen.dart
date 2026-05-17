import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/onboarding_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/user_profile_model.dart';
import '../../logging/data/logging_repository.dart';
import '../../logging/data/daily_summary_model.dart';
import '../../logging/data/hydration_log_model.dart';
import '../../reminder/data/reminder_response_repository.dart';
import '../../../core/services/sync_service.dart';
import '../../../providers/reminder_provider.dart';
import '../../../app/theme/app_colors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _handleNavigation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    // 1. Minimum delay for branding + startup tasks in parallel
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2000)),
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

    // 4. Fire and forget background tasks (AFTER navigation)
    _runBackgroundTasks();
  }

  Future<void> _performStartupTasks() async {
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final loggingRepo = ref.read(loggingRepositoryProvider);
      final profile = await profileRepo.getUserProfile();

      if (profile == null) return;

      final now = DateTime.now();
      final originalLastOpenedAt = profile.lastOpenedAt;

      if (originalLastOpenedAt != null) {
        final isNewDay = !_isSameDay(originalLastOpenedAt, now);
        if (isNewDay) {
          await _performMidnightReset(profile, loggingRepo);
        }
      }

      profile.lastOpenedAt = now;
      await profileRepo.saveProfile(profile);
      await _incrementSessionCount(profile, loggingRepo, now);
      await _checkReminderResponses(profile.userId);
      await _checkDropout(originalLastOpenedAt, profile, profileRepo, loggingRepo, now);
      await _flushNotificationActions(profile, loggingRepo);
    } catch (e) {
      debugPrint('[SplashScreen] Startup reconciliation failed: $e');
    }
  }

  Future<void> _performMidnightReset(UserProfile profile, LoggingRepository loggingRepo) async {
    final yesterday = profile.lastOpenedAt!;
    final yesterdaySummary = await loggingRepo.getDailySummary(profile.userId, yesterday);

    if (yesterdaySummary != null) {
      final isMaintained = yesterdaySummary.complianceRate >= 0.8;
      final updatedSummary = yesterdaySummary.copyWith(
        streakMaintained: isMaintained,
        isSynced: false,
      );
      await loggingRepo.upsertDailySummary(updatedSummary);
    }
  }

  Future<void> _incrementSessionCount(UserProfile profile, LoggingRepository loggingRepo, DateTime now) async {
    final targetMl = profile.targetManualMl ?? profile.dailyTargetMl;
    final existing = await loggingRepo.getDailySummary(profile.userId, now);

    if (existing != null) {
      final updated = existing.copyWith(
        sessionCount: existing.sessionCount + 1,
        isSynced: false,
      );
      await loggingRepo.upsertDailySummary(updated);
    } else {
      final logs = await loggingRepo.getLogsForDate(profile.userId, now);
      final totalMl = logs.fold(0, (sum, log) => sum + log.volume);

      final summary = DailySummary()
        ..userId = profile.userId
        ..date = now
        ..targetMl = targetMl
        ..achievedMl = totalMl
        ..complianceRate = targetMl > 0 ? totalMl / targetMl : 0.0
        ..remindersSent = 0
        ..remindersResponded = 0
        ..sessionCount = 1
        ..streakMaintained = false
        ..isSynced = false
        ..createdAt = DateTime.now();
      await loggingRepo.upsertDailySummary(summary);
    }
  }

  Future<void> _checkDropout(DateTime? originalLastOpenedAt, UserProfile profile, ProfileRepository profileRepo, LoggingRepository loggingRepo, DateTime now) async {
    if (originalLastOpenedAt == null) return;
    final gap = now.difference(originalLastOpenedAt).inDays;
    if (gap > 3 && !profile.dropoutFlag) {
      profile.dropoutFlag = true;
      profile.isSynced = false;
      await profileRepo.saveProfile(profile);

      final todaySummary = await loggingRepo.getDailySummary(profile.userId, now);
      if (todaySummary != null) {
        final updated = todaySummary.copyWith(dropoutFlag: true, isSynced: false);
        await loggingRepo.upsertDailySummary(updated);
      }
    }
  }

  Future<void> _flushNotificationActions(UserProfile profile, LoggingRepository loggingRepo) async {
    try {
      final committed = await loggingRepo.flushActionQueue(profile.userId);
      if (committed.isEmpty) return;
      final byDate = <String, List<HydrationLog>>{};
      for (final log in committed) {
        final key = '${log.timestamp.year}-${log.timestamp.month}-${log.timestamp.day}';
        byDate.putIfAbsent(key, () => []).add(log);
      }
      final targetMl = profile.targetManualMl ?? profile.dailyTargetMl;
      for (final entry in byDate.entries) {
        final dateRef = entry.value.first.timestamp;
        final allLogsForDate = await loggingRepo.getLogsForDate(profile.userId, dateRef);
        final totalMl = allLogsForDate.fold(0, (sum, log) => sum + log.volume);
        final existing = await loggingRepo.getDailySummary(profile.userId, dateRef);
        if (existing != null) {
          final updated = existing.copyWith(achievedMl: totalMl, complianceRate: targetMl > 0 ? totalMl / targetMl : 0.0, isSynced: false);
          await loggingRepo.upsertDailySummary(updated);
        }
      }
    } catch (e) {
      debugPrint('[SplashScreen] _flushNotificationActions failed silently: $e');
    }
  }

  Future<void> _checkReminderResponses(String userId) async {
    try {
      final responseRepo = ref.read(reminderResponseRepositoryProvider);
      await responseRepo.flushQueue(userId);
      await responseRepo.checkAndMarkNoResponses(userId, cutoffMinutes: 60);
    } catch (e) {
      debugPrint('[SplashScreen] _checkReminderResponses failed silently: $e');
    }
  }

  void _runBackgroundTasks() {
    ref.read(syncServiceProvider).pushUnsyncedRecords();
    _rescheduleReminders();
  }

  Future<void> _rescheduleReminders() async {
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final loggingRepo = ref.read(loggingRepositoryProvider);
      final profile = await profileRepo.getUserProfile();
      if (profile == null) return;
      final now = DateTime.now();
      final logs = await loggingRepo.getLogsForDate(profile.userId, now);
      final currentMl = logs.fold(0, (sum, log) => sum + log.volume);
      final targetMl = profile.targetManualMl ?? profile.dailyTargetMl;
      ref.read(reminderServiceProvider).rescheduleIfNeeded(currentMl: currentMl, targetMl: targetMl);
    } catch (e) {
      debugPrint('[SplashScreen] _rescheduleReminders failed silently: $e');
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.onPrimary,
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          
          Center(
            child: FadeTransition(
              opacity: _fadeInAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Silhouette Logo
                    Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.onPrimary,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/splash_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: 40),
                    Text(
                      'SEHATI',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                            color: AppColors.primary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
