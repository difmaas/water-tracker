import '../data/user_profile_model.dart';
import '../../../core/constants/app_constants.dart';

/// Type alias for a hydration modifier function.
/// Each modifier receives the current ml value and the full profile,
/// and returns an adjusted ml value.
typedef HydrationModifier = double Function(double currentMl, UserProfile profile);

/// Modifier-based hydration calculator.
///
/// Architecture:
/// 1. Start with base calculation (weight × 35 ml — EFSA 2010 baseline).
/// 2. Apply each modifier in sequence.
/// 3. Clamp result to [kTargetClampMin, kTargetClampMax].
///
/// To add a new modifier: implement a top-level function matching
/// [HydrationModifier] and add it to the [_modifiers] list below.
class HydrationCalculator {
  // ── Base Calculation ─────────────────────────────────────────────────────────

  static double _baseRecommendation(double beratBadan) {
    return beratBadan * 35; // ml — EFSA 2010 baseline
  }

  // ── Active Modifiers ─────────────────────────────────────────────────────────

  /// Activity modifier — additive ml based on level aktivitas.
  static double _activityModifier(double current, UserProfile profile) {
    const additions = {
      'rendah': 0.0,
      'ringan': 300.0,
      'sedang': 500.0,
      'aktif': 700.0,
      'sangat_aktif': 1000.0,
    };
    return current + (additions[profile.levelAktivitas] ?? 0.0);
  }

  /// Gender modifier — perempuan baseline is 200ml lower (EFSA adequate intake).
  static double _genderModifier(double current, UserProfile profile) {
    if (profile.jenisKelamin == 'perempuan') {
      return current - 200;
    }
    return current; // laki_laki: +0 (baseline)
  }

  /// Geographic modifier — dataran_tinggi increases respiratory water loss.
  static double _geographicModifier(double current, UserProfile profile) {
    if (profile.letakGeografis == 'dataran_tinggi') {
      return current + 200;
    }
    return current; // dataran_rendah: +0
  }

  // _medicalConditionModifier — reserved, not active yet.
  // Will be added after formula finalized with nakes consultation.

  // ── Modifier Chain ───────────────────────────────────────────────────────────

  static const List<HydrationModifier> _modifiers = [
    _activityModifier,
    _genderModifier,
    _geographicModifier,
  ];

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Calculates the recommended daily water intake in ml for the given profile.
  /// Result is clamped to [kTargetClampMin]–[kTargetClampMax].
  static int calculate(UserProfile profile) {
    double result = _baseRecommendation(profile.beratBadan);
    for (final modifier in _modifiers) {
      result = modifier(result, profile);
    }
    return result.round().clamp(kTargetClampMin, kTargetClampMax);
  }

  /// Returns a breakdown of which modifiers were applied and their delta values.
  /// Used on the confirmation screen to show the user how the target was derived.
  static List<ModifierBreakdown> getBreakdown(UserProfile profile) {
    final base = _baseRecommendation(profile.beratBadan);
    double running = base;
    final breakdowns = <ModifierBreakdown>[];

    // Activity
    final afterActivity = _activityModifier(running, profile);
    final activityDelta = afterActivity - running;
    if (activityDelta != 0) {
      breakdowns.add(ModifierBreakdown(
        label: 'Level aktivitas (${profile.levelAktivitas})',
        delta: activityDelta.round(),
      ));
    }
    running = afterActivity;

    // Gender
    final afterGender = _genderModifier(running, profile);
    final genderDelta = afterGender - running;
    if (genderDelta != 0) {
      breakdowns.add(ModifierBreakdown(
        label: 'Jenis kelamin (${profile.jenisKelamin})',
        delta: genderDelta.round(),
      ));
    }
    running = afterGender;

    // Geographic
    final afterGeo = _geographicModifier(running, profile);
    final geoDelta = afterGeo - running;
    if (geoDelta != 0) {
      breakdowns.add(ModifierBreakdown(
        label: 'Letak geografis (${profile.letakGeografis})',
        delta: geoDelta.round(),
      ));
    }

    return breakdowns;
  }
}

/// Represents a single modifier contribution for display on the confirmation screen.
class ModifierBreakdown {
  final String label;
  final int delta; // Positive = increase, negative = decrease (ml)

  const ModifierBreakdown({required this.label, required this.delta});

  String get deltaLabel => delta >= 0 ? '+$delta ml' : '$delta ml';
}
