import 'package:flutter/material.dart';
import '../../../logging/data/daily_summary_model.dart';
import '../../progress_provider.dart';

/// Weekly compliance summary cards for F-14 Progress Screen.
///
/// Shows three key metrics for the last 7 days:
/// - Average compliance rate (%)
/// - Days where compliance >= 80%
/// - Active days (at least 1 log recorded)
class ComplianceSummary extends StatelessWidget {
  final ProgressState state;

  const ComplianceSummary({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pct = (state.weeklyAvgCompliance * 100).toStringAsFixed(0);
    final total = state.weekSummaries.length;

    // Overall performance label
    final String performanceLabel;
    final Color performanceColor;
    if (state.weeklyAvgCompliance >= 0.8) {
      performanceLabel = 'Luar Biasa! 🎉';
      performanceColor = const Color(0xFF43A047);
    } else if (state.weeklyAvgCompliance >= 0.5) {
      performanceLabel = 'Cukup Baik 👍';
      performanceColor = const Color(0xFFFFA726);
    } else if (state.weekSummaries.isEmpty) {
      performanceLabel = 'Mulai Catat!';
      performanceColor = Colors.grey;
    } else {
      performanceLabel = 'Perlu Ditingkatkan';
      performanceColor = const Color(0xFFEF5350);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Performance headline card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1565C0),
                Color(0xFF1976D2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '7 Hari Terakhir',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      performanceLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Three metric cards in a row
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.emoji_events_rounded,
                iconColor: const Color(0xFF43A047),
                value: '${state.daysAbove80}/$total',
                label: 'Hari >=80%',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF1565C0),
                value: '${state.activeDays}/$total',
                label: 'Hari Aktif',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                icon: Icons.trending_up_rounded,
                iconColor: performanceColor,
                value: state.weekSummaries.isNotEmpty
                    ? '${_bestDayPct(state.weekSummaries)}%'
                    : '—',
                label: 'Terbaik',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Returns the best single-day compliance as a percentage string.
  static String _bestDayPct(List<DailySummary> summaries) {
    if (summaries.isEmpty) return '0';
    double best = 0;
    for (final s in summaries) {
      if (s.complianceRate > best) best = s.complianceRate;
    }
    return (best * 100).toStringAsFixed(0);
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A237E),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
