import 'package:isar/isar.dart';

// part 'daily_summary_model.g.dart';

// @collection
class DailySummary {
  Id id = Isar.autoIncrement;
  late String userId;
  late DateTime date;
  late int targetMl;
  late int achievedMl;
  late double complianceRate;   // achievedMl / targetMl
  late int remindersSent;
  late int remindersResponded;
  late int sessionCount;        // incremented on every app open for this date
  late bool streakMaintained;   // complianceRate >= 0.8
  DateTime? firstLogTimestamp;
  int? streakBreakHour;         // hour of last log if streak broken
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
}
