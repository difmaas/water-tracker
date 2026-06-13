import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app/app.dart';
import 'providers/isar_provider.dart';
import 'providers/onboarding_provider.dart';
import 'core/constants/app_constants.dart';
import 'features/logging/data/daily_summary_model.dart';
import 'features/logging/data/hydration_log_model.dart';
import 'features/reminder/data/reminder_response_model.dart';
import 'features/profile/data/user_profile_model.dart';
import 'features/reminder/data/reminder_response_repository.dart';

/// Global plugin instance — must be initialized before runApp().
/// Accessed by ReminderService via this top-level reference.
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ── Notification tap callbacks ───────────────────────────────────────────────────────────────────

/// Handles notification taps when the app is TERMINATED.
///
/// MUST be a top-level function — runs in a separate isolate.
/// Notification has no action buttons — tapping the body opens the app via OS.
/// Test notifications are silently ignored.
@pragma('vm:entry-point')
Future<void> _onBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  await _queueOpenedAppResponse(response);
}

/// Handles notification taps when the app is OPEN or BACKGROUNDED.
///
/// Notifications have no action buttons. Only path: user taps the notification
/// body — OS brings app to foreground and this callback fires with actionId == null.
/// Queues a ReminderResponse(actionUsed: 'opened_app') for research tracking.
void _onForegroundNotificationResponse(NotificationResponse response) {
  _queueOpenedAppResponse(response);
}

Future<void> _queueOpenedAppResponse(NotificationResponse response) async {
  // Ignore test notifications—no data writes
  if (response.id == NotificationIds.test ||
      response.payload == 'test_notification') {
    return;
  }

  final responseId = response.id;
  final isRegularReminder =
      responseId == NotificationIds.legacyRegular ||
      (responseId != null &&
          responseId >= NotificationIds.regularReminderBase &&
          responseId <
              NotificationIds.regularReminderBase +
                  NotificationIds.regularReminderMaxSlots);
  if (!isRegularReminder) return;

  // Only handle body taps (actionId == null)
  // There are no action buttons, so any non-null actionId is unexpected—ignore.
  if (response.actionId != null) return;

  final now = DateTime.now();
  final prefs = await SharedPreferences.getInstance();
  final payloadSentAt = response.payload != null
      ? DateTime.tryParse(response.payload!)
      : null;
  final fallbackSentAtStr = prefs.getString(kLastReminderSentAtKey);
  final fallbackSentAt = fallbackSentAtStr != null
      ? DateTime.tryParse(fallbackSentAtStr)
      : null;
  final sentAt = payloadSentAt ?? fallbackSentAt ?? now;
  final elapsed = now.difference(sentAt).inMinutes;
  final safeElapsed = elapsed < 0 ? 0 : elapsed;

  // F-08: Body tap — user opens app via notification
  await ReminderResponseRepository.queueResponse(
    prefs: prefs,
    response: PendingReminderResponse(
      completed: true,
      delayMinutes: safeElapsed,
      actionUsed: 'opened_app',
      timestamp: now,
      sentAt: sentAt,
    ),
  );
  debugPrint(
    '[Notification] Queued ReminderResponse(opened_app, delay=${safeElapsed}min)',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure system UI to run in edge-to-edge (fullscreen drawing behind status & navigation bars)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // 1. Initialize timezone data (required for flutter_local_notifications scheduling)
  tz.initializeTimeZones();
  // Use device local timezone — no switching support per FEATURES_V2.md
  tz.setLocalLocation(tz.local);

  // 2. Initialize flutter_local_notifications with notification callbacks
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

  // 4. Initialize Isar before ProviderScope so repositories are never unbound.
  final dir = await getApplicationDocumentsDirectory();
  final isar = await Isar.open([
    UserProfileSchema,
    HydrationLogSchema,
    DailySummarySchema,
    ReminderResponseSchema,
  ], directory: dir.path);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        isarProvider.overrideWithValue(isar),
      ],
      child: const HydrationApp(),
    ),
  );
}
