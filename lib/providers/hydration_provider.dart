import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/logging/data/logging_repository.dart';
import '../features/logging/data/hydration_log_model.dart';
import '../features/logging/data/daily_summary_model.dart';
import '../features/reminder/data/reminder_response_repository.dart';
import 'reminder_provider.dart';

/// Display state for the Daily Dashboard.
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

/// V2 AUDIT FIX: HydrationNotifier._loadToday() is strictly READ-ONLY.
///
/// ✅ ALLOWED: read profile, read today's logs, update display state
/// ❌ FORBIDDEN: performMidnightReset, updateLastOpenedAt,
///              incrementSessionCount, checkDropout
///
/// All startup data mutations happen in SplashScreen._performStartupTasks()
/// BEFORE context.go('/dashboard') is called.
///
/// Write operations (addLog, undoLog) are user-initiated actions and safe
/// to perform here — they are NOT startup mutations.
class HydrationNotifier extends Notifier<HydrationState> {
  ProfileRepository get _profileRepo => ref.read(profileRepositoryProvider);
  LoggingRepository get _loggingRepo => ref.read(loggingRepositoryProvider);

  @override
  HydrationState build() {
    Future.microtask(() => _loadToday());
    return const HydrationState(isLoading: true);
  }

  /// READ-ONLY: Loads today's data and updates display state.
  /// No startup mutations (no writes to Isar/SharedPrefs).
  /// Midnight reset, sessionCount, dropout, lastOpenedAt are all
  /// handled by SplashScreen before we get here.
  Future<void> _loadToday() async {
    try {
      state = state.copyWith(isLoading: true);

      final profile = await _profileRepo.getUserProfile();
      final now = DateTime.now();

      if (profile == null) {
        // Fallback — no profile set up yet
        state = state.copyWith(
          isLoading: false,
          targetMl: 2000,
          userName: '',
          funFact: kHydrationFacts[Random().nextInt(kHydrationFacts.length)],
        );
        return;
      }

      // Read today's logs (READ-ONLY — no writes)
      final logs = await _loggingRepo.getLogsForDate(profile.userId, now);
      int totalMl = logs.fold(0, (sum, log) => sum + log.volume);

      // Pick random fact — preserve current fact if already set (avoid flicker on refresh)
      final fact = state.funFact.isNotEmpty
          ? state.funFact
          : kHydrationFacts[Random().nextInt(kHydrationFacts.length)];

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
    } catch (e, st) {
      debugPrint('Error in _loadToday: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  // ── F-05: User-initiated write operations ─────────────────────────────────

  /// Adds a hydration log and upserts today's DailySummary.
  /// Returns the saved log (with assigned ID) for undo Snackbar support.
  ///
  /// This is a user-initiated write — NOT a startup mutation.
  Future<HydrationLog?> addLog(int volumeMl, {String loggedVia = 'app'}) async {
    try {
      final profile = await _profileRepo.getUserProfile();
      if (profile == null) return null;

      final now = DateTime.now();

      // 1. Create and save the HydrationLog
      final log = HydrationLog()
        ..userId = profile.userId
        ..volume = volumeMl
        ..timestamp = now
        ..loggedVia = loggedVia
        ..isSynced = false
        ..createdAt = now;

      await _loggingRepo.saveLog(log);

      // F-08: If logged within 30 min of last notification, record ReminderResponse.
      // Fire-and-forget — never blocks the log save.
      _checkAndRecordOpenedAppResponse(profile.userId, now);

      // 2. Upsert DailySummary (canonical pattern per AGENTS_V2.md §15)
      await _upsertDailySummaryAfterLog(profile.userId, now);

      // 3. Refresh display state
      await _loadToday();

      // 4. Recalculate reminder interval based on new progress (fire-and-forget)
      // This is the post-log reschedule per ARCHITECTURE_V2.md §4
      ref.read(reminderServiceProvider).rescheduleIfNeeded(
        currentMl: state.currentMl,
        targetMl: state.targetMl,
      );

      return log;
    } catch (e, st) {
      debugPrint('Error in addLog: $e\n$st');
      return null;
    }
  }

  /// Deletes a log by ID and recalculates DailySummary.
  /// Used by the undo Snackbar action.
  Future<void> undoLog(int logId) async {
    try {
      final profile = await _profileRepo.getUserProfile();
      if (profile == null) return;

      final now = DateTime.now();

      // 1. Delete the log
      await _loggingRepo.deleteLog(logId);

      // 2. Recalculate DailySummary
      await _upsertDailySummaryAfterLog(profile.userId, now);

      // 3. Refresh display state
      await _loadToday();
    } catch (e, st) {
      debugPrint('Error in undoLog: $e\n$st');
    }
  }

  /// Canonical DailySummary upsert pattern (AGENTS_V2.md §15).
  /// Called after every log add/delete to keep the summary in sync.
  Future<void> _upsertDailySummaryAfterLog(String userId, DateTime date) async {
    final logs = await _loggingRepo.getLogsForDate(userId, date);
    final totalMl = logs.fold(0, (sum, log) => sum + log.volume);
    final profile = await _profileRepo.getUserProfile();
    final targetMl = profile?.targetManualMl ?? profile?.dailyTargetMl ?? 2000;

    final existing = await _loggingRepo.getDailySummary(userId, date);

    if (existing != null) {
      // UPDATE: recalculate achievedMl and complianceRate,
      // preserve sessionCount, firstLogTimestamp, remindersSent
      final updated = existing.copyWith(
        achievedMl: totalMl,
        complianceRate: targetMl > 0 ? totalMl / targetMl : 0.0,
        isSynced: false, // mark dirty on every update
      );
      await _loggingRepo.upsertDailySummary(updated);
    } else {
      // INSERT: first interaction of the day — create new DailySummary
      final firstLogTimestamp = logs.isNotEmpty ? logs.first.timestamp : null;
      final summary = DailySummary()
        ..userId = userId
        ..date = date
        ..targetMl = targetMl
        ..achievedMl = totalMl
        ..complianceRate = targetMl > 0 ? totalMl / targetMl : 0.0
        ..remindersSent = 0
        ..remindersResponded = 0
        ..sessionCount = 1
        ..streakMaintained = false
        ..firstLogTimestamp = firstLogTimestamp
        ..isSynced = false
        ..createdAt = DateTime.now();
      await _loggingRepo.upsertDailySummary(summary);
    }
  }

  /// Called externally to refresh display state (e.g. after navigation back).
  Future<void> refresh() async {
    await _loadToday();
  }

  /// F-08: Checks if this app-initiated log falls within 30 minutes of the
  /// last scheduled notification. If so, updates the ReminderResponse with
  /// actionUsed='opened_app' and completed=true.
  ///
  /// Fire-and-forget — called from addLog() without await.
  Future<void> _checkAndRecordOpenedAppResponse(
      String userId, DateTime loggedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sentAtStr = prefs.getString(kLastReminderSentAtKey);
      if (sentAtStr == null) return;

      final sentAt = DateTime.parse(sentAtStr);
      final elapsed = loggedAt.difference(sentAt).inMinutes;

      // Only record if within 30-minute response window
      if (elapsed < 0 || elapsed > 30) return;

      // Check deduplication guard — skip if already responded to this notification
      final lastRecorded = prefs.getString(kLastResponseRecordedAtKey);
      if (lastRecorded != null && lastRecorded == sentAtStr) return;

      final responseRepo = ref.read(reminderResponseRepositoryProvider);
      await responseRepo.markResponded(
        userId: userId,
        completed: true,
        delayMinutes: elapsed,
        actionUsed: 'opened_app',
        notificationScheduledAt: sentAt,
      );
    } catch (e) {
      debugPrint(
          '[HydrationNotifier] _checkAndRecordOpenedAppResponse failed: $e');
    }
  }
}

final hydrationProvider = NotifierProvider<HydrationNotifier, HydrationState>(() {
  return HydrationNotifier();
});
