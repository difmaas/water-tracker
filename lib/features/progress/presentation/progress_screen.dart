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
import '../../../providers/app_settings_provider.dart';

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
  int _historyLimit = 10;

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
    Color iconColor = Colors.black,
    Color textColor = Colors.black,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: textColor,
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
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );
    final titleColor = lightweightMode ? const Color(0xFF854D0E) : Colors.black;
    final valueColor = lightweightMode ? const Color(0xFF713F12) : Colors.black;
    final iconColor = lightweightMode ? const Color(0xFF854D0E) : Colors.black;
    final dividerColor = lightweightMode
        ? const Color(0xFF854D0E).withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.05);

    return _buildProgressCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 24,
      lightweightBgColor: const Color(0xFFFEFCE8),
      lightweightBorderColor: const Color(0xFFFEF08A),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ringkasan Selama 7 Hari Terakhir',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.insert_chart_outlined_rounded,
              iconColor: iconColor,
              textColor: titleColor.withValues(alpha: 0.9),
              spans: [
                const TextSpan(text: "Rata-rata "),
                TextSpan(
                  text: "${_formatVolume(stats.averageDailyMl)} ml",
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: valueColor,
                  ),
                ),
                const TextSpan(text: " per hari"),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.gps_fixed_rounded,
              iconColor: iconColor,
              textColor: titleColor.withValues(alpha: 0.9),
              spans: [
                TextSpan(
                  text: "${stats.achievedDays} dari ${stats.validDays} hari",
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: valueColor,
                  ),
                ),
                const TextSpan(text: " mencapai target"),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              icon: Icons.emoji_events_rounded,
              iconColor: iconColor,
              textColor: titleColor.withValues(alpha: 0.9),
              spans: [
                const TextSpan(text: "Konsistensi "),
                TextSpan(
                  text: "${stats.consistencyPercentage}%",
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ],
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
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;
    final isAchieved = achievedMl >= targetMl;
    final hasProgress = achievedMl > 0;
    final dateLabel = '${date.day}';

    BoxDecoration decoration;
    Color textColor;

    if (lightweightMode) {
      if (!isAvailable) {
        decoration = BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        );
        textColor = Colors.black.withValues(alpha: 0.45);
      } else if (isAchieved) {
        decoration = BoxDecoration(
          color: const Color(0xFF1A73E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1557B0), width: 1.0),
        );
        textColor = Colors.white;
      } else if (hasProgress) {
        decoration = BoxDecoration(
          color: const Color(0xFFEAF5FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD7EAFB), width: 1.0),
        );
        textColor = const Color(0xFF0F172A);
      } else {
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        );
        textColor = isToday ? kPrimary : const Color(0xFF0F172A);
      }
    } else {
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
      textStyle: GoogleFonts.manrope(
        color: Colors.black,
        fontWeight: FontWeight.normal,
        fontSize: 12,
        height: 1.35,
      ),
      child: lightweightMode
          ? Container(
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
            )
          : ClipRRect(
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
                      style: GoogleFonts.manrope(
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

    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    final titleColor = lightweightMode ? const Color(0xFF047857) : Colors.black;
    final dividerColor = lightweightMode
        ? const Color(0xFF047857).withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.05);
    final monthLabelColor = lightweightMode
        ? const Color(0xFF047857)
        : kTextDark;
    final chevronColor = lightweightMode ? const Color(0xFF047857) : kPrimary;
    final dayHeaderColor = lightweightMode
        ? const Color(0xFF047857).withValues(alpha: 0.7)
        : const Color(0xFF64748B);

    return _buildProgressCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 24,
      lightweightBgColor: const Color(0xFFECFDF5),
      lightweightBorderColor: const Color(0xFFA7F3D0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double gridSpacing = 8.0;
          final double availableWidth =
              constraints.maxWidth - 40; // Card padding 20 on each side
          final double cellWidth = (availableWidth - (gridSpacing * 6)) / 7;
          final double gridHeight =
              (cellWidth * 6) + (gridSpacing * 5); // 6 rows max
          // monthYearLabel & arrows header (approx 52px) + day headers (20px) + spacing sizes
          final double calendarHeight = 52.0 + 20.0 + 32.0 + gridHeight;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistik Selama 30 Hari Terakhir',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: dividerColor),
                const SizedBox(height: 16),
                SizedBox(
                  height: calendarHeight,
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

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                        _calendarPageController.previousPage(
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
                          // Day headers (S, S, R, K, J, S, M)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                                              fontWeight: FontWeight.w600,
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
                                  summary?.targetMl ?? profile.dailyTargetMl;

                              final normalizedCellDate = DateTime(
                                cellDate.year,
                                cellDate.month,
                                cellDate.day,
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
          );
        },
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

    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    return _buildProgressCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 24,
      lightweightBgColor: const Color(0xFFEAF5FF),
      lightweightBorderColor: const Color(0xFFD7EAFB),
      child: SizedBox(
        width: double.infinity,
        height: 260,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Grafik Minum 7 Hari Terakhir',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: lightweightMode
                        ? const Color(0xFF1A73E8)
                        : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) =>
                            Colors.black.withValues(alpha: 0.8),
                        tooltipBorderRadius: BorderRadius.circular(8),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final ml = rod.toY.round();
                          return BarTooltipItem(
                            '$ml ml',
                            GoogleFonts.manrope(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.normal,
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
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 ||
                                index >= stats.dailyTotals.length) {
                              return const SizedBox.shrink();
                            }
                            final date = stats.dailyTotals[index].date;
                            final labels = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
                            final label = labels[date.weekday - 1];
                            final isToday =
                                date.day == DateTime.now().day &&
                                date.month == DateTime.now().month;

                            return SideTitleWidget(
                              meta: meta,
                              space: 4,
                              child: Text(
                                label,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: isToday
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isToday
                                      ? kPrimary
                                      : const Color(0xFF64748B),
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
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: currentTarget.toDouble(),
                          color: kPrimary.withValues(alpha: 0.35),
                          strokeWidth: 1.2,
                          dashArray: [5, 5],
                        ),
                      ],
                    ),
                    barGroups: List.generate(stats.dailyTotals.length, (index) {
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
                            color: lightweightMode
                                ? (!isAvailable
                                      ? const Color(0xFFE2E8F0)
                                      : kPrimary)
                                : null,
                            gradient: lightweightMode
                                ? null
                                : (!isAvailable
                                      ? LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.black.withValues(
                                              alpha: 0.10,
                                            ),
                                            Colors.black.withValues(
                                              alpha: 0.04,
                                            ),
                                          ],
                                        )
                                      : LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            kPrimary.withValues(alpha: 0.65),
                                            kPrimary.withValues(alpha: 0.20),
                                          ],
                                        )),
                            width: 36,
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: lightweightMode
                                  ? (isAvailable
                                        ? kPrimary
                                        : const Color(0xFFE2E8F0))
                                  : Colors.white.withValues(alpha: 0.6),
                              width: 1.2,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: lightweightMode
                                  ? const Color(0xFFF1F5F9)
                                  : Colors.white.withValues(alpha: 0.15),
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

  @override
  Widget build(BuildContext context) {
    final progressState = ref.watch(progressProvider);
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

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
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.bold,
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
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Lihat kebiasaan minummu dari hari ke hari',
                style: GoogleFonts.manrope(
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
              'Riwayat Minum',
              style: GoogleFonts.manrope(
                fontSize: 26,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lihat kebiasaan minummu dari hari ke hari',
              style: GoogleFonts.manrope(
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
            // 5. Riwayat Harian List (Grouped in a single card)
            _buildProgressCardShell(
              lightweightMode: lightweightMode,
              borderRadius: 24,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Riwayat Harian',
                        style: GoogleFonts.manrope(
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
                      itemCount: activeElapsedDays > _historyLimit
                          ? _historyLimit
                          : activeElapsedDays,
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
                                          style: GoogleFonts.manrope(
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
                                              style: GoogleFonts.manrope(
                                                fontSize: 13,
                                                color: Colors.black.withValues(
                                                  alpha: 0.6,
                                                ),
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
                                                style: GoogleFonts.manrope(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.normal,
                                                  color: isAchieved
                                                      ? kPrimary
                                                      : Colors.black.withValues(
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
                    if (activeElapsedDays > _historyLimit) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _historyLimit += 15;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: kPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Tampilkan Lebih Banyak',
                                  style: GoogleFonts.manrope(
                                    color: kPrimary,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: lightweightMode ? 16 : 120),
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
    Color? lightweightBorderColor,
  }) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: lightweightMode
            ? (lightweightBgColor ?? const Color(0xFFFFFFFF))
            : null,
        gradient: lightweightMode
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.50),
                  Colors.white.withValues(alpha: 0.20),
                ],
              ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: lightweightMode
              ? (lightweightBorderColor ?? const Color(0xFFE2E8F0))
              : Colors.white.withValues(alpha: 0.6),
          width: lightweightMode ? 1.0 : 1.2,
        ),
        boxShadow: lightweightMode
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
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

    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    final container = Container(
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
        color: lightweightMode ? Colors.white : null,
        gradient: lightweightMode
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.60),
                  Colors.white.withValues(alpha: 0.30),
                ],
              ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: lightweightMode
              ? const Color(0xFFE2E8F0)
              : Colors.white.withValues(alpha: 0.6),
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
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.normal,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getFormattedDate(date),
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.black.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lightweightMode ? Colors.white : null,
              gradient: lightweightMode
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.40),
                        Colors.white.withValues(alpha: 0.15),
                      ],
                    ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: lightweightMode
                    ? const Color(0xFFE2E8F0)
                    : Colors.white.withValues(alpha: 0.5),
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
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total minum: $achievedMl ml',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$displayPct%',
                  style: GoogleFonts.manrope(
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
                      style: GoogleFonts.manrope(
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
                        style: GoogleFonts.manrope(
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
                    color: lightweightMode ? Colors.white : null,
                    gradient: lightweightMode
                        ? null
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.40),
                              Colors.white.withValues(alpha: 0.15),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: lightweightMode
                          ? const Color(0xFFE2E8F0)
                          : Colors.white.withValues(alpha: 0.5),
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
                            style: GoogleFonts.manrope(
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
    );

    if (lightweightMode) {
      return container;
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: container,
      ),
    );
  }
}
