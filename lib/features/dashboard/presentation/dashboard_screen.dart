import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/hydration_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../logging/data/hydration_log_model.dart';
import 'widgets/progress_ring.dart';
import 'widgets/quick_add_buttons.dart';
import 'widgets/hydration_log_tile.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(hydrationProvider.notifier).refresh();
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  Widget _buildNextReminderSection(
    BuildContext context,
    WidgetRef ref,
    HydrationState state,
  ) {
    final now = DateTime.now();
    final startFormatted =
        '${state.reminderWindowStart.toString().padLeft(2, '0')}.00';
    final endFormatted =
        '${state.reminderWindowEnd.toString().padLeft(2, '0')}.00';

    // State 1: Permission not enabled
    if (!state.notificationPermissionGranted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E6), // Soft warning amber
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFE599), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.notifications_off_rounded,
                  color: Color(0xFFD48800),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifikasi belum aktif',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF873800),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Aktifkan pengingat minum',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF873800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(reminderServiceProvider).requestPermissions();
                  ref.read(hydrationProvider.notifier).refresh();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF9AB00), // Warning orange
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Aktifkan Pengingat',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // State 2: Target achieved
    if (state.isTargetReached) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEBF8EE), // Soft green background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA3E2B5), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF34A853),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target hari ini tercapai',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF236132),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tidak ada pengingat tambahan',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF236132),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // State 3: Outside active reminder window
    final isWithinWindow =
        now.hour >= state.reminderWindowStart &&
        now.hour < state.reminderWindowEnd;
    if (!isWithinWindow) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Soft grey background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.nights_stay_rounded,
              color: Color(0xFF64748B),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reminder aktif kembali besok $startFormatted',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // State 4: Within active reminder window (Active next reminder)
    String reminderText = 'Segera';
    if (state.nextReminderTime != null) {
      final nextHour = state.nextReminderTime!.hour.toString().padLeft(2, '0');
      final nextMin = state.nextReminderTime!.minute.toString().padLeft(2, '0');
      reminderText = '$nextHour.$nextMin';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F4FF), // Soft blue background #E8F4FF
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: Color(0xFF1A73E8),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder berikutnya',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reminderText,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A73E8), // Primary blue #1A73E8
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Aktif $startFormatted - $endFormatted',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaySummarySection(HydrationState state) {
    String lastDrinkTime = '-';
    if (state.todayLogs.isNotEmpty) {
      final sortedLogs = List<HydrationLog>.from(state.todayLogs)
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final lastLog = sortedLogs.last;
      final hour = lastLog.timestamp.hour.toString().padLeft(2, '0');
      final min = lastLog.timestamp.minute.toString().padLeft(2, '0');
      lastDrinkTime = '$hour.$min';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F4FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hari Ini',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.local_drink_rounded,
                color: Color(0xFF1A73E8),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                '${state.todayLogs.length}x minum tercatat',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.access_time_filled_rounded,
                color: Color(0xFF6B7280),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Terakhir: $lastDrinkTime',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarProgressSection(HydrationState state) {
    const daysName = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F4FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progres Mingguan',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final progress = state.weeklyProgress.length > index
                  ? state.weeklyProgress[index]
                  : null;
              final dayName = daysName[index];

              Color cellColor = const Color(0xFFF1F5F9);
              Color borderCol = Colors.transparent;
              Widget statusWidget = const SizedBox(height: 16);

              if (progress != null) {
                switch (progress.status) {
                  case WeekDayStatus.achieved:
                    cellColor = const Color(0xFFEBF8EE);
                    borderCol = const Color(0xFFA3E2B5);
                    statusWidget = const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Color(0xFF34A853),
                    );
                    break;
                  case WeekDayStatus.partial:
                    cellColor = const Color(0xFFFFF9E6);
                    borderCol = const Color(0xFFFFE599);
                    statusWidget = const Icon(
                      Icons.fiber_manual_record_rounded,
                      size: 10,
                      color: Color(0xFFF9AB00),
                    );
                    break;
                  case WeekDayStatus.empty:
                    cellColor = const Color(0xFFF3F4F6);
                    borderCol = const Color(0xFFE5E7EB);
                    statusWidget = const Icon(
                      Icons.radio_button_unchecked_rounded,
                      size: 10,
                      color: Color(0xFFD1D5DB),
                    );
                    break;
                  case WeekDayStatus.future:
                    cellColor = Colors.white;
                    borderCol = const Color(0xFFF3F4F6);
                    statusWidget = const Text(
                      '○',
                      style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                    );
                    break;
                }

                if (progress.isToday) {
                  borderCol = const Color(0xFF1A73E8);
                }
              }

              return Column(
                children: [
                  Text(
                    dayName,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: progress?.isToday == true
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: progress?.isToday == true
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cellColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderCol, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: statusWidget,
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 14),
          // Small legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: const Color(0xFF34A853),
                label: 'Tercapai',
                icon: Icons.check_rounded,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                color: const Color(0xFFF9AB00),
                label: 'Sebagian',
                icon: Icons.fiber_manual_record_rounded,
                iconSize: 8,
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                color: const Color(0xFFD1D5DB),
                label: 'Belum ada',
                icon: Icons.radio_button_unchecked_rounded,
                iconSize: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
    double iconSize = 12,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydrationProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FBFF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
        ),
      );
    }

    final capitalizeName = state.userName.isNotEmpty
        ? _capitalize(state.userName)
        : 'Siswa';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FBFF), // Light background #F8FBFF
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(0xFFF8FBFF),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 24,
          toolbarHeight: 100,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Halo, $capitalizeName! 👋',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Yuk minum air hari ini',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false, // AppBar is already safe
          child: RefreshIndicator(
            color: const Color(0xFF1A73E8),
            onRefresh: () => ref.read(hydrationProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Main Daily Progress Section
                  const ProgressRing(),
                  const SizedBox(height: 24),

                  // 2. Quick Add Water Section
                  const QuickAddButtons(),
                  const SizedBox(height: 24),

                  // 3. Next Reminder Section (Below Quick Add Buttons)
                  _buildNextReminderSection(context, ref, state),
                  const SizedBox(height: 24),

                  // 4. Calendar Progress Card
                  _buildCalendarProgressSection(state),
                  const SizedBox(height: 24),

                  // 5. Today Summary Section
                  _buildTodaySummarySection(state),
                  const SizedBox(height: 24),

                  // 5. Today's Logs List (Catatan Hari Ini)
                  if (state.todayLogs.isNotEmpty) ...[
                    Text(
                      'Catatan Hari Ini',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(() {
                      final sortedLogs = List<HydrationLog>.from(
                        state.todayLogs,
                      )..sort((a, b) => b.timestamp.compareTo(a.timestamp));
                      return sortedLogs.map(
                        (log) => HydrationLogTile(log: log),
                      );
                    })(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
