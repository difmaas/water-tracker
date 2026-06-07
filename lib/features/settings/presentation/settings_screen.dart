import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../providers/hydration_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/user_profile_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Styles matching Splash/Onboarding/Profile Setup
  static const Color kPrimary = Color(0xFF1A73E8);
  static const Color kBackground = Color(0xFFF8FBFF);
  static const Color kAccent = Color(0xFFE8F4FF);
  static const Color kTextDark = Color(0xFF1F2937);
  static const Color kTextSecondary = Color(0xFF6B7280);

  int? _startHour;
  int? _endHour;
  bool _isSaving = false;

  UserProfile? _profile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await ref.read(profileRepositoryProvider).getUserProfile();
    if (profile != null) {
      setState(() {
        _profile = profile;
        _startHour = profile.reminderWindowStart;
        _endHour = profile.reminderWindowEnd;
        _isLoadingProfile = false;
      });
    } else {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  bool get _isWindowValid {
    if (_startHour == null || _endHour == null) return false;
    return AppDateUtils.isValidReminderWindow(_startHour!, _endHour!);
  }

  Future<void> _saveReminderSettings() async {
    if (!_isWindowValid) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getUserProfile();
      if (profile != null) {
        final updated = profile.copyWith(
          reminderWindowStart: _startHour!,
          reminderWindowEnd: _endHour!,
          isSynced: false,
        );
        await repo.saveProfile(updated);

        // Cancel old and reschedule new notifications
        await ref.read(reminderServiceProvider).rescheduleWithNewWindow();

        setState(() {
          _profile = updated;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pengaturan pengingat berhasil disimpan',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              backgroundColor: kPrimary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan pengingat: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await ref
        .read(reminderServiceProvider)
        .requestPermissions();
    if (granted && _profile != null) {
      final repo = ref.read(profileRepositoryProvider);
      final updated = _profile!.copyWith(
        notificationPermissionGranted: true,
        reminderSystemActive: true,
        isSynced: false,
      );
      await repo.saveProfile(updated);
      _loadProfileData();
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Reset Data?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFFEF4444),
          ),
        ),
        content: Text(
          'Semua data profil, riwayat minum, dan pengaturan akan dihapus dari perangkat ini. Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: kTextSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: kTextSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final router = GoRouter.of(context);
              final navigator = Navigator.of(context);

              // 1. Clear persistent local database (Isar)
              await ref.read(profileRepositoryProvider).clearAllData();

              // 2. Cancel all scheduled reminder notifications
              await ref.read(reminderServiceProvider).cancelAll();

              // 3. Clear SharedPreferences keys for onboarding/profile status
              final prefs = ref.read(sharedPreferencesProvider);
              await prefs.remove('isOnboarded');
              await prefs.remove('hasProfile');

              // 4. Invalidate all cache states in Riverpod to trigger reconstruction
              ref.invalidate(onboardingProvider);
              ref.invalidate(profileStatusProvider);
              ref.invalidate(profileProvider);
              ref.invalidate(hydrationProvider);

              navigator.pop();
              router.go('/');
            },
            child: Text(
              'Reset',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: kBackground,
        body: Center(child: CircularProgressIndicator(color: kPrimary)),
      );
    }

    if (_profile == null) {
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
                'Pengaturan',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Atur pengingat dan informasi aplikasi',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        body: const Center(
          child: Text(
            'Profil tidak ditemukan. Selesaikan setup profil dahulu.',
          ),
        ),
      );
    }

    final isNotifGranted = _profile!.notificationPermissionGranted;

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
              'Pengaturan',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Atur pengingat dan informasi aplikasi',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Reminder Settings Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kAccent, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pengingat Minum',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Atur jam aktif pengingat minum harianmu.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Jam Mulai
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jam Mulai',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: kTextSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _startHour,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: kTextDark,
                                  ),
                                  items: List.generate(17, (i) => i + 6).map((
                                    h,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: h,
                                      child: Text(
                                        '${h.toString().padLeft(2, '0')}.00',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _startHour = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Jam Selesai
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jam Selesai',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: kTextSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _endHour,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: kTextDark,
                                  ),
                                  items: List.generate(17, (i) => i + 6).map((
                                    h,
                                  ) {
                                    return DropdownMenuItem<int>(
                                      value: h,
                                      child: Text(
                                        '${h.toString().padLeft(2, '0')}.00',
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _endHour = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pengingat dikirim setiap 2 jam selama jam aktif.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: kTextSecondary,
                    ),
                  ),
                  if (!_isWindowValid &&
                      _startHour != null &&
                      _endHour != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Color(0xFFEF4444),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _startHour! < 6 || _endHour! > 22
                                  ? 'Jam pengingat hanya dapat diatur antara 06.00 sampai 22.00.'
                                  : _endHour! <= _startHour!
                                  ? 'Jam selesai harus lebih besar dari jam mulai.'
                                  : 'Jendela pengingat minimal 8 jam.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFB91C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isWindowValid && !_isSaving
                          ? _saveReminderSettings
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade200,
                        disabledForegroundColor: Colors.grey.shade400,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.0,
                              ),
                            )
                          : Text(
                              'Simpan Pengingat',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Profile Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kAccent, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profil Pengguna',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProfileRow('Nama Panggilan', _profile!.nama),
                  _buildProfileRow(
                    'Usia',
                    '${AppDateUtils.ageFromBirthdate(_profile!.tanggalLahir)} Tahun',
                  ),
                  _buildProfileRow(
                    'Jenis Kelamin',
                    _profile!.jenisKelamin == 'laki_laki'
                        ? 'Laki-laki'
                        : 'Perempuan',
                  ),
                  _buildProfileRow(
                    'Berat Badan',
                    '${_profile!.beratBadan.toStringAsFixed(0)} kg',
                  ),
                  _buildProfileRow(
                    'Aktivitas',
                    _profile!.levelAktivitas == 'aktif'
                        ? 'Tinggi'
                        : (_profile!.levelAktivitas == 'sedang'
                              ? 'Sedang'
                              : 'Ringan'),
                  ),
                  _buildProfileRow(
                    'Target Harian',
                    '${_profile!.dailyTargetMl} ml',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(profileProvider.notifier)
                            .initializeForEdit(_profile!);
                        context.push('/profile-setup?edit=true');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: const BorderSide(color: kAccent, width: 2),
                        backgroundColor: kAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Edit Profil',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Notification Permission Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kAccent, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status Notifikasi',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: kTextDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isNotifGranted
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isNotifGranted ? 'Aktif' : 'Belum Aktif',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isNotifGranted
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isNotifGranted
                        ? 'Pengingat minum sudah aktif.'
                        : 'Aktifkan notifikasi agar SEHATI bisa mengingatkan waktu minum.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: kTextSecondary,
                      height: 1.4,
                    ),
                  ),
                  if (!isNotifGranted) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _requestNotificationPermission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Aktifkan Notifikasi',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. App Info Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kAccent, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tentang SEHATI',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: kTextDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAppInfoRow('Nama Aplikasi', 'SEHATI'),
                  _buildAppInfoRow(
                    'Deskripsi',
                    'Aplikasi pengingat minum air putih untuk mendukung kebiasaan hidrasi siswa.',
                  ),
                  _buildAppInfoRow('Versi Aplikasi', '2.0.0'),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    '“Aplikasi ini membantu Anda mencatat asupan air harian untuk menjaga kesehatan tubuh dan bukan pengganti saran medis profesional.”',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: kTextSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // 5. Reset Data Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _showResetConfirmation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFFFEE2E2), width: 2),
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Reset Data Aplikasi',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: kTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: kTextDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: kTextSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: kTextDark,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}
