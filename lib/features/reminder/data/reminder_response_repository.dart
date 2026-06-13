// features/reminder/data/reminder_response_repository.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:isar_community/isar.dart';

import '../../../providers/isar_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../logging/data/logging_repository.dart';
import 'reminder_response_model.dart';

/// Persists [ReminderResponse] records in Isar.
class ReminderResponseRepository {
  final Isar _isar;
  final SharedPreferences _prefs;
  final LoggingRepository _loggingRepo;

  static const _responsesKey = 'reminder_responses_json';
  static const _migrationKey = 'isar_migrated_reminder_responses_json';

  ReminderResponseRepository(this._isar, this._prefs, this._loggingRepo);

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Creates a new pending [ReminderResponse] when a notification is SCHEDULED.
  ///
  /// Per AGENTS_V3 §15: ReminderResponse is created at schedule time with
  /// actionUsed: null. It is later updated when user responds or lazy detection runs.
  Future<bool> createPending({
    required String userId,
    required DateTime notificationScheduledAt,
  }) async {
    try {
      final now = notificationScheduledAt;
      final response = ReminderResponse()
        ..userId = userId
        ..completed = false
        ..delayMinutes = null
        ..actionUsed = null
        ..notificationScheduledAt = notificationScheduledAt
        ..timestamp = now
        ..isSynced = false
        ..createdAt = now;

      await _migrateLegacyResponsesIfNeeded();
      final existing = await _isar.reminderResponses.where().findAll();
      final alreadyExists = existing.any(
        (r) =>
            r.userId == userId &&
            r.actionUsed == null &&
            r.notificationScheduledAt.toIso8601String() ==
                notificationScheduledAt.toIso8601String(),
      );
      if (alreadyExists) {
        debugPrint(
          '[ReminderResponseRepository] Pending already exists for scheduledAt=$notificationScheduledAt',
        );
        return false;
      }

      await _isar.writeTxn(() async {
        await _isar.reminderResponses.put(response);
      });

      debugPrint(
        '[ReminderResponseRepository] Created pending for scheduledAt=$notificationScheduledAt',
      );
      return true;
    } catch (e) {
      debugPrint('[ReminderResponseRepository] createPending() failed: $e');
      return false;
    }
  }

  /// Updates an existing pending ReminderResponse to a completed state.
  ///
  /// Finds the record by [notificationScheduledAt] and updates it in-place.
  /// If no pending record found (e.g. first install, old data), creates one.
  ///
  /// FIX C-01: Uses [notificationScheduledAt.toLocal()] date for DailySummary attribution,
  /// NOT DateTime.now() — ensures stats are attributed to the correct research day.
  Future<void> markResponded({
    required String userId,
    required bool completed,
    required int delayMinutes,
    required String actionUsed,
    required DateTime notificationScheduledAt,
  }) async {
    try {
      final now = DateTime.now();
      final safeDelayMinutes = delayMinutes < 0 ? 0 : delayMinutes;
      await _migrateLegacyResponsesIfNeeded();
      final all = await _getAll();

      // Find the pending record for this notification
      final idx = all.lastIndexWhere(
        (r) =>
            r.userId == userId &&
            r.actionUsed == null &&
            r.notificationScheduledAt.toIso8601String() ==
                notificationScheduledAt.toIso8601String(),
      );

      if (idx >= 0) {
        // Update existing pending record
        all[idx] = all[idx].copyWith(
          completed: completed,
          delayMinutes: safeDelayMinutes,
          actionUsed: actionUsed,
          timestamp: now,
          isSynced: false,
        );
      } else {
        // No pending record found — create a complete record directly
        final response = ReminderResponse()
          ..userId = userId
          ..completed = completed
          ..delayMinutes = safeDelayMinutes
          ..actionUsed = actionUsed
          ..notificationScheduledAt = notificationScheduledAt
          ..timestamp = now
          ..isSynced = false
          ..createdAt = now;
        all.add(response);
      }

      // Single batch write — H-02 fix
      await _saveAll(all);

      // Mark deduplication guard
      await _prefs.setString(
        kLastResponseRecordedAtKey,
        notificationScheduledAt.toIso8601String(),
      );

      // FIX C-01: Attribute to the date the notification was scheduled, not today
      if (completed) {
        await _incrementRemindersResponded(
          userId,
          notificationScheduledAt.toLocal(),
        );
      }

      debugPrint(
        '[ReminderResponseRepository] Marked: actionUsed=$actionUsed, '
        'completed=$completed, delay=${safeDelayMinutes}min',
      );
    } catch (e) {
      debugPrint('[ReminderResponseRepository] markResponded() failed: $e');
    }
  }

  // ── Queue helpers (SharedPreferences, background-isolate safe) ─────────────

  /// Appends a [PendingReminderResponse] to the SharedPreferences queue.
  /// Safe to call from background isolate — no Riverpod, no Isar.
  static Future<void> queueResponse({
    required SharedPreferences prefs,
    required PendingReminderResponse response,
  }) async {
    final existing = prefs.getString(kPendingReminderResponsesKey);
    final list = existing != null
        ? PendingReminderResponse.decodeList(existing)
        : <PendingReminderResponse>[];
    final responseKey = response.sentAt.toIso8601String();
    if (list.any((item) => item.sentAt.toIso8601String() == responseKey)) {
      return;
    }
    list.add(response);
    await prefs.setString(
      kPendingReminderResponsesKey,
      PendingReminderResponse.encodeList(list),
    );
  }

  /// Reads and flushes all pending queued responses into the main store.
  ///
  /// FIX H-02: Loads all records once, processes all pending items,
  /// then saves everything in a single write operation.
  ///
  /// Called from Splash Step 4.6 after [userId] is known.
  Future<void> flushQueue(String userId) async {
    final jsonString = _prefs.getString(kPendingReminderResponsesKey);
    if (jsonString == null || jsonString.isEmpty) return;

    final pending = PendingReminderResponse.decodeList(jsonString);
    final lastRecorded = _prefs.getString(kLastResponseRecordedAtKey);
    await _migrateLegacyResponsesIfNeeded();
    final all = await _getAll();
    bool modified = false;
    String? latestRecordedKey;
    final processedQueuedKeys = <String>{};

    for (final p in pending) {
      final sentAtKey = p.sentAt.toIso8601String();

      if (!processedQueuedKeys.add(sentAtKey)) {
        debugPrint(
          '[ReminderResponseRepository] Skipping duplicate queued response for sentAt=${p.sentAt}',
        );
        continue;
      }

      // Skip if we already recorded a response for this sentAt timestamp
      if (lastRecorded != null && lastRecorded == sentAtKey) {
        debugPrint(
          '[ReminderResponseRepository] Skipping duplicate for sentAt=${p.sentAt}',
        );
        continue;
      }

      final now = DateTime.now();
      final safeDelayMinutes = p.delayMinutes < 0 ? 0 : p.delayMinutes;

      // Find and update matching pending record
      final idx = all.lastIndexWhere(
        (r) =>
            r.userId == userId &&
            r.actionUsed == null &&
            r.notificationScheduledAt.toIso8601String() == sentAtKey,
      );

      if (idx >= 0) {
        all[idx] = all[idx].copyWith(
          completed: p.completed,
          delayMinutes: safeDelayMinutes,
          actionUsed: p.actionUsed,
          timestamp: now,
          isSynced: false,
        );
      } else {
        // No matching pending — create directly
        final response = ReminderResponse()
          ..userId = userId
          ..completed = p.completed
          ..delayMinutes = safeDelayMinutes
          ..actionUsed = p.actionUsed
          ..notificationScheduledAt = p.sentAt
          ..timestamp = now
          ..isSynced = false
          ..createdAt = now;
        all.add(response);
      }

      modified = true;
      latestRecordedKey = sentAtKey;

      // FIX C-01: Attribute to the correct day
      if (p.completed) {
        await _incrementRemindersResponded(userId, p.sentAt.toLocal());
      }
    }

    if (modified) {
      // Single batch save — H-02 fix
      await _saveAll(all);
    }

    if (latestRecordedKey != null) {
      await _prefs.setString(kLastResponseRecordedAtKey, latestRecordedKey);
    }
    await _prefs.remove(kPendingReminderResponsesKey);
  }

  // ── No-response lazy detection (AGENTS_V3 §7) ────────────────────────────

  /// FIX H-03: Detects ALL pending responses older than [cutoffMinutes],
  /// not just the last one. Runs on every app open (Splash Step 4).
  ///
  /// For each ReminderResponse where:
  ///   - actionUsed == null (still pending)
  ///   - notificationScheduledAt is > cutoffMinutes ago
  /// → Mark as no_response. Does NOT increment remindersResponded.
  Future<void> checkAndMarkNoResponses(
    String userId, {
    int cutoffMinutes = 60,
  }) async {
    try {
      await _migrateLegacyResponsesIfNeeded();
      final all = await _getAll();
      final cutoff = DateTime.now().subtract(Duration(minutes: cutoffMinutes));
      bool modified = false;

      for (int i = 0; i < all.length; i++) {
        final r = all[i];
        if (r.userId != userId) continue;
        if (r.actionUsed != null) continue; // already responded
        if (r.notificationScheduledAt.isAfter(cutoff)) continue; // too recent

        // Mark as no_response
        all[i] = r.copyWith(
          completed: false,
          delayMinutes: cutoffMinutes,
          actionUsed: 'no_response',
          timestamp: DateTime.now(),
          isSynced: false,
        );
        modified = true;
        debugPrint(
          '[ReminderResponseRepository] Marked no_response for scheduledAt=${r.notificationScheduledAt}',
        );
        // NOTE: remindersResponded is NOT incremented for no_response (per AGENTS_V3 §7)
      }

      if (modified) {
        await _saveAll(all);
      }
    } catch (e) {
      debugPrint(
        '[ReminderResponseRepository] checkAndMarkNoResponses() failed: $e',
      );
    }
  }

  /// Drops pending records for notifications that were scheduled but canceled
  /// before firing, preventing false no_response rows after settings changes.
  Future<void> discardPendingScheduledAfter(
    String userId,
    DateTime cutoff,
  ) async {
    try {
      await _migrateLegacyResponsesIfNeeded();
      final all = await _getAll();
      final toDelete = all
          .where(
            (r) =>
                r.userId == userId &&
                r.actionUsed == null &&
                r.notificationScheduledAt.isAfter(cutoff),
          )
          .map((r) => r.id)
          .toList();

      if (toDelete.isEmpty) return;

      await _isar.writeTxn(() async {
        await _isar.reminderResponses.deleteAll(toDelete);
      });

      debugPrint(
        '[ReminderResponseRepository] Discarded ${toDelete.length} canceled pending response(s)',
      );
    } catch (e) {
      debugPrint(
        '[ReminderResponseRepository] discardPendingScheduledAfter() failed: $e',
      );
    }
  }

  /// Drops future pending records except the scheduled times that are still
  /// backed by a rebuilt regular reminder notification.
  Future<void> discardPendingScheduledAfterExcept(
    String userId,
    DateTime cutoff, {
    required Iterable<DateTime> keepScheduledTimes,
  }) async {
    try {
      await _migrateLegacyResponsesIfNeeded();
      final keep = keepScheduledTimes
          .map((time) => time.toIso8601String())
          .toSet();
      final all = await _getAll();
      final toDelete = all
          .where(
            (r) =>
                r.userId == userId &&
                r.actionUsed == null &&
                r.notificationScheduledAt.isAfter(cutoff) &&
                !keep.contains(r.notificationScheduledAt.toIso8601String()),
          )
          .map((r) => r.id)
          .toList();

      if (toDelete.isEmpty) return;

      await _isar.writeTxn(() async {
        await _isar.reminderResponses.deleteAll(toDelete);
      });

      debugPrint(
        '[ReminderResponseRepository] Discarded ${toDelete.length} stale pending response(s)',
      );
    } catch (e) {
      debugPrint(
        '[ReminderResponseRepository] discardPendingScheduledAfterExcept() failed: $e',
      );
    }
  }

  /// Drops pending records for canceled regular reminders inside a local time
  /// range, preventing false no_response rows after target-achieved cleanup.
  Future<void> discardPendingScheduledBetween(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      await _migrateLegacyResponsesIfNeeded();
      final all = await _getAll();
      final toDelete = all
          .where(
            (r) =>
                r.userId == userId &&
                r.actionUsed == null &&
                r.notificationScheduledAt.isAfter(start) &&
                !r.notificationScheduledAt.isAfter(end),
          )
          .map((r) => r.id)
          .toList();

      if (toDelete.isEmpty) return;

      await _isar.writeTxn(() async {
        await _isar.reminderResponses.deleteAll(toDelete);
      });

      debugPrint(
        '[ReminderResponseRepository] Discarded ${toDelete.length} canceled same-day pending response(s)',
      );
    } catch (e) {
      debugPrint(
        '[ReminderResponseRepository] discardPendingScheduledBetween() failed: $e',
      );
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// FIX C-01: Takes [date] as parameter — uses notification's scheduled date,
  /// not DateTime.now(). Prevents cross-day data attribution errors.
  Future<void> _incrementRemindersResponded(
    String userId,
    DateTime date,
  ) async {
    try {
      final existing = await _loggingRepo.getDailySummary(userId, date);
      if (existing != null) {
        final updated = existing.copyWith(
          remindersResponded: existing.remindersResponded + 1,
          isSynced: false,
        );
        await _loggingRepo.upsertDailySummary(updated);
      }
    } catch (e) {
      debugPrint(
        '[ReminderResponseRepository] _incrementRemindersResponded failed: $e',
      );
    }
  }

  Future<List<ReminderResponse>> _getAll() async {
    final responses = await _isar.reminderResponses.where().findAll();
    responses.sort((a, b) => a.id.compareTo(b.id));
    return responses;
  }

  Future<void> _migrateLegacyResponsesIfNeeded() async {
    if (_prefs.getBool(_migrationKey) == true) return;

    final existing = await _isar.reminderResponses.where().findFirst();
    if (existing != null) {
      await _prefs.setBool(_migrationKey, true);
      return;
    }

    final jsonString = _prefs.getString(_responsesKey);
    if (jsonString == null) {
      await _prefs.setBool(_migrationKey, true);
      return;
    }

    final List<dynamic> raw = jsonDecode(jsonString);
    final responses = raw
        .map((e) => ReminderResponse.fromJson(e as Map<String, dynamic>))
        .toList();
    if (responses.isNotEmpty) {
      await _isar.writeTxn(() async {
        await _isar.reminderResponses.putAll(responses);
      });
    }
    await _prefs.setBool(_migrationKey, true);
  }

  Future<void> _saveAll(List<ReminderResponse> responses) async {
    await _isar.writeTxn(() async {
      await _isar.reminderResponses.putAll(responses);
    });
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final reminderResponseRepositoryProvider = Provider<ReminderResponseRepository>(
  (ref) {
    final isar = ref.watch(isarProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final loggingRepo = ref.watch(loggingRepositoryProvider);
    return ReminderResponseRepository(isar, prefs, loggingRepo);
  },
);
