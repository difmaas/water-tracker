import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

import '../../main.dart' show flutterLocalNotificationsPlugin;
import '../../core/constants/app_constants.dart';
import '../profile/data/profile_repository.dart';
import '../logging/data/logging_repository.dart';
import 'data/reminder_response_repository.dart';
import 'domain/reminder_logic.dart';

/// Channel ID for hydration reminders.
const String _kChannelId = 'hydration_reminders';
const String _kChannelName = 'Pengingat Minum Air';
const String _kChannelDesc = 'Notifikasi pengingat minum air harian';

/// Handles all local notification scheduling for the Reminder System (F-06).
///
/// Rules from AGENTS_V3.md §7:
/// - initialize() called once immediately after profile confirmation
/// - rescheduleIfNeeded() called on every app open (Splash) + after every log
/// - Never schedule if notificationPermissionGranted: false
/// - AndroidScheduleMode.exactAllowWhileIdle required
/// - remindersSent incremented at schedule time, not fire time
/// - Tapping the notification opens the app; logging is done manually inside the app
class ReminderService {
  final ProfileRepository _profileRepo;
  final LoggingRepository _loggingRepo;
  final ReminderResponseRepository _responseRepo;
  Future<void>? _scheduleOperation;

  ReminderService(this._profileRepo, this._loggingRepo, this._responseRepo);

  // ── Permission Management ───────────────────────────────────────────────────

  /// Requests all necessary permissions for the reminder system.
  /// Handles Android 13+ Notification permission and Android 12+ Exact Alarm.
  Future<bool> requestPermissions() async {
    bool allGranted = true;

    // 1. Request Notification Permission (Android 13+)
    // Use the plugin's own method for better consistency with F-07 implementation.
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    final bool? notifGranted = await androidImplementation
        ?.requestNotificationsPermission();
    if (notifGranted != true) allGranted = false;

    // 1.5 Create the notification channel explicitly
    await _createNotificationChannel();

    final exactAlarmAllowed = await canScheduleExactAlarms();
    if (exactAlarmAllowed == false) {
      try {
        final bool? pluginExactGranted = await androidImplementation
            ?.requestExactAlarmsPermission();
        if (pluginExactGranted == false) allGranted = false;
      } catch (e) {
        debugPrint(
          '[ReminderService] requestExactAlarmsPermission unavailable: $e',
        );
      }
    }

    // 2. Request Exact Alarm Permission (Android 12+)
    // Only required if targeting API 31+ and using exact alarms.
    // Note: Permission.scheduleExactAlarm.request() usually opens settings on Android 14+.
    if (exactAlarmAllowed == null &&
        await Permission.scheduleExactAlarm.isDenied) {
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      if (!alarmStatus.isGranted) {
        allGranted = false;
      }
    }

    // 3. Update UserProfile with result
    await _updateProfilePermission(allGranted);

    // 4. If granted, trigger immediate reschedule
    if (allGranted) {
      await rescheduleWithNewWindow();
    }

    return allGranted;
  }

  Future<bool?> canScheduleExactAlarms() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    try {
      final pluginStatus = await androidImplementation
          ?.canScheduleExactNotifications();
      if (pluginStatus != null) return pluginStatus;
    } catch (e) {
      debugPrint(
        '[ReminderService] canScheduleExactNotifications unavailable: $e',
      );
    }

    try {
      final status = await Permission.scheduleExactAlarm.status;
      if (status.isGranted) return true;
      if (status.isDenied || status.isPermanentlyDenied) return false;
    } catch (e) {
      debugPrint('[ReminderService] Exact alarm status unavailable: $e');
    }

    return null;
  }

  Future<void> _updateProfilePermission(bool granted) async {
    final profile = await _profileRepo.getUserProfile();
    if (profile == null) return;

    if (profile.notificationPermissionGranted != granted) {
      final updated = profile.copyWith(
        notificationPermissionGranted: granted,
        reminderSystemActive: granted,
        isSynced: false,
      );
      await _profileRepo.saveProfile(updated);
      debugPrint(
        '[ReminderService] UserProfile updated: permissionGranted=$granted',
      );
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Called immediately after profile confirmation (F-03).
  /// Schedules all remaining regular reminder slots for the current day.
  Future<void> initialize(int targetMl) async {
    await rescheduleIfNeeded(currentMl: 0, targetMl: targetMl);
  }

  /// Called on every app open (Splash) and after every hydration log (addLog).
  /// Failures are silent, but scheduling work is serialized and awaited by callers.
  ///
  /// Logic:
  ///   - Cancel stored regular reminder IDs + legacy regular ID 42
  ///   - Keep test ID 44 and re-engagement ID 43 untouched
  ///   - Schedule all remaining fixed interval slots for the current local day
  Future<void> rescheduleIfNeeded({
    required int currentMl,
    required int targetMl,
  }) async {
    await _runScheduleOperation(
      () => _rebuildTodaySchedule(currentMl: currentMl, targetMl: targetMl),
    );
  }

  /// Forcefully reschedule the next reminder using a new time window.
  /// Called from Settings when window bounds are modified.
  Future<void> rescheduleWithNewWindow() async {
    debugPrint(
      '[ReminderService] Manual reschedule triggered via window change',
    );
    final profile = await _profileRepo.getUserProfile();
    if (profile == null) return;

    await cancelAll();

    final today = DateTime.now();
    final logs = await _loggingRepo.getLogsForDate(profile.userId, today);
    final currentMl = logs.fold<int>(0, (sum, log) => sum + log.volume);

    await rescheduleIfNeeded(
      currentMl: currentMl,
      targetMl: profile.targetManualMl ?? profile.dailyTargetMl,
    );
  }

  /// Schedules a re-engagement notification immediately when dropout (>3 days gap) is detected.
  Future<void> scheduleReEngagementNotification() async {
    try {
      final profile = await _profileRepo.getUserProfile();
      if (profile == null ||
          !profile.notificationPermissionGranted ||
          !profile.reminderSystemActive) {
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      // Show immediately using ID 43 to avoid touching regular/test reminders.
      await flutterLocalNotificationsPlugin.show(
        id: NotificationIds.reEngagement,
        title: '💧 Mari kembali terhidrasi!',
        body:
            'Sudah 3 hari kamu tidak memantau hidrasimu. Yuk, mulai minum air lagi bersama teman kecilmu!',
        notificationDetails: notificationDetails,
      );
      debugPrint('[ReminderService] Re-engagement notification sent');
    } catch (e) {
      debugPrint(
        '[ReminderService] scheduleReEngagementNotification failed: $e',
      );
    }
  }

  /// QA Debug: Firing local notification immediately (id: NotificationIds.test)
  /// with payload 'test_notification' and no action buttons.
  Future<void> fireTestNotificationNow() async {
    try {
      await _createNotificationChannel();

      const androidDetails = AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        id: NotificationIds.test,
        title: 'Tes Notifikasi SEHATI',
        body: 'Notifikasi uji coba berhasil muncul.',
        notificationDetails: notificationDetails,
        payload: 'test_notification',
      );
      debugPrint('[ReminderService] Test notification fired immediately');
    } catch (e) {
      debugPrint('[ReminderService] fireTestNotificationNow failed: $e');
    }
  }

  /// QA Debug: Scheduling local notification 1 minute from now (id: NotificationIds.test)
  /// with payload 'test_notification' and no action buttons.
  Future<void> scheduleTestNotification1Min() async {
    try {
      await _createNotificationChannel();

      const androidDetails = AndroidNotificationDetails(
        _kChannelId,
        _kChannelName,
        channelDescription: _kChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.public,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      final scheduledTime = DateTime.now().add(const Duration(minutes: 1));
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: NotificationIds.test,
        title: 'Tes Notifikasi Terjadwal',
        body: 'Notifikasi uji coba 1 menit berhasil muncul.',
        scheduledDate: tzScheduledTime,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'test_notification',
      );
      debugPrint('[ReminderService] Test notification scheduled in 1 minute');
    } catch (e) {
      debugPrint('[ReminderService] scheduleTestNotification1Min failed: $e');
    }
  }

  /// Debug-only inspection helper for QA.
  /// Returns a formatted summary of all pending local notifications.
  Future<String> debugDescribePendingNotifications() async {
    final profile = await _profileRepo.getUserProfile();
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final storedRegularIds =
        prefs.getStringList(kScheduledRegularReminderIdsKey) ?? const [];
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final systemNotificationsEnabled = await androidImplementation
        ?.areNotificationsEnabled();
    final exactAlarmAllowed = await canScheduleExactAlarms();
    final pending = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    pending.sort((a, b) => a.id.compareTo(b.id));

    String nextReminderText = 'not available';
    if (profile == null) {
      nextReminderText = 'no-profile';
    } else if (!profile.notificationPermissionGranted) {
      nextReminderText = 'notification-permission-inactive';
    } else if (!profile.reminderSystemActive) {
      nextReminderText = 'reminder-inactive';
    } else {
      final logs = await _loggingRepo.getLogsForDate(profile.userId, now);
      final currentMl = logs.fold<int>(0, (sum, log) => sum + log.volume);
      final targetMl = profile.targetManualMl ?? profile.dailyTargetMl;
      if (targetMl > 0 && currentMl >= targetMl) {
        nextReminderText = 'target-reached-today';
      } else {
        final nextReminder = ReminderLogic.nextReminderTime(
          now,
          reminderType: profile.reminderType,
          reminderIntervalHours: profile.reminderInterval,
          progress: targetMl > 0 ? currentMl / targetMl : 0,
          startHour: profile.reminderWindowStart,
          endHour: profile.reminderWindowEnd,
        );
        nextReminderText = nextReminder.toIso8601String();
      }
    }

    final regularIds = <int>[];
    final protectedIds = <int>[];
    final legacyIds = <int>[];
    final unexpectedRegularIds = <int>[];

    final buffer = StringBuffer()
      ..writeln('Pending notifications: ${pending.length}')
      ..writeln(
        'System notifications enabled: ${systemNotificationsEnabled ?? 'unknown'}',
      )
      ..writeln(
        'Exact alarm permission: ${exactAlarmAllowed == null ? 'unknown / not available on this Android version' : (exactAlarmAllowed ? 'allowed' : 'denied')}',
      )
      ..writeln(
        'Profile notificationPermissionGranted: ${profile?.notificationPermissionGranted ?? 'no-profile'}',
      )
      ..writeln(
        'Profile reminderSystemActive: ${profile?.reminderSystemActive ?? 'no-profile'}',
      )
      ..writeln('Derived next reminder time: $nextReminderText')
      ..writeln('Stored regular reminder IDs: ${storedRegularIds.join(', ')}')
      ..writeln('Regular reminder IDs use deterministic range: 10000+')
      ..writeln('Legacy ID 42 should be absent after rebuild')
      ..writeln('Protected IDs 43 and 44 are not touched by regular rebuild')
      ..writeln();

    for (final request in pending) {
      final id = request.id;
      final isRegular = _isReservedRegularId(id);
      final isProtected =
          id == NotificationIds.reEngagement || id == NotificationIds.test;
      final isLegacy = id == NotificationIds.legacyRegular;

      if (isRegular) {
        regularIds.add(id);
      } else if (isProtected) {
        protectedIds.add(id);
      } else if (isLegacy) {
        legacyIds.add(id);
      } else {
        unexpectedRegularIds.add(id);
      }

      buffer.writeln(
        'id=${request.id} | title=${request.title ?? '-'} | body=${request.body ?? '-'} | payload=${request.payload ?? '-'}',
      );
    }

    buffer
      ..writeln()
      ..writeln(
        'Test ID 44 pending: ${protectedIds.contains(NotificationIds.test)}',
      )
      ..writeln('Regular 10000+ pending: ${regularIds.isNotEmpty}')
      ..writeln('Regular range pending: ${regularIds.join(', ')}')
      ..writeln('Protected pending: ${protectedIds.join(', ')}')
      ..writeln('Legacy 42 pending: ${legacyIds.join(', ')}')
      ..writeln(
        'Unexpected non-regular IDs: ${unexpectedRegularIds.join(', ')}',
      );

    if (pending.isEmpty) {
      buffer.writeln('No pending notifications.');
    }

    return buffer.toString();
  }

  /// Cancels all pending regular reminder notifications.
  /// Called at: midnight reset.
  Future<void> cancelAll() async {
    await _runScheduleOperation(() async {
      try {
        final profile = await _profileRepo.getUserProfile();
        final now = DateTime.now();
        await _cancelStoredRegularNotifications();
        if (profile != null) {
          await _responseRepo.discardPendingScheduledAfter(profile.userId, now);
        }
      } catch (e) {
        debugPrint('[ReminderService] cancelAll() failed silently: $e');
      }
    });
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  Future<void> _runScheduleOperation(Future<void> Function() action) async {
    final inFlight = _scheduleOperation;
    if (inFlight != null) {
      await inFlight;
    }

    final operation = Future<void>.sync(action);
    _scheduleOperation = operation;
    try {
      await operation;
    } finally {
      if (identical(_scheduleOperation, operation)) {
        _scheduleOperation = null;
      }
    }
  }

  Future<void> _rebuildTodaySchedule({
    required int currentMl,
    required int targetMl,
  }) async {
    try {
      final profile = await _profileRepo.getUserProfile();
      if (profile == null) return;

      final now = DateTime.now();
      await _createNotificationChannel();
      await _cancelStoredRegularNotifications();

      if (!profile.notificationPermissionGranted ||
          !profile.reminderSystemActive) {
        await _responseRepo.discardPendingScheduledAfter(profile.userId, now);
        return;
      }

      if (targetMl > 0 && currentMl >= targetMl) {
        await _discardPendingRegularResponsesForToday(profile.userId, now);
        debugPrint(
          '[ReminderService] Daily target reached — canceled remaining regular reminders today',
        );
        return;
      }

      final slots = ReminderLogic.remainingSlotsForToday(
        now,
        reminderIntervalHours: profile.reminderInterval,
        startHour: profile.reminderWindowStart,
        endHour: profile.reminderWindowEnd,
      );

      final (startHour, _) = ReminderLogic.normalizedWindow(
        profile.reminderWindowStart,
        profile.reminderWindowEnd,
      );
      final intervalHours = ReminderLogic.normalizeIntervalHours(
        profile.reminderInterval,
      );
      final scheduledIds = <int>[];

      for (final slot in slots) {
        final id = _regularNotificationIdForSlot(
          slot,
          startHour: startHour,
          intervalHours: intervalHours,
        );
        if (!_isReservedRegularId(id)) continue;

        await _scheduleNotification(
          notificationId: id,
          scheduledTime: slot,
          userId: profile.userId,
        );
        scheduledIds.add(id);
      }

      await _storeScheduledRegularIds(scheduledIds);
      await _responseRepo.discardPendingScheduledAfterExcept(
        profile.userId,
        now,
        keepScheduledTimes: slots,
      );

      debugPrint(
        '[ReminderService] Rebuilt regular reminders — ${scheduledIds.length} slot(s) scheduled today',
      );
    } catch (e) {
      debugPrint('[ReminderService] _rebuildTodaySchedule failed silently: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int notificationId,
    required DateTime scheduledTime,
    required String userId,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: notificationId,
      title: 'Waktunya Minum Air',
      body: 'Ambil jeda sebentar dan catat minummu di SEHATI.',
      scheduledDate: tzScheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: scheduledTime.toIso8601String(),
    );

    // F-08: Persist sentAt timestamp for ReminderResponse paths.
    // Written at schedule time so response callbacks can compute delayMinutes.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        kLastReminderSentAtKey,
        scheduledTime.toIso8601String(),
      );
      // Clear the last-recorded guard so the new notification can be responded to
      await prefs.remove(kLastResponseRecordedAtKey);
    } catch (e) {
      debugPrint('[ReminderService] Failed to persist sentAt: $e');
    }

    // F-06/F-08: Create a pending ReminderResponse at schedule time (actionUsed: null).
    // This enables lazy no_response detection on next app open.
    // Per AGENTS_V3 §15 and §7.
    final pendingCreated = await _responseRepo.createPending(
      userId: userId,
      notificationScheduledAt: scheduledTime,
    );

    if (pendingCreated) {
      await _incrementRemindersSent(userId, scheduledTime);
    }
  }

  Future<void> _cancelStoredRegularNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(kScheduledRegularReminderIdsKey) ?? [];
      final ids = <int>{
        NotificationIds.legacyRegular,
        for (final parsed in stored.map(int.tryParse).nonNulls) parsed,
        for (var i = 0; i < NotificationIds.regularReminderMaxSlots; i++)
          NotificationIds.regularReminderBase + i,
      };

      for (final id in ids) {
        await flutterLocalNotificationsPlugin.cancel(id: id);
      }
      await prefs.remove(kScheduledRegularReminderIdsKey);
    } catch (e) {
      debugPrint(
        '[ReminderService] _cancelStoredRegularNotifications failed silently: $e',
      );
    }
  }

  Future<void> _storeScheduledRegularIds(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    if (ids.isEmpty) {
      await prefs.remove(kScheduledRegularReminderIdsKey);
      return;
    }

    await prefs.setStringList(
      kScheduledRegularReminderIdsKey,
      ids.map((id) => id.toString()).toList(growable: false),
    );
  }

  Future<void> _discardPendingRegularResponsesForToday(
    String userId,
    DateTime now,
  ) async {
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    await _responseRepo.discardPendingScheduledBetween(userId, now, endOfToday);
  }

  int _regularNotificationIdForSlot(
    DateTime slot, {
    required int startHour,
    required int intervalHours,
  }) {
    final firstSlot = DateTime(slot.year, slot.month, slot.day, startHour);
    final slotIndex =
        slot.difference(firstSlot).inMinutes ~/ (intervalHours * 60);
    return NotificationIds.regularReminderBase + slotIndex;
  }

  bool _isReservedRegularId(int id) {
    return id >= NotificationIds.regularReminderBase &&
        id <
            NotificationIds.regularReminderBase +
                NotificationIds.regularReminderMaxSlots;
  }

  /// Upserts the DailySummary for [date], incrementing remindersSent by 1.
  ///
  /// FIX C-02: [date] is now the scheduledTime date, not necessarily today.
  /// This ensures notifications scheduled for tomorrow morning are attributed
  /// to tomorrow's research record, not today's.
  Future<void> _incrementRemindersSent(String userId, DateTime date) async {
    try {
      final existing = await _loggingRepo.getDailySummary(userId, date);
      if (existing != null) {
        final updated = existing.copyWith(
          remindersSent: existing.remindersSent + 1,
          isSynced: false,
        );
        await _loggingRepo.upsertDailySummary(updated);
      }
      // If no DailySummary yet for that date, skip —
      // the summary will be created on the correct day's app open.
    } catch (e) {
      debugPrint(
        '[ReminderService] _incrementRemindersSent failed silently: $e',
      );
    }
  }

  /// Explicitly creates the notification channel for Android.
  Future<void> _createNotificationChannel() async {
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation == null) return;

    const channel = AndroidNotificationChannel(
      _kChannelId,
      _kChannelName,
      description: _kChannelDesc,
      importance: Importance.high,
    );

    await androidImplementation.createNotificationChannel(channel);
    debugPrint('[ReminderService] Notification channel created: $_kChannelId');
  }
}
