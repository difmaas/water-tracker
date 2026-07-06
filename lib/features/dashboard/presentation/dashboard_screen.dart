import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/hydration_provider.dart';
import '../../logging/data/hydration_log_model.dart';
import 'widgets/progress_ring.dart';
import 'widgets/quick_add_buttons.dart';
import 'widgets/hydration_log_tile.dart';
import 'widgets/target_achieved_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  int _selectedVolume = 250;
  double? _prevWaveY;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
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
    Color? lightweightBgColor,
    Color? lightweightBorderColor,
  }) {
    final card = Container(
      decoration: BoxDecoration(
        color: lightweightMode
            ? (lightweightBgColor ?? const Color(0xFFFFFFFF))
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
        border: Border.all(
          color: lightweightMode
              ? (lightweightBorderColor ?? const Color(0xFFE2E8F0))
              : Colors.white.withValues(alpha: 0.72),
          width: lightweightMode ? 1.0 : 1.2,
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

  Widget _buildTodaySummaryCard(HydrationState state, bool lightweightMode) {
    return _buildCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 24,
      lightweightBgColor: const Color(0xFFECFDF5),
      lightweightBorderColor: const Color(0xFFA7F3D0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kebutuhan Harian',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: lightweightMode
                    ? const Color(0xFF047857)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_formatVolume(state.targetMl)} ml',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: lightweightMode ? const Color(0xFF065F46) : Colors.black,
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
      borderRadius: 24,
      lightweightBgColor: const Color(0xFFFEFCE8),
      lightweightBorderColor: const Color(0xFFFEF08A),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pengingat Berikutnya',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: lightweightMode
                    ? const Color(0xFF854D0E)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reminderText,
              style: GoogleFonts.manrope(
                fontSize: reminderText.length > 12 ? 12 : 15,
                fontWeight: FontWeight.normal,
                color: lightweightMode ? const Color(0xFF713F12) : Colors.black,
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
    final sortedLogs = List<HydrationLog>.from(state.todayLogs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final latestLog = sortedLogs.isEmpty ? null : sortedLogs.first;

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
                'Catatan Terakhir',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ),
            Divider(height: 1, color: Colors.black.withValues(alpha: 0.05)),
            const SizedBox(height: 4),
            if (latestLog == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                child: Center(
                  child: Text(
                    'Kamu belum minum hari ini',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              )
            else ...[
              HydrationLogTile(
                log: latestLog,
                isFirst: true,
                isLast: true,
                showActions: false,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(
                  'Edit dan hapus catatan tersedia di halaman Riwayat.',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime12h(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final isAm = hour < 12;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = isAm ? 'AM' : 'PM';
    return '${displayHour.toString().padLeft(2, '0')}:$minute $period';
  }

  Future<void> _addWater(
    BuildContext context,
    int volumeMl,
    bool lightweightMode,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final oldState = ref.read(hydrationProvider);
    final wasReachedBefore = oldState.isTargetReached;

    final log = await ref.read(hydrationProvider.notifier).addLog(volumeMl);

    if (log == null) return;

    if (!context.mounted) return;

    final newState = ref.read(hydrationProvider);
    final isReachedAfter = newState.isTargetReached;

    if (!wasReachedBefore && isReachedAfter) {
      showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        barrierColor: Colors.black.withValues(alpha: 0.15),
        builder: (sheetContext) {
          return TargetAchievedSheet(
            state: newState,
            lightweightMode: lightweightMode,
          );
        },
      );
    } else {
      scaffoldMessenger.clearSnackBars();

      final snackBarController = scaffoldMessenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          padding: EdgeInsets.zero,
          margin: lightweightMode
              ? EdgeInsets.only(
                  left: (screenWidth - 240) / 2,
                  right: (screenWidth - 240) / 2,
                  bottom: 24.0,
                )
              : const EdgeInsets.fromLTRB(24, 0, 24, 24),
          content: lightweightMode
              ? Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF1A73E8),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${volumeMl}ml',
                            style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(hydrationProvider.notifier).undoLog(log.id);
                          scaffoldMessenger.hideCurrentSnackBar();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.manrope(
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.82),
                            Colors.white.withValues(alpha: 0.68),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.45),
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
                      child: _UndoSnackBarContent(
                        volumeMl: volumeMl,
                        scaffoldMessenger: scaffoldMessenger,
                        logId: log.id,
                      ),
                    ),
                  ),
                ),
        ),
      );

      Future.delayed(const Duration(seconds: 5), () {
        try {
          snackBarController.close();
        } catch (_) {}
      });
    }
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

    if (lightweightMode) {
      // Formatting next reminder text
      String reminderText;
      if (!state.reminderSystemActive ||
          !state.notificationPermissionGranted ||
          state.nextReminderTime == null) {
        reminderText = '--:--';
      } else {
        final now = DateTime.now();
        final isToday = state.nextReminderTime!.year == now.year &&
            state.nextReminderTime!.month == now.month &&
            state.nextReminderTime!.day == now.day;
        final formattedTime = _formatTime12h(state.nextReminderTime!);
        reminderText = isToday ? formattedTime : 'Besok, $formattedTime';
      }

      return PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true, // Let it flow under bottom nav
          extendBodyBehindAppBar: true,
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
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Yuk tetap terhidrasi',
                  style: GoogleFonts.manrope(
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
          body: LayoutBuilder(
            builder: (context, constraints) {
              final double screenHeight = constraints.maxHeight;
              final double progress = state.progressPercent;
              final double waveYPercent = 0.86 - (progress * 0.41);
              final double waveY = screenHeight * waveYPercent;

              return Stack(
                children: [
                  // 1. Wave and deep blue background at the bottom
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: _prevWaveY ?? waveY,
                        end: waveY,
                      ),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedWaveY, child) {
                        _prevWaveY = animatedWaveY;
                        return AnimatedBuilder(
                          animation: _waveController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: WaveBackgroundPainter(
                                waveYHeight: animatedWaveY,
                                animationValue: _waveController.value,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // 2. Foreground content layout
                  SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 100), // Spacing for AppBar

                        const Spacer(flex: 1),

                        // Large Total Drink Amount (Center)
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${state.currentMl}',
                                style: GoogleFonts.manrope(
                                  fontSize: 74,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -2.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () =>
                                    context.push('/profile-setup?edit=true'),
                                child: Text(
                                  '/ ${_formatVolume(state.targetMl)} ml',
                                  style: GoogleFonts.manrope(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 1),

                        // Next Reminder (Centered, Cardless)
                        Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Pengingat Berikutnya',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reminderText,
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(flex: 24),

                        // Quick volume slider inside the blue area
                        QuickVolumeCarousel(
                          volumes: const [250, 500, 750, 1000],
                          selectedVolume: _selectedVolume,
                          onVolumeChanged: (vol) {
                            setState(() {
                              _selectedVolume = vol;
                            });
                          },
                        ),

                        const SizedBox(height: 12),
                        // Centered White "+ Minum" Button (Pill, padded taller)
                        Center(
                          child: SizedBox(
                            width: 240,
                            child: Opacity(
                              opacity: state.isDrinkDisabled ? 0.5 : 1.0,
                              child: ElevatedButton(
                                onPressed: state.isDrinkDisabled
                                    ? null
                                    : () => _addWater(context, _selectedVolume, true),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F172A),
                                  disabledBackgroundColor: Colors.white,
                                  disabledForegroundColor: const Color(0xFF0F172A).withValues(alpha: 0.6),
                                  elevation: state.isDrinkDisabled ? 0 : 2,
                                  shadowColor: Colors.black.withValues(
                                    alpha: 0.08,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                    side: BorderSide(
                                      color: const Color(
                                        0xFF1A73E8,
                                      ).withValues(alpha: 0.12),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'MINUM',
                                      style: GoogleFonts.manrope(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Spacing at the bottom to stay clear of bottom nav + safe area
                        SizedBox(
                          height: 24.0 + MediaQuery.paddingOf(context).bottom,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: !lightweightMode,
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
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Yuk minum air hari ini',
                style: GoogleFonts.manrope(
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
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  ),
                  const SizedBox(height: 24),

                  // 2. Quick Add Water Section
                  QuickAddButtons(lightweightMode: lightweightMode),
                  const SizedBox(height: 24),

                  // 5. Today's Logs List (Riwayat Minum Hari Ini)
                  _buildHistoryCard(state, lightweightMode),
                  SizedBox(height: lightweightMode ? 16 : 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WaveBackgroundPainter extends CustomPainter {
  final double waveYHeight;
  final double animationValue;

  WaveBackgroundPainter({
    required this.waveYHeight,
    required this.animationValue,
  });

  Path _buildWavePath(
    Size size,
    double baseHeight,
    double amplitude,
    double frequency,
    double phase,
  ) {
    final path = Path();
    final double startY = baseHeight + amplitude * math.sin(phase);
    path.moveTo(0, startY);
    for (double x = 0; x <= size.width; x += 6) {
      final double y = baseHeight + amplitude * math.sin(x * frequency + phase);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 1. Draw top area background (soft periwinkle #EAF2FF)
    paint.color = const Color(0xFFEAF2FF);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    final double phase = animationValue * 2 * math.pi;

    // 2. Draw 3 moving wave layers at Y-coordinate
    // Layer 1 (Back wave): primary blue Color(0xFF1A73E8) at 0.15 opacity
    final path1 = _buildWavePath(
      size,
      waveYHeight - 15,
      12.0,
      2 * math.pi / size.width,
      phase,
    );
    paint.color = const Color(0xFF1A73E8).withValues(alpha: 0.15);
    canvas.drawPath(path1, paint);

    // Layer 2 (Middle wave): primary blue Color(0xFF1A73E8) at 0.30 opacity
    final path2 = _buildWavePath(
      size,
      waveYHeight + 2,
      15.0,
      2.5 * math.pi / size.width,
      -phase + 1.5,
    );
    paint.color = const Color(0xFF1A73E8).withValues(alpha: 0.30);
    canvas.drawPath(path2, paint);

    // Layer 3 (Front wave): solid gradient/color
    final path3 = _buildWavePath(
      size,
      waveYHeight + 18,
      10.0,
      1.8 * math.pi / size.width,
      phase * 2.0 + 3.0,
    );

    paint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1A73E8), Color(0xFF114EA3)],
    ).createShader(Rect.fromLTWH(0, waveYHeight - 10, size.width, size.height));
    canvas.drawPath(path3, paint);
    paint.shader = null;
  }

  @override
  bool shouldRepaint(covariant WaveBackgroundPainter oldDelegate) {
    return oldDelegate.waveYHeight != waveYHeight ||
        oldDelegate.animationValue != animationValue;
  }
}

class QuickVolumeCarousel extends StatefulWidget {
  final List<int> volumes;
  final int selectedVolume;
  final ValueChanged<int> onVolumeChanged;

  const QuickVolumeCarousel({
    super.key,
    required this.volumes,
    required this.selectedVolume,
    required this.onVolumeChanged,
  });

  @override
  State<QuickVolumeCarousel> createState() => _QuickVolumeCarouselState();
}

class _QuickVolumeCarouselState extends State<QuickVolumeCarousel> {
  late PageController _pageController;
  late double _currentPage;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.volumes.indexOf(widget.selectedVolume);
    _currentPage = initialIndex >= 0 ? initialIndex.toDouble() : 0.0;
    _pageController = PageController(
      initialPage: _currentPage.toInt(),
      viewportFraction: 0.36,
    );
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.volumes.length,
        onPageChanged: (index) {
          widget.onVolumeChanged(widget.volumes[index]);
        },
        itemBuilder: (context, index) {
          final volume = widget.volumes[index];
          final double difference = (index - _currentPage).abs();
          final double scale = (1.0 - (difference * 0.15)).clamp(0.8, 1.0);
          final double opacity = (1.0 - (difference * 0.4)).clamp(0.4, 1.0);

          final isSelected = index == _currentPage.round();

          return Center(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 130,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2.5 : 1.2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/${volume}ml.svg',
                          width: volume == 750 ? 72 : (volume == 1000 ? 56 : 60),
                          height: volume == 750 ? 72 : (volume == 1000 ? 56 : 60),
                          colorFilter: const ColorFilter.mode(
                            Color(0xFF1A73E8),
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$volume ml',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UndoSnackBarContent extends ConsumerWidget {
  final int volumeMl;
  final ScaffoldMessengerState scaffoldMessenger;
  final int logId;

  const _UndoSnackBarContent({
    required this.volumeMl,
    required this.scaffoldMessenger,
    required this.logId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF1A73E8),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Berhasil ditambah +${volumeMl}ml',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.normal,
              fontSize: 13,
              color: const Color(0xFF1F2937),
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            ref.read(hydrationProvider.notifier).undoLog(logId);
            scaffoldMessenger.hideCurrentSnackBar();
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Batal',
            style: GoogleFonts.manrope(
              color: const Color(0xFFEF4444),
              fontWeight: FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
