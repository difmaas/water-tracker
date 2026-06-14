import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logging/data/daily_summary_model.dart';
import '../logging/data/logging_repository.dart';
import '../profile/data/profile_repository.dart';
import '../profile/data/user_profile_model.dart';

/// Represents daily total for a single day in the weekly window.
class WeeklyDayTotal {
  final DateTime date;
  final int achievedMl;
  final int targetMl;
  final bool isAvailable;
  final bool hasData;

  const WeeklyDayTotal({
    required this.date,
    required this.achievedMl,
    required this.targetMl,
    required this.isAvailable,
    required this.hasData,
  });
}

/// Represents the computed weekly statistics.
class WeeklyStats {
  final int averageDailyMl;
  final int achievedDays;
  final int validDays;
  final int consistencyPercentage;
  final WeeklyDayTotal? highestDay;
  final WeeklyDayTotal? lowestRecordedDay;
  final List<WeeklyDayTotal> dailyTotals;

  const WeeklyStats({
    required this.averageDailyMl,
    required this.achievedDays,
    required this.validDays,
    required this.consistencyPercentage,
    this.highestDay,
    this.lowestRecordedDay,
    required this.dailyTotals,
  });
}

/// State for the Progress Screen.
class ProgressState {
  final List<DailySummary> weekSummaries;
  final List<DailySummary> monthSummaries;
  final double weeklyAvgCompliance;
  final int daysAbove80;
  final int activeDays;
  final WeeklyStats? weeklyStats;
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const ProgressState({
    this.weekSummaries = const [],
    this.monthSummaries = const [],
    this.weeklyAvgCompliance = 0.0,
    this.daysAbove80 = 0,
    this.activeDays = 0,
    this.weeklyStats,
    this.profile,
    this.isLoading = false,
    this.error,
  });

  ProgressState copyWith({
    List<DailySummary>? weekSummaries,
    List<DailySummary>? monthSummaries,
    double? weeklyAvgCompliance,
    int? daysAbove80,
    int? activeDays,
    WeeklyStats? weeklyStats,
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProgressState(
      weekSummaries: weekSummaries ?? this.weekSummaries,
      monthSummaries: monthSummaries ?? this.monthSummaries,
      weeklyAvgCompliance: weeklyAvgCompliance ?? this.weeklyAvgCompliance,
      daysAbove80: daysAbove80 ?? this.daysAbove80,
      activeDays: activeDays ?? this.activeDays,
      weeklyStats: weeklyStats ?? this.weeklyStats,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provides read-only progress data for the last 7 days.
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
          weeklyStats: null,
          profile: null,
        );
        return;
      }

      final loggingRepo = ref.read(loggingRepositoryProvider);

      // Fetch all historical summaries to map them by date
      final allSummaries = await loggingRepo.getHistorySummaries(
        profile.userId,
        limit: 0,
      );

      final now = DateTime.now();
      final todayMidnight = DateTime(now.year, now.month, now.day);
      final startDateTime = profile.createdAt;
      final startDate = DateTime(
        startDateTime.year,
        startDateTime.month,
        startDateTime.day,
      );

      // Map summaries by date (date-only) for O(1) lookup
      final Map<DateTime, DailySummary> summaryMap = {};
      for (final s in allSummaries) {
        final sDate = DateTime(s.date.year, s.date.month, s.date.day);
        summaryMap[sDate] = s;
      }

      // Generate the last 7 calendar days window (oldest to newest: today-6 to today)
      final List<WeeklyDayTotal> dailyTotals = [];
      for (int i = 6; i >= 0; i--) {
        final dayDate = todayMidnight.subtract(Duration(days: i));
        final isAvailable = !dayDate.isBefore(startDate);

        final summary = summaryMap[dayDate];
        final achievedMl = summary?.achievedMl ?? 0;
        final targetMl = summary?.targetMl ?? profile.dailyTargetMl;
        final hasData = summary != null;

        dailyTotals.add(
          WeeklyDayTotal(
            date: dayDate,
            achievedMl: achievedMl,
            targetMl: targetMl,
            isAvailable: isAvailable,
            hasData: hasData,
          ),
        );
      }

      // Filter available/valid days
      final availableDays = dailyTotals.where((dt) => dt.isAvailable).toList();
      final validDays = availableDays.length;

      // Calculate total intake of available days
      final totalIntake = availableDays.fold<int>(
        0,
        (sum, dt) => sum + dt.achievedMl,
      );
      final averageDailyMl = validDays > 0
          ? (totalIntake / validDays).round()
          : 0;

      // Calculate achieved days (days where achievedMl >= targetMl)
      final achievedDays = availableDays
          .where((dt) => dt.achievedMl >= dt.targetMl)
          .length;

      // Consistency percentage
      final consistencyPercentage = validDays > 0
          ? ((achievedDays / validDays) * 100).round()
          : 0;

      // Highest day (maximum achievedMl among available days with data)
      final daysWithData = availableDays.where((dt) => dt.hasData).toList();
      WeeklyDayTotal? highestDay;
      if (daysWithData.isNotEmpty) {
        highestDay = daysWithData.reduce(
          (curr, next) => curr.achievedMl > next.achievedMl ? curr : next,
        );
      }

      // Lowest recorded day (minimum achievedMl among available days with data)
      WeeklyDayTotal? lowestRecordedDay;
      if (daysWithData.isNotEmpty) {
        lowestRecordedDay = daysWithData.reduce(
          (curr, next) => curr.achievedMl < next.achievedMl ? curr : next,
        );
      }

      final weeklyStats = WeeklyStats(
        averageDailyMl: averageDailyMl,
        achievedDays: achievedDays,
        validDays: validDays,
        consistencyPercentage: consistencyPercentage,
        highestDay: highestDay,
        lowestRecordedDay: lowestRecordedDay,
        dailyTotals: dailyTotals,
      );

      // Keep old variables populated for backwards compatibility if needed
      final newest7 = allSummaries.length > 7
          ? allSummaries.sublist(0, 7)
          : allSummaries;
      final ordered = newest7.reversed.toList();

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
        monthSummaries: allSummaries,
        weeklyAvgCompliance: avgCompliance,
        daysAbove80: daysAbove80,
        activeDays: activeDays,
        weeklyStats: weeklyStats,
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Force-refresh.
  Future<void> refresh() => _load();
}

final progressProvider = NotifierProvider<ProgressNotifier, ProgressState>(() {
  return ProgressNotifier();
});
