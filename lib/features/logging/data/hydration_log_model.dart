// features/logging/data/hydration_log_model.dart
import 'package:isar_community/isar.dart';

part 'hydration_log_model.g.dart';

@collection
class HydrationLog {
  Id id = Isar.autoIncrement;
  late String userId;
  late int volume;
  late DateTime timestamp;
  late String loggedVia; // 'app' | 'notification_action'
  bool isSynced = false;
  late DateTime createdAt;

  HydrationLog();

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'volume': volume,
    'timestamp': timestamp.toIso8601String(),
    'loggedVia': loggedVia,
    'isSynced': isSynced,
    'createdAt': createdAt.toIso8601String(),
  };

  factory HydrationLog.fromJson(Map<String, dynamic> json) {
    return HydrationLog()
      ..id = json['id'] as int? ?? Isar.autoIncrement
      ..userId = json['userId'] as String
      ..volume = json['volume'] as int
      ..timestamp = DateTime.parse(json['timestamp'] as String)
      ..loggedVia = json['loggedVia'] as String
      ..isSynced = json['isSynced'] as bool
      ..createdAt = DateTime.parse(json['createdAt'] as String);
  }
}
