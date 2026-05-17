import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/data/user_profile_model.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int? _startHour;
  int? _endHour;
  String? _reminderType;
  int? _reminderInterval;
  String? _unit;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentWindow();
  }

  Future<void> _loadCurrentWindow() async {
    final profile = await ref.read(profileRepositoryProvider).getUserProfile();
    if (profile != null) {
      setState(() {
        _startHour = profile.reminderWindowStart;
        _endHour = profile.reminderWindowEnd;
        _reminderType = profile.reminderType;
        _reminderInterval = profile.reminderInterval;
        _unit = profile.unit;
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final current = isStart ? (_startHour ?? 7) : (_endHour ?? 21);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current, minute: 0),
      helpText: isStart ? 'Pilih Jam Mulai' : 'Pilih Jam Selesai',
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startHour = picked.hour;
        } else {
          _endHour = picked.hour;
        }
      });
    }
  }

  bool get _isWindowValid {
    if (_startHour == null || _endHour == null) return false;
    return AppDateUtils.isValidReminderWindow(_startHour!, _endHour!);
  }

  Future<void> _saveWindow() async {
    if (!_isWindowValid) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getUserProfile();
      if (profile != null) {
        final updated = profile.copyWith(
          reminderWindowStart: _startHour,
          reminderWindowEnd: _endHour,
          reminderType: _reminderType,
          reminderInterval: _reminderInterval,
          unit: _unit,
          isSynced: false,
        );
        await repo.saveProfile(updated);
        await ref.read(reminderServiceProvider).rescheduleWithNewWindow();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan berhasil diperbarui')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1565C0),
      ),
      body: FutureBuilder<UserProfile?>(
        future: ref.read(profileRepositoryProvider).getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;
          if (profile == null) {
            return const Center(child: Text('Profil tidak ditemukan'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Pengingat'),
                _buildReminderCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Satuan'),
                _buildUnitCard(),
                const SizedBox(height: 24),
                _buildSectionHeader('Profil Anda'),
                _buildProfileSummaryCard(profile),
                const SizedBox(height: 24),
                _buildSectionHeader('Aplikasi & Riset'),
                _buildAppInfoCard(),
                const SizedBox(height: 32),
                _buildResetSection(),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildReminderCard() {
    final isValid = _isWindowValid;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Waktu Pengingat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerTile(
                    'Mulai',
                    _startHour != null ? '${_startHour!.toString().padLeft(2, '0')}:00' : '--:--',
                    () => _selectTime(true),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                ),
                Expanded(
                  child: _buildTimePickerTile(
                    'Selesai',
                    _endHour != null ? '${_endHour!.toString().padLeft(2, '0')}:00' : '--:--',
                    () => _selectTime(false),
                  ),
                ),
              ],
            ),
            if (!isValid && _startHour != null && _endHour != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Pengingat harus antara jam 06:00–22:00 dengan durasi tidur kamu minimal 8 jam.',
                style: TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Tipe Pengingat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            RadioGroup<String>(
              groupValue: _reminderType,
              onChanged: (v) {
                if (v != null) {
                  setState(() => _reminderType = v);
                }
              },
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Smart', style: TextStyle(fontSize: 13)),
                      value: 'smart',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Interval', style: TextStyle(fontSize: 13)),
                      value: 'interval',
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            if (_reminderType == 'interval') ...[
              const SizedBox(height: 8),
              const Text('Durasi Interval', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('1 Jam'),
                    selected: _reminderInterval == 1,
                    onSelected: (_) => setState(() => _reminderInterval = 1),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('2 Jam'),
                    selected: _reminderInterval == 2,
                    onSelected: (_) => setState(() => _reminderInterval = 2),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('3 Jam'),
                    selected: _reminderInterval == 3,
                    onSelected: (_) => setState(() => _reminderInterval = 3),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isValid && !_isSaving ? _saveWindow : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: RadioGroup<String>(
          groupValue: _unit,
          onChanged: (v) {
            setState(() => _unit = v);
            _saveWindow(); // auto save
          },
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Mililiter (ml)', style: TextStyle(fontSize: 14)),
                  value: 'ml',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Ounce (oz)', style: TextStyle(fontSize: 14)),
                  value: 'oz',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerTile(String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard(UserProfile profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSummaryRow('Nama', profile.nama),
            _buildSummaryRow('Jenis Kelamin', profile.jenisKelamin == 'laki_laki' ? 'Laki-laki' : 'Perempuan'),
            _buildSummaryRow('Berat Badan', '${profile.beratBadan} kg'),
            _buildSummaryRow('Level Aktivitas', profile.levelAktivitas[0].toUpperCase() + profile.levelAktivitas.substring(1)),
            _buildSummaryRow('Lokasi', profile.letakGeografis.replaceAll('_', ' ')),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target Harian', style: TextStyle(color: Colors.black54, fontSize: 13)),
                    Text('Berdasarkan kalkulasi', style: TextStyle(color: Colors.black38, fontSize: 11)),
                  ],
                ),
                Text(
                  '${profile.dailyTargetMl} ml',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(profileProvider.notifier).initializeForEdit(profile);
                context.push('/profile-setup?edit=true');
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profil Lengkap'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Versi Aplikasi', style: TextStyle(color: Colors.black54, fontSize: 13)),
                Text('2.0.0 (Research)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                kSettingsResearchDisclaimer,
                style: TextStyle(fontSize: 11, color: Color(0xFF1565C0), height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetSection() {
    return Column(
      children: [
        const Text(
          'Tindakan Berbahaya',
          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _showResetConfirmation,
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            child: const Text('Hapus Semua Data & Reset App'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Menghapus semua data profil, log hidrasi, dan progress harian secara lokal.',
          style: TextStyle(color: Colors.black38, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Aplikasi?'),
        content: const Text(
          'Semua data hidrasi dan profil Anda akan dihapus permanen dari perangkat ini. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              final router = GoRouter.of(context);
              final navigator = Navigator.of(context);
              
              await ref.read(profileRepositoryProvider).clearAllData();
              
              if (mounted) {
                navigator.pop();
                router.go('/');
              }
            },
            child: const Text('Hapus Sekarang', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
