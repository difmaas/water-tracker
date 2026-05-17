import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../logging/data/daily_summary_model.dart';
import '../../progress_provider.dart';

/// Weekly bar chart widget for F-14 Progress Screen.
///
/// Displays up to 7 bars — one per DailySummary day.
/// Each bar shows achievedMl as a fraction of targetMl.
///
/// Features:
/// - Color-coded bars: green >=80%, yellow 40–79%, red <40%
/// - Dashed horizontal reference line at 80% compliance
/// - Y-axis labels in percentage (0%–100%)
/// - X-axis labels: short day abbreviation (Sen, Sel, …)
class WeeklyBarChart extends StatelessWidget {
  final ProgressState state;

  const WeeklyBarChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.weekSummaries.isEmpty) {
      return const _EmptyChartPlaceholder();
    }

    // Find max target across all days for chart ceiling
    int maxTarget = 0;
    for (final s in state.weekSummaries) {
      if (s.targetMl > maxTarget) maxTarget = s.targetMl;
    }
    final chartMax = maxTarget > 0 ? maxTarget.toDouble() : 2000.0;

    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, top: 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: chartMax,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF1565C0),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final s = state.weekSummaries[group.x];
                  final ml = rod.toY.toInt();
                  final pct = s.targetMl > 0
                      ? ((ml / s.targetMl) * 100).toStringAsFixed(0)
                      : '0';
                  return BarTooltipItem(
                    '$ml ml\n$pct%',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  interval: chartMax / 4,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max) return const SizedBox.shrink();
                    final pct = chartMax > 0
                        ? ((value / chartMax) * 100).toInt()
                        : 0;
                    return Text(
                      '$pct%',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 ||
                        index >= state.weekSummaries.length) {
                      return const SizedBox.shrink();
                    }
                    final date = state.weekSummaries[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _dayAbbr(date.weekday),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: chartMax / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: _buildBarGroups(chartMax),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: chartMax * 0.8,
                  color: const Color(0xFF81C784),
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF388E3C), // readable darker green
                      fontWeight: FontWeight.w600,
                    ),
                    labelResolver: (_) => '80%',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(double chartMax) {
    return state.weekSummaries.asMap().entries.map((entry) {
      final index = entry.key;
      final DailySummary s = entry.value;
      final compliance =
          s.targetMl > 0 ? s.achievedMl / s.targetMl : 0.0;

      final Color barColor;
      if (compliance >= 1.0) {
        barColor = const Color(0xFFF06292); // Sangat Tinggi (Pink)
      } else if (compliance >= 0.8) {
        barColor = const Color(0xFF81C784); // Tinggi (Green)
      } else if (compliance >= 0.4) {
        barColor = const Color(0xFF64B5F6); // Sedang (Blue)
      } else {
        barColor = const Color(0xFFECEFF1); // Rendah (Grey)
      }

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: s.achievedMl.toDouble().clamp(0.0, chartMax),
            color: barColor,
            width: 24,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: chartMax,
              color: Colors.grey.shade100,
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Bahasa Indonesia abbreviated weekday names.
  static String _dayAbbr(int weekday) {
    const names = {
      1: 'Sen',
      2: 'Sel',
      3: 'Rab',
      4: 'Kam',
      5: 'Jum',
      6: 'Sab',
      7: 'Min',
    };
    return names[weekday] ?? '?';
  }
}

/// Shown when there are no DailySummary records yet.
class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Belum ada data mingguan.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Data akan muncul setelah 1 hari pencatatan.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
