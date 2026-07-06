import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_model.dart';
import '../../logging/data/daily_summary_model.dart';
import '../../logging/data/hydration_log_model.dart';
import '../../reminder/data/reminder_response_model.dart';
import '../../../providers/isar_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../core/utils/id_utils.dart';

/// IMPORTANT: `nama` is stored locally here but MUST NEVER appear in
/// the SyncService Supabase payload — excluded explicitly in SyncService.
class ProfileRepository {
  final Isar _isar;
  final SharedPreferences _prefs;
  static const _key = 'user_profile_json';
  static const _migrationKey = 'isar_migrated_user_profile_json';

  ProfileRepository(this._isar, this._prefs);

  Future<void> saveProfile(UserProfile profile) async {
    await _migrateLegacyProfileIfNeeded();

    if (profile.id == Isar.autoIncrement || profile.id == 0) {
      final existing = await _getStoredProfile();
      if (existing != null && existing.userId == profile.userId) {
        profile.id = existing.id;
      }
    }

    await _isar.writeTxn(() async {
      await _isar.userProfiles.put(profile);
    });
  }

  Future<UserProfile?> getUserProfile() async {
    await _migrateLegacyProfileIfNeeded();
    final profile = await _getStoredProfile();
    if (profile != null && profile.participantId.isEmpty) {
      profile.participantId = generateParticipantId();
      await saveProfile(profile);
    }
    return profile;
  }

  Future<UserProfile?> _getStoredProfile() async {
    return _isar.userProfiles.where().findFirst();
  }

  Future<void> _migrateLegacyProfileIfNeeded() async {
    if (_prefs.getBool(_migrationKey) == true) return;

    final existing = await _isar.userProfiles.where().findFirst();
    if (existing != null) {
      await _prefs.setBool(_migrationKey, true);
      return;
    }

    final jsonString = _prefs.getString(_key);
    if (jsonString == null) {
      await _prefs.setBool(_migrationKey, true);
      return;
    }

    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final profile = UserProfile.fromJson(json);
    await _isar.writeTxn(() async {
      await _isar.userProfiles.put(profile);
    });
    await _prefs.setBool(_migrationKey, true);
  }

  Future<void> reconcileDailyData() async {
    // Placeholder for future startup reconciliation beyond splash logic.
  }

  Future<void> updateLastOpenedAt(DateTime timestamp) async {
    final profile = await getUserProfile();
    if (profile != null) {
      profile.lastOpenedAt = timestamp;
      await saveProfile(profile);
    }
  }

  Future<void> clearAllData() async {
    // Aggressive clear for research reset
    await _isar.writeTxn(() async {
      await _isar.userProfiles.clear();
      await _isar.hydrationLogs.clear();
      await _isar.dailySummarys.clear();
      await _isar.reminderResponses.clear();
    });
    await _prefs.clear();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final isar = ref.watch(isarProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileRepository(isar, prefs);
});
