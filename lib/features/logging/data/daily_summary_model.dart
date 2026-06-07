// features/logging/data/daily_summary_model.dart
import 'package:isar_community/isar.dart';

part 'daily_summary_model.g.dart';

@collection
class DailySummary {
  Id id = Isar.autoIncrement;
  late String userId;
  late DateTime date;
  late int targetMl;
  late int achievedMl;
  late double complianceRate; // achievedMl / targetMl
  late int remindersSent;
  late int remindersResponded;
  late int sessionCount; // incremented on every app open for this date
  late bool streakMaintained; // complianceRate >= 0.8
  DateTime? firstLogTimestamp;
  int? streakBreakHour; // hour of last log if streak broken
  bool dropoutFlag = false;
  bool isSynced = false;
  late DateTime createdAt;

  DailySummary();

  DailySummary copyWith({
    String? userId,
    DateTime? date,
    int? targetMl,
    int? achievedMl,
    double? complianceRate,
    int? remindersSent,
    int? remindersResponded,
    int? sessionCount,
    bool? streakMaintained,
    DateTime? firstLogTimestamp,
    int? streakBreakHour,
    bool? dropoutFlag,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return DailySummary()
      ..id = id
      ..userId = userId ?? this.userId
      ..date = date ?? this.date
      ..targetMl = targetMl ?? this.targetMl
      ..achievedMl = achievedMl ?? this.achievedMl
      ..complianceRate = complianceRate ?? this.complianceRate
      ..remindersSent = remindersSent ?? this.remindersSent
      ..remindersResponded = remindersResponded ?? this.remindersResponded
      ..sessionCount = sessionCount ?? this.sessionCount
      ..streakMaintained = streakMaintained ?? this.streakMaintained
      ..firstLogTimestamp = firstLogTimestamp ?? this.firstLogTimestamp
      ..streakBreakHour = streakBreakHour ?? this.streakBreakHour
      ..dropoutFlag = dropoutFlag ?? this.dropoutFlag
      ..isSynced = isSynced ?? this.isSynced
      ..createdAt = createdAt ?? this.createdAt;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'date': date.toIso8601String(),
    'targetMl': targetMl,
    'achievedMl': achievedMl,
    'complianceRate': complianceRate,
    'remindersSent': remindersSent,
    'remindersResponded': remindersResponded,
    'sessionCount': sessionCount,
    'streakMaintained': streakMaintained,
    'firstLogTimestamp': firstLogTimestamp?.toIso8601String(),
    'streakBreakHour': streakBreakHour,
    'dropoutFlag': dropoutFlag,
    'isSynced': isSynced,
    'createdAt': createdAt.toIso8601String(),
  };

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary()
      ..id = json['id'] as int? ?? Isar.autoIncrement
      ..userId = json['userId'] as String
      ..date = DateTime.parse(json['date'] as String)
      ..targetMl = json['targetMl'] as int
      ..achievedMl = json['achievedMl'] as int
      ..complianceRate = (json['complianceRate'] as num).toDouble()
      ..remindersSent = json['remindersSent'] as int
      ..remindersResponded = json['remindersResponded'] as int
      ..sessionCount = json['sessionCount'] as int
      ..streakMaintained = json['streakMaintained'] as bool
      ..firstLogTimestamp = json['firstLogTimestamp'] != null
          ? DateTime.parse(json['firstLogTimestamp'] as String)
          : null
      ..streakBreakHour = json['streakBreakHour'] as int?
      ..dropoutFlag = json['dropoutFlag'] as bool
      ..isSynced = json['isSynced'] as bool
      ..createdAt = DateTime.parse(json['createdAt'] as String);
  }
}
