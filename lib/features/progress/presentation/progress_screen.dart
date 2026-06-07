import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../logging/data/daily_summary_model.dart';
import '../../logging/data/hydration_log_model.dart';
import '../../logging/data/logging_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/user_profile_model.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  bool _isLoading = true;
  String? _error;
  UserProfile? _profile;
  List<DailySummary> _summaries = [];

  // Theme styling colors matching Splash/Onboarding/Settings
  static const Color kPrimary = Color(0xFF1A73E8);
  static const Color kBackground = Color(0xFFF8FBFF);
  static const Color kAccent = Color(0xFFE8F4FF);
  static const Color kTextDark = Color(0xFF1F2937);
  static const Color kTextSecondary = Color(0xFF6B7280);
  static const Color kSuccess = Color(0xFF34A853);
  static const Color kWarning = Color(0xFFF9AB00);

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .getUserProfile();
      if (profile != null) {
        // Fetch all summaries (limit: 0 returns all historical logs from Isar)
        final summaries = await ref
            .read(loggingRepositoryProvider)
            .getHistorySummaries(profile.userId, limit: 0);
        setState(() {
          _profile = profile;
          _summaries = summaries;
          _isLoading = false;
        });
      } else {
        setState(() {
          _profile = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
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

  void _showDayDetail(DateTime date, int dayNum, int achievedMl, int targetMl) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _DayDetailBottomSheet(
          userId: _profile!.userId,
          date: date,
          dayNum: dayNum,
          achievedMl: achievedMl,
          targetMl: targetMl,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: kBackground,
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
                '$_error',
                style: GoogleFonts.inter(fontSize: 12, color: kTextSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHistoryData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = _profile;
    if (profile == null) {
      return Scaffold(backgroundColor: kBackground, body: _buildEmptyState());
    }

    // Day 1 calculation
    final startDateTime = profile.createdAt;
    final startDate = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final elapsedDays = todayDate.difference(startDate).inDays + 1;

    // Map summaries by date for O(1) lookup
    final Map<DateTime, DailySummary> summaryMap = {};
    for (final s in _summaries) {
      final sDate = DateTime(s.date.year, s.date.month, s.date.day);
      summaryMap[sDate] = s;
    }

    // Compute metrics
    int totalIntake = 0;
    int completedCount = 0;
    int bestMl = 0;
    final int activeElapsedDays = elapsedDays > 0 ? elapsedDays : 1;

    for (int i = 1; i <= activeElapsedDays; i++) {
      final dayDate = startDate.add(Duration(days: i - 1));
      final summary = summaryMap[dayDate];
      if (summary != null) {
        totalIntake += summary.achievedMl;
        if (summary.achievedMl >= summary.targetMl) {
          completedCount++;
        }
        if (summary.achievedMl > bestMl) {
          bestMl = summary.achievedMl;
        }
      }
    }

    final avgIntake = activeElapsedDays > 0
        ? (totalIntake / activeElapsedDays).round()
        : 0;
    final compliancePct = activeElapsedDays > 0
        ? ((completedCount / activeElapsedDays) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kBackground,
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
              'Riwayat Minum',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lihat kebiasaan minummu dari hari ke hari',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: kPrimary,
        onRefresh: _loadHistoryData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // A. Top Summary Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildSummaryCard(
                  'Total Minum',
                  '$totalIntake ml',
                  Icons.local_drink_rounded,
                ),
                _buildSummaryCard(
                  'Rata-rata Harian',
                  '$avgIntake ml/hari',
                  Icons.show_chart_rounded,
                ),
                _buildSummaryCard(
                  'Target Tercapai',
                  '$completedCount hari',
                  Icons.star_rounded,
                ),
                _buildSummaryCard(
                  'Konsistensi',
                  '$compliancePct%',
                  Icons.check_circle_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildBestDayCard(bestMl),
            const SizedBox(height: 24),

            // C. Daily History List
            Text(
              'Riwayat Harian',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 12),
            if (activeElapsedDays == 0)
              _buildEmptyState()
            else
              ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeElapsedDays,
                itemBuilder: (context, index) {
                  // Sorted newest to oldest
                  final dayNum = activeElapsedDays - index;
                  final dayDate = startDate.add(Duration(days: dayNum - 1));
                  final summary = summaryMap[dayDate];

                  final achieved = summary?.achievedMl ?? 0;
                  final target = summary?.targetMl ?? profile.dailyTargetMl;
                  final isAchieved = achieved >= target;

                  return GestureDetector(
                    onTap: () =>
                        _showDayDetail(dayDate, dayNum, achieved, target),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: kAccent, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getFormattedDate(dayDate),
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: kTextDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      '$achieved / $target ml',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: kTextSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAchieved
                                            ? kSuccess.withValues(alpha: 0.12)
                                            : kWarning.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isAchieved
                                            ? 'Target tercapai'
                                            : 'Belum tercapai',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isAchieved
                                              ? kSuccess
                                              : kWarning,
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
                              color: kAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBestDayCard(int bestMl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAccent, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: kAccent,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: kWarning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hari Terbaik',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: kTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$bestMl ml',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAccent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: kPrimary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: kTextDark,
            ),
          ),
        ],
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
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: kAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop_outlined,
                color: kPrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Belum ada riwayat minum',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Catat minum pertamamu hari ini untuk mulai melihat progres.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: kTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDetailBottomSheet extends ConsumerWidget {
  final String userId;
  final DateTime date;
  final int dayNum;
  final int achievedMl;
  final int targetMl;

  const _DayDetailBottomSheet({
    required this.userId,
    required this.date,
    required this.dayNum,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Detail Harian',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ProgressScreenState.kTextDark,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  color: _ProgressScreenState.kTextSecondary,
                ),
              ),
            ],
          ),
          Text(
            _getFormattedDate(date),
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _ProgressScreenState.kTextSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Overview Stats
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _ProgressScreenState.kAccent,
              borderRadius: BorderRadius.circular(20),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _ProgressScreenState.kPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total minum: $achievedMl ml',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _ProgressScreenState.kPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$displayPct%',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: _ProgressScreenState.kPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Logs Title
          Text(
            'Log Minum',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _ProgressScreenState.kTextDark,
            ),
          ),
          const SizedBox(height: 10),

          // FutureBuilder for Logs
          Flexible(
            child: FutureBuilder<List<HydrationLog>>(
              future: ref
                  .read(loggingRepositoryProvider)
                  .getLogsForDate(userId, date),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _ProgressScreenState.kPrimary,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Gagal memuat log minum',
                      style: GoogleFonts.inter(color: Colors.red, fontSize: 13),
                    ),
                  );
                }

                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'Belum ada catatan minum untuk hari ini.',
                        style: GoogleFonts.inter(
                          color: _ProgressScreenState.kTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (context, idx) {
                    final log = logs[idx];
                    final timeStr =
                        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';
                    final isAuto = log.loggedVia == 'notification_action';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAuto
                                ? Icons.notifications_active_rounded
                                : Icons.water_drop_rounded,
                            color: _ProgressScreenState.kPrimary,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${log.volume} ml',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: _ProgressScreenState.kTextDark,
                                  ),
                                ),
                                Text(
                                  isAuto ? 'Tombol Notifikasi' : 'Input Manual',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: _ProgressScreenState.kTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeStr,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _ProgressScreenState.kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
