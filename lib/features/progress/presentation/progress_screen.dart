import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../logging/data/daily_summary_model.dart';
import '../../logging/data/hydration_log_model.dart';
import '../../profile/data/user_profile_model.dart';
import '../../dashboard/presentation/widgets/hydration_log_tile.dart';
import '../progress_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/hydration_provider.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  static const int _calendarInitialPage = 600;
  late final PageController _calendarPageController;
  late DateTime _selectedLogDate;
  int _touchedBarIndex = -1;
  Timer? _tooltipTimer;
  final Map<DateTime, GlobalKey<TooltipState>> _tooltipKeys = {};

  // Theme styling colors matching Splash/Onboarding/Settings
  static const Color kPrimary = Color(0xFF1A73E8);
  static const Color kSoftBlueCard = Color(0xFFEAF5FF);
  static const Color kSoftBlueFill = Color(0xFFD7EAFB);
  static const Color kTextDark = Color(0xFF1F2937);
  static const Color kTextSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _calendarPageController = PageController(initialPage: _calendarInitialPage);
    final now = DateTime.now();
    _selectedLogDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _calendarPageController.dispose();
    super.dispose();
  }

  String _getFormattedDate(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatVolume(int ml) {
    final str = ml.toString();
    if (str.length <= 3) return str;
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  String _getMonthYearLabel(DateTime date) {
    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  DateTime _addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _weeklyTotalMl(WeeklyStats stats) {
    return stats.dailyTotals
        .where((day) => day.isAvailable)
        .fold<int>(0, (sum, day) => sum + day.achievedMl);
  }

  List<DailySummary> _last30DaySummaries(List<DailySummary> summaries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 29));

    return summaries.where((summary) {
      final date = DateTime(
        summary.date.year,
        summary.date.month,
        summary.date.day,
      );
      return !date.isBefore(start) && !date.isAfter(today);
    }).toList();
  }

  Widget _buildSectionTitle(String title) {
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: lightweightMode ? FontWeight.w700 : FontWeight.normal,
          color: Colors.black,
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  Widget _buildHistoryStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF263238),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayLogTile(List<HydrationLog> logs, int index) {
    final log = logs[index];
    return HydrationLogTile(
      log: log,
      isFirst: index == 0,
      isLast: index == logs.length - 1,
      showActions: true,
    );
  }

  Widget _buildCalendarDayCell({
    required DateTime date,
    required bool isAvailable,
    required bool isToday,
    required bool isSelected,
    required int achievedMl,
    required int targetMl,
  }) {
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;
    final isAchieved = achievedMl >= targetMl;
    final hasProgress = achievedMl > 0;
    final dateLabel = '${date.day}';

    final shouldOutline = isSelected || isToday;

    BoxDecoration decoration;
    Color textColor;

    if (lightweightMode) {
      if (!isAvailable) {
        decoration = BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shouldOutline ? kPrimary : const Color(0xFFE2E8F0),
            width: shouldOutline ? 1.6 : 1.0,
          ),
        );
        textColor = Colors.black.withValues(alpha: 0.45);
      } else if (isAchieved) {
        decoration = BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shouldOutline ? const Color(0xFF0F3F99) : kPrimary,
            width: shouldOutline ? 1.6 : 1.0,
          ),
        );
        textColor = Colors.white;
      } else if (hasProgress) {
        decoration = BoxDecoration(
          color: kSoftBlueCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shouldOutline ? kPrimary : kSoftBlueFill,
            width: shouldOutline ? 1.6 : 1.0,
          ),
        );
        textColor = kTextDark;
      } else {
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shouldOutline ? kPrimary : const Color(0xFFE2E8F0),
            width: shouldOutline ? 1.6 : 1.0,
          ),
        );
        textColor = shouldOutline ? kPrimary : const Color(0xFF0F172A);
      }
    } else {
      if (!isAvailable) {
        decoration = BoxDecoration(
          color: Colors.white.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shouldOutline
                ? kPrimary
                : Colors.white.withValues(alpha: 0.42),
            width: shouldOutline ? 1.6 : 1.0,
          ),
        );
        textColor = Colors.black.withValues(alpha: 0.45);
      } else if (isAchieved) {
        decoration = BoxDecoration(
          color: kPrimary.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shouldOutline
                ? const Color(0xFF0F3F99)
                : kPrimary.withValues(alpha: 0.75),
            width: shouldOutline ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        );
        textColor = Colors.white;
      } else if (hasProgress) {
        decoration = BoxDecoration(
          color: kSoftBlueCard.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shouldOutline
                ? kPrimary
                : kSoftBlueFill.withValues(alpha: 0.92),
            width: shouldOutline ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        );
        textColor = kTextDark;
      } else {
        decoration = BoxDecoration(
          color: Colors.white.withValues(alpha: 0.56),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: shouldOutline
                ? kPrimary
                : Colors.white.withValues(alpha: 0.46),
            width: shouldOutline ? 1.6 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        );
        textColor = shouldOutline
            ? kPrimary
            : Colors.black.withValues(alpha: 0.72);
      }
    }

    final tooltipMessage = isAvailable
        ? '${_getFormattedDate(date)}\n${_formatVolume(achievedMl)} / ${_formatVolume(targetMl)} ml'
        : '${_getFormattedDate(date)}\nBelum aktif';

    final cellContent = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      width: 40,
      height: 40,
      decoration: decoration,
      child: Center(
        child: Text(
          dateLabel,
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: textColor,
          ),
        ),
      ),
    );

    final tooltipKey = _tooltipKeys.putIfAbsent(
      date,
      () => GlobalKey<TooltipState>(),
    );

    return Tooltip(
      key: tooltipKey,
      message: tooltipMessage,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      decoration: BoxDecoration(
        color: lightweightMode
            ? const Color(0xFF1E3A8A)
            : Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(lightweightMode ? 10 : 12),
        border: lightweightMode
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.2,
              ),
        boxShadow: lightweightMode
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      textStyle: GoogleFonts.manrope(
        color: lightweightMode ? Colors.white : const Color(0xFF0F172A),
        fontWeight: lightweightMode ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
        height: 1.35,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isAvailable
              ? () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    tooltipKey.currentState?.ensureTooltipVisible();
                  });

                  if (_selectedLogDate != date) {
                    setState(() {
                      _selectedLogDate = date;
                    });
                  }
                }
              : null,
          child: cellContent,
        ),
      ),
    );
  }

  Widget _buildCalendarSection(
    UserProfile profile,
    List<DailySummary> summaries,
  ) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final startDateTime = profile.createdAt;
    final userStartDate = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );

    final Map<DateTime, DailySummary> summaryMap = {};
    for (final summary in summaries) {
      final summaryDate = DateTime(
        summary.date.year,
        summary.date.month,
        summary.date.day,
      );
      summaryMap[summaryDate] = summary;
    }

    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    final monthLabelColor = lightweightMode
        ? const Color(0xFF0F172A)
        : kTextDark;
    final chevronColor = lightweightMode ? const Color(0xFF0F172A) : kPrimary;
    final dayHeaderColor = lightweightMode
        ? const Color(0xFF0F172A).withValues(alpha: 0.7)
        : const Color(0xFF64748B);

    final last30Summaries = _last30DaySummaries(summaries);
    final monthlyTotal = last30Summaries.fold<int>(
      0,
      (sum, summary) => sum + summary.achievedMl,
    );
    final monthlyAverage = (monthlyTotal / 30).round();
    final monthlyAchieved = last30Summaries
        .where((summary) => summary.achievedMl >= summary.targetMl)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('30 hari'),
        _buildProgressCardShell(
          lightweightMode: lightweightMode,
          borderRadius: 18,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double gridSpacing = 8.0;
              final double availableWidth = constraints.maxWidth - 40;
              final double cellWidth = (availableWidth - (gridSpacing * 6)) / 7;
              final double gridHeight = (cellWidth * 6) + (gridSpacing * 5);
              final double calendarHeight = 82.0 + gridHeight;

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: calendarHeight,
                      child: PageView.builder(
                        controller: _calendarPageController,
                        itemBuilder: (context, pageIndex) {
                          final monthOffset = pageIndex - _calendarInitialPage;
                          final monthStart = _addMonths(
                            todayMidnight,
                            monthOffset,
                          );
                          final firstDayOfMonth = DateTime(
                            monthStart.year,
                            monthStart.month,
                            1,
                          );
                          final nextMonth = DateTime(
                            monthStart.year,
                            monthStart.month + 1,
                            1,
                          );
                          final daysInMonth = nextMonth
                              .subtract(const Duration(days: 1))
                              .day;
                          final paddingCount = firstDayOfMonth.weekday - 1;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _getMonthYearLabel(monthStart),
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                        color: monthLabelColor,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.chevron_left_rounded,
                                            color: chevronColor,
                                          ),
                                          onPressed: () {
                                            _calendarPageController
                                                .previousPage(
                                                  duration: const Duration(
                                                    milliseconds: 300,
                                                  ),
                                                  curve: Curves.easeInOut,
                                                );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.chevron_right_rounded,
                                            color: chevronColor,
                                          ),
                                          onPressed: () {
                                            _calendarPageController.nextPage(
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Day headers (Sen, Sel, Rab, Kam, Jum, Sab, Min)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children:
                                    [
                                          'Sen',
                                          'Sel',
                                          'Rab',
                                          'Kam',
                                          'Jum',
                                          'Sab',
                                          'Min',
                                        ]
                                        .map(
                                          (day) => SizedBox(
                                            width: 40,
                                            child: Center(
                                              child: Text(
                                                day,
                                                style: GoogleFonts.manrope(
                                                  fontSize: 10,
                                                  fontWeight: lightweightMode
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                  color: dayHeaderColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                              const SizedBox(height: 8),
                              // Grid of days
                              GridView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 7,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                    ),
                                itemCount: daysInMonth + paddingCount,
                                itemBuilder: (context, index) {
                                  if (index < paddingCount) {
                                    return const SizedBox.shrink();
                                  }
                                  final day = index - paddingCount + 1;
                                  final cellDate = DateTime(
                                    monthStart.year,
                                    monthStart.month,
                                    day,
                                  );

                                  final isAvailable =
                                      cellDate.isAfter(userStartDate) ||
                                      cellDate.isAtSameMomentAs(userStartDate);
                                  final isToday = cellDate.isAtSameMomentAs(
                                    todayMidnight,
                                  );

                                  final summary = summaryMap[cellDate];
                                  final achieved = summary?.achievedMl ?? 0;
                                  final target =
                                      summary?.targetMl ??
                                      profile.dailyTargetMl;

                                  final normalizedCellDate = DateTime(
                                    cellDate.year,
                                    cellDate.month,
                                    cellDate.day,
                                  );

                                  return _buildCalendarDayCell(
                                    date: normalizedCellDate,
                                    isAvailable: isAvailable,
                                    isToday: isToday,
                                    isSelected: _isSameDay(
                                      normalizedCellDate,
                                      _selectedLogDate,
                                    ),
                                    achievedMl: achieved,
                                    targetMl: target,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildHistoryStatRow(
                      'Total minum',
                      '${_formatVolume(monthlyTotal)} ml',
                    ),
                    _buildHistoryStatRow(
                      'Rata-rata harian',
                      '${_formatVolume(monthlyAverage)} ml',
                    ),
                    _buildHistoryStatRow(
                      'Target tercapai',
                      '$monthlyAchieved hari',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBarChartSection(WeeklyStats stats) {
    // Determine the max Y value for the chart to scale properly
    double maxY = 2500;
    for (final dt in stats.dailyTotals) {
      if (dt.achievedMl > maxY) {
        maxY = dt.achievedMl.toDouble();
      }
      if (dt.targetMl > maxY) {
        maxY = dt.targetMl.toDouble();
      }
    }
    // Give some padding at the top of the chart
    maxY = (maxY + 500).toDouble();

    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );
    final weeklyTotal = _weeklyTotalMl(stats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('7 hari'),
        _buildProgressCardShell(
          lightweightMode: lightweightMode,
          borderRadius: 18,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => lightweightMode
                              ? const Color(0xFF1E3A8A)
                              : Colors.white.withValues(alpha: 0.88),
                          tooltipBorderRadius: BorderRadius.circular(lightweightMode ? 10 : 12),
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final ml = rod.toY.round();
                            return BarTooltipItem(
                              '$ml ml',
                              GoogleFonts.manrope(
                                color: lightweightMode
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 12,
                                fontWeight: lightweightMode
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                        touchCallback: (event, response) {
                          setState(() {
                            if (event.isInterestedForInteractions &&
                                response != null &&
                                response.spot != null) {
                              _touchedBarIndex =
                                  response.spot!.touchedBarGroupIndex;
                              _tooltipTimer?.cancel();
                              _tooltipTimer = Timer(
                                const Duration(seconds: 2),
                                () {
                                  setState(() {
                                    _touchedBarIndex = -1;
                                  });
                                },
                              );
                            } else {
                              _touchedBarIndex = -1;
                            }
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 ||
                                  index >= stats.dailyTotals.length) {
                                return const SizedBox.shrink();
                              }
                              final date = stats.dailyTotals[index].date;
                              final labels = [
                                'Sen',
                                'Sel',
                                'Rab',
                                'Kam',
                                'Jum',
                                'Sab',
                                'Min',
                              ];
                              final label = labels[date.weekday - 1];
                              final isToday =
                                  date.day == DateTime.now().day &&
                                  date.month == DateTime.now().month;

                              return SideTitleWidget(
                                meta: meta,
                                space: 6,
                                child: Text(
                                  label,
                                  style: GoogleFonts.manrope(
                                    fontSize: 16,
                                    fontWeight: lightweightMode
                                        ? (isToday
                                              ? FontWeight.w700
                                              : FontWeight.w600)
                                        : FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(stats.dailyTotals.length, (
                        index,
                      ) {
                        final dt = stats.dailyTotals[index];
                        final value = dt.achievedMl.toDouble();
                        final isAvailable =
                            dt.date.isBefore(DateTime.now()) ||
                            (dt.date.day == DateTime.now().day &&
                                dt.date.month == DateTime.now().month);

                        return BarChartGroupData(
                          x: index,
                          showingTooltipIndicators: _touchedBarIndex == index
                              ? [0]
                              : [],
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              color: !isAvailable
                                  ? const Color(0xFFEAF2FF)
                                  : (_touchedBarIndex == index
                                        ? kPrimary
                                        : (_touchedBarIndex >= 0
                                            ? const Color(0xFF5AA7F2).withValues(alpha: 0.72)
                                            : const Color(0xFF5AA7F2))),
                              width: 36,
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxY,
                                color: Colors.transparent,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      _buildHistoryStatRow(
                        'Total minum',
                        '${_formatVolume(weeklyTotal)} ml',
                      ),
                      _buildHistoryStatRow(
                        'Rata-rata harian',
                        '${_formatVolume(stats.averageDailyMl)} ml',
                      ),
                      _buildHistoryStatRow(
                        'Target tercapai',
                        '${stats.achievedDays} hari',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sepertinya Kamu Pengguna Baru Ya',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'yuk mulai minum biar bisa pantau kebiasaan kamu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: Colors.black.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.normal,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard(
    HydrationState hydrationState,
    bool lightweightMode,
  ) {
    final sortedLogs = List<HydrationLog>.from(hydrationState.todayLogs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final rawPercent = hydrationState.targetMl > 0
        ? (hydrationState.currentMl / hydrationState.targetMl) * 100
        : 0.0;
    final progress = hydrationState.progressPercent.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Hari ini'),
        _buildProgressCardShell(
          lightweightMode: lightweightMode,
          borderRadius: 18,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatVolume(hydrationState.currentMl)} / ${_formatVolume(hydrationState.targetMl)} ml',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: lightweightMode
                        ? FontWeight.w700
                        : FontWeight.normal,
                    color: Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${rawPercent.toStringAsFixed(0)}% dari kebutuhan harian kamu',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF5AA7F2),
                    ),
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  sortedLogs.isEmpty
                      ? 'Belum ada catatan minum hari ini.'
                      : '${sortedLogs.length} kali minum hari ini',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.black.withValues(alpha: 0.72),
                  ),
                ),
                if (sortedLogs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  if (sortedLogs.length <= 4)
                    ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedLogs.length,
                      itemBuilder: (context, index) =>
                          _buildTodayLogTile(sortedLogs, index),
                    )
                  else
                    SizedBox(
                      height: 224,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        primary: false,
                        physics: const ClampingScrollPhysics(),
                        itemCount: sortedLogs.length,
                        itemBuilder: (context, index) =>
                            _buildTodayLogTile(sortedLogs, index),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(progressProvider);
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );
    final hydrationState = ref.watch(hydrationProvider);

    if (progressState.isLoading) {
      return Scaffold(
        backgroundColor: lightweightMode
            ? const Color(0xFFEAF2FF)
            : Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    if (progressState.error != null) {
      return Scaffold(
        backgroundColor: lightweightMode
            ? const Color(0xFFEAF2FF)
            : Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Color(0xFFEF4444),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat data riwayat',
                style: GoogleFonts.manrope(
                  fontWeight: lightweightMode
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progressState.error}',
                style: GoogleFonts.manrope(fontSize: 12, color: kTextSecondary),
              ),
              const SizedBox(height: 16),
              AppButton.main(
                label: 'Coba Lagi',
                onPressed: () => ref.read(progressProvider.notifier).refresh(),
              ),
            ],
          ),
        ),
      );
    }

    final profile = progressState.profile;
    if (profile == null) {
      return Scaffold(
        backgroundColor: lightweightMode
            ? const Color(0xFFEAF2FF)
            : Colors.transparent,
        body: _buildEmptyState(),
      );
    }

    final stats = progressState.weeklyStats;
    final summaries = progressState.monthSummaries;

    // Safeguard in case stats or summaries are not ready
    if (stats == null) {
      return Scaffold(
        backgroundColor: lightweightMode
            ? const Color(0xFFEAF2FF)
            : Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    return Scaffold(
      backgroundColor: lightweightMode
          ? const Color(0xFFEAF2FF)
          : Colors.transparent,
      extendBody: !lightweightMode,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 24,
        toolbarHeight: 100,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Riwayat minum',
              style: GoogleFonts.manrope(
                fontSize: 24,
                fontWeight: lightweightMode
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lihat kebiasaan minum kamu dari hari ke hari',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: () => ref.read(progressProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildTodaySummaryCard(hydrationState, lightweightMode),
            const SizedBox(height: 24),
            _buildBarChartSection(stats),
            const SizedBox(height: 24),
            _buildCalendarSection(profile, summaries),
            SizedBox(height: lightweightMode ? 16 : 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCardShell({
    required bool lightweightMode,
    required double borderRadius,
    required Widget child,
    Color? lightweightBgColor,
  }) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: lightweightMode
            ? (lightweightBgColor ?? const Color(0xFFD7E5FF))
            : Colors.white.withValues(alpha: 0.78),
        gradient: lightweightMode
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.58),
                ],
              ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: lightweightMode
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: 1.2,
              ),
        boxShadow: lightweightMode
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(6, 10),
                ),
              ],
      ),
      child: child,
    );

    if (lightweightMode) {
      return card;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: card,
      ),
    );
  }
}
