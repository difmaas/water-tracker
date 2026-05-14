import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_model.dart';
import '../../../providers/onboarding_provider.dart';

class ProfileRepository {
  final SharedPreferences _prefs;
  static const _key = 'user_profile_json';

  ProfileRepository(this._prefs);

  Future<void> saveProfile(UserProfile profile) async {
    // For now, using SharedPreferences as a stable proxy due to Isar generator issues
    final json = {
      'userId': profile.userId,
      'gender': profile.gender,
      'age': profile.age,
      'weightKg': profile.weightKg,
      'activityLevel': profile.activityLevel,
      'dailyTargetMl': profile.dailyTargetMl,
      'targetAccepted': profile.targetAccepted,
      'manualTargetMl': profile.manualTargetMl,
      'notificationPermissionGranted': profile.notificationPermissionGranted,
      'reminderSystemActive': profile.reminderSystemActive,
      'createdAt': profile.createdAt.toIso8601String(),
      'lastOpenedAt': profile.lastOpenedAt?.toIso8601String(),
      'dropoutFlag': profile.dropoutFlag,
      'isSynced': profile.isSynced,
    };
    await _prefs.setString(_key, jsonEncode(json));
  }

  Future<UserProfile?> getUserProfile() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return null;

    final json = jsonDecode(jsonString);
    return UserProfile()
      ..userId = json['userId']
      ..gender = json['gender']
      ..age = json['age']
      ..weightKg = json['weightKg']
      ..activityLevel = json['activityLevel']
      ..dailyTargetMl = json['dailyTargetMl']
      ..targetAccepted = json['targetAccepted']
      ..manualTargetMl = json['manualTargetMl']
      ..notificationPermissionGranted = json['notificationPermissionGranted']
      ..reminderSystemActive = json['reminderSystemActive']
      ..createdAt = DateTime.parse(json['createdAt'])
      ..lastOpenedAt = json['lastOpenedAt'] != null ? DateTime.parse(json['lastOpenedAt']) : null
      ..dropoutFlag = json['dropoutFlag']
      ..isSynced = json['isSynced'];
  }

  Future<void> reconcileDailyData() async {
    // Placeholder - Logic moved to SharedPreferences proxy for stability
  }

  Future<void> updateLastOpenedAt(DateTime timestamp) async {
    final profile = await getUserProfile();
    if (profile != null) {
      profile.lastOpenedAt = timestamp;
      await saveProfile(profile);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileRepository(prefs);
});
