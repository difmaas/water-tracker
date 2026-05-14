import 'package:isar/isar.dart';

// part 'user_profile_model.g.dart'; // Re-enable after Isar generator fix

// @collection // Re-enable after Isar generator fix
class UserProfile {
  Id id = Isar.autoIncrement;

  // ── Identifiers ──────────────────────────────────────────────────────────────
  late String userId; // UUID v4 — generated once at profile setup

  // ── Personal Data (Isar only — nama never synced to Supabase) ───────────────
  late String nama; // Min 3, max 10 chars, letters and spaces only. Never synced.
  late DateTime tanggalLahir; // Age derived at runtime via AppDateUtils.ageFromBirthdate()

  // ── Physical Profile ─────────────────────────────────────────────────────────
  late String jenisKelamin; // 'laki_laki' | 'perempuan'
  late double beratBadan; // kg

  // ── Lifestyle & Context ──────────────────────────────────────────────────────
  late String levelAktivitas; // 'rendah'|'ringan'|'sedang'|'aktif'|'sangat_aktif'
  late String letakGeografis; // 'dataran_rendah' | 'dataran_tinggi'

  // ── Research Variable (NOT used in calculation — collected for research only)
  List<String> riwayatPenyakit = []; // Multi-select. See kMedicalConditions.

  // ── Hydration Target ────────────────────────────────────────────────────────
  late int dailyTargetMl;
  late bool targetDiterima; // true = accepted recommendation, false = manual override
  int? targetManualMl; // Only set when targetDiterima == false

  // ── Notification & Reminder ──────────────────────────────────────────────────
  late bool notificationPermissionGranted; // Captured during onboarding
  late bool reminderSystemActive;

  // ── Lifecycle ────────────────────────────────────────────────────────────────
  late DateTime createdAt;
  DateTime? lastOpenedAt; // Updated on every app open
  bool dropoutFlag = false; // Set if gap > 3 days detected on app open
  bool isSynced = false;

  UserProfile();

  UserProfile copyWith({
    String? userId,
    String? nama,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    double? beratBadan,
    String? levelAktivitas,
    String? letakGeografis,
    List<String>? riwayatPenyakit,
    int? dailyTargetMl,
    bool? targetDiterima,
    int? targetManualMl,
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
      ..nama = nama ?? this.nama
      ..tanggalLahir = tanggalLahir ?? this.tanggalLahir
      ..jenisKelamin = jenisKelamin ?? this.jenisKelamin
      ..beratBadan = beratBadan ?? this.beratBadan
      ..levelAktivitas = levelAktivitas ?? this.levelAktivitas
      ..letakGeografis = letakGeografis ?? this.letakGeografis
      ..riwayatPenyakit = riwayatPenyakit ?? this.riwayatPenyakit
      ..dailyTargetMl = dailyTargetMl ?? this.dailyTargetMl
      ..targetDiterima = targetDiterima ?? this.targetDiterima
      ..targetManualMl = targetManualMl ?? this.targetManualMl
      ..notificationPermissionGranted =
          notificationPermissionGranted ?? this.notificationPermissionGranted
      ..reminderSystemActive = reminderSystemActive ?? this.reminderSystemActive
      ..createdAt = createdAt ?? this.createdAt
      ..lastOpenedAt = lastOpenedAt ?? this.lastOpenedAt
      ..dropoutFlag = dropoutFlag ?? this.dropoutFlag
      ..isSynced = isSynced ?? this.isSynced;
  }
}
