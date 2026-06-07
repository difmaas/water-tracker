import 'dart:convert';

/// Lightweight model for a hydration log queued by a background notification
/// action tap (F-07).
///
/// Background isolate cannot access Riverpod or Isar. Instead the callback
/// serializes this model to SharedPreferences. The Splash screen flushes the
/// queue on the next app open via [LoggingRepository.flushActionQueue].
class NotificationActionLog {
  final int volume;
  final DateTime timestamp;
  final String actionId; // 'action_250' | 'action_500'

  const NotificationActionLog({
    required this.volume,
    required this.timestamp,
    required this.actionId,
  });

  Map<String, dynamic> toJson() => {
    'volume': volume,
    'timestamp': timestamp.toIso8601String(),
    'actionId': actionId,
  };

  factory NotificationActionLog.fromJson(Map<String, dynamic> json) =>
      NotificationActionLog(
        volume: json['volume'] as int,
        timestamp: DateTime.parse(json['timestamp'] as String),
        actionId: json['actionId'] as String,
      );

  /// Encodes a list of pending actions to a JSON string for SharedPreferences.
  static String encodeList(List<NotificationActionLog> list) =>
      jsonEncode(list.map((e) => e.toJson()).toList());

  /// Decodes a JSON string from SharedPreferences into a list of pending actions.
  static List<NotificationActionLog> decodeList(String jsonString) {
    final List<dynamic> raw = jsonDecode(jsonString);
    return raw
        .map((e) => NotificationActionLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
