import 'package:isar/isar.dart';

// part 'user_profile_model.g.dart';

// @collection
class UserProfile {
  Id id = Isar.autoIncrement;
  late String userId;           // UUID v4, generated once at profile setup
  late String gender;           // 'male' | 'female'
  late int age;
  late double weightKg;
  late String activityLevel;    // 'sedentary'|'light'|'moderate'|'active'|'very_active'
  late int dailyTargetMl;
  late bool targetAccepted;
  int? manualTargetMl;
  late bool notificationPermissionGranted;
  late bool reminderSystemActive;
  late DateTime createdAt;
  DateTime? lastOpenedAt;       // updated on every app open
  bool dropoutFlag = false;
  bool isSynced = false;

  UserProfile();

  UserProfile copyWith({
    String? userId,
    String? gender,
    int? age,
    double? weightKg,
    String? activityLevel,
    int? dailyTargetMl,
    bool? targetAccepted,
    int? manualTargetMl,
    bool? notificationPermissionGranted,
    bool? reminderSystemActive,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
    bool? dropoutFlag,
    bool? isSynced,
  }) {
    return UserProfile()
      ..id = id
      ..userId = userId ?? this.userId
      ..gender = gender ?? this.gender
      ..age = age ?? this.age
      ..weightKg = weightKg ?? this.weightKg
      ..activityLevel = activityLevel ?? this.activityLevel
      ..dailyTargetMl = dailyTargetMl ?? this.dailyTargetMl
      ..targetAccepted = targetAccepted ?? this.targetAccepted
      ..manualTargetMl = manualTargetMl ?? this.manualTargetMl
      ..notificationPermissionGranted = notificationPermissionGranted ?? this.notificationPermissionGranted
      ..reminderSystemActive = reminderSystemActive ?? this.reminderSystemActive
      ..createdAt = createdAt ?? this.createdAt
      ..lastOpenedAt = lastOpenedAt ?? this.lastOpenedAt
      ..dropoutFlag = dropoutFlag ?? this.dropoutFlag
      ..isSynced = isSynced ?? this.isSynced;
  }
}
