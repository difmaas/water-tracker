import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../features/profile/data/profile_repository.dart';
import '../../../providers/onboarding_provider.dart';

/// Handles auto-sync of local records to Supabase.
/// Called as fire-and-forget on every app open.
/// Failures are silent — data is safe in local storage.
class SyncService {
  final ProfileRepository _profileRepository;

  SyncService(this._profileRepository);

  Future<void> pushUnsyncedRecords() async {
    try {
      await _pushUserProfile();
      // TODO(F-07): pushHydrationLogs
      // TODO(F-07): pushReminderResponses
      // TODO(F-07): pushDailySummaries
    } catch (e) {
      // Sync failures are always silent per AGENTS.md
      // ignore: avoid_print
      print('[SyncService] Sync failed silently: $e');
    }
  }

  Future<void> _pushUserProfile() async {
    final profile = await _profileRepository.getUserProfile();
    if (profile == null || profile.isSynced) return;

    final client = Supabase.instance.client;

    // IMPORTANT: `nama` is explicitly excluded from this payload.
    // Per AGENTS.md and refactor spec, nama is stored locally only (Isar/SharedPrefs).
    // It must NEVER be pushed to Supabase.
    await client.from('users').upsert({
      'user_id': profile.userId,
      'tanggal_lahir': profile.tanggalLahir.toIso8601String().split('T').first,
      'jenis_kelamin': profile.jenisKelamin,
      'berat_badan': profile.beratBadan,
      'level_aktivitas': profile.levelAktivitas,
      'letak_geografis': profile.letakGeografis,
      'riwayat_penyakit': profile.riwayatPenyakit,
      'daily_target_ml': profile.dailyTargetMl,
      'target_diterima': profile.targetDiterima,
      'target_manual_ml': profile.targetManualMl,
      'notification_permission_granted': profile.notificationPermissionGranted,
      'reminder_system_active': profile.reminderSystemActive,
      'created_at': profile.createdAt.toIso8601String(),
      'dropout_flag': profile.dropoutFlag,
    });

    // Mark synced in local storage
    profile.isSynced = true;
    await _profileRepository.saveProfile(profile);
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final profileRepo = ref.read(profileRepositoryProvider);
  return SyncService(profileRepo);
});
