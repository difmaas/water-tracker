import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hydration_log_model.dart';
import 'daily_summary_model.dart';
import '../../../providers/onboarding_provider.dart';
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
}

final loggingRepositoryProvider = Provider<LoggingRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LoggingRepository(prefs);
});
