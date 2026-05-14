import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/data/user_profile_model.dart';
import '../features/logging/data/logging_repository.dart';
import '../features/logging/data/hydration_log_model.dart';
import '../features/logging/data/daily_summary_model.dart';

class HydrationState {
  final int currentMl;
  final int targetMl;
  final List<HydrationLog> todayLogs;
  final bool isLoading;
  final String userName;
  final int currentStreak;
  final String funFact;
  final bool notificationPermissionGranted;

  double get progressPercent => targetMl > 0 ? (currentMl / targetMl).clamp(0.0, 1.0) : 0.0;
  int get remainingMl => (targetMl - currentMl).clamp(0, targetMl);
  bool get isTargetReached => currentMl >= targetMl;

  const HydrationState({
    this.currentMl = 0,
    this.targetMl = 2000,
    this.todayLogs = const [],
    this.isLoading = true,
    this.userName = '',
    this.currentStreak = 0,
    this.funFact = '',
    this.notificationPermissionGranted = false,
  });

  HydrationState copyWith({
    int? currentMl,
    int? targetMl,
    List<HydrationLog>? todayLogs,
    bool? isLoading,
    String? userName,
    int? currentStreak,
    String? funFact,
    bool? notificationPermissionGranted,
  }) {
    return HydrationState(
      currentMl: currentMl ?? this.currentMl,
      targetMl: targetMl ?? this.targetMl,
      todayLogs: todayLogs ?? this.todayLogs,
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      currentStreak: currentStreak ?? this.currentStreak,
      funFact: funFact ?? this.funFact,
      notificationPermissionGranted: notificationPermissionGranted ?? this.notificationPermissionGranted,
    );
  }
}

class HydrationNotifier extends Notifier<HydrationState> {
  ProfileRepository get _profileRepo => ref.read(profileRepositoryProvider);
  LoggingRepository get _loggingRepo => ref.read(loggingRepositoryProvider);

  @override
  HydrationState build() {
    Future.microtask(() => _loadToday());
    return const HydrationState(isLoading: true);
  }

  Future<void> _loadToday() async {
    try {
      state = state.copyWith(isLoading: true);

      final profile = await _profileRepo.getUserProfile();
      final now = DateTime.now();

      if (profile == null) {
        // Fallback
        state = state.copyWith(
          isLoading: false,
          targetMl: 2000,
          userName: '',
          funFact: kHydrationFacts[Random().nextInt(kHydrationFacts.length)],
        );
        return;
      }

      // Midnight reset check
      if (profile.lastOpenedAt != null) {
        final isNewDay = !_isSameDay(profile.lastOpenedAt!, now);
        if (isNewDay) {
          await _performMidnightReset(profile, profile.lastOpenedAt!);
        }
      }

      // Load logs for today
      final logs = await _loggingRepo.getLogsForDate(profile.userId, now);
      int totalMl = logs.fold(0, (sum, log) => sum + log.volume);

      // Pick random fact
      final fact = kHydrationFacts[Random().nextInt(kHydrationFacts.length)];

      state = state.copyWith(
        currentMl: totalMl,
        targetMl: profile.targetManualMl ?? profile.dailyTargetMl,
        todayLogs: logs,
        userName: profile.nama,
        currentStreak: 0, // Placeholder for Phase 2
        funFact: fact,
        notificationPermissionGranted: profile.notificationPermissionGranted,
        isLoading: false,
      );

      // After loading, run session count and dropout logic
      await _incrementSessionCount(profile.userId, now, state.targetMl, totalMl);
      await _checkDropout(profile, now);
    } catch (e, st) {
      print('Error in _loadToday: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _performMidnightReset(UserProfile profile, DateTime lastOpened) async {
    final yesterdaySummary = await _loggingRepo.getDailySummary(profile.userId, lastOpened);
    if (yesterdaySummary != null) {
      final isMaintained = yesterdaySummary.complianceRate >= 0.8;
      final updatedSummary = yesterdaySummary.copyWith(
        streakMaintained: isMaintained,
        isSynced: false,
      );
      await _loggingRepo.upsertDailySummary(updatedSummary);
    }
  }

  Future<void> _incrementSessionCount(String userId, DateTime date, int targetMl, int currentMl) async {
    final existing = await _loggingRepo.getDailySummary(userId, date);

    if (existing != null) {
      final updated = existing.copyWith(
        sessionCount: existing.sessionCount + 1,
        isSynced: false,
      );
      await _loggingRepo.upsertDailySummary(updated);
    } else {
      final summary = DailySummary()
        ..userId = userId
        ..date = date
        ..targetMl = targetMl
        ..achievedMl = currentMl
        ..complianceRate = targetMl > 0 ? currentMl / targetMl : 0.0
        ..remindersSent = 0
        ..remindersResponded = 0
        ..sessionCount = 1
        ..streakMaintained = false
        ..isSynced = false
        ..createdAt = DateTime.now();
      await _loggingRepo.upsertDailySummary(summary);
    }
  }

  Future<void> _checkDropout(UserProfile profile, DateTime now) async {
    if (profile.lastOpenedAt != null) {
      final gap = now.difference(profile.lastOpenedAt!).inDays;
      if (gap > 3 && !profile.dropoutFlag) {
        profile.dropoutFlag = true;
        profile.isSynced = false;
        await _profileRepo.saveProfile(profile);
      }
    }
    await _profileRepo.updateLastOpenedAt(now);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final hydrationProvider = NotifierProvider<HydrationNotifier, HydrationState>(() {
  return HydrationNotifier();
});
