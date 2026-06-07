import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/data/daily_summary_model.dart';
import '../logging/data/logging_repository.dart';
import '../profile/data/profile_repository.dart';

/// State for the Progress Screen.
///
/// Holds the last 7 [DailySummary] records (oldest→newest) and the
/// pre-computed weekly aggregate values for display.
class ProgressState {
  /// Sorted oldest → newest for correct bar chart X-axis order.
  final List<DailySummary> weekSummaries;

  /// Sorted oldest → newest for monthly calendar display.
  final List<DailySummary> monthSummaries;

  /// Average complianceRate over available days (0.0–1.0).
  final double weeklyAvgCompliance;

  /// Number of days where complianceRate >= 0.8 (streak-quality days).
  final int daysAbove80;

  /// Total days with at least one log (achievedMl > 0).
  final int activeDays;

  final bool isLoading;
  final String? error;

  const ProgressState({
    this.weekSummaries = const [],
    this.monthSummaries = const [],
    this.weeklyAvgCompliance = 0.0,
    this.daysAbove80 = 0,
    this.activeDays = 0,
    this.isLoading = false,
    this.error,
  });

  ProgressState copyWith({
    List<DailySummary>? weekSummaries,
    List<DailySummary>? monthSummaries,
    double? weeklyAvgCompliance,
    int? daysAbove80,
    int? activeDays,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      weekSummaries: weekSummaries ?? this.weekSummaries,
      monthSummaries: monthSummaries ?? this.monthSummaries,
      weeklyAvgCompliance: weeklyAvgCompliance ?? this.weeklyAvgCompliance,
      daysAbove80: daysAbove80 ?? this.daysAbove80,
      activeDays: activeDays ?? this.activeDays,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provides read-only progress data for the last 7 days.
///
/// F-14 — Progress Screen (FEATURES_V3 §Phase 3).
/// Data source: Isar only via [LoggingRepository]. Never Supabase.
class ProgressNotifier extends Notifier<ProgressState> {
  @override
  ProgressState build() {
    Future.microtask(() => _load());
    return const ProgressState(isLoading: true);
  }

  Future<void> _load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final profileRepo = ref.read(profileRepositoryProvider);
      final profile = await profileRepo.getUserProfile();

      if (profile == null) {
        state = state.copyWith(
          isLoading: false,
          weekSummaries: [],
          monthSummaries: [],
        );
        return;
      }

      final loggingRepo = ref.read(loggingRepositoryProvider);

      // Fetch last 7 days, newest first
      final newest7 = await loggingRepo.getHistorySummaries(
        profile.userId,
        limit: 7,
      );

      // Reverse to oldest→newest for correct left-to-right chart axis
      final ordered = newest7.reversed.toList();

      // Fetch last 35 days for calendar (covers any calendar month view)
      final newest35 = await loggingRepo.getHistorySummaries(
        profile.userId,
        limit: 35,
      );
      final orderedMonth = newest35.reversed.toList();

      // Compute weekly aggregates
      double totalCompliance = 0;
      int daysAbove80 = 0;
      int activeDays = 0;

      for (final s in ordered) {
        totalCompliance += s.complianceRate;
        if (s.complianceRate >= 0.8) daysAbove80++;
        if (s.achievedMl > 0) activeDays++;
      }

      final avgCompliance = ordered.isEmpty
          ? 0.0
          : totalCompliance / ordered.length;

      state = state.copyWith(
        weekSummaries: ordered,
        monthSummaries: orderedMonth,
        weeklyAvgCompliance: avgCompliance,
        daysAbove80: daysAbove80,
        activeDays: activeDays,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Force-refresh (called when user taps refresh button).
  Future<void> refresh() => _load();
}

final progressProvider = NotifierProvider<ProgressNotifier, ProgressState>(() {
  return ProgressNotifier();
});
