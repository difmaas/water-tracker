import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../logging/data/daily_summary_model.dart';
import '../../logging/data/hydration_log_model.dart';
import '../../logging/data/logging_repository.dart';
import '../progress_provider.dart';
import 'widgets/weekly_bar_chart.dart';
import 'widgets/compliance_summary.dart';

/// F-14 — Progress Screen.
///
/// Shows last 7 days of hydration compliance via:
/// - Weekly bar chart (achievedMl vs targetMl)
/// - 80% reference line
/// - Summary cards: avg compliance, days >=80%, active days, best day
/// - Expandable daily details with intake logs (merged from F-11 History)
///
/// Data source: Isar DailySummary only — never Supabase.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(progressProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: const Text(
          'Progres & Riwayat',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: -1.0,
          ),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFF5F8FF),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF1A1A2E)),
            tooltip: 'Muat ulang',
            onPressed: () => ref.read(progressProvider.notifier).refresh(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1565C0)),
            )
          : state.error != null
              ? _ErrorState(
                  onRetry: () =>
                      ref.read(progressProvider.notifier).refresh(),
                )
              : RefreshIndicator(
                  color: const Color(0xFF1565C0),
                  onRefresh: () =>
                      ref.read(progressProvider.notifier).refresh(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      // Summary cards
                      ComplianceSummary(state: state),
                      const SizedBox(height: 32),

                      // Chart section header
                      Row(
                        children: [
                          const Text(
                            'Grafik Konsumsi Harian',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Separated Chart Legends (Pastel & Beautiful Mapped to M. Calendar Mappings)
                      Row(
                        children: [
                          const _LegendDot(color: Color(0xFFF06292), label: '>=100%'),
                          const SizedBox(width: 12),
                          const _LegendDot(color: Color(0xFF81C784), label: '80-99%'),
                          const SizedBox(width: 12),
                          const _LegendDot(color: Color(0xFF64B5F6), label: '40-79%'),
                          const SizedBox(width: 12),
                          const _LegendDot(color: Color(0xFFECEFF1), label: '<40%'),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Reference line hint
                      Row(
                        children: [
                          Container(
                            width: 20,
                            height: 2,
                            decoration: BoxDecoration(
                              color: const Color(0xFF81C784), // Match Tinggi Green
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Garis target 80%',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Weekly Bar Chart (No background card wrap)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: WeeklyBarChart(state: state),
                      ),
                      const SizedBox(height: 48),

                      // Monthly Calendar Title
                      const Text(
                        'Grafik Konsumsi selama Sebulan Terakhir',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Calendar Grid (No background card wrap)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _MonthlyCalendarGrid(state: state),
                      ),
                      const SizedBox(height: 12),

                      // Daily detail list (newest-first)
                      if (state.weekSummaries.isNotEmpty) ...[
                        const Text(
                          'Detail & Riwayat Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...state.weekSummaries.reversed.map(
                          (s) => _DayDetailTile(summary: s),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

// ── Legend dot ────────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: color == const Color(0xFFECEFF1)
                ? Border.all(color: Colors.grey.shade300, width: 0.8)
                : null,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

// ── Day detail tile ───────────────────────────────────────────────────────────

class _DayDetailTile extends ConsumerStatefulWidget {
  final DailySummary summary;

  const _DayDetailTile({required this.summary});

  @override
  ConsumerState<_DayDetailTile> createState() => _DayDetailTileState();
}

class _DayDetailTileState extends ConsumerState<_DayDetailTile> {
  List<HydrationLog>? _logs;
  bool _isLoadingLogs = false;

  Future<void> _fetchLogs() async {
    if (_logs != null || _isLoadingLogs) return;

    setState(() {
      _isLoadingLogs = true;
    });

    try {
      final repo = ref.read(loggingRepositoryProvider);
      final logs = await repo.getLogsForDate(widget.summary.userId, widget.summary.date);
      
      // Sort logs by timestamp descending
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (mounted) {
        setState(() {
          _logs = logs;
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLogs = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final compliance = summary.complianceRate;
    final pct = (compliance * 100).toStringAsFixed(0);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final d = summary.date;
    final dayLabel = '${d.day} ${months[d.month - 1]}';
    
    final isToday = d.day == DateTime.now().day && 
                    d.month == DateTime.now().month && 
                    d.year == DateTime.now().year;

    final Color barColor;
    if (compliance >= 0.8) {
      barColor = const Color(0xFF43A047);
    } else if (compliance >= 0.4) {
      barColor = const Color(0xFFFFA726);
    } else {
      barColor = const Color(0xFFEF5350);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            if (expanded) {
              _fetchLogs();
            }
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Row(
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(width: 8),
              if (isToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'HARI INI',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ),
              if (summary.dropoutFlag)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'DROPOUT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC62828),
                    ),
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: barColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pct%',
                  style: TextStyle(
                    color: barColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: compliance.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade100,
                  color: barColor,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${summary.achievedMl} ml / ${summary.targetMl} ml',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1, indent: 16, endIndent: 16),
            if (_isLoadingLogs)
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF1565C0),
                  ),
                ),
              )
            else if (_logs == null || _logs!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Tidak ada log untuk hari ini',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: _logs!.map((log) {
                    final time = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';
                    final isAuto = log.loggedVia == 'notification_action';
                    
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      leading: Icon(
                        isAuto ? Icons.notifications_active_outlined : Icons.water_drop_outlined,
                        size: 18,
                        color: isAuto ? const Color(0xFFFFA000) : const Color(0xFF1976D2),
                      ),
                      title: Text(
                        '${log.volume} ml',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        isAuto ? 'Via Notifikasi' : 'Input Manual',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      ),
                      trailing: Text(
                        time,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data progres.',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa penyimpanan dan coba lagi.',
              style: TextStyle(
                  color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Monthly Calendar Grid Widget ──────────────────────────────────────────────

class _MonthlyCalendarGrid extends StatefulWidget {
  final ProgressState state;
  const _MonthlyCalendarGrid({required this.state});

  @override
  State<_MonthlyCalendarGrid> createState() => _MonthlyCalendarGridState();
}

class _MonthlyCalendarGridState extends State<_MonthlyCalendarGrid> {
  late DateTime _viewDate;

  @override
  void initState() {
    super.initState();
    _viewDate = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    // Do not allow navigating past the current month
    if (_viewDate.year == now.year && _viewDate.month == now.month) return;

    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth = _viewDate.year == now.year && _viewDate.month == now.month;

    // Start of the viewed month
    final firstDayOfMonth = DateTime(_viewDate.year, _viewDate.month, 1);
    // Number of days in the viewed month
    final lastDayOfMonth = DateTime(_viewDate.year, _viewDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    // Weekday of the first day: 1 = Mon, 7 = Sun
    final firstWeekday = firstDayOfMonth.weekday;
    // Number of empty slots at the start
    final leadingEmptyDays = firstWeekday - 1;

    // Indonesian day name abbreviations
    const weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    // Map monthSummaries by date for easy lookup (key: day number)
    final summaryMap = <int, DailySummary>{};
    for (final s in widget.state.monthSummaries) {
      if (s.date.year == _viewDate.year && s.date.month == _viewDate.month) {
        summaryMap[s.date.day] = s;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month & Year header with premium styling
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF1565C0)),
                  onPressed: _previousMonth,
                ),
                Text(
                  '${_getMonthName(_viewDate.month)} ${_viewDate.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1565C0),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    color: isCurrentMonth ? Colors.grey.shade400 : const Color(0xFF1565C0),
                  ),
                  onPressed: isCurrentMonth ? null : _nextMonth,
                ),
              ],
            ),
            // Badge indicating status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCurrentMonth ? const Color(0xFFE3F2FD) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCurrentMonth ? const Color(0xFFBBDEFB) : const Color(0xFFE0E0E0),
                ),
              ),
              child: Text(
                isCurrentMonth ? 'Bulan ini' : 'Arsip',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCurrentMonth ? const Color(0xFF1565C0) : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Weekday Headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),

        // Grid of Days
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leadingEmptyDays + daysInMonth,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0, // perfect circle
          ),
          itemBuilder: (context, index) {
            if (index < leadingEmptyDays) {
              return const SizedBox.shrink(); // Empty slot
            }

            final day = index - leadingEmptyDays + 1;
            final isFuture = isCurrentMonth && day > now.day;
            final summary = summaryMap[day];

            Color cellColor = const Color(0xFFECEFF1); // Default Low/No-log color (Grey)
            Color textColor = Colors.grey.shade700;
            FontWeight fontWeight = FontWeight.w500;

            if (summary != null && !isFuture) {
              final compliance = summary.complianceRate;
              if (compliance >= 1.0) {
                cellColor = const Color(0xFFF06292); // Very High (Pink)
                textColor = Colors.white;
                fontWeight = FontWeight.bold;
              } else if (compliance >= 0.8) {
                cellColor = const Color(0xFF81C784); // High (Green)
                textColor = Colors.white;
                fontWeight = FontWeight.bold;
              } else if (compliance >= 0.4) {
                cellColor = const Color(0xFF64B5F6); // Moderate (Blue)
                textColor = Colors.white;
                fontWeight = FontWeight.bold;
              } else {
                cellColor = const Color(0xFFECEFF1); // Low (Grey)
                textColor = Colors.grey.shade700;
              }
            } else if (isFuture) {
              // Future day styling: transparent with very light border
              cellColor = Colors.transparent;
              textColor = Colors.grey.shade400;
            }

            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cellColor,
                shape: BoxShape.circle,
                border: isFuture
                    ? Border.all(color: Colors.grey.shade200, width: 1.5)
                    : null,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor,
                  fontWeight: fontWeight,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }
}
