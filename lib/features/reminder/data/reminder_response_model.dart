// features/reminder/data/reminder_response_model.dart
import 'dart:convert';
import 'package:isar_community/isar.dart';

part 'reminder_response_model.g.dart';

/// Canonical schema per AGENTS_V3.md §15.
///
/// Captures user behavior after every reminder notification for research
/// analysis (F-08). One record per notification outcome.
///
/// Lifecycle:
///   1. Created when notification is SCHEDULED with actionUsed: null
///   2. Updated when user taps the notification and opens the app
///   3. Updated by lazy detection on app open if still null after 60 min → 'no_response'
@collection
class ReminderResponse {
  Id id = Isar.autoIncrement;

  /// Local UUID v4 — foreign key to UserProfile.userId.
  late String userId;

  /// Whether the user responded to the notification.
  /// true  → notification tap opened the app
  /// false → no response detected within 60 min
  late bool completed;

  /// Minutes elapsed between notification sent and response.
  /// 0 for action button taps (immediate).
  /// 60 for no_response path.
  /// Actual elapsed for opened_app paths.
  int? delayMinutes;

  /// How the user responded. One of:
  /// 'opened_app' | 'no_response' | null (pending)
  String? actionUsed;

  /// AGENTS_V3 §15 — When the notification was SCHEDULED (device clock).
  /// Used for:
  ///   - Lazy no_response detection: if actionUsed == null and
  ///     notificationScheduledAt is > 60 min ago → mark as no_response
  ///   - delayMinutes calculation for opened_app responses
  late DateTime notificationScheduledAt;

  /// When this response record was last updated (app-side clock).
  late DateTime timestamp;

  bool isSynced = false;
  late DateTime createdAt;

  ReminderResponse();

  ReminderResponse copyWith({
    String? userId,
    bool? completed,
    int? delayMinutes,
    String? actionUsed,
    DateTime? notificationScheduledAt,
    DateTime? timestamp,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return ReminderResponse()
      ..id = id
      ..userId = userId ?? this.userId
      ..completed = completed ?? this.completed
      ..delayMinutes = delayMinutes ?? this.delayMinutes
      ..actionUsed = actionUsed ?? this.actionUsed
      ..notificationScheduledAt =
          notificationScheduledAt ?? this.notificationScheduledAt
      ..timestamp = timestamp ?? this.timestamp
      ..isSynced = isSynced ?? this.isSynced
      ..createdAt = createdAt ?? this.createdAt;
  }

  // ── JSON serialization for legacy migration and background queues ───────

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'completed': completed,
    'delayMinutes': delayMinutes,
    'actionUsed': actionUsed,
    'notificationScheduledAt': notificationScheduledAt.toIso8601String(),
    'timestamp': timestamp.toIso8601String(),
    'isSynced': isSynced,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ReminderResponse.fromJson(Map<String, dynamic> json) {
    final scheduledAtStr = json['notificationScheduledAt'] as String?;
    return ReminderResponse()
      ..id = json['id'] as int? ?? Isar.autoIncrement
      ..userId = json['userId'] as String
      ..completed = json['completed'] as bool
      ..delayMinutes = json['delayMinutes'] as int?
      ..actionUsed = json['actionUsed'] as String?
      // Graceful fallback: existing records without this field default to timestamp
      ..notificationScheduledAt = scheduledAtStr != null
          ? DateTime.parse(scheduledAtStr)
          : DateTime.parse(json['timestamp'] as String)
      ..timestamp = DateTime.parse(json['timestamp'] as String)
      ..isSynced = json['isSynced'] as bool? ?? false
      ..createdAt = DateTime.parse(json['createdAt'] as String);
  }
}

// ── Pending queue model (SharedPreferences, background-isolate safe) ─────────

/// Lightweight queue entry for ReminderResponses captured in notification
/// callbacks before the full repository is available.
///
/// Background isolate cannot access Riverpod providers — writes this to
/// SharedPreferences. Splash Step 4.6 flushes into [ReminderResponse] records.
class PendingReminderResponse {
  final bool completed;
  final int delayMinutes;
  final String actionUsed;
  final DateTime timestamp;

  /// The sentAt timestamp of the notification this response belongs to.
  /// Used to deduplicate via [kLastResponseRecordedAtKey].
  final DateTime sentAt;

  const PendingReminderResponse({
    required this.completed,
    required this.delayMinutes,
    required this.actionUsed,
    required this.timestamp,
    required this.sentAt,
  });

  Map<String, dynamic> toJson() => {
    'completed': completed,
    'delayMinutes': delayMinutes,
    'actionUsed': actionUsed,
    'timestamp': timestamp.toIso8601String(),
    'sentAt': sentAt.toIso8601String(),
  };

  factory PendingReminderResponse.fromJson(Map<String, dynamic> json) =>
      PendingReminderResponse(
        completed: json['completed'] as bool,
        delayMinutes: json['delayMinutes'] as int,
        actionUsed: json['actionUsed'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        sentAt: DateTime.parse(json['sentAt'] as String),
      );

  static String encodeList(List<PendingReminderResponse> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  static List<PendingReminderResponse> decodeList(String jsonString) {
    final List<dynamic> raw = jsonDecode(jsonString);
    return raw
        .map((e) => PendingReminderResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
