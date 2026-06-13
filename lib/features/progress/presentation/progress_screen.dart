import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../logging/data/daily_summary_model.dart';
import '../../logging/data/hydration_log_model.dart';
import '../../logging/data/logging_repository.dart';
import '../../profile/data/user_profile_model.dart';
import '../../dashboard/presentation/widgets/hydration_log_tile.dart';
import '../progress_provider.dart';
import '../../../core/widgets/app_button.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  static const int _calendarInitialPage = 600;
  late final PageController _calendarPageController;
  int _touchedBarIndex = -1;
  Timer? _tooltipTimer;

  // Theme styling colors matching Splash/Onboarding/Settings
  static const Color kPrimary = Color(0xFF1A73E8);
  static const Color kTextDark = Color(0xFF1F2937);
  static const Color kTextSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _calendarPageController = PageController(initialPage: _calendarInitialPage);
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

  void _showDayDetail(
    String userId,
    DateTime date,
    int dayNum,
    int achievedMl,
    int targetMl,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      builder: (context) {
        return _DayDetailBottomSheet(
          userId: userId,
          date: date,
          achievedMl: achievedMl,
          targetMl: targetMl,
        );
      },
    );
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

  String _getShortDayName(DateTime date) {
    const dayNames = {
      DateTime.monday: 'Sen',
      DateTime.tuesday: 'Sel',
      DateTime.wednesday: 'Rab',
      DateTime.thursday: 'Kam',
      DateTime.friday: 'Jum',
      DateTime.saturday: 'Sab',
      DateTime.sunday: 'Min',
    };
    return dayNames[date.weekday] ?? '';
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

  Widget _buildStatRow({
    required IconData icon,
    required List<TextSpan> spans,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.black, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
              children: spans,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyStatsCard(WeeklyStats stats) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.50),
                Colors.white.withValues(alpha: 0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Selama 7 Hari Terakhir',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
              const SizedBox(height: 16),
              _buildStatRow(
                icon: Icons.insert_chart_outlined_rounded,
                spans: [
                  const TextSpan(text: "Rata-rata "),
                  TextSpan(
                    text: "${_formatVolume(stats.averageDailyMl)} ml",
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  const TextSpan(text: " per hari"),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                icon: Icons.gps_fixed_rounded,
                spans: [
                  TextSpan(
                    text: "${stats.achievedDays} dari ${stats.validDays} hari",
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                  const TextSpan(text: " mencapai target"),
                ],
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                icon: Icons.emoji_events_rounded,
                spans: [
                  const TextSpan(text: "Konsistensi "),
                  TextSpan(
                    text: "${stats.consistencyPercentage}%",
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarDayCell({
    required DateTime date,
    required bool isAvailable,
    required bool isToday,
    required int achievedMl,
    required int targetMl,
  }) {
    final isAchieved = achievedMl >= targetMl;
    final hasProgress = achievedMl > 0;
    final dateLabel = '${date.day}';

    BoxDecoration decoration;
    Color textColor;

    if (!isAvailable) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.06),
            Colors.black.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.0,
        ),
      );
      textColor = Colors.black.withValues(alpha: 0.45);
    } else if (isAchieved) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            kPrimary.withValues(alpha: 0.65),
            kPrimary.withValues(alpha: 0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.0,
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.38),
            Colors.white.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.50),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      );
      textColor = Colors.black;
    } else {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.26),
            Colors.white.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.40),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      );
      textColor = isToday ? kPrimary : Colors.black.withValues(alpha: 0.72);
    }

    final tooltipMessage = isAvailable
        ? '${_getFormattedDate(date)}\n${_formatVolume(achievedMl)} / ${_formatVolume(targetMl)} ml'
        : '${_getFormattedDate(date)}\nBelum aktif';

    return Tooltip(
      message: tooltipMessage,
      triggerMode: TooltipTriggerMode.tap,
      preferBelow: false,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textStyle: GoogleFonts.inter(
        color: Colors.black,
        fontWeight: FontWeight.normal,
        fontSize: 12,
        height: 1.35,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 40,
            height: 40,
            decoration: decoration,
            child: Center(
              child: Text(
                dateLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: textColor,
                ),
              ),
            ),
          ),
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.50),
                Colors.white.withValues(alpha: 0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistik Selama 30 Hari Terakhir',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
              const SizedBox(height: 16),
              SizedBox(
                height: 348,
                child: PageView.builder(
                  controller: _calendarPageController,
                  itemBuilder: (context, pageIndex) {
                    final monthOffset = pageIndex - _calendarInitialPage;
                    final monthStart = _addMonths(todayMidnight, monthOffset);
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
                    final totalCells = paddingCount + daysInMonth;
                    final visibleMonth = DateTime(
                      monthStart.year,
                      monthStart.month,
                      1,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getMonthYearLabel(visibleMonth),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: Colors.black.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['S', 'S', 'R', 'K', 'J', 'S', 'M']
                              .map(
                                (day) => SizedBox(
                                  width: 40,
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.normal,
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                mainAxisExtent: 40,
                              ),
                          itemCount: totalCells,
                          itemBuilder: (context, index) {
                            if (index < paddingCount) {
                              return const SizedBox.shrink();
                            }

                            final dayNumber = index - paddingCount + 1;
                            final cellDate = DateTime(
                              visibleMonth.year,
                              visibleMonth.month,
                              dayNumber,
                            );
                            final normalizedCellDate = DateTime(
                              cellDate.year,
                              cellDate.month,
                              cellDate.day,
                            );
                            final summary = summaryMap[normalizedCellDate];
                            final achieved = summary?.achievedMl ?? 0;
                            final target =
                                summary?.targetMl ?? profile.dailyTargetMl;
                            final isAvailable =
                                !normalizedCellDate.isBefore(userStartDate) &&
                                !normalizedCellDate.isAfter(todayMidnight);
                            final isToday = DateUtils.isSameDay(
                              normalizedCellDate,
                              todayMidnight,
                            );

                            return _buildCalendarDayCell(
                              date: normalizedCellDate,
                              isAvailable: isAvailable,
                              isToday: isToday,
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
            ],
          ),
        ),
      ),
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

    // Use current target for target line
    final currentTarget = stats.dailyTotals.last.targetMl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          height: 260,
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.50),
                Colors.white.withValues(alpha: 0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Statistik Selama 7 Hari Terakhir',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: false,
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (event is FlTapDownEvent) {
                          setState(() {
                            if (barTouchResponse == null ||
                                barTouchResponse.spot == null) {
                              _touchedBarIndex = -1;
                              _tooltipTimer?.cancel();
                            } else {
                              final index =
                                  barTouchResponse.spot!.touchedBarGroupIndex;
                              if (_touchedBarIndex == index) {
                                _touchedBarIndex = -1;
                                _tooltipTimer?.cancel();
                              } else {
                                _touchedBarIndex = index;
                                _tooltipTimer?.cancel();
                                _tooltipTimer = Timer(
                                  const Duration(seconds: 2),
                                  () {
                                    if (mounted) {
                                      setState(() {
                                        _touchedBarIndex = -1;
                                      });
                                    }
                                  },
                                );
                              }
                            }
                          });
                        }
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) =>
                            Colors.white.withValues(alpha: 0.62),
                        tooltipBorderRadius: BorderRadius.circular(14),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dayData = stats.dailyTotals[group.x.toInt()];
                          if (!dayData.isAvailable) return null;
                          return BarTooltipItem(
                            '${_formatVolume(dayData.achievedMl)} ml',
                            GoogleFonts.inter(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= stats.dailyTotals.length) {
                              return const SizedBox.shrink();
                            }
                            final dayData = stats.dailyTotals[index];
                            final dayLabel = _getShortDayName(dayData.date);
                            final isToday = DateUtils.isSameDay(
                              dayData.date,
                              DateTime.now(),
                            );

                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dayLabel,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                  color: isToday
                                      ? kPrimary
                                      : Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                            );
                          },
                          reservedSize: 28,
                        ),
                      ),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    // Dashed target line
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: currentTarget.toDouble(),
                          color: Colors.black.withValues(alpha: 0.25),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topLeft,
                            padding: const EdgeInsets.only(left: 4, top: 4),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.normal,
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                            // Technical comment: Historical targets may vary, target line represents current target.
                            labelResolver: (line) =>
                                'Target: ${line.y.toInt()} ml',
                          ),
                        ),
                      ],
                    ),
                    barGroups: List.generate(stats.dailyTotals.length, (index) {
                      final dayData = stats.dailyTotals[index];
                      final isAvailable = dayData.isAvailable;
                      final value = isAvailable
                          ? dayData.achievedMl.toDouble()
                          : 0.0;

                      return BarChartGroupData(
                        x: index,
                        showingTooltipIndicators: _touchedBarIndex == index
                            ? [0]
                            : [],
                        barRods: [
                          BarChartRodData(
                            toY: value,
                            gradient: !isAvailable
                                ? LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.10),
                                      Colors.black.withValues(alpha: 0.04),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      kPrimary.withValues(alpha: 0.65),
                                      kPrimary.withValues(alpha: 0.20),
                                    ],
                                  ),
                            width: 36,
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(progressProvider);

    if (progressState.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    if (progressState.error != null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
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
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${progressState.error}',
                style: GoogleFonts.inter(fontSize: 12, color: kTextSecondary),
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
        backgroundColor: Colors.transparent,
        body: _buildEmptyState(),
      );
    }

    final stats = progressState.weeklyStats;
    final summaries = progressState.monthSummaries;

    // Empty state if there's no history data at all
    if (summaries.isEmpty || stats == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
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
                'Riwayat Minum',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lihat kebiasaan minummu dari hari ke hari',
                style: GoogleFonts.inter(
                  fontSize: 13,
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
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 200,
              child: _buildEmptyState(),
            ),
          ),
        ),
      );
    }

    final startDateTime = profile.createdAt;
    final startDate = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final elapsedDays = todayDate.difference(startDate).inDays + 1;
    final activeElapsedDays = elapsedDays > 0 ? elapsedDays : 1;

    // Map summaries by date for O(1) lookup in daily history list
    final Map<DateTime, DailySummary> summaryMap = {};
    for (final s in summaries) {
      final sDate = DateTime(s.date.year, s.date.month, s.date.day);
      summaryMap[sDate] = s;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
              'Riwayat Minum',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lihat kebiasaan minummu dari hari ke hari',
              style: GoogleFonts.inter(
                fontSize: 13,
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
            // 2. Card statistik utama (Header "Ringkasan 7 Hari" is now inside this card)
            _buildWeeklyStatsCard(stats),
            const SizedBox(height: 24),

            // 3. Grafik batang mingguan
            _buildBarChartSection(stats),
            const SizedBox(height: 24),

            // 4. Kalender Hidrasi 30 Hari
            _buildCalendarSection(profile, summaries),
            const SizedBox(height: 24),

            // 5. Riwayat Harian List (Grouped in a single glassmorphic card)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.50),
                        Colors.white.withValues(alpha: 0.20),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'Riwayat Harian',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: Colors.black.withValues(alpha: 0.05),
                      ),
                      const SizedBox(height: 4),
                      ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeElapsedDays,
                        itemBuilder: (context, index) {
                          // Sorted newest to oldest
                          final dayNum = activeElapsedDays - index;
                          final dayDate = startDate.add(
                            Duration(days: dayNum - 1),
                          );
                          final summary = summaryMap[dayDate];

                          final achieved = summary?.achievedMl ?? 0;
                          final target =
                              summary?.targetMl ?? profile.dailyTargetMl;
                          final isAchieved = achieved >= target;
                          final normalizedDayDate = DateTime(
                            dayDate.year,
                            dayDate.month,
                            dayDate.day,
                          );

                          final Widget itemContent = Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showDayDetail(
                                profile.userId,
                                normalizedDayDate,
                                dayNum,
                                achieved,
                                target,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getFormattedDate(dayDate),
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                '$achieved / $target ml',
                                                style: GoogleFonts.inter(
                                                  fontSize: 13,
                                                  color: Colors.black
                                                      .withValues(alpha: 0.6),
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: isAchieved
                                                      ? kPrimary.withValues(
                                                          alpha: 0.12,
                                                        )
                                                      : Colors.black.withValues(
                                                          alpha: 0.08,
                                                        ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  isAchieved
                                                      ? 'Target tercapai'
                                                      : 'Belum tercapai',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: isAchieved
                                                        ? kPrimary
                                                        : Colors.black
                                                              .withValues(
                                                                alpha: 0.6,
                                                              ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );

                          if (index < activeElapsedDays - 1) {
                            return Column(
                              children: [
                                itemContent,
                                Divider(
                                  height: 1,
                                  color: Colors.black.withValues(alpha: 0.05),
                                ),
                              ],
                            );
                          }
                          return itemContent;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

class _DayDetailBottomSheet extends ConsumerWidget {
  final String userId;
  final DateTime date;
  final int achievedMl;
  final int targetMl;

  const _DayDetailBottomSheet({
    required this.userId,
    required this.date,
    required this.achievedMl,
    required this.targetMl,
  });

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double rawPct = targetMl > 0 ? (achievedMl / targetMl) * 100 : 0.0;
    final displayPct = rawPct.toStringAsFixed(0);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.78,
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 24,
            right: 24,
            bottom: bottomInset + 28,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.60),
                Colors.white.withValues(alpha: 0.30),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detail Harian',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getFormattedDate(date),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.40),
                      Colors.white.withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target harian: $targetMl ml',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.normal,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total minum: $achievedMl ml',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$displayPct%',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: FutureBuilder<List<HydrationLog>>(
                  future: ref
                      .read(loggingRepositoryProvider)
                      .getLogsForDate(userId, normalizedDate),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _ProgressScreenState.kPrimary,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Gagal memuat log minum',
                          style: GoogleFonts.inter(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }

                    final logs = List<HydrationLog>.from(snapshot.data ?? []);
                    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
                    if (logs.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Center(
                          child: Text(
                            'Belum ada catatan minum untuk hari ini.',
                            style: GoogleFonts.inter(
                              color: Colors.black.withValues(alpha: 0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.40),
                            Colors.white.withValues(alpha: 0.15),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 16,
                                top: 16,
                                bottom: 8,
                              ),
                              child: Text(
                                'Daftar Log Minum',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: logs.length,
                                itemBuilder: (context, idx) {
                                  final log = logs[idx];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Column(
                                      children: [
                                        HydrationLogTile(
                                          log: log,
                                          isFirst: idx == 0,
                                          isLast: idx == logs.length - 1,
                                          showActions: false,
                                        ),
                                        if (idx < logs.length - 1)
                                          const SizedBox(height: 8),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
