import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../features/profile/data/profile_repository.dart';
import '../features/profile/data/user_profile_model.dart';
import '../features/profile/domain/hydration_calculator.dart';
import '../core/utils/date_utils.dart';
import 'onboarding_provider.dart';

class ProfileFormState {
  // ── Form fields ──────────────────────────────────────────────────────────────
  final String nama;
  final DateTime? tanggalLahir;
  final String jenisKelamin;
  final double beratBadan;
  final String levelAktivitas;
  final String letakGeografis;
  final List<String> riwayatPenyakit;

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
    this.levelAktivitas = '',
    this.letakGeografis = '',
    this.riwayatPenyakit = const [],
    this.calculatedTargetMl = 0,
    this.targetManualMl,
    this.isLoading = false,
  });

  ProfileFormState copyWith({
    String? nama,
    DateTime? tanggalLahir,
    String? jenisKelamin,
    double? beratBadan,
    String? levelAktivitas,
    String? letakGeografis,
    List<String>? riwayatPenyakit,
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
      levelAktivitas: levelAktivitas ?? this.levelAktivitas,
      letakGeografis: letakGeografis ?? this.letakGeografis,
      riwayatPenyakit: riwayatPenyakit ?? this.riwayatPenyakit,
      calculatedTargetMl: calculatedTargetMl ?? this.calculatedTargetMl,
      targetManualMl: clearManualTarget ? null : (targetManualMl ?? this.targetManualMl),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Returns true when all required fields are valid for form submission.
  bool get isValid {
    final namaOk = _isNamaValid(nama);
    final lahirOk = tanggalLahir != null && AppDateUtils.isValidAge(tanggalLahir!);
    final kelaminOk = jenisKelamin.isNotEmpty;
    final beratOk = beratBadan >= 20 && beratBadan <= 200;
    final aktivitasOk = levelAktivitas.isNotEmpty;
    final geografisOk = letakGeografis.isNotEmpty;
    return namaOk && lahirOk && kelaminOk && beratOk && aktivitasOk && geografisOk;
  }

  static bool _isNamaValid(String value) {
    if (value.length < 3 || value.length > 10) return false;
    return RegExp(r'^[A-Za-z ]+$').hasMatch(value);
  }
}

class ProfileNotifier extends Notifier<ProfileFormState> {
  @override
  ProfileFormState build() => ProfileFormState();

  // ── Field Updaters ───────────────────────────────────────────────────────────

  void updateNama(String value) => state = state.copyWith(nama: value);

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

  void updateLevelAktivitas(String value) {
    state = state.copyWith(levelAktivitas: value);
    _recalculate();
  }

  void updateLetakGeografis(String value) {
    state = state.copyWith(letakGeografis: value);
    _recalculate();
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
      // 1. Generate UUID v4
      final userId = const Uuid().v4();

      // 2. Supabase anonymous auth (required for RLS compliance)
      try {
        await Supabase.instance.client.auth.signInAnonymously();
      } catch (e) {
        // Ignore if Supabase is not initialized (Opsi B)
        // ignore: avoid_print
        print('Supabase not initialized, skipping auth: $e');
      }

      final finalTarget = state.targetManualMl ?? state.calculatedTargetMl;
      final isManualOverride = state.targetManualMl != null;

      // 3. Construct UserProfile
      final profile = UserProfile()
        ..userId = userId
        ..nama = state.nama // Isar only — excluded from SyncService payload
        ..tanggalLahir = state.tanggalLahir!
        ..jenisKelamin = state.jenisKelamin
        ..beratBadan = state.beratBadan
        ..levelAktivitas = state.levelAktivitas
        ..letakGeografis = state.letakGeografis
        ..riwayatPenyakit = state.riwayatPenyakit
        ..dailyTargetMl = finalTarget
        ..targetDiterima = !isManualOverride
        ..targetManualMl = state.targetManualMl
        ..notificationPermissionGranted = true // Captured at onboarding
        ..reminderSystemActive = true
        ..createdAt = DateTime.now()
        ..isSynced = false;

      // 4. Persist
      await ref.read(profileRepositoryProvider).saveProfile(profile);

      // 5. Mark profile as created in routing guard
      await ref.read(profileStatusProvider.notifier).setProfileCreated();
    } catch (e) {
      // Sync failures are silent per AGENTS.md — log only
      // ignore: avoid_print
      print('Profile submission error: $e');
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileFormState>(() {
  return ProfileNotifier();
});
