import 'package:isar/isar.dart';

// part 'user_profile_model.g.dart'; // Re-enable after Isar generator fix

/// Canonical UserProfile schema per AGENTS_V2 (V3) §15.
// @collection // Re-enable after Isar generator fix
class UserProfile {
  Id id = Isar.autoIncrement;

  // ── Identifiers ──────────────────────────────────────────────────────────────
  String userId = ''; // UUID v4 — generated once at profile setup

  // ── Personal Data (Local only — nama never synced to Supabase) ──────────────
  String nama = ''; // Min 3, max 10 chars, letters and spaces only. Never synced.
  DateTime tanggalLahir = DateTime(2000); // Age derived at runtime via AppDateUtils.ageFromBirthdate()

  // ── Physical Profile ─────────────────────────────────────────────────────────
  String jenisKelamin = ''; // 'laki_laki' | 'perempuan'
  double beratBadan = 0.0; // kg
  double tinggiBadan = 0.0; // cm

  // ── Lifestyle & Context ──────────────────────────────────────────────────────
  String levelAktivitas = ''; // 'rendah'|'ringan'|'sedang'|'aktif'|'sangat_aktif'
  String letakGeografis = ''; // 'dataran_rendah' | 'dataran_tinggi'

  // ── Research Variable (NOT used in calculation — collected for research only)
  List<String> riwayatPenyakit = []; // Multi-select. See kMedicalConditions.

  // ── Hydration Target ────────────────────────────────────────────────────────
  int dailyTargetMl = 0;
  bool targetDiterima = true; // true = accepted recommendation, false = manual override
  int? targetManualMl; // Only set when targetDiterima == false
  String unit = 'ml'; // 'ml' | 'oz'

  // ── Notification & Reminder ──────────────────────────────────────────────────
  bool notificationPermissionGranted = false; // Captured during onboarding
  bool reminderSystemActive = false;
  int reminderWindowStart = 7;  // V3: hour (06–22, default 7)
  int reminderWindowEnd = 21;   // V3: hour (06–22, default 21, min 8h gap)
  String reminderType = 'interval'; // 'smart' | 'interval'
  int reminderInterval = 2; // 1, 2, or 3 (hours)

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  DateTime createdAt = DateTime.now();
  DateTime? lastOpenedAt; // Updated on every app open
  bool dropoutFlag = false; // Set if gap > 3 days detected on app open
  bool dropoutNotificationSent = false; // V3: one-time re-engagement flag
  int currentStreak = 0; // V3: streak counter for Phase 3 gamification
  bool isSynced = false;

  UserProfile();

  UserProfile copyWith({
    String? userId,
    String? nama,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    double? beratBadan,
    double? tinggiBadan,
    String? levelAktivitas,
    String? letakGeografis,
    List<String>? riwayatPenyakit,
    int? dailyTargetMl,
    bool? targetDiterima,
    int? targetManualMl,
    String? unit,
    bool? notificationPermissionGranted,
    bool? reminderSystemActive,
    int? reminderWindowStart,
    int? reminderWindowEnd,
    String? reminderType,
    int? reminderInterval,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
    bool? dropoutFlag,
    bool? dropoutNotificationSent,
    int? currentStreak,
    bool? isSynced,
  }) {
    return UserProfile()
      ..id = id
      ..userId = userId ?? this.userId
      ..nama = nama ?? this.nama
      ..tanggalLahir = tanggalLahir ?? this.tanggalLahir
      ..jenisKelamin = jenisKelamin ?? this.jenisKelamin
      ..beratBadan = beratBadan ?? this.beratBadan
      ..tinggiBadan = tinggiBadan ?? this.tinggiBadan
      ..levelAktivitas = levelAktivitas ?? this.levelAktivitas
      ..letakGeografis = letakGeografis ?? this.letakGeografis
      ..riwayatPenyakit = riwayatPenyakit ?? this.riwayatPenyakit
      ..dailyTargetMl = dailyTargetMl ?? this.dailyTargetMl
      ..targetDiterima = targetDiterima ?? this.targetDiterima
      ..targetManualMl = targetManualMl ?? this.targetManualMl
      ..unit = unit ?? this.unit
      ..notificationPermissionGranted =
          notificationPermissionGranted ?? this.notificationPermissionGranted
      ..reminderSystemActive = reminderSystemActive ?? this.reminderSystemActive
      ..reminderWindowStart = reminderWindowStart ?? this.reminderWindowStart
      ..reminderWindowEnd = reminderWindowEnd ?? this.reminderWindowEnd
      ..reminderType = reminderType ?? this.reminderType
      ..reminderInterval = reminderInterval ?? this.reminderInterval
      ..createdAt = createdAt ?? this.createdAt
      ..lastOpenedAt = lastOpenedAt ?? this.lastOpenedAt
      ..dropoutFlag = dropoutFlag ?? this.dropoutFlag
      ..dropoutNotificationSent = dropoutNotificationSent ?? this.dropoutNotificationSent
      ..currentStreak = currentStreak ?? this.currentStreak
      ..isSynced = isSynced ?? this.isSynced;
  }
}
