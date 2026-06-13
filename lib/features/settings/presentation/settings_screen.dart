import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
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

  UserProfile? _profile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await ref.read(profileRepositoryProvider).getUserProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
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
              style: GoogleFonts.inter(fontWeight: FontWeight.normal),
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _exportCsv() async {
    if (_isExporting) return;

    setState(() => _isExporting = true);
    try {
      final result = await ref
          .read(csvExportServiceProvider)
          .exportHydrationLogs();
      final shareResult = await Share.shareXFiles(
        [XFile(result.filePath, mimeType: 'text/csv', name: result.fileName)],
        text: 'Riwayat hidrasi SEHATI',
        subject: result.fileName,
      );

      if (!mounted) return;

      final shared = shareResult.status == ShareResultStatus.success;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shared
                ? 'File CSV berhasil dibagikan.'
                : 'File CSV dibuat. Berbagi dibatalkan.',
            style: GoogleFonts.inter(fontWeight: FontWeight.normal),
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
      debugPrint('[SettingsScreen] CSV export failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengekspor data. Coba lagi nanti.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.90),
                    Colors.white.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset Data?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Semua data profil, riwayat minum, dan pengaturan akan dihapus dari perangkat ini. Tindakan ini tidak dapat dibatalkan.',
                    style: GoogleFonts.inter(
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
                            await ref.read(reminderServiceProvider).cancelAll();

                            // 3. Clear SharedPreferences keys for onboarding/profile status
                            final prefs = ref.read(sharedPreferencesProvider);
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
            appBar: _buildSettingsAppBar(),
            body: const Center(
              child: Text(
                'Profil tidak ditemukan. Selesaikan setup profil dahulu.',
              ),
            ),
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
          appBar: _buildSettingsAppBar(),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Unified Profile Card (Banner + Summary)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        width: double.infinity,
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
                              blurRadius: 10,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Banner Image
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F4FF),
                                borderRadius: const BorderRadius.vertical(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _capitalize(_profile!.nama),
                                              style: GoogleFonts.inter(
                                                fontSize: 22,
                                                fontWeight: FontWeight.normal,
                                                color: kTextDark,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Aktivitas: ${_profile!.levelAktivitas == 'aktif' ? 'Tinggi' : (_profile!.levelAktivitas == 'sedang' ? 'Sedang' : 'Ringan')}',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: kTextSecondary,
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
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _profile!.jenisKelamin ==
                                                      'laki_laki'
                                                  ? Icons.male_rounded
                                                  : Icons.female_rounded,
                                              size: 13,
                                              color: const Color(0xFF1A73E8),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _profile!.jenisKelamin ==
                                                      'laki_laki'
                                                  ? 'Laki-laki'
                                                  : 'Perempuan',
                                              style: GoogleFonts.inter(
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 22,
                                        sigmaY: 22,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.50,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.20,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.6,
                                            ),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'TARGET HIDRASI HARIAN',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: const Color(
                                                      0xFF64748B,
                                                    ),
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${_profile!.dailyTargetMl} ml / hari',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.normal,
                                                    color: const Color(
                                                      0xFF0F172A,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 22,
                                        sigmaY: 22,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withValues(
                                                alpha: 0.50,
                                              ),
                                              Colors.white.withValues(
                                                alpha: 0.20,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.6,
                                            ),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'PENGINGAT MINUM',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color: const Color(
                                                      0xFF64748B,
                                                    ),
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                                // Status Chip
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        _profile!
                                                            .reminderSystemActive
                                                        ? const Color(
                                                            0xFFDCFCE7,
                                                          )
                                                        : const Color(
                                                            0xFFFEE2E2,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 6,
                                                        height: 6,
                                                        decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
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
                                                        _profile!
                                                                .reminderSystemActive
                                                            ? 'Aktif'
                                                            : 'Nonaktif',
                                                        style: GoogleFonts.inter(
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
                                            if (_profile!
                                                .reminderSystemActive) ...[
                                              const SizedBox(height: 12),
                                              const Divider(
                                                height: 1,
                                                color: Color(0xFFF1F5F9),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Rentang Waktu',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFF64748B,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${_profile!.reminderWindowStart.toString().padLeft(2, '0')}.00 - ${_profile!.reminderWindowEnd.toString().padLeft(2, '0')}.00',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: const Color(
                                                        0xFF0F172A,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Interval',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: const Color(
                                                        0xFF64748B,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    'Setiap ${_profile!.reminderInterval} Jam',
                                                    style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      color: const Color(
                                                        0xFF0F172A,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ] else ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                'Pengingat minum dinonaktifkan. Anda tidak akan menerima notifikasi pengingat harian.',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.normal,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
                                        final updated = await context
                                            .push<bool>(
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
                  ),
                ),

                _buildDisplayPreferenceCard(lightweightMode),
                const SizedBox(height: 24),

                // 4 & 6. Manajemen Data Card (Export CSV & Reset Data)
                ClipRRect(
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
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manajemen Data',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.normal,
                              color: kTextDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Kelola data penelitian Anda. Ekspor catatan hidrasi untuk analisis laporan OPSI, atau bersihkan seluruh data dari perangkat ini.',
                            style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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
                                    style: GoogleFonts.inter(
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
                              label: 'Export Data CSV',
                              isLoading: _isExporting,
                              onPressed: _isExporting ? null : _exportCsv,
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
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Menghapus seluruh data profil, catatan hidrasi harian, dan pengaturan secara permanen. Tindakan ini tidak dapat dibatalkan.',
                            style: GoogleFonts.inter(
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
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
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
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'QA Debug Options',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                                color: kTextDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Gunakan opsi di bawah ini untuk memverifikasi fungsionalitas notifikasi lokal pada perangkat Android riil.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: kTextSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton.main(
                                label: 'Inspect Pending Notifications',
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  if (await _checkAndNotifyPermission()) {
                                    final report = await ref
                                        .read(reminderServiceProvider)
                                        .debugDescribePendingNotifications();
                                    debugPrint(report);
                                    if (!context.mounted) return;
                                    await showDialog<void>(
                                      context: context,
                                      builder: (dialogContext) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Pending Notifications',
                                          ),
                                          content: SizedBox(
                                            width: double.maxFinite,
                                            child: SingleChildScrollView(
                                              child: SelectableText(report),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                dialogContext,
                                              ).pop(),
                                              child: const Text('Tutup'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pending notification report ditampilkan.',
                                        ),
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
                                label: 'Test Notifikasi Sekarang',
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  if (await _checkAndNotifyPermission()) {
                                    await ref
                                        .read(reminderServiceProvider)
                                        .fireTestNotificationNow();
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Notifikasi tes instan dikirim.',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          backgroundColor: kPrimary,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: AppButton.main(
                                label: 'Jadwalkan Notifikasi 1 Menit Lagi',
                                onPressed: () async {
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );
                                  if (await _checkAndNotifyPermission()) {
                                    await ref
                                        .read(reminderServiceProvider)
                                        .scheduleTestNotification1Min();
                                    if (mounted) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Notifikasi tes dijadwalkan 1 menit lagi.',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          backgroundColor: kPrimary,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildSettingsAppBar() {
    return AppBar(
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
            'Pengaturan',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.normal,
              color: Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Atur pengingat dan informasi aplikasi',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.50),
                Colors.white.withValues(alpha: 0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.0,
            ),
          ),
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
                      style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
      ),
    );
  }

  Widget _buildDisplayPreferenceCard(bool lightweightMode) {
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
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: kPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Ringan',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.normal,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kurangi efek visual agar aplikasi lebih lancar di HP lama.',
                      style: GoogleFonts.inter(
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
      ),
    );
  }
}
