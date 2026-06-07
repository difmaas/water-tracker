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

/// Fixed notification ID — always replace, never stack.
/// Prevents multiple notifications on aggressive OEM devices.
const int _kNotificationId = 42;

/// Channel ID for hydration reminders.
const String _kChannelId = 'hydration_reminders';
const String _kChannelName = 'Pengingat Minum Air';
const String _kChannelDesc = 'Notifikasi pengingat minum air harian';

/// Handles all local notification scheduling for the Reminder System (F-06)
/// and Direct Action Notification (F-07).
///
/// Rules from AGENTS_V2.md §7:
/// - initialize() called once immediately after profile confirmation
/// - rescheduleIfNeeded() called on every app open (Splash) + after every log
/// - Never schedule if notificationPermissionGranted: false
/// - AndroidScheduleMode.exactAllowWhileIdle required
/// - remindersSent incremented at schedule time, not fire time
/// - Action buttons (+250ml, +500ml, Buka App) on every notification (F-07)
class ReminderService {
  final ProfileRepository _profileRepo;
  final LoggingRepository _loggingRepo;
  final ReminderResponseRepository _responseRepo;

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

    // 2. Request Exact Alarm Permission (Android 12+)
    // Only required if targeting API 31+ and using exact alarms.
    // Note: Permission.scheduleExactAlarm.request() usually opens settings on Android 14+.
    if (await Permission.scheduleExactAlarm.isDenied) {
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
  /// Schedules the first reminder and activates the reminder system.
  Future<void> initialize(int targetMl) async {
    try {
      final profile = await _profileRepo.getUserProfile();
      if (profile == null) return;

      // Guard: skip if user denied notification permission
      if (!profile.notificationPermissionGranted) {
        debugPrint('[ReminderService] Skipping init — permission not granted');
        return;
      }

      // Ensure channel exists
      await _createNotificationChannel();

      final now = DateTime.now();
      final scheduledTime = ReminderLogic.nextReminderTime(
        now,
        reminderType: profile.reminderType,
        reminderIntervalHours: profile.reminderInterval,
        startHour: profile.reminderWindowStart,
        endHour: profile.reminderWindowEnd,
        progress: 0.0,
      );

      await _scheduleNotification(
        scheduledTime: scheduledTime,
        currentMl: 0,
        targetMl: targetMl,
        userId: profile.userId,
        today: now,
      );

      debugPrint(
        '[ReminderService] Initialized — first reminder at $scheduledTime',
      );
    } catch (e) {
      debugPrint('[ReminderService] initialize() failed silently: $e');
    }
  }

  /// Called on every app open (Splash) and after every hydration log (addLog).
  /// Fire-and-forget — failures are always silent.
  ///
  /// Logic (from ARCHITECTURE_V3.md §4 Boot Recovery):
  ///   - Check pending notifications
  ///   - Pending exists → skip (already scheduled)
  ///   - No pending + within window + progress < 80% → reschedule now
  ///   - Progress > 80% → schedule tomorrow morning (overwrites today's)
  Future<void> rescheduleIfNeeded({
    required int currentMl,
    required int targetMl,
  }) async {
    try {
      final profile = await _profileRepo.getUserProfile();
      if (profile == null) return;

      if (!profile.notificationPermissionGranted ||
          !profile.reminderSystemActive) {
        return;
      }

      // Check if a notification is already pending
      final pending = await flutterLocalNotificationsPlugin
          .pendingNotificationRequests();
      final alreadyScheduled = pending.any((n) => n.id == _kNotificationId);

      if (alreadyScheduled) {
        debugPrint(
          '[ReminderService] Pending notification exists — skipping reschedule',
        );
        return;
      }

      // No pending notification → schedule next one
      final now = DateTime.now();
      final progress = targetMl > 0 ? (currentMl / targetMl) : 0.0;
      final scheduledTime = ReminderLogic.nextReminderTime(
        now,
        reminderType: profile.reminderType,
        reminderIntervalHours: profile.reminderInterval,
        startHour: profile.reminderWindowStart,
        endHour: profile.reminderWindowEnd,
        progress: progress,
      );

      await _scheduleNotification(
        scheduledTime: scheduledTime,
        currentMl: currentMl,
        targetMl: targetMl,
        userId: profile.userId,
        today: now,
      );

      debugPrint('[ReminderService] Rescheduled — next at $scheduledTime');
    } catch (e) {
      debugPrint('[ReminderService] rescheduleIfNeeded() failed silently: $e');
    }
  }

  /// Forcefully reschedule the next reminder using a new time window.
  /// Called from Settings when window bounds are modified.
  Future<void> rescheduleWithNewWindow() async {
    debugPrint(
      '[ReminderService] Manual reschedule triggered via window change',
    );
    await cancelAll();

    final profile = await _profileRepo.getUserProfile();
    if (profile == null) return;

    final today = DateTime.now();
    final logs = await _loggingRepo.getLogsForDate(profile.userId, today);
    final currentMl = logs.fold<int>(0, (sum, log) => sum + log.volume);

    await rescheduleIfNeeded(
      currentMl: currentMl,
      targetMl: profile.dailyTargetMl,
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
      );
      const notificationDetails = NotificationDetails(android: androidDetails);

      // Show immediately (using a unique ID 43 to avoid overwriting regular reminders)
      await flutterLocalNotificationsPlugin.show(
        id: 43,
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

  /// Cancels all pending hydration reminder notifications.
  /// Called at: midnight reset.
  Future<void> cancelAll() async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id: _kNotificationId);
    } catch (e) {
      debugPrint('[ReminderService] cancelAll() failed silently: $e');
    }
  }

  // ── Private Helpers ─────────────────────────────────────────────────────────

  Future<void> _scheduleNotification({
    required DateTime scheduledTime,
    required int currentMl,
    required int targetMl,
    required String userId,
    required DateTime today,
  }) async {
    final progressPercent = targetMl > 0
        ? ((currentMl / targetMl) * 100).toInt()
        : 0;
    final remainingMl = (targetMl - currentMl).clamp(0, targetMl);
    final String notificationBody;
    if (progressPercent >= 80) {
      notificationBody =
          'Sedikit lagi menuju targetmu. Kurang ${remainingMl}ml lagi!';
    } else {
      notificationBody =
          'Jangan lupa minum air hari ini. Kurang ${remainingMl}ml lagi.';
    }

    final androidDetails = AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      // Expanded notification shows progress details
      styleInformation: BigTextStyleInformation(
        notificationBody,
        contentTitle: '💧 Waktunya minum air!',
        summaryText: 'Hidrasi Tracker',
      ),
      // F-07: Direct action buttons — user logs without opening app
      actions: const [
        AndroidNotificationAction(
          kActionId250,
          '+250ml',
          showsUserInterface: false, // background log, no app open
        ),
        AndroidNotificationAction(
          kActionId500,
          '+500ml',
          showsUserInterface: false, // background log, no app open
        ),
        AndroidNotificationAction(
          kActionIdOpenApp,
          'Buka App',
          showsUserInterface: true, // opens app to dashboard
        ),
      ],
    );

    final notificationDetails = NotificationDetails(android: androidDetails);
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: _kNotificationId,
      title: '💧 Waktunya minum air!',
      body: notificationBody,
      scheduledDate: tzScheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
    await _responseRepo.createPending(
      userId: userId,
      notificationScheduledAt: scheduledTime,
    );

    // FIX C-02: Only increment remindersSent for the day the notification fires.
    // If scheduledTime is tomorrow (outside today's window), attribute to that day.
    await _incrementRemindersSent(userId, scheduledTime);
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
