import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';
import 'hydration_log_model.dart';
import 'daily_summary_model.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../reminder/data/notification_action_log.dart';

/// Persists HydrationLogs and DailySummaries in Isar.
class LoggingRepository {
  final Isar _isar;
  final SharedPreferences _prefs;
  static const _logsKey = 'hydration_logs_json';
  static const _summaryKey = 'daily_summaries_json';
  static const _logsMigrationKey = 'isar_migrated_hydration_logs_json';
  static const _summariesMigrationKey = 'isar_migrated_daily_summaries_json';

  LoggingRepository(this._isar, this._prefs);

  // --- HydrationLogs ---

  Future<List<HydrationLog>> getLogsForDate(
    String userId,
    DateTime date,
  ) async {
    await _migrateLegacyLogsIfNeeded();
    final allLogs = await _getAllLogs();
    final logs = allLogs.where((log) {
      return log.userId == userId &&
          log.timestamp.year == date.year &&
          log.timestamp.month == date.month &&
          log.timestamp.day == date.day;
    }).toList();
    logs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return logs;
  }

  Future<void> saveLog(HydrationLog log) async {
    await _migrateLegacyLogsIfNeeded();
    await _isar.writeTxn(() async {
      await _isar.hydrationLogs.put(log);
    });
  }

  Future<List<HydrationLog>> _getAllLogs() async {
    final logs = await _isar.hydrationLogs.where().findAll();
    logs.sort((a, b) => a.id.compareTo(b.id));
    return logs;
  }

  Future<void> deleteLog(int logId) async {
    await _migrateLegacyLogsIfNeeded();
    await _isar.writeTxn(() async {
      await _isar.hydrationLogs.delete(logId);
    });
  }

  Future<HydrationLog?> getLog(int logId) async {
    await _migrateLegacyLogsIfNeeded();
    return await _isar.hydrationLogs.get(logId);
  }

  // --- DailySummary ---

  Future<DailySummary?> getDailySummary(String userId, DateTime date) async {
    await _migrateLegacySummariesIfNeeded();
    final summaries = await _getAllSummaries();
    try {
      return summaries.firstWhere(
        (s) =>
            s.userId == userId &&
            s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// Fetch history summaries sorted by date descending
  Future<List<DailySummary>> getHistorySummaries(
    String userId, {
    int limit = 7,
  }) async {
    await _migrateLegacySummariesIfNeeded();
    final summaries = await _getAllSummaries();
    final userSummaries = summaries.where((s) => s.userId == userId).toList();
    // Sort descending (newest first)
    userSummaries.sort((a, b) => b.date.compareTo(a.date));

    if (limit > 0 && userSummaries.length > limit) {
      return userSummaries.sublist(0, limit);
    }
    return userSummaries;
  }

  Future<void> upsertDailySummary(DailySummary summary) async {
    await _migrateLegacySummariesIfNeeded();
    final summaries = await _getAllSummaries();
    final index = summaries.indexWhere(
      (s) =>
          s.userId == summary.userId &&
          s.date.year == summary.date.year &&
          s.date.month == summary.date.month &&
          s.date.day == summary.date.day,
    );

    if (index >= 0) {
      summary.id = summaries[index].id;
    }
    await _isar.writeTxn(() async {
      await _isar.dailySummarys.put(summary);
    });
  }

  Future<List<DailySummary>> _getAllSummaries() async {
    final summaries = await _isar.dailySummarys.where().findAll();
    summaries.sort((a, b) => a.id.compareTo(b.id));
    return summaries;
  }

  Future<void> _migrateLegacyLogsIfNeeded() async {
    if (_prefs.getBool(_logsMigrationKey) == true) return;

    final existing = await _isar.hydrationLogs.where().findFirst();
    if (existing != null) {
      await _prefs.setBool(_logsMigrationKey, true);
      return;
    }

    final jsonString = _prefs.getString(_logsKey);
    if (jsonString == null) {
      await _prefs.setBool(_logsMigrationKey, true);
      return;
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final logs = jsonList
        .map((json) => HydrationLog.fromJson(json as Map<String, dynamic>))
        .toList();

    if (logs.isNotEmpty) {
      await _isar.writeTxn(() async {
        await _isar.hydrationLogs.putAll(logs);
      });
    }
    await _prefs.setBool(_logsMigrationKey, true);
  }

  Future<void> _migrateLegacySummariesIfNeeded() async {
    if (_prefs.getBool(_summariesMigrationKey) == true) return;

    final existing = await _isar.dailySummarys.where().findFirst();
    if (existing != null) {
      await _prefs.setBool(_summariesMigrationKey, true);
      return;
    }

    final jsonString = _prefs.getString(_summaryKey);
    if (jsonString == null) {
      await _prefs.setBool(_summariesMigrationKey, true);
      return;
    }

    final List<dynamic> jsonList = jsonDecode(jsonString);
    final summaries = jsonList
        .map((json) => DailySummary.fromJson(json as Map<String, dynamic>))
        .toList();

    if (summaries.isNotEmpty) {
      await _isar.writeTxn(() async {
        await _isar.dailySummarys.putAll(summaries);
      });
    }
    await _prefs.setBool(_summariesMigrationKey, true);
  }

  // ── Notification Action Queue (F-07) ────────────────────────────────────────

  /// Appends a notification action to the pending queue in SharedPreferences.
  ///
  /// Safe to call from a background isolate — reads/writes raw prefs only.
  /// The [prefs] parameter must be obtained via [SharedPreferences.getInstance()]
  /// directly (not via a provider) when called from background isolate.
  static Future<void> queueActionLog({
    required SharedPreferences prefs,
    required NotificationActionLog action,
  }) async {
    final existing = prefs.getString(kPendingActionsKey);
    final list = existing != null
        ? NotificationActionLog.decodeList(existing)
        : <NotificationActionLog>[];
    list.add(action);
    await prefs.setString(
      kPendingActionsKey,
      NotificationActionLog.encodeList(list),
    );
  }

  /// Reads all queued notification action logs, saves each as a [HydrationLog]
  /// with [loggedVia] = `'notification_action'`, then clears the queue.
  ///
  /// FIX H-01: Loads all existing logs ONCE, appends all queued items,
  /// saves ONCE — avoiding O(N²) read/write cycles on large datasets.
  ///
  /// Called from Splash screen's startup chain (Step 4.5) before dashboard
  /// navigation, after userId is available from the profile.
  Future<List<HydrationLog>> flushActionQueue(String userId) async {
    final jsonString = _prefs.getString(kPendingActionsKey);
    if (jsonString == null || jsonString.isEmpty) return [];

    final actions = NotificationActionLog.decodeList(jsonString);
    if (actions.isEmpty) return [];

    await _migrateLegacyLogsIfNeeded();
    final committed = <HydrationLog>[];

    for (final action in actions) {
      final log = HydrationLog()
        ..userId = userId
        ..volume = action.volume
        ..timestamp = action.timestamp
        ..loggedVia = 'notification_action'
        ..isSynced = false
        ..createdAt = action.timestamp;
      committed.add(log);
    }

    await _isar.writeTxn(() async {
      await _isar.hydrationLogs.putAll(committed);
    });

    // Clear the queue after successful flush
    await _prefs.remove(kPendingActionsKey);

    debugPrint(
      '[LoggingRepository] Flushed ${committed.length} queued notification action(s)',
    );
    return committed;
  }
}

final loggingRepositoryProvider = Provider<LoggingRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return LoggingRepository(isar, prefs);
});
