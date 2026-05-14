import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_profile_model.dart';
import '../../../providers/onboarding_provider.dart';

/// Persists UserProfile using SharedPreferences (JSON proxy).
///
/// NOTE: This is a temporary stability workaround due to Isar generator
/// incompatibility with the current dev environment. All field names
/// exactly mirror the Isar schema to allow a clean migration later.
///
/// IMPORTANT: `nama` is stored locally here but MUST NEVER appear in
/// the SyncService Supabase payload — excluded explicitly in SyncService.
class ProfileRepository {
  final SharedPreferences _prefs;
  static const _key = 'user_profile_json';

  ProfileRepository(this._prefs);

  Future<void> saveProfile(UserProfile profile) async {
    final json = {
      'userId': profile.userId,
      // nama: Isar-only field. Intentionally included here for local persistence.
      // SyncService explicitly excludes this field from the Supabase payload.
      'nama': profile.nama,
      'tanggalLahir': profile.tanggalLahir.toIso8601String(),
      'jenisKelamin': profile.jenisKelamin,
      'beratBadan': profile.beratBadan,
      'levelAktivitas': profile.levelAktivitas,
      'letakGeografis': profile.letakGeografis,
      'riwayatPenyakit': profile.riwayatPenyakit,
      'dailyTargetMl': profile.dailyTargetMl,
      'targetDiterima': profile.targetDiterima,
      'targetManualMl': profile.targetManualMl,
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

    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserProfile()
      ..userId = json['userId'] as String
      ..nama = json['nama'] as String
      ..tanggalLahir = DateTime.parse(json['tanggalLahir'] as String)
      ..jenisKelamin = json['jenisKelamin'] as String
      ..beratBadan = (json['beratBadan'] as num).toDouble()
      ..levelAktivitas = json['levelAktivitas'] as String
      ..letakGeografis = json['letakGeografis'] as String
      ..riwayatPenyakit = List<String>.from(json['riwayatPenyakit'] as List)
      ..dailyTargetMl = json['dailyTargetMl'] as int
      ..targetDiterima = json['targetDiterima'] as bool
      ..targetManualMl = json['targetManualMl'] as int?
      ..notificationPermissionGranted =
          json['notificationPermissionGranted'] as bool
      ..reminderSystemActive = json['reminderSystemActive'] as bool
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..lastOpenedAt = json['lastOpenedAt'] != null
          ? DateTime.parse(json['lastOpenedAt'] as String)
          : null
      ..dropoutFlag = json['dropoutFlag'] as bool
      ..isSynced = json['isSynced'] as bool;
  }

  Future<void> reconcileDailyData() async {
    // Placeholder — will contain lastOpenedAt comparison logic
    // once Isar-backed DailySummary is available.
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
