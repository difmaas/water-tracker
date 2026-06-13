import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/onboarding_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/user_profile_model.dart';
import '../../logging/data/logging_repository.dart';
import '../../logging/data/daily_summary_model.dart';
import '../../reminder/data/reminder_response_repository.dart';
import '../../../core/services/sync_service.dart';
import '../../../providers/reminder_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _handleNavigation();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _handleNavigation() async {
    // 1. Wait for animation + startup tasks
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 3000)),
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
      await _checkDropout(
        originalLastOpenedAt,
        profile,
        profileRepo,
        loggingRepo,
        now,
      );
    } catch (e) {
      debugPrint('[SplashScreen] Startup reconciliation failed: $e');
    }
  }

  Future<void> _performMidnightReset(
    UserProfile profile,
    LoggingRepository loggingRepo,
  ) async {
    final yesterday = profile.lastOpenedAt!;
    final yesterdaySummary = await loggingRepo.getDailySummary(
      profile.userId,
      yesterday,
    );

    bool isMaintained = false;
    int? streakBreakHour;

    if (yesterdaySummary != null) {
      isMaintained = yesterdaySummary.complianceRate >= 0.8;
      if (!isMaintained) {
        final yesterdayLogs = await loggingRepo.getLogsForDate(
          profile.userId,
          yesterday,
        );
        if (yesterdayLogs.isNotEmpty) {
          yesterdayLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          streakBreakHour = yesterdayLogs.last.timestamp.hour;
        }
      }

      final updatedSummary = yesterdaySummary.copyWith(
        streakMaintained: isMaintained,
        streakBreakHour: streakBreakHour,
        isSynced: false,
      );
      await loggingRepo.upsertDailySummary(updatedSummary);
    }

    // 2. Update currentStreak in UserProfile
    if (isMaintained) {
      profile.currentStreak += 1;
    } else {
      profile.currentStreak = 0;
    }
    profile.isSynced = false;

    // 6. Cancel all pending notifications
    final reminderService = ref.read(reminderServiceProvider);
    await reminderService.cancelAll();
  }

  Future<void> _incrementSessionCount(
    UserProfile profile,
    LoggingRepository loggingRepo,
    DateTime now,
  ) async {
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

  Future<void> _checkDropout(
    DateTime? originalLastOpenedAt,
    UserProfile profile,
    ProfileRepository profileRepo,
    LoggingRepository loggingRepo,
    DateTime now,
  ) async {
    if (originalLastOpenedAt == null) return;
    final gap = now.difference(originalLastOpenedAt).inDays;
    if (gap > 3) {
      profile.dropoutFlag = true;
      profile.isSynced = false;

      final todaySummary = await loggingRepo.getDailySummary(
        profile.userId,
        now,
      );
      if (todaySummary != null) {
        final updated = todaySummary.copyWith(
          dropoutFlag: true,
          isSynced: false,
        );
        await loggingRepo.upsertDailySummary(updated);
      }

      if (!profile.dropoutNotificationSent) {
        final reminderService = ref.read(reminderServiceProvider);
        await reminderService.scheduleReEngagementNotification();
        profile.dropoutNotificationSent = true;
      }

      await profileRepo.saveProfile(profile);
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
      await ref
          .read(reminderServiceProvider)
          .rescheduleIfNeeded(currentMl: currentMl, targetMl: targetMl);
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
      backgroundColor: const Color(0xFFF8FBFF), // Fresh background #F8FBFF
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/app_icon.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'SEHATI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: const Color(0xFF1A73E8), // Primary #1A73E8
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Jangan lupa minum air putih hari ini',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5F6368),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
