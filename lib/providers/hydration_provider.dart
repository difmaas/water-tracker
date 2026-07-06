import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/logging/data/logging_repository.dart';
import '../features/logging/data/hydration_log_model.dart';
import '../features/logging/data/daily_summary_model.dart';
import '../features/reminder/domain/reminder_logic.dart';
import '../features/progress/progress_provider.dart';
import 'reminder_provider.dart';

/// Display state for the Daily Dashboard.
class HydrationState {
  final int currentMl;
  final int targetMl;
  final List<HydrationLog> todayLogs;
  final bool isLoading;
  final String userName;
  final String jenisKelamin;
  final int currentStreak;
  final bool notificationPermissionGranted;
  final DateTime? nextReminderTime;
  final int reminderInterval;
  final int reminderWindowStart;
  final int reminderWindowEnd;
  final bool reminderSystemActive;
  final int researchDay;
  final bool isDrinkDisabled;

  double get progressPercent =>
      targetMl > 0 ? (currentMl / targetMl).clamp(0.0, 1.0) : 0.0;
  int get remainingMl => (targetMl - currentMl).clamp(0, targetMl);
  bool get isTargetReached => currentMl >= targetMl;

  const HydrationState({
    this.currentMl = 0,
    this.targetMl = 2000,
    this.todayLogs = const [],
    this.isLoading = true,
    this.userName = '',
    this.jenisKelamin = '',
    this.currentStreak = 0,
    this.notificationPermissionGranted = false,
    this.nextReminderTime,
    this.reminderInterval = 2,
    this.reminderWindowStart = 7,
    this.reminderWindowEnd = 21,
    this.reminderSystemActive = false,
    this.researchDay = 1,
    this.isDrinkDisabled = false,
  });

  HydrationState copyWith({
    int? currentMl,
    int? targetMl,
    List<HydrationLog>? todayLogs,
    bool? isLoading,
    String? userName,
    String? jenisKelamin,
    int? currentStreak,
    bool? notificationPermissionGranted,
    DateTime? nextReminderTime,
    int? reminderInterval,
    int? reminderWindowStart,
    int? reminderWindowEnd,
    bool? reminderSystemActive,
    int? researchDay,
    bool? isDrinkDisabled,
    bool clearNextReminder = false,
  }) {
    return HydrationState(
      currentMl: currentMl ?? this.currentMl,
      targetMl: targetMl ?? this.targetMl,
      todayLogs: todayLogs ?? this.todayLogs,
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      currentStreak: currentStreak ?? this.currentStreak,
      notificationPermissionGranted:
          notificationPermissionGranted ?? this.notificationPermissionGranted,
      nextReminderTime: clearNextReminder
          ? null
          : (nextReminderTime ?? this.nextReminderTime),
      reminderInterval: reminderInterval ?? this.reminderInterval,
      reminderWindowStart: reminderWindowStart ?? this.reminderWindowStart,
      reminderWindowEnd: reminderWindowEnd ?? this.reminderWindowEnd,
      reminderSystemActive: reminderSystemActive ?? this.reminderSystemActive,
      researchDay: researchDay ?? this.researchDay,
      isDrinkDisabled: isDrinkDisabled ?? this.isDrinkDisabled,
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
///
/// Guard: Cooldown 5s after logging water.
class HydrationNotifier extends Notifier<HydrationState> {
  ProfileRepository get _profileRepo => ref.read(profileRepositoryProvider);
  LoggingRepository get _loggingRepo => ref.read(loggingRepositoryProvider);
  Timer? _disableTimer;

  @override
  HydrationState build() {
    ref.onDispose(() {
      _disableTimer?.cancel();
    });
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
          clearNextReminder: true,
        );
        return;
      }

      // Read today's logs (READ-ONLY — no writes)
      final logs = await _loggingRepo.getLogsForDate(profile.userId, now);
      int totalMl = logs.fold(0, (sum, log) => sum + log.volume);
      final target = profile.targetManualMl ?? profile.dailyTargetMl;

      DateTime? nextReminder;
      if (profile.reminderSystemActive &&
          profile.notificationPermissionGranted) {
        final remainingSlots = totalMl < target
            ? ReminderLogic.remainingSlotsForToday(
                now,
                reminderIntervalHours: profile.reminderInterval,
                startHour: profile.reminderWindowStart,
                endHour: profile.reminderWindowEnd,
              )
            : const <DateTime>[];

        if (remainingSlots.isNotEmpty) {
          nextReminder = remainingSlots.first;
        } else {
          final (startHour, _) = ReminderLogic.normalizedWindow(
            profile.reminderWindowStart,
            profile.reminderWindowEnd,
          );
          nextReminder = DateTime(now.year, now.month, now.day + 1, startHour);
        }
      }

      int researchDay = 1;
      final startDate = DateTime(
        profile.createdAt.year,
        profile.createdAt.month,
        profile.createdAt.day,
      );
      final todayDate = DateTime(now.year, now.month, now.day);
      final elapsed = todayDate.difference(startDate).inDays + 1;
      researchDay = elapsed.clamp(1, 14);

      state = state.copyWith(
        currentMl: totalMl,
        targetMl: target,
        todayLogs: logs,
        userName: profile.nama,
        jenisKelamin: profile.jenisKelamin,
        currentStreak: profile.currentStreak,
        notificationPermissionGranted: profile.notificationPermissionGranted,
        nextReminderTime: nextReminder,
        clearNextReminder: nextReminder == null,
        reminderInterval: profile.reminderInterval,
        reminderWindowStart: profile.reminderWindowStart,
        reminderWindowEnd: profile.reminderWindowEnd,
        reminderSystemActive: profile.reminderSystemActive,
        researchDay: researchDay,
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('Error in _loadToday: $e\n$st');
      state = state.copyWith(isLoading: false);
    }
  }

  // ── F-05: User-initiated write operations ─────────────────────────────────
  
  void _startDrinkCooldown() {
    _disableTimer?.cancel();
    state = state.copyWith(isDrinkDisabled: true);
    _disableTimer = Timer(const Duration(seconds: 5), () {
      state = state.copyWith(isDrinkDisabled: false);
    });
  }

  void _cancelDrinkCooldown() {
    _disableTimer?.cancel();
    state = state.copyWith(isDrinkDisabled: false);
  }

  /// Adds a hydration log and upserts today's DailySummary.
  /// Returns the saved log (with assigned ID) for undo Snackbar support.
  ///
  /// This is a user-initiated write — NOT a startup mutation.
  Future<HydrationLog?> addLog(int volumeMl, {String loggedVia = 'app'}) async {
    if (state.isDrinkDisabled) return null;

    _startDrinkCooldown();

    try {
      if (volumeMl <= 0) {
        debugPrint('[HydrationNotifier] Ignoring invalid volume: $volumeMl');
        _cancelDrinkCooldown();
        return null;
      }

      final profile = await _profileRepo.getUserProfile();
      if (profile == null) {
        _cancelDrinkCooldown();
        return null;
      }

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

      // 2. Upsert DailySummary (canonical pattern per AGENTS_V2.md §15)
      await _upsertDailySummaryAfterLog(profile.userId, now);

      // 3. Refresh display state
      await _loadToday();

      // Trigger progress/history refresh
      _refreshProgress('addLog');

      // 4. Rebuild today's remaining reminder slots after the new total.
      await _rescheduleRemindersForCurrentState();

      return log;
    } catch (e, st) {
      debugPrint('Error in addLog: $e\n$st');
      _cancelDrinkCooldown();
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

      // Trigger progress/history refresh
      _refreshProgress('undoLog');

      // 4. Rebuild reminders because undo can drop total below target.
      await _rescheduleRemindersForCurrentState();
    } catch (e, st) {
      debugPrint('Error in undoLog: $e\n$st');
    }
  }

  /// Deletes a log by ID and recalculates DailySummary for that specific log's date.
  Future<void> deleteLog(int logId, DateTime logTimestamp) async {
    try {
      final profile = await _profileRepo.getUserProfile();
      if (profile == null) return;

      // 1. Delete the log
      await _loggingRepo.deleteLog(logId);

      // 2. Recalculate DailySummary for the log's date
      await _upsertDailySummaryAfterLog(profile.userId, logTimestamp);

      // 3. Refresh display state
      await _loadToday();

      // Trigger progress/history refresh
      _refreshProgress('deleteLog');

      // 4. Recalculate reminders if it's today
      final now = DateTime.now();
      if (_isSameLocalDay(logTimestamp, now)) {
        await _rescheduleRemindersForCurrentState();
      }
    } catch (e, st) {
      debugPrint('Error in deleteLog: $e\n$st');
    }
  }

  /// Updates a log's volume and recalculates DailySummary for that specific log's date.
  Future<void> updateLog(
    int logId,
    int newVolume,
    DateTime logTimestamp,
  ) async {
    try {
      if (newVolume <= 0) {
        debugPrint('[HydrationNotifier] Ignoring invalid update: $newVolume');
        return;
      }

      final profile = await _profileRepo.getUserProfile();
      if (profile == null) return;

      final log = await _loggingRepo.getLog(logId);
      if (log == null) return;

      // Update the volume
      log.volume = newVolume;
      log.isSynced = false; // Mark unsynced on edit

      await _loggingRepo.saveLog(log);

      // Recalculate DailySummary for the log's date
      await _upsertDailySummaryAfterLog(profile.userId, logTimestamp);

      // Refresh display state
      await _loadToday();

      // Trigger progress/history refresh
      _refreshProgress('updateLog');

      // Recalculate reminders if it's today
      final now = DateTime.now();
      if (_isSameLocalDay(logTimestamp, now)) {
        await _rescheduleRemindersForCurrentState();
      }
    } catch (e, st) {
      debugPrint('Error in updateLog: $e\n$st');
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
      final firstLogTimestamp = logs.isNotEmpty ? logs.first.timestamp : null;

      // UPDATE: recalculate achievedMl, complianceRate, and firstLogTimestamp,
      // preserve sessionCount and reminder counters.
      final updated = existing.copyWith(
        achievedMl: totalMl,
        complianceRate: targetMl > 0 ? totalMl / targetMl : 0.0,
        firstLogTimestamp: firstLogTimestamp,
        clearFirstLogTimestamp: logs.isEmpty,
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

  void _refreshProgress(String source) {
    try {
      ref.read(progressProvider.notifier).refresh();
    } catch (e) {
      debugPrint('Error refreshing progressProvider in $source: $e');
    }
  }

  Future<void> _rescheduleRemindersForCurrentState() {
    return ref
        .read(reminderServiceProvider)
        .rescheduleIfNeeded(
          currentMl: state.currentMl,
          targetMl: state.targetMl,
        );
  }

  bool _isSameLocalDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Called externally to refresh display state (e.g. after navigation back).
  Future<void> refresh() async {
    await _loadToday();
  }
}

final hydrationProvider = NotifierProvider<HydrationNotifier, HydrationState>(
  () {
    return HydrationNotifier();
  },
);
