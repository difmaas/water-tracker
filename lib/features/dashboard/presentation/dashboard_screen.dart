import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/hydration_provider.dart';
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

  String _formatVolume(int volume) {
    final value = volume.toString();
    if (value.length > 3) {
      return '${value.substring(0, value.length - 3)}.${value.substring(value.length - 3)}';
    }
    return value;
  }

  Widget _buildCardShell({
    required bool lightweightMode,
    required double borderRadius,
    required Widget child,
  }) {
    final card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: lightweightMode
              ? [Colors.white.withValues(alpha: 0.88), const Color(0xFFF4FAFF)]
              : [
                  Colors.white.withValues(alpha: 0.50),
                  Colors.white.withValues(alpha: 0.20),
                ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: lightweightMode
              ? const Color(0xFFD7E8F7)
              : Colors.white.withValues(alpha: 0.6),
          width: 1.2,
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

  Widget _buildTodaySummaryCard(HydrationState state, bool lightweightMode) {
    return _buildCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kebutuhan Harian',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_formatVolume(state.targetMl)} ml',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextReminderCard(HydrationState state, bool lightweightMode) {
    String reminderText;
    if (!state.reminderSystemActive) {
      reminderText = 'Notifikasi dimatikan';
    } else if (!state.notificationPermissionGranted) {
      reminderText = 'Izin notifikasi belum aktif';
    } else if (state.nextReminderTime == null) {
      reminderText = 'Belum ada jadwal pengingat';
    } else {
      final nextHour = state.nextReminderTime!.hour.toString().padLeft(2, '0');
      final nextMin = state.nextReminderTime!.minute.toString().padLeft(2, '0');
      final now = DateTime.now();
      final isToday =
          state.nextReminderTime!.year == now.year &&
          state.nextReminderTime!.month == now.month &&
          state.nextReminderTime!.day == now.day;
      reminderText = isToday
          ? '$nextHour.$nextMin'
          : 'Besok, $nextHour.$nextMin';
    }

    return _buildCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pengingat Berikutnya',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              reminderText,
              style: GoogleFonts.inter(
                fontSize: reminderText.length > 12 ? 12 : 15,
                fontWeight: FontWeight.normal,
                color: Colors.black,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(HydrationState state, bool lightweightMode) {
    return _buildCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 24,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 4, bottom: 8),
              child: Text(
                'Riwayat Minum Hari Ini',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ),
            Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
            const SizedBox(height: 4),
            if (state.todayLogs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Center(
                  child: Text(
                    'Kamu belum minum hari ini',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else
              ...(() {
                final sortedLogs = List<HydrationLog>.from(state.todayLogs)
                  ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                final List<Widget> children = [];
                for (int i = 0; i < sortedLogs.length; i++) {
                  children.add(
                    HydrationLogTile(
                      log: sortedLogs[i],
                      isFirst: i == 0,
                      isLast: i == sortedLogs.length - 1,
                    ),
                  );
                  if (i < sortedLogs.length - 1) {
                    children.add(const SizedBox(height: 8));
                  }
                }
                return children;
              })(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydrationProvider);
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
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
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor:
              Colors.transparent, // Transparent to show background painter
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
                'Halo, $capitalizeName! 👋',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Yuk minum air hari ini',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: GestureDetector(
                onTap: () => context.push('/profile-setup?edit=true'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.15),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Transform.scale(
                            scale: 1.2,
                            child: Image.asset(
                              state.jenisKelamin == 'laki_laki'
                                  ? 'assets/images/man.webp'
                                  : 'assets/images/woman.webp',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: RefreshIndicator(
            color: const Color(0xFF1A73E8),
            onRefresh: () => ref.read(hydrationProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Main Daily Progress Section
                  ProgressRing(lightweightMode: lightweightMode),
                  const SizedBox(height: 24),

                  // Side-by-side Grid Metrics Section
                  Row(
                    children: [
                      Expanded(
                        child: _buildNextReminderCard(state, lightweightMode),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTodaySummaryCard(state, lightweightMode),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Quick Add Water Section
                  QuickAddButtons(lightweightMode: lightweightMode),
                  const SizedBox(height: 24),

                  // 5. Today's Logs List (Riwayat Minum Hari Ini)
                  _buildHistoryCard(state, lightweightMode),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
