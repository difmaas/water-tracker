import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:uuid/uuid.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/data/user_profile_model.dart';
import '../features/profile/domain/hydration_calculator.dart';
import '../features/logging/data/daily_summary_model.dart';
import '../features/logging/data/logging_repository.dart';
import '../features/reminder/domain/reminder_logic.dart';
import '../core/utils/date_utils.dart';
import 'hydration_provider.dart';
import 'onboarding_provider.dart';
import 'reminder_provider.dart';

class ProfileFormState {
  // ── Form fields ──────────────────────────────────────────────────────────────
  final String nama;
  final DateTime? tanggalLahir;
  final String jenisKelamin;
  final double beratBadan;
  final double tinggiBadan;
  final String levelAktivitas;
  final String letakGeografis;
  final List<String> riwayatPenyakit;
  final String reminderType;
  final int reminderInterval;
  final int reminderWindowStart;
  final int reminderWindowEnd;
  final bool reminderSystemActive;

  // ── Calculated result ────────────────────────────────────────────────────────
  final int calculatedTargetMl;
  final int? targetManualMl; // Non-null = user overrode the recommendation

  // ── UI state ─────────────────────────────────────────────────────────────────
  final bool isLoading;

  ProfileFormState({
    this.nama = '',
    this.tanggalLahir,
    this.jenisKelamin = '',
    this.beratBadan = 0.0,
    this.tinggiBadan = 0.0,
    this.levelAktivitas = '',
    this.letakGeografis = '',
    this.riwayatPenyakit = const [],
    this.reminderType = 'fixed',
    this.reminderInterval = 2,
    this.reminderWindowStart = 7,
    this.reminderWindowEnd = 21,
    this.reminderSystemActive = true,
    this.calculatedTargetMl = 0,
    this.targetManualMl,
    this.isLoading = false,
  });

  ProfileFormState copyWith({
    String? nama,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    double? beratBadan,
    double? tinggiBadan,
    String? levelAktivitas,
    String? letakGeografis,
    List<String>? riwayatPenyakit,
    String? reminderType,
    int? reminderInterval,
    int? reminderWindowStart,
    int? reminderWindowEnd,
    bool? reminderSystemActive,
    int? calculatedTargetMl,
    int? targetManualMl,
    bool clearManualTarget = false,
    bool? isLoading,
  }) {
    return ProfileFormState(
      nama: nama ?? this.nama,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      beratBadan: beratBadan ?? this.beratBadan,
      tinggiBadan: tinggiBadan ?? this.tinggiBadan,
      levelAktivitas: levelAktivitas ?? this.levelAktivitas,
      letakGeografis: letakGeografis ?? this.letakGeografis,
      riwayatPenyakit: riwayatPenyakit ?? this.riwayatPenyakit,
      reminderType: reminderType ?? this.reminderType,
      reminderInterval: reminderInterval ?? this.reminderInterval,
      reminderWindowStart: reminderWindowStart ?? this.reminderWindowStart,
      reminderWindowEnd: reminderWindowEnd ?? this.reminderWindowEnd,
      reminderSystemActive: reminderSystemActive ?? this.reminderSystemActive,
      calculatedTargetMl: calculatedTargetMl ?? this.calculatedTargetMl,
      targetManualMl: clearManualTarget
          ? null
          : (targetManualMl ?? this.targetManualMl),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Returns true when all required fields are valid for form submission.
  bool get isValid {
    final namaOk = _isNamaValid(nama);
    final lahirOk =
        tanggalLahir != null && AppDateUtils.isValidAge(tanggalLahir!);
    final kelaminOk = jenisKelamin.isNotEmpty;
    final beratOk = beratBadan >= 20 && beratBadan <= 200;
    final tinggiOk = tinggiBadan >= 50 && tinggiBadan <= 250;
    final aktivitasOk = levelAktivitas.isNotEmpty;
    final geografisOk = letakGeografis.isNotEmpty;
    final windowOk =
        !reminderSystemActive ||
        (reminderWindowEnd - reminderWindowStart >= 8 &&
            reminderWindowStart >= 6 &&
            reminderWindowStart <= 22 &&
            reminderWindowEnd >= 6 &&
            reminderWindowEnd <= 22);
    return namaOk &&
        lahirOk &&
        kelaminOk &&
        beratOk &&
        tinggiOk &&
        aktivitasOk &&
        geografisOk &&
        windowOk;
  }

  static bool _isNamaValid(String value) {
    if (value.length < 3 || value.length > 10) return false;
    return RegExp(r'^[A-Za-z ]+$').hasMatch(value);
  }
}

class ProfileNotifier extends Notifier<ProfileFormState> {
  @override
  ProfileFormState build() => ProfileFormState();

  void reset() {
    state = ProfileFormState(
      tinggiBadan: 160.0,
      letakGeografis: 'dataran_rendah',
    );
  }

  // ── Field Updaters ───────────────────────────────────────────────────────────

  void updateNama(String value) {
    if (value.isEmpty) {
      state = state.copyWith(nama: value);
      return;
    }
    final capitalized = value
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
    state = state.copyWith(nama: capitalized);
  }

  void updateTanggalLahir(DateTime? value) {
    state = state.copyWith(tanggalLahir: value);
  }

  void updateJenisKelamin(String value) {
    state = state.copyWith(jenisKelamin: value);
    _recalculate();
  }

  void updateBeratBadan(double value) {
    state = state.copyWith(beratBadan: value);
    _recalculate();
  }

  void updateTinggiBadan(double value) {
    state = state.copyWith(tinggiBadan: value);
    _recalculate();
  }

  void updateLevelAktivitas(String value) {
    state = state.copyWith(levelAktivitas: value);
    _recalculate();
  }

  void updateLetakGeografis(String value) {
    state = state.copyWith(letakGeografis: value);
    _recalculate();
  }

  void updateReminderType(String value) {
    state = state.copyWith(reminderType: value);
  }

  void updateReminderInterval(int value) {
    state = state.copyWith(
      reminderInterval: ReminderLogic.normalizeIntervalHours(value),
    );
  }

  void updateReminderSystemActive(bool value) {
    state = state.copyWith(reminderSystemActive: value);
  }

  void toggleRiwayatPenyakit(String condition) {
    final current = List<String>.from(state.riwayatPenyakit);
    if (current.contains(condition)) {
      current.remove(condition);
    } else {
      current.add(condition);
    }
    state = state.copyWith(riwayatPenyakit: current);
    // riwayatPenyakit does NOT trigger recalculate — research data only
  }

  void updateManualTarget(int? ml) {
    if (ml == null) {
      state = state.copyWith(clearManualTarget: true);
    } else {
      state = state.copyWith(targetManualMl: ml);
    }
  }

  void initializeForEdit(UserProfile profile) {
    state = ProfileFormState(
      nama: profile.nama,
      tanggalLahir: profile.tanggalLahir,
      jenisKelamin: profile.jenisKelamin,
      beratBadan: profile.beratBadan,
      tinggiBadan: profile.tinggiBadan,
      levelAktivitas: profile.levelAktivitas,
      letakGeografis: profile.letakGeografis,
      riwayatPenyakit: profile.riwayatPenyakit,
      reminderType: 'fixed',
      reminderInterval: ReminderLogic.normalizeIntervalHours(
        profile.reminderInterval,
      ),
      reminderWindowStart: profile.reminderWindowStart,
      reminderWindowEnd: profile.reminderWindowEnd,
      reminderSystemActive: profile.reminderSystemActive,
      calculatedTargetMl: profile.dailyTargetMl, // initial guess
      targetManualMl: profile.targetManualMl,
    );
    _recalculate(); // recalculate based on existing data
  }

  void updateFormReminderWindow(int start, int end) {
    state = state.copyWith(reminderWindowStart: start, reminderWindowEnd: end);
  }

  Future<void> updateReminderWindow(int start, int end) async {
    if (!AppDateUtils.isValidReminderWindow(start, end)) return;

    final repo = ref.read(profileRepositoryProvider);
    final profile = await repo.getUserProfile();
    if (profile == null) return;

    final updated = profile.copyWith(
      reminderWindowStart: start,
      reminderWindowEnd: end,
      isSynced: false,
    );

    await repo.saveProfile(updated);
    // Trigger immediate reschedule
    await ref.read(reminderServiceProvider).rescheduleWithNewWindow();
  }

  // ── Calculation ──────────────────────────────────────────────────────────────

  void _recalculate() {
    // Only calculate when enough data is available
    if (state.jenisKelamin.isEmpty ||
        state.beratBadan <= 0 ||
        state.levelAktivitas.isEmpty ||
        state.letakGeografis.isEmpty) {
      return;
    }

    // Build a temporary profile for the calculator
    final tempProfile = UserProfile()
      ..jenisKelamin = state.jenisKelamin
      ..beratBadan = state.beratBadan
      ..tinggiBadan = state.tinggiBadan
      ..levelAktivitas = state.levelAktivitas
      ..letakGeografis = state.letakGeografis
      ..riwayatPenyakit = state.riwayatPenyakit;

    final target = HydrationCalculator.calculate(tempProfile);
    state = state.copyWith(calculatedTargetMl: target, clearManualTarget: true);
  }

  // ── Submission ───────────────────────────────────────────────────────────────

  Future<void> submitProfile() async {
    state = state.copyWith(isLoading: true);
    try {
      if (!state.isValid) {
        throw StateError('Data profil atau jendela pengingat tidak valid');
      }

      final repo = ref.read(profileRepositoryProvider);
      final existing = await repo.getUserProfile();

      // 1. Preservation or generation of userId
      final userId = existing?.userId ?? const Uuid().v4();

      // 2. Supabase anonymous auth (deferred per AGENTS.md §6)
      /*
      if (existing == null) {
        try {
          await Supabase.instance.client.auth.signInAnonymously();
        } catch (e) {
          debugPrint('[ProfileProvider] Supabase auth error: $e');
        }
      }
      */

      final finalTarget = state.targetManualMl ?? state.calculatedTargetMl;
      final isManualOverride = state.targetManualMl != null;
      final reminderInterval = ReminderLogic.normalizeIntervalHours(
        state.reminderInterval,
      );

      final oldReminderActive = existing?.reminderSystemActive ?? false;
      final oldReminderInterval = existing?.reminderInterval;
      final oldReminderStart = existing?.reminderWindowStart;
      final oldReminderEnd = existing?.reminderWindowEnd;
      final oldTarget = existing == null
          ? null
          : (existing.targetManualMl ?? existing.dailyTargetMl);
      final reminderToggleChanged =
          existing == null || oldReminderActive != state.reminderSystemActive;
      final reminderActive = state.reminderSystemActive;

      // Permission and the user's reminder toggle are separate state.
      final shouldRequestPermission =
          reminderActive && (existing == null || reminderToggleChanged);
      final notifGranted = shouldRequestPermission
          ? await ref.read(reminderServiceProvider).requestPermissions()
          : (existing?.notificationPermissionGranted ?? false);

      // 3. Construct or Update UserProfile
      final profile = (existing ?? UserProfile())
        ..userId = userId
        ..nama = state.nama
        ..tanggalLahir = state.tanggalLahir!
        ..jenisKelamin = state.jenisKelamin
        ..beratBadan = state.beratBadan
        ..tinggiBadan = state.tinggiBadan
        ..levelAktivitas = state.levelAktivitas
        ..letakGeografis = state.letakGeografis
        ..riwayatPenyakit = state.riwayatPenyakit
        ..dailyTargetMl = finalTarget
        ..targetDiterima = !isManualOverride
        ..targetManualMl = state.targetManualMl
        ..notificationPermissionGranted = notifGranted
        ..reminderSystemActive = reminderActive
        ..reminderWindowStart = state.reminderWindowStart
        ..reminderWindowEnd = state.reminderWindowEnd
        ..reminderType = 'fixed'
        ..reminderInterval = reminderInterval
        ..createdAt = existing?.createdAt ?? DateTime.now()
        ..isSynced = false;

      // 4. Persist
      await repo.saveProfile(profile);
      await _recalculateTodaySummary(profile);

      // 5. Mark profile as created
      await ref.read(profileStatusProvider.notifier).setProfileCreated();

      // 6. Initialize, Reschedule, or Cancel reminder system
      if (existing == null) {
        if (reminderActive && notifGranted) {
          await ref.read(reminderServiceProvider).initialize(finalTarget);
        }
      } else {
        final reminderScheduleChanged =
            reminderActive &&
            notifGranted &&
            (reminderToggleChanged ||
                oldReminderInterval != reminderInterval ||
                oldReminderStart != state.reminderWindowStart ||
                oldReminderEnd != state.reminderWindowEnd ||
                oldTarget != finalTarget);

        if (reminderToggleChanged && !reminderActive) {
          await ref.read(reminderServiceProvider).cancelAll();
        } else if (reminderScheduleChanged) {
          await ref.read(reminderServiceProvider).rescheduleWithNewWindow();
        }
      }

      ref.invalidate(hydrationProvider);
    } catch (e) {
      debugPrint('[ProfileProvider] Profile submission error: $e');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _recalculateTodaySummary(UserProfile profile) async {
    final loggingRepo = ref.read(loggingRepositoryProvider);
    final now = DateTime.now();
    final logs = await loggingRepo.getLogsForDate(profile.userId, now);
    final totalMl = logs.fold<int>(0, (sum, log) => sum + log.volume);
    final targetMl = profile.targetManualMl ?? profile.dailyTargetMl;
    final firstLogTimestamp = logs.isNotEmpty ? logs.first.timestamp : null;
    final existing = await loggingRepo.getDailySummary(profile.userId, now);

    if (existing != null) {
      final updated = existing.copyWith(
        targetMl: targetMl,
        achievedMl: totalMl,
        complianceRate: targetMl > 0 ? totalMl / targetMl : 0.0,
        firstLogTimestamp: firstLogTimestamp,
        clearFirstLogTimestamp: logs.isEmpty,
        isSynced: false,
      );
      await loggingRepo.upsertDailySummary(updated);
      return;
    }

    if (logs.isEmpty) return;

    final summary = DailySummary()
      ..userId = profile.userId
      ..date = now
      ..targetMl = targetMl
      ..achievedMl = totalMl
      ..complianceRate = targetMl > 0 ? totalMl / targetMl : 0.0
      ..remindersSent = 0
      ..remindersResponded = 0
      ..sessionCount = 1
      ..streakMaintained = false
      ..firstLogTimestamp = firstLogTimestamp
      ..isSynced = false
      ..createdAt = DateTime.now();
    await loggingRepo.upsertDailySummary(summary);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileFormState>(() {
  return ProfileNotifier();
});
