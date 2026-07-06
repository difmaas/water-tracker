import 'package:isar_community/isar.dart';

part 'user_profile_model.g.dart';

/// Canonical UserProfile schema per AGENTS_V2 (V3) §15.
@collection
class UserProfile {
  Id id = Isar.autoIncrement;

  // ── Identifiers ──────────────────────────────────────────────────────────────
  String userId = ''; // UUID v4 — generated once at profile setup
  String participantId = ''; // Randomized ID for research export & settings

  // ── Personal Data (Local only — nama never synced to Supabase) ──────────────
  String nama =
      ''; // Min 3, max 10 chars, letters and spaces only. Never synced.
  DateTime tanggalLahir = DateTime(
    2000,
  ); // Age derived at runtime via AppDateUtils.ageFromBirthdate()

  // ── Physical Profile ─────────────────────────────────────────────────────────
  String jenisKelamin = ''; // 'laki_laki' | 'perempuan'
  double beratBadan = 0.0; // kg
  double tinggiBadan = 0.0; // cm

  // ── Lifestyle & Context ──────────────────────────────────────────────────────
  String levelAktivitas =
      ''; // 'rendah'|'ringan'|'sedang'|'aktif'|'sangat_aktif'
  String letakGeografis = ''; // 'dataran_rendah' | 'dataran_tinggi'

  // ── Research Variable (NOT used in calculation — collected for research only)
  List<String> riwayatPenyakit = []; // Multi-select. See kMedicalConditions.

  // ── Hydration Target ────────────────────────────────────────────────────────
  int dailyTargetMl = 0;
  bool targetDiterima =
      true; // true = accepted recommendation, false = manual override
  int? targetManualMl; // Only set when targetDiterima == false
  String unit = 'ml'; // 'ml' | 'oz'

  // ── Notification & Reminder ──────────────────────────────────────────────────
  bool notificationPermissionGranted = false; // Captured during onboarding
  bool reminderSystemActive = false;
  int reminderWindowStart = 7; // V3: hour (06–22, default 7)
  int reminderWindowEnd = 21; // V3: hour (06–22, default 21, min 8h gap)
  String reminderType = 'fixed'; // MVP: fixed 2-hour reminders
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
    String? participantId,
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
      ..participantId = participantId ?? this.participantId
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
      ..dropoutNotificationSent =
          dropoutNotificationSent ?? this.dropoutNotificationSent
      ..currentStreak = currentStreak ?? this.currentStreak
      ..isSynced = isSynced ?? this.isSynced;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'participantId': participantId,
    'nama': nama,
    'tanggalLahir': tanggalLahir.toIso8601String(),
    'jenisKelamin': jenisKelamin,
    'beratBadan': beratBadan,
    'tinggiBadan': tinggiBadan,
    'levelAktivitas': levelAktivitas,
    'letakGeografis': letakGeografis,
    'riwayatPenyakit': riwayatPenyakit,
    'dailyTargetMl': dailyTargetMl,
    'targetDiterima': targetDiterima,
    'targetManualMl': targetManualMl,
    'unit': unit,
    'notificationPermissionGranted': notificationPermissionGranted,
    'reminderSystemActive': reminderSystemActive,
    'reminderWindowStart': reminderWindowStart,
    'reminderWindowEnd': reminderWindowEnd,
    'reminderType': reminderType,
    'reminderInterval': reminderInterval,
    'createdAt': createdAt.toIso8601String(),
    'lastOpenedAt': lastOpenedAt?.toIso8601String(),
    'dropoutFlag': dropoutFlag,
    'dropoutNotificationSent': dropoutNotificationSent,
    'currentStreak': currentStreak,
    'isSynced': isSynced,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile()
      ..id = json['id'] as int? ?? Isar.autoIncrement
      ..userId = json['userId'] as String
      ..participantId = json['participantId'] as String? ?? ''
      ..nama = json['nama'] as String? ?? ''
      ..tanggalLahir = DateTime.parse(json['tanggalLahir'] as String)
      ..jenisKelamin = json['jenisKelamin'] as String
      ..beratBadan = (json['beratBadan'] as num).toDouble()
      ..tinggiBadan = (json['tinggiBadan'] as num?)?.toDouble() ?? 0.0
      ..levelAktivitas = json['levelAktivitas'] as String
      ..letakGeografis = json['letakGeografis'] as String
      ..riwayatPenyakit = List<String>.from(
        json['riwayatPenyakit'] as List? ?? const [],
      )
      ..dailyTargetMl = json['dailyTargetMl'] as int
      ..targetDiterima = json['targetDiterima'] as bool
      ..targetManualMl = json['targetManualMl'] as int?
      ..unit = json['unit'] as String? ?? 'ml'
      ..notificationPermissionGranted =
          json['notificationPermissionGranted'] as bool
      ..reminderSystemActive = json['reminderSystemActive'] as bool
      ..reminderWindowStart = json['reminderWindowStart'] as int? ?? 7
      ..reminderWindowEnd = json['reminderWindowEnd'] as int? ?? 21
      ..reminderType = json['reminderType'] as String? ?? 'fixed'
      ..reminderInterval = json['reminderInterval'] as int? ?? 2
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..lastOpenedAt = json['lastOpenedAt'] != null
          ? DateTime.parse(json['lastOpenedAt'] as String)
          : null
      ..dropoutFlag = json['dropoutFlag'] as bool
      ..dropoutNotificationSent =
          json['dropoutNotificationSent'] as bool? ?? false
      ..currentStreak = json['currentStreak'] as int? ?? 0
      ..isSynced = json['isSynced'] as bool;
  }
}
