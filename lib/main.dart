import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app/app.dart';
import 'providers/onboarding_provider.dart';
import 'core/constants/app_constants.dart';
import 'features/reminder/data/notification_action_log.dart';
import 'features/reminder/data/reminder_response_model.dart';
import 'features/logging/data/logging_repository.dart';
import 'features/reminder/data/reminder_response_repository.dart';

/// Global plugin instance — must be initialized before runApp().
/// Accessed by ReminderService via this top-level reference.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ── F-07: Background notification action callback ────────────────────────────

/// Handles notification action taps when the app is TERMINATED.
///
/// MUST be a top-level function — runs in a separate isolate.
/// Cannot access Riverpod providers, Isar, or any app state.
/// Writes to SharedPreferences directly using the pending action queue pattern.
@pragma('vm:entry-point')
Future<void> _onBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  final actionId = response.actionId;
  if (actionId == null) return;

  // Only handle +250ml and +500ml — "Buka App" (showsUserInterface: true)
  // is handled by the OS opening the app directly.
  if (actionId != kActionId250 && actionId != kActionId500) return;

  final volume = actionId == kActionId250 ? 250 : 500;
  final actionUsed = actionId == kActionId250 ? 'button_250' : 'button_500';

  try {
    final prefs = await SharedPreferences.getInstance();

    // F-07: Queue the hydration log
    await LoggingRepository.queueActionLog(
      prefs: prefs,
      action: NotificationActionLog(
        volume: volume,
        timestamp: DateTime.now(),
        actionId: actionId,
      ),
    );

    // F-08: Queue the ReminderResponse (button tap — delayMinutes always 0)
    final sentAtStr = prefs.getString(kLastReminderSentAtKey);
    final sentAt = sentAtStr != null
        ? DateTime.parse(sentAtStr)
        : DateTime.now();
    await ReminderResponseRepository.queueResponse(
      prefs: prefs,
      response: PendingReminderResponse(
        completed: true,
        delayMinutes: 0,
        actionUsed: actionUsed,
        timestamp: DateTime.now(),
        sentAt: sentAt,
      ),
    );

    debugPrint('[Background] Queued ${volume}ml + ReminderResponse($actionUsed)');
  } catch (e) {
    debugPrint('[Background] Failed to queue action: $e');
  }
}

// ── F-07: Foreground notification action callback ────────────────────────────

/// Handles notification action taps when the app is OPEN or BACKGROUNDED.
///
/// Uses the same queue pattern for consistency — Splash flushes on next visit
/// to the foreground (which happens immediately for foreground taps).
void _onForegroundNotificationResponse(NotificationResponse response) {
  final actionId = response.actionId;
  final now = DateTime.now();

  SharedPreferences.getInstance().then((prefs) async {
    final sentAtStr = prefs.getString(kLastReminderSentAtKey);
    final sentAt = sentAtStr != null ? DateTime.parse(sentAtStr) : now;
    final elapsed = now.difference(sentAt).inMinutes;

    if (actionId == kActionId250 || actionId == kActionId500) {
      // F-07: Button tap — queue hydration log
      final volume = actionId == kActionId250 ? 250 : 500;
      final actionUsed = actionId == kActionId250 ? 'button_250' : 'button_500';

      await LoggingRepository.queueActionLog(
        prefs: prefs,
        action: NotificationActionLog(
          volume: volume,
          timestamp: now,
          actionId: actionId!, // non-null: guarded by enclosing if condition
        ),
      );

      // F-08: Queue ReminderResponse for button tap
      await ReminderResponseRepository.queueResponse(
        prefs: prefs,
        response: PendingReminderResponse(
          completed: true,
          delayMinutes: 0,
          actionUsed: actionUsed,
          timestamp: now,
          sentAt: sentAt,
        ),
      );
      debugPrint('[Foreground] Queued ${volume}ml + ReminderResponse($actionUsed)');
    } else if (actionId == null) {
      // F-08: Notification body tap (no actionId) — user opens app
      await ReminderResponseRepository.queueResponse(
        prefs: prefs,
        response: PendingReminderResponse(
          completed: true,
          delayMinutes: elapsed,
          actionUsed: 'opened_app',
          timestamp: now,
          sentAt: sentAt,
        ),
      );
      debugPrint('[Foreground] Queued ReminderResponse(opened_app, delay=${elapsed}min)');
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize timezone data (required for flutter_local_notifications scheduling)
  tz.initializeTimeZones();
  // Use device local timezone — no switching support per FEATURES_V2.md
  tz.setLocalLocation(tz.local);

  // 2. Initialize flutter_local_notifications with F-07 callbacks
  const androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
    // Foreground / backgrounded tap handler
    onDidReceiveNotificationResponse: _onForegroundNotificationResponse,
    // Terminated app tap handler — runs in separate isolate
    onDidReceiveBackgroundNotificationResponse:
        _onBackgroundNotificationResponse,
  );

  // 3. Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // 4. Initialize Isar (TODO: Re-enable after generator fix)
  // final dir = await getApplicationDocumentsDirectory();
  // final isar = await Isar.open(
  //   [UserProfileSchema, DailySummarySchema],
  //   directory: dir.path,
  // );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        // isarProvider.overrideWithValue(isar),
      ],
      child: const HydrationApp(),
    ),
  );
}
