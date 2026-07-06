import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logging/data/daily_summary_model.dart';
import '../../logging/data/hydration_log_model.dart';
import '../../logging/data/logging_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/user_profile_model.dart';
import '../../../core/utils/id_utils.dart';
import '../../../providers/onboarding_provider.dart';

class CsvExportResult {
  final String csvText;
  final String fileName;
  final String filePath;
  final int rowCount;

  const CsvExportResult({
    required this.csvText,
    required this.fileName,
    required this.filePath,
    required this.rowCount,
  });
}

class CsvExportEmptyException implements Exception {
  const CsvExportEmptyException();
}

class CsvExportService {
  final ProfileRepository _profileRepo;
  final LoggingRepository _loggingRepo;
  final SharedPreferences _prefs;

  const CsvExportService(this._profileRepo, this._loggingRepo, this._prefs);

  Future<UserProfile> _getVerifiedProfile() async {
    final profile = await _profileRepo.getUserProfile();
    if (profile == null) {
      throw const CsvExportEmptyException();
    }
    if (profile.participantId.isEmpty) {
      profile.participantId = generateParticipantId();
      await _profileRepo.saveProfile(profile);
    }
    return profile;
  }

  Future<CsvExportResult> exportDailySummary({
    int rangeDays = 14,
    DateTime? now,
  }) async {
    final profile = await _getVerifiedProfile();

    final exportNow = now ?? DateTime.now();
    final today = DateTime(exportNow.year, exportNow.month, exportNow.day);
    final start = today.subtract(Duration(days: rangeDays - 1));
    final endExclusive = today.add(const Duration(days: 1));

    final logs = await _loggingRepo.getLogsInRange(
      profile.userId,
      start: start,
      end: endExclusive,
    );

    final summaries = await _loggingRepo.getHistorySummaries(
      profile.userId,
      limit: 0,
    );
    final summariesByDate = <DateTime, DailySummary>{};
    for (final summary in summaries) {
      final key = _dateOnly(summary.date);
      summariesByDate[key] = summary;
    }

    final logsByDate = <DateTime, List<HydrationLog>>{};
    for (final log in logs) {
      final key = _dateOnly(log.timestamp);
      logsByDate.putIfAbsent(key, () => <HydrationLog>[]).add(log);
    }

    final isLightweight = _prefs.getBool('lightweightMode') ?? true;
    final appMode = isLightweight ? 'lightweight' : 'main';
    final profileCreatedAt = _dateOnly(profile.createdAt);

    final rows = <List<String>>[
      [
        'participant_id',
        'nama',
        'tanggal',
        'day_index',
        'target_harian_ml',
        'total_minum_ml',
        'persentase_target',
        'status_target',
        'jumlah_catatan_minum',
        'waktu_minum_pertama',
        'waktu_minum_terakhir',
        'app_mode',
      ],
    ];

    int rowsWritten = 0;
    for (int i = 0; i < rangeDays; i++) {
      final date = start.add(Duration(days: i));
      final dailyLogs = logsByDate[date] ?? <HydrationLog>[];
      dailyLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final summary = summariesByDate[date];
      final targetMl = summary?.targetMl ?? profile.dailyTargetMl;
      final totalMl = dailyLogs.fold<int>(0, (sum, log) => sum + log.volume);
      final percentage = targetMl > 0
          ? ((totalMl / targetMl) * 100).round()
          : 0;

      final diffDays = date.difference(profileCreatedAt).inDays;
      final dayIndex = diffDays < 0 ? 1 : diffDays + 1;

      final String timeFirst = dailyLogs.isNotEmpty
          ? _formatTime(dailyLogs.first.timestamp)
          : '-';
      final String timeLast = dailyLogs.isNotEmpty
          ? _formatTime(dailyLogs.last.timestamp)
          : '-';

      rows.add([
        profile.participantId,
        profile.nama,
        _formatDate(date),
        dayIndex.toString(),
        targetMl.toString(),
        totalMl.toString(),
        percentage.toString(),
        _targetStatus(percentage),
        dailyLogs.length.toString(),
        timeFirst,
        timeLast,
        appMode,
      ]);
      rowsWritten++;
    }

    final csvText = rows.map(_csvRow).join('\n');
    final fileName = 'sehati_daily_summary_${_formatFileDate(exportNow)}.csv';
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvText, flush: true);

    debugPrint(
      '[CsvExportService] Exported $rowsWritten daily summary rows to ${file.path}',
    );

    return CsvExportResult(
      csvText: csvText,
      fileName: fileName,
      filePath: file.path,
      rowCount: rowsWritten,
    );
  }

  Future<CsvExportResult> exportDrinkLogs({
    int rangeDays = 14,
    DateTime? now,
  }) async {
    final profile = await _getVerifiedProfile();

    final exportNow = now ?? DateTime.now();
    final today = DateTime(exportNow.year, exportNow.month, exportNow.day);
    final start = today.subtract(Duration(days: rangeDays - 1));
    final endExclusive = today.add(const Duration(days: 1));

    final logs = await _loggingRepo.getLogsInRange(
      profile.userId,
      start: start,
      end: endExclusive,
    );

    if (logs.isEmpty) {
      throw const CsvExportEmptyException();
    }

    final logsByDate = <DateTime, List<HydrationLog>>{};
    for (final log in logs) {
      final key = _dateOnly(log.timestamp);
      logsByDate.putIfAbsent(key, () => <HydrationLog>[]).add(log);
    }

    final profileCreatedAt = _dateOnly(profile.createdAt);

    final rows = <List<String>>[
      [
        'participant_id',
        'nama',
        'tanggal',
        'day_index',
        'log_ke',
        'waktu_minum',
        'volume_ml',
      ],
    ];

    int logsCount = 0;
    final sortedDates = logsByDate.keys.toList()..sort();
    for (final date in sortedDates) {
      final dailyLogs = logsByDate[date]!
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final diffDays = date.difference(profileCreatedAt).inDays;
      final dayIndex = diffDays < 0 ? 1 : diffDays + 1;

      for (int index = 0; index < dailyLogs.length; index++) {
        final log = dailyLogs[index];
        rows.add([
          profile.participantId,
          profile.nama,
          _formatDate(date),
          dayIndex.toString(),
          (index + 1).toString(),
          _formatTime(log.timestamp),
          log.volume.toString(),
        ]);
        logsCount++;
      }
    }

    final csvText = rows.map(_csvRow).join('\n');
    final fileName = 'sehati_drink_logs_${_formatFileDate(exportNow)}.csv';
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csvText, flush: true);

    debugPrint(
      '[CsvExportService] Exported $logsCount drink logs to ${file.path}',
    );

    return CsvExportResult(
      csvText: csvText,
      fileName: fileName,
      filePath: file.path,
      rowCount: logsCount,
    );
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _targetStatus(int percentage) {
    if (percentage >= 100) return 'tercapai';
    if (percentage >= 75) return 'baik';
    if (percentage >= 50) return 'kurang';
    if (percentage >= 1) return 'rendah';
    return 'tidak_ada_data';
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatFileDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _csvRow(List<String> values) {
    return values.map(_csvValue).join(',');
  }

  static String _csvValue(String value) {
    final needsQuotes =
        value.contains(',') || value.contains('"') || value.contains('\n');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  final profileRepo = ref.watch(profileRepositoryProvider);
  final loggingRepo = ref.watch(loggingRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return CsvExportService(profileRepo, loggingRepo, prefs);
});
