import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hydration_log_model.dart';
import 'daily_summary_model.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../reminder/data/notification_action_log.dart';
import 'package:isar/isar.dart';

/// Persists HydrationLogs and DailySummaries using SharedPreferences (JSON proxy).
///
/// NOTE: This is a temporary stability workaround due to Isar generator
/// incompatibility. Will be replaced by actual Isar calls in F-05.
class LoggingRepository {
  final SharedPreferences _prefs;
  static const _logsKey = 'hydration_logs_json';
  static const _summaryKey = 'daily_summaries_json';

  LoggingRepository(this._prefs);

  // --- HydrationLogs ---

  Future<List<HydrationLog>> getLogsForDate(String userId, DateTime date) async {
    final allLogs = await _getAllLogs();
    return allLogs.where((log) {
      return log.userId == userId &&
          log.timestamp.year == date.year &&
          log.timestamp.month == date.month &&
          log.timestamp.day == date.day;
    }).toList();
  }

  Future<void> saveLog(HydrationLog log) async {
    final logs = await _getAllLogs();
    // Simulate auto-increment ID
    if (log.id == Isar.autoIncrement || log.id == 0) {
      log.id = logs.isEmpty ? 1 : (logs.last.id + 1);
    }
    logs.add(log);
    await _saveAllLogs(logs);
  }

  Future<List<HydrationLog>> _getAllLogs() async {
    final jsonString = _prefs.getString(_logsKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => HydrationLog.fromJson(json)).toList();
  }

  Future<void> deleteLog(int logId) async {
    final logs = await _getAllLogs();
    logs.removeWhere((log) => log.id == logId);
    await _saveAllLogs(logs);
  }

  Future<void> _saveAllLogs(List<HydrationLog> logs) async {
    final jsonString = jsonEncode(logs.map((e) => e.toJson()).toList());
    await _prefs.setString(_logsKey, jsonString);
  }

  // --- DailySummary ---

  Future<DailySummary?> getDailySummary(String userId, DateTime date) async {
    final summaries = await _getAllSummaries();
    try {
      return summaries.firstWhere((s) =>
          s.userId == userId &&
          s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day);
    } catch (e) {
      return null;
    }
  }

  /// Fetch history summaries sorted by date descending
  Future<List<DailySummary>> getHistorySummaries(String userId, {int limit = 7}) async {
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
    final summaries = await _getAllSummaries();
    final index = summaries.indexWhere((s) =>
        s.userId == summary.userId &&
        s.date.year == summary.date.year &&
        s.date.month == summary.date.month &&
        s.date.day == summary.date.day);

    if (index >= 0) {
      // Simulate ID retention on update
      summary.id = summaries[index].id;
      summaries[index] = summary;
    } else {
      if (summary.id == Isar.autoIncrement || summary.id == 0) {
        summary.id = summaries.isEmpty ? 1 : (summaries.last.id + 1);
      }
      summaries.add(summary);
    }
    await _saveAllSummaries(summaries);
  }

  Future<List<DailySummary>> _getAllSummaries() async {
    final jsonString = _prefs.getString(_summaryKey);
    if (jsonString == null) return [];
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => DailySummary.fromJson(json)).toList();
  }

  Future<void> _saveAllSummaries(List<DailySummary> summaries) async {
    final jsonString = jsonEncode(summaries.map((e) => e.toJson()).toList());
    await _prefs.setString(_summaryKey, jsonString);
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
    await prefs.setString(kPendingActionsKey, NotificationActionLog.encodeList(list));
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

    // FIX H-01: Load all logs once
    final allLogs = await _getAllLogs();
    int nextId = allLogs.isEmpty ? 1 : (allLogs.last.id + 1);
    final committed = <HydrationLog>[];

    for (final action in actions) {
      final log = HydrationLog()
        ..userId = userId
        ..volume = action.volume
        ..timestamp = action.timestamp
        ..loggedVia = 'notification_action'
        ..isSynced = false
        ..createdAt = action.timestamp;

      log.id = nextId++;
      allLogs.add(log);
      committed.add(log);
    }

    // FIX H-01: Single batch write for all queued items
    await _saveAllLogs(allLogs);

    // Clear the queue after successful flush
    await _prefs.remove(kPendingActionsKey);

    debugPrint('[LoggingRepository] Flushed ${committed.length} queued notification action(s)');
    return committed;
  }
}

final loggingRepositoryProvider = Provider<LoggingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LoggingRepository(prefs);
});
