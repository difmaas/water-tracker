import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/presentation/main_scaffold.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../providers/hydration_provider.dart';
import '../../export/data/export_service.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/user_profile_model.dart';
import '../../../core/widgets/app_button.dart';

const bool kInternalQaBuild = bool.fromEnvironment('INTERNAL_QA');

bool get _qaToolsEnabled => kDebugMode || kInternalQaBuild;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Styles matching Splash/Onboarding/Profile Setup
  static const Color kPrimary = Color(0xFF1A73E8);
  static const Color kTextDark = Color(0xFF1F2937);
  static const Color kTextSecondary = Color(0xFF6B7280);

  bool _isExporting = false;
  bool _qaModeEnabled = false;
  int _qaTapCount = 0;
  String? _pendingNotificationReport;
  bool? _exactAlarmAllowed;

  UserProfile? _profile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await ref.read(profileRepositoryProvider).getUserProfile();
    final exactAlarmAllowed = await ref
        .read(reminderServiceProvider)
        .canScheduleExactAlarms();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _exactAlarmAllowed = exactAlarmAllowed;
      _isLoadingProfile = false;
    });
  }

  Future<bool> _checkAndNotifyPermission() async {
    final messenger = ScaffoldMessenger.of(context);
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      final message = status.isPermanentlyDenied
          ? 'Izin notifikasi diblokir permanen. Buka pengaturan aplikasi dan aktifkan notifikasi SEHATI.'
          : 'Notifikasi belum aktif. Aktifkan izin notifikasi agar pengingat bisa muncul.';

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              message,
              style: GoogleFonts.manrope(fontWeight: FontWeight.normal),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _exportDailySummaryCsv() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    try {
      final result = await ref
          .read(csvExportServiceProvider)
          .exportDailySummary();
      final shareResult = await Share.shareXFiles(
        [XFile(result.filePath, mimeType: 'text/csv', name: result.fileName)],
        text: 'Riwayat Ringkasan Harian SEHATI',
        subject: result.fileName,
      );

      if (!mounted) return;

      final shared = shareResult.status == ShareResultStatus.success;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shared
                ? 'File CSV Ringkasan Harian berhasil dibagikan.'
                : 'File CSV Ringkasan Harian dibuat. Berbagi dibatalkan.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.normal),
          ),
          backgroundColor: shared ? kPrimary : kTextSecondary,
        ),
      );
    } on CsvExportEmptyException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada data ringkasan harian untuk diekspor.')),
      );
    } catch (e, st) {
      debugPrint('[SettingsScreen] CSV summary export failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengekspor data ringkasan harian. Coba lagi nanti.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportDrinkLogsCsv() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    try {
      final result = await ref
          .read(csvExportServiceProvider)
          .exportDrinkLogs();
      final shareResult = await Share.shareXFiles(
        [XFile(result.filePath, mimeType: 'text/csv', name: result.fileName)],
        text: 'Riwayat Log Minum SEHATI',
        subject: result.fileName,
      );

      if (!mounted) return;

      final shared = shareResult.status == ShareResultStatus.success;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shared
                ? 'File CSV Log Minum berhasil dibagikan.'
                : 'File CSV Log Minum dibuat. Berbagi dibatalkan.',
            style: GoogleFonts.manrope(fontWeight: FontWeight.normal),
          ),
          backgroundColor: shared ? kPrimary : kTextSecondary,
        ),
      );
    } on CsvExportEmptyException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada data minum untuk diekspor.')),
      );
    } catch (e, st) {
      debugPrint('[SettingsScreen] CSV drink logs export failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengekspor log minum. Coba lagi nanti.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _handleSettingsTitleTap() {
    if (!_qaToolsEnabled) return;
    if (_qaModeEnabled) return;

    _qaTapCount += 1;
    if (_qaTapCount < 7) return;

    setState(() {
      _qaModeEnabled = true;
      _qaTapCount = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mode Pengujian aktif.',
          style: GoogleFonts.manrope(fontWeight: FontWeight.normal),
        ),
        backgroundColor: kPrimary,
      ),
    );
  }

  Future<String?> _loadPendingNotificationReport() async {
    if (!_qaToolsEnabled) return null;
    if (!await _checkAndNotifyPermission()) return null;

    final report = await ref
        .read(reminderServiceProvider)
        .debugDescribePendingNotifications();
    debugPrint(report);

    if (mounted) {
      setState(() {
        _pendingNotificationReport = report;
      });
    }

    return report;
  }

  Future<void> _showPendingNotificationReport() async {
    if (!_qaToolsEnabled) return;
    final report = await _loadPendingNotificationReport();
    if (report == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pending Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(child: SelectableText(report)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showResetConfirmation() {
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: lightweightMode
            ? Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFD7E5FF),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFD7E5FF),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Expanded(
                          child: Text(
                            'Hapus Data?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              width: 1.2,
                            ),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.close_rounded,
                              size: 20,
                              color: Color(0xFF0F172A),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Semua data profil, riwayat minum, dan pengaturan akan dihapus dari perangkat ini. Tindakan ini tidak dapat dibatalkan.',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        color: const Color(0xFF0F172A),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final router = GoRouter.of(context);
                          final navigator = Navigator.of(context);

                          // 1. Clear persistent local database (Isar)
                          await ref
                              .read(profileRepositoryProvider)
                              .clearAllData();

                          // 2. Cancel all scheduled reminder notifications
                          await ref.read(reminderServiceProvider).cancelAll();

                          // 3. Clear SharedPreferences keys for onboarding/profile status
                          final prefs = ref.read(sharedPreferencesProvider);
                          await prefs.remove('isOnboarded');
                          await prefs.remove('hasProfile');
                          await ref.read(appSettingsProvider.notifier).reset();

                          // 4. Invalidate all cache states in Riverpod to trigger reconstruction
                          ref.invalidate(onboardingProvider);
                          ref.invalidate(profileStatusProvider);
                          ref.invalidate(appSettingsProvider);
                          ref.invalidate(profileProvider);
                          ref.invalidate(hydrationProvider);

                          navigator.pop();
                          router.go('/');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFEF4444),
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                            side: BorderSide(
                              color: const Color(
                                0xFF1A73E8,
                              ).withValues(alpha: 0.12),
                              width: 1.0,
                            ),
                          ),
                          textStyle: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        child: const Text('RESET'),
                      ),
                    ),
                  ],
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.96),
                          Colors.white.withValues(alpha: 0.88),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reset Data?',
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Semua data profil, riwayat minum, dan pengaturan akan dihapus dari perangkat ini. Tindakan ini tidak dapat dibatalkan.',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: kTextSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton.secondary(
                                label: 'Batal',
                                isTransparent: true,
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppButton.main(
                                label: 'Reset',
                                color: const Color(0xFFEF4444),
                                onPressed: () async {
                                  final router = GoRouter.of(context);
                                  final navigator = Navigator.of(context);

                                  // 1. Clear persistent local database (Isar)
                                  await ref
                                      .read(profileRepositoryProvider)
                                      .clearAllData();

                                  // 2. Cancel all scheduled reminder notifications
                                  await ref
                                      .read(reminderServiceProvider)
                                      .cancelAll();

                                  // 3. Clear SharedPreferences keys for onboarding/profile status
                                  final prefs = ref.read(
                                    sharedPreferencesProvider,
                                  );
                                  await prefs.remove('isOnboarded');
                                  await prefs.remove('hasProfile');
                                  await ref
                                      .read(appSettingsProvider.notifier)
                                      .reset();

                                  // 4. Invalidate all cache states in Riverpod to trigger reconstruction
                                  ref.invalidate(onboardingProvider);
                                  ref.invalidate(profileStatusProvider);
                                  ref.invalidate(appSettingsProvider);
                                  ref.invalidate(profileProvider);
                                  ref.invalidate(hydrationProvider);

                                  navigator.pop();
                                  router.go('/');
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    if (_isLoadingProfile) {
      return Stack(
        children: [
          Positioned.fill(
            child: HydrationBackground(lightweightMode: lightweightMode),
          ),
          const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator(color: kPrimary)),
          ),
        ],
      );
    }

    if (_profile == null) {
      return Stack(
        children: [
          Positioned.fill(
            child: HydrationBackground(lightweightMode: lightweightMode),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildSettingsAppBar(lightweightMode),
            body: const Center(
              child: Text(
                'Profil tidak ditemukan. Selesaikan setup profil dahulu.',
              ),
            ),
          ),
        ],
      );
    }

    if (lightweightMode) {
      return Stack(
        children: [
          const Positioned.fill(
            child: HydrationBackground(lightweightMode: true),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildSettingsAppBar(true),
            body: _buildLightSettingsView(),
          ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: HydrationBackground(lightweightMode: lightweightMode),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, -0.95),
                  radius: 0.9,
                  colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildSettingsAppBar(lightweightMode),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Unified Profile Card (Banner + Summary)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildSettingsCardShell(
                    lightweightMode: lightweightMode,
                    borderRadius: 24,
                    isProfileCard: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Banner Image
                        Container(
                          height: 160,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F4FF),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(22.5),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(22.5),
                            ),
                            child: Image.asset(
                              _profile!.jenisKelamin == 'laki_laki'
                                  ? 'assets/images/man_settings.webp'
                                  : 'assets/images/woman_settings.webp',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                        // Bottom Profile Details
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name and gender chip row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _capitalize(_profile!.nama),
                                          style: GoogleFonts.manrope(
                                            fontSize: 22,
                                            fontWeight: FontWeight.normal,
                                            color: kTextDark,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Aktivitas: ${_profile!.levelAktivitas == 'aktif' ? 'Tinggi' : (_profile!.levelAktivitas == 'sedang' ? 'Sedang' : 'Ringan')}',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: kTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID Penelitian: ${_profile!.participantId}',
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: kTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'ID ini digunakan untuk export data penelitian agar data tetap konsisten.',
                                          style: GoogleFonts.manrope(
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F4FF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _profile!.jenisKelamin == 'laki_laki'
                                              ? Icons.male_rounded
                                              : Icons.female_rounded,
                                          size: 13,
                                          color: const Color(0xFF1A73E8),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _profile!.jenisKelamin == 'laki_laki'
                                              ? 'Laki-laki'
                                              : 'Perempuan',
                                          style: GoogleFonts.manrope(
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal,
                                            color: const Color(0xFF1A73E8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Hydration Target Card
                              _buildSettingsInnerCardShell(
                                lightweightMode: lightweightMode,
                                borderRadius: 20,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'TARGET HIDRASI HARIAN',
                                            style: GoogleFonts.manrope(
                                              fontSize: 10,
                                              fontWeight: FontWeight.normal,
                                              color: const Color(0xFF64748B),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_profile!.dailyTargetMl} ml / hari',
                                            style: GoogleFonts.manrope(
                                              fontSize: 18,
                                              fontWeight: FontWeight.normal,
                                              color: const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Physical Stats Grid
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatGridCard(
                                      label: 'Usia',
                                      value:
                                          '${AppDateUtils.ageFromBirthdate(_profile!.tanggalLahir)} Tahun',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildStatGridCard(
                                      label: 'Berat Badan',
                                      value:
                                          '${_profile!.beratBadan.toStringAsFixed(0)} kg',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Reminder Status Card
                              _buildSettingsInnerCardShell(
                                lightweightMode: lightweightMode,
                                borderRadius: 20,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'PENGINGAT MINUM',
                                            style: GoogleFonts.manrope(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: const Color(0xFF64748B),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          // Status Chip
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  _profile!.reminderSystemActive
                                                  ? const Color(0xFFDCFCE7)
                                                  : const Color(0xFFFEE2E2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color:
                                                        _profile!
                                                            .reminderSystemActive
                                                        ? const Color(
                                                            0xFF16A34A,
                                                          )
                                                        : const Color(
                                                            0xFFDC2626,
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _profile!.reminderSystemActive
                                                      ? 'Aktif'
                                                      : 'Nonaktif',
                                                  style: GoogleFonts.manrope(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color:
                                                        _profile!
                                                            .reminderSystemActive
                                                        ? const Color(
                                                            0xFF15803D,
                                                          )
                                                        : const Color(
                                                            0xFFB91C1C,
                                                          ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_profile!.reminderSystemActive) ...[
                                        const SizedBox(height: 12),
                                        const Divider(
                                          height: 1,
                                          color: Color(0xFFF1F5F9),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Rentang Waktu',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                            Text(
                                              '${_profile!.reminderWindowStart.toString().padLeft(2, '0')}.00 - ${_profile!.reminderWindowEnd.toString().padLeft(2, '0')}.00',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.normal,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Interval',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                            Text(
                                              'Setiap ${_profile!.reminderInterval} Jam',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.normal,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          'Pengingat minum dinonaktifkan. Anda tidak akan menerima notifikasi pengingat harian.',
                                          style: GoogleFonts.manrope(
                                            fontSize: 11,
                                            fontWeight: FontWeight.normal,
                                            color: const Color(0xFF64748B),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              if (_exactAlarmAllowed == false) ...[
                                const SizedBox(height: 20),
                                _buildExactAlarmWarning(),
                                const SizedBox(height: 20),
                              ] else
                                const SizedBox(height: 20),

                              // Edit Button
                              SizedBox(
                                width: double.infinity,
                                child: AppButton.main(
                                  label: 'Edit Profil',
                                  onPressed: () async {
                                    ref
                                        .read(profileProvider.notifier)
                                        .initializeForEdit(_profile!);
                                    final updated = await context.push<bool>(
                                      '/profile-setup?edit=true',
                                    );
                                    if (!mounted) return;
                                    if (updated == true) {
                                      await _loadProfileData();
                                      ref.invalidate(hydrationProvider);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                _buildDisplayPreferenceCard(lightweightMode),
                const SizedBox(height: 24),

                // 4 & 6. Manajemen Data Card (Export CSV & Reset Data)
                _buildSettingsCardShell(
                  lightweightMode: lightweightMode,
                  borderRadius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manajemen Data',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.normal,
                            color: kTextDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Kelola data penelitian Anda. Ekspor catatan hidrasi untuk analisis laporan OPSI, atau bersihkan seluruh data dari perangkat ini.',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: kTextSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bagian 1: Ekspor Data CSV
                        Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.table_chart_outlined,
                                  size: 12,
                                  color: Color(0xFF1E40AF),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Format: CSV',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF1E40AF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.date_range_outlined,
                                  size: 12,
                                  color: Color(0xFF166534),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Rentang: 14 Hari',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF166534),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton.main(
                            label: 'Ekspor Ringkasan Harian',
                            isLoading: _isExporting,
                            onPressed: _isExporting ? null : _exportDailySummaryCsv,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton.main(
                            label: 'Ekspor Log Minum Lengkap',
                            isLoading: _isExporting,
                            onPressed: _isExporting ? null : _exportDrinkLogsCsv,
                          ),
                        ),

                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Colors.black.withValues(alpha: 0.05),
                        ),
                        const SizedBox(height: 16),

                        // Bagian 2: Danger Zone (Reset Data)
                        Text(
                          'Tindakan Berbahaya',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Menghapus seluruh data profil, catatan hidrasi harian, dan pengaturan secara permanen. Tindakan ini tidak dapat dibatalkan.',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            color: const Color(0xFF7F1D1D),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: AppButton.main(
                            label: 'Reset Data Aplikasi',
                            color: const Color(0xFFEF4444),
                            onPressed: _showResetConfirmation,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_qaToolsEnabled && _qaModeEnabled) ...[
                  const SizedBox(height: 16),
                  _buildQaModeCard(lightweightMode),
                ],
                SizedBox(height: lightweightMode ? 16 : 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSettingsAppBar(bool lightweightMode) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 24,
      toolbarHeight: 100,
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleSettingsTitleTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Pengaturan',
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
              'Atur profil dan informasi aplikasi',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightSettingsView() {
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNewSectionTitle('Profil'),
          _buildNewLightProfileCard(),
          const SizedBox(height: 24),
          _buildNewSectionTitle('Tema'),
          _buildNewLightThemeCard(lightweightMode),
          const SizedBox(height: 24),
          _buildNewSectionTitle('Aplikasi & Data'),
          _buildNewLightAppCard(),
          if (_qaToolsEnabled && _qaModeEnabled) ...[
            const SizedBox(height: 16),
            _buildQaModeCard(true),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNewSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
    );
  }

  String _genderLabel() {
    return _profile!.jenisKelamin == 'laki_laki' ? 'Laki-laki' : 'Perempuan';
  }

  Widget _buildNewLightProfileCard() {
    final age = AppDateUtils.ageFromBirthdate(_profile!.tanggalLahir);
    final gender = _genderLabel();
    final activity =
        _profile!.levelAktivitas == 'aktif' ||
            _profile!.levelAktivitas == 'sangat_aktif'
        ? 'Tinggi'
        : (_profile!.levelAktivitas == 'sedang' ? 'Sedang' : 'Rendah');
    final target = '${_profile!.dailyTargetMl} ml';
    final interval = '${_profile!.reminderInterval} jam';
    final window =
        '${_profile!.reminderWindowStart.toString().padLeft(2, '0')}:00 - ${_profile!.reminderWindowEnd.toString().padLeft(2, '0')}:00';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD7E5FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: Image.asset(
                    _profile!.jenisKelamin == 'laki_laki'
                        ? 'assets/images/man.webp'
                        : 'assets/images/woman.webp',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _capitalize(_profile!.nama),
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gender,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildNewProfileStatRow('ID Penelitian', _profile!.participantId),
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4, bottom: 12),
            child: Text(
              'ID ini digunakan untuk export data penelitian agar data tetap konsisten.',
              style: GoogleFonts.manrope(
                fontSize: 10,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          _buildNewProfileStatRow('Usia', '$age Tahun'),
          const SizedBox(height: 12),
          _buildNewProfileStatRow(
            'Berat badan',
            '${_profile!.beratBadan.toStringAsFixed(0)} kg',
          ),
          const SizedBox(height: 12),
          _buildNewProfileStatRow('Tingkat aktivitas', activity),
          const SizedBox(height: 12),
          _buildNewProfileStatRow('Kebutuhan harian', target),
          const SizedBox(height: 12),
          _buildNewProfileStatRow('Interval', interval),
          const SizedBox(height: 12),
          _buildNewProfileStatRow('Rentang waktu', window),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  ref
                      .read(profileProvider.notifier)
                      .initializeForEdit(_profile!);
                  final updated = await context.push<bool>(
                    '/profile-setup?edit=true',
                  );
                  if (!mounted) return;
                  if (updated == true) {
                    await _loadProfileData();
                    ref.invalidate(hydrationProvider);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'EDIT PROFIL',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewProfileStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildNewLightThemeCard(bool lightweightMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFD7E5FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Minimalist',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          Switch.adaptive(
            value: lightweightMode,
            activeThumbColor: kPrimary,
            activeTrackColor: kPrimary.withValues(alpha: 0.3),
            onChanged: (value) {
              ref.read(appSettingsProvider.notifier).setLightweightMode(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewLightAppCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD7E5FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildNewAppCardRow(
            title: 'Tentang SEHATI',
            subtitle: 'Informasi aplikasi',
            actionIcon: Icons.info_outline_rounded,
            actionIconColor: const Color.fromARGB(255, 0, 0, 0),
            onTap: _showAboutSehatiDialog,
          ),
          const SizedBox(height: 4),

          _buildNewAppCardRow(
            title: 'Ekspor Ringkasan Harian',
            subtitle: 'Ekspor ringkasan harian kamu',
            actionIcon: Icons.download_rounded,
            actionIconColor: const Color.fromARGB(255, 0, 0, 0),
            onTap: _isExporting ? null : _exportDailySummaryCsv,
          ),
          const SizedBox(height: 4),

          _buildNewAppCardRow(
            title: 'Ekspor Log Minum Lengkap',
            subtitle: 'Ekspor detail catatan minum kamu',
            actionIcon: Icons.download_rounded,
            actionIconColor: const Color.fromARGB(255, 0, 0, 0),
            onTap: _isExporting ? null : _exportDrinkLogsCsv,
          ),

          _buildNewAppCardRow(
            title: 'Hapus Data',
            subtitle: 'Hapus semua data kamu',
            actionIcon: Icons.delete_outline_rounded,
            actionIconColor: const Color.fromARGB(255, 0, 0, 0),
            onTap: _showResetConfirmation,
          ),
        ],
      ),
    );
  }

  void _showAboutSehatiDialog() {
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dialogContent = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: lightweightMode
                ? const Color(0xFFD7E5FF)
                : Colors.white.withValues(alpha: 0.34),
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
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: lightweightMode
                  ? const Color(0xFFD7E5FF)
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Tentang SEHATI',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'SEHATI membantu kamu lebih rutin minum air putih dengan fitur target harian, pengingat, catatan minum, serta riwayat yang mudah dipahami.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 2,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
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
                    child: Text(
                      'TUTUP',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: lightweightMode
                ? dialogContent
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: dialogContent,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildNewAppCardRow({
    required String title,
    required String subtitle,
    IconData? actionIcon,
    Color? actionIconColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            if (actionIcon != null) ...[
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.0),
                ),
                child: Icon(
                  actionIcon,
                  color: actionIconColor ?? const Color(0xFF1A73E8),
                  size: 18,
                ),
              ),
            ] else ...[
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExactAlarmWarning() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: Color(0xFFEA580C),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Izin alarm presisi belum aktif. Pengingat bisa tetap berjalan, tetapi waktunya mungkin tidak selalu tepat.',
              style: GoogleFonts.manrope(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF9A3412),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQaModeCard(bool lightweightMode) {
    return _buildSettingsCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mode Pengujian',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fitur ini hanya untuk mengecek notifikasi saat pengujian.',
              style: GoogleFonts.manrope(
                fontSize: 12,
                color: kTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: AppButton.main(
                label: 'Test Notifikasi Sekarang',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (await _checkAndNotifyPermission()) {
                    await ref
                        .read(reminderServiceProvider)
                        .fireTestNotificationNow();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Notifikasi tes instan dikirim.',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        backgroundColor: kPrimary,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton.main(
                label: 'Jadwalkan Notifikasi 1 Menit',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  if (await _checkAndNotifyPermission()) {
                    await ref
                        .read(reminderServiceProvider)
                        .scheduleTestNotification1Min();
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Notifikasi tes dijadwalkan 1 menit lagi.',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        backgroundColor: kPrimary,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton.secondary(
                label: 'Inspect Pending Notifications',
                onPressed: _showPendingNotificationReport,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton.secondary(
                label: 'Refresh Status Notifikasi',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final report = await _loadPendingNotificationReport();
                  if (report == null || !mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Pending notification list diperbarui.'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: AppButton.secondary(
                label: 'Sembunyikan Mode Pengujian',
                color: const Color(0xFFEF4444),
                isTransparent: true,
                onPressed: () {
                  setState(() {
                    _qaModeEnabled = false;
                    _qaTapCount = 0;
                    _pendingNotificationReport = null;
                  });
                },
              ),
            ),
            if (_pendingNotificationReport != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _pendingNotificationReport!,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      color: const Color(0xFF334155),
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }

  Widget _buildStatGridCard({required String label, required String value}) {
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;
    return _buildSettingsInnerCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 16,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCardShell({
    required bool lightweightMode,
    required double borderRadius,
    required Widget child,
    bool isProfileCard = false,
  }) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: lightweightMode
            ? const Color(0xFFEAF5FF)
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
              ? const Color(0xFFD7EAFB)
              : Colors.white.withValues(alpha: 0.72),
          width: isProfileCard ? 1.5 : 1.2,
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

  Widget _buildSettingsInnerCardShell({
    required bool lightweightMode,
    required double borderRadius,
    required Widget child,
  }) {
    final card = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: lightweightMode
            ? Colors.white
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
              ? const Color(0xFFE2E8F0)
              : Colors.white.withValues(alpha: 0.72),
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

  Widget _buildDisplayPreferenceCard(bool lightweightMode) {
    return _buildSettingsCardShell(
      lightweightMode: lightweightMode,
      borderRadius: 24,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Minimalist',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.normal,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tampilan sederhana tanpa efek visual berat, lebih ringan digunakan.',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: kTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch.adaptive(
              value: lightweightMode,
              activeThumbColor: kPrimary,
              onChanged: (value) {
                ref
                    .read(appSettingsProvider.notifier)
                    .setLightweightMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
