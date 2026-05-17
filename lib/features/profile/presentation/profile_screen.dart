import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/profile_provider.dart';
import '../domain/hydration_calculator.dart';
import '../data/user_profile_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  const ProfileScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with TickerProviderStateMixin {
  int _currentStep = 0;
  static const int _kTotalSteps = 9;

  final _namaController = TextEditingController();
  final _beratController = TextEditingController();
  final _tinggiController = TextEditingController();

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeController.forward();

    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final s = ref.read(profileProvider);
        _namaController.text = s.nama;
        _beratController.text = s.beratBadan > 0 ? s.beratBadan.toString() : '';
        _tinggiController.text = s.tinggiBadan > 0 ? s.tinggiBadan.toString() : '';
      });
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _beratController.dispose();
    _tinggiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final s = ref.read(profileProvider);
    if (!_canProceedFromStep(_currentStep, s)) return;

    if (_currentStep < _kTotalSteps - 1) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep++);
        _fadeController.forward();
      });
    } else {
      _handleSubmit();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _fadeController.reverse().then((_) {
        setState(() => _currentStep--);
        _fadeController.forward();
      });
    }
  }

  bool _canProceedFromStep(int step, ProfileFormState s) {
    switch (step) {
      case 0: return _validateNama(s.nama) == null;
      case 1: return _validateTanggalLahir(s.tanggalLahir) == null;
      case 2: return s.jenisKelamin.isNotEmpty;
      case 3: return _validateBerat(s.beratBadan) == null;
      case 4: return _validateTinggi(s.tinggiBadan) == null;
      case 5: return s.levelAktivitas.isNotEmpty;
      case 6: return s.letakGeografis.isNotEmpty;
      case 7: return s.reminderType.isNotEmpty;
      case 8: return true;
      default: return false;
    }
  }

  String? _validateNama(String value) {
    if (value.isEmpty) return 'Nama harus 3–10 karakter.';
    if (value.length < 3 || value.length > 10) return 'Nama harus 3–10 karakter.';
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value)) return 'Hanya boleh huruf.';
    return null;
  }

  String? _validateTanggalLahir(DateTime? value) {
    if (value == null) return 'Pilih tanggal lahir.';
    if (!AppDateUtils.isValidAge(value)) return 'Usia 10–80 tahun.';
    return null;
  }

  String? _validateBerat(double value) {
    if (value < 20 || value > 200) return '20–200 kg.';
    return null;
  }

  String? _validateTinggi(double value) {
    if (value < 50 || value > 250) return '50–250 cm.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          const _AnimatedWaterBackground(),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditing ? 'Ubah Profil' : 'Lengkapi Profil',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A2E),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Langkah ${_currentStep + 1} dari $_kTotalSteps',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (widget.isEditing)
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.close, color: Colors.black54),
                        ),
                    ],
                  ),
                ),
                
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        height: 6,
                        width: (MediaQuery.of(context).size.width - 48) * 
                               ((_currentStep + 1) / _kTotalSteps),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1565C0).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeController,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _GlassCard(
                        child: _buildCurrentStep(s, notifier),
                      ),
                    ),
                  ),
                ),

                // Footer Actions
                _buildFooter(s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ProfileFormState s) {
    final canProceed = _canProceedFromStep(_currentStep, s);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE0E0E0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('KEMBALI', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: canProceed ? _nextStep : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: s.isLoading && _currentStep == _kTotalSteps - 1
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _currentStep == _kTotalSteps - 1 ? 'SELESAI' : 'LANJUT',
                    style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep(ProfileFormState s, ProfileNotifier notifier) {
    switch (_currentStep) {
      case 0: return _buildNamaStep(s, notifier);
      case 1: return _buildTanggalLahirStep(s, notifier);
      case 2: return _buildJenisKelaminStep(s, notifier);
      case 3: return _buildWeightHeightStep(s, notifier);
      case 4: return _buildActivityLevelStep(s, notifier);
      case 5: return _buildGeographyStep(s, notifier);
      case 6: return _buildMedicalStep(s, notifier);
      case 7: return _buildReminderStep(s, notifier);
      case 8: return _buildKonfirmasiStep(s, notifier);
      default: return const SizedBox();
    }
  }

  Widget _buildStepTitle(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        Text(desc, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4)),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNamaStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Siapa nama Anda?', 'Gunakan nama panggilan Anda untuk pengalaman yang lebih personal.'),
        TextField(
          controller: _namaController,
          maxLength: 10,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: _inputDecoration('Nama Panggilan', Icons.person_outline),
          onChanged: notifier.updateNama,
        ),
      ],
    );
  }

  Widget _buildTanggalLahirStep(ProfileFormState s, ProfileNotifier notifier) {
    final label = s.tanggalLahir != null
        ? '${s.tanggalLahir!.day.toString().padLeft(2, '0')} / ${s.tanggalLahir!.month.toString().padLeft(2, '0')} / ${s.tanggalLahir!.year}'
        : 'Pilih Tanggal';
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Kapan Anda lahir?', 'Informasi ini membantu kami menyesuaikan kebutuhan hidrasi berdasarkan usia.'),
        InkWell(
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(now.year - 17),
              firstDate: DateTime(now.year - 80),
              lastDate: DateTime(now.year - 10),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(primary: Color(0xFF1565C0)),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) notifier.updateTanggalLahir(picked);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined, color: Color(0xFF1565C0)),
                const SizedBox(width: 16),
                Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
              ],
            ),
          ),
        ),
        if (s.tanggalLahir != null) ...[
          const SizedBox(height: 16),
          Text(
            'Usia Anda: ${AppDateUtils.ageFromBirthdate(s.tanggalLahir!)} Tahun',
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _buildJenisKelaminStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Jenis Kelamin', 'Kebutuhan cairan biologis berbeda antara laki-laki dan perempuan.'),
        Row(
          children: [
            Expanded(child: _genderOption('Laki-laki', 'laki_laki', Icons.male, s.jenisKelamin, notifier.updateJenisKelamin)),
            const SizedBox(width: 16),
            Expanded(child: _genderOption('Perempuan', 'perempuan', Icons.female, s.jenisKelamin, notifier.updateJenisKelamin)),
          ],
        ),
      ],
    );
  }

  Widget _genderOption(String label, String value, IconData icon, String current, Function(String) onTap) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0) : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200),
          boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? Colors.white : Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightHeightStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Fisik Anda', 'Informasi berat dan tinggi badan digunakan untuk menghitung volume hidrasi ideal.'),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Berat Badan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _beratController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: _inputDecoration('Kg', null),
                    onChanged: (v) => notifier.updateBeratBadan(double.tryParse(v) ?? 0.0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tinggi Badan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tinggiController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: _inputDecoration('Cm', null),
                    onChanged: (v) => notifier.updateTinggiBadan(double.tryParse(v) ?? 0.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityLevelStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Seberapa aktif Anda?', 'Semakin tinggi aktivitas fisik, semakin banyak cairan yang dibutuhkan tubuh.'),
        ...kActivityLevels.map((item) {
          final isSelected = s.levelAktivitas == item['value'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => notifier.updateLevelAktivitas(item['value']!),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1565C0).withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['label']!, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF1565C0) : Colors.black87)),
                          const SizedBox(height: 4),
                          Text(item['description']!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF1565C0)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGeographyStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Dimana Anda tinggal?', 'Suhu dan kelembapan di wilayah dataran tinggi vs rendah memengaruhi penguapan cairan tubuh.'),
        ...kGeographicOptions.map((opt) {
          final isSelected = s.letakGeografis == opt['value'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => notifier.updateLetakGeografis(opt['value']!),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF1565C0).withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Text(opt['label']!, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF1565C0) : Colors.black87)),
                    const Spacer(),
                    if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF1565C0)),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMedicalStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Riwayat Kesehatan', 'Opsional - Informasi ini berguna bagi penelitian untuk memahami latar belakang partisipan.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kMedicalConditions.map((condition) {
            final isSelected = s.riwayatPenyakit.contains(condition);
            return FilterChip(
              label: Text(kMedicalConditionLabels[condition] ?? condition),
              selected: isSelected,
              onSelected: (_) => notifier.toggleRiwayatPenyakit(condition),
              selectedColor: const Color(0xFF1565C0).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF1565C0),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF1565C0) : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200)),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReminderStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Mode Pengingat', 'Pilih bagaimana aplikasi mengingatkan Anda untuk minum.'),
        _reminderOption(
          'Smart Reminder', 
          'Algoritma cerdas yang menyesuaikan dengan sisa target dan waktu aktif Anda.',
          'smart', 
          Icons.auto_awesome_outlined,
          s.reminderType,
          notifier.updateReminderType
        ),
        const SizedBox(height: 16),
        _reminderOption(
          'Interval Tetap', 
          'Pengingat pada jam-jam yang sudah ditentukan (misal setiap 2 jam).',
          'interval', 
          Icons.timer_outlined,
          s.reminderType,
          notifier.updateReminderType
        ),
        if (s.reminderType == 'interval') ...[
          const SizedBox(height: 24),
          const Text('Pilih Interval:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 12),
          Row(
            children: [1, 2, 3].map((h) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('$h Jam'),
                  selected: s.reminderInterval == h,
                  onSelected: (_) => notifier.updateReminderInterval(h),
                ),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _reminderOption(String title, String desc, String value, IconData icon, String current, Function(String) onTap) {
    final isSelected = value == current;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1565C0).withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade400),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF1565C0) : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKonfirmasiStep(ProfileFormState s, ProfileNotifier notifier) {
    final tempProfile = UserProfile()
      ..jenisKelamin = s.jenisKelamin
      ..beratBadan = s.beratBadan
      ..levelAktivitas = s.levelAktivitas
      ..letakGeografis = s.letakGeografis
      ..riwayatPenyakit = s.riwayatPenyakit;

    final breakdowns = HydrationCalculator.getBreakdown(tempProfile);
    final displayTarget = s.targetManualMl ?? s.calculatedTargetMl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStepTitle('Hasil Perhitungan', 'Berdasarkan data Anda, ini adalah kebutuhan cairan harian yang disarankan.'),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            children: [
              const Text('TARGET HARIAN', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text(
                '$displayTarget ml',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              ...breakdowns.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(b.delta >= 0 ? Icons.add_circle : Icons.remove_circle, color: Colors.white70, size: 16),
                    const SizedBox(width: 12),
                    Text(b.label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const Spacer(),
                    Text(b.deltaLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              )),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => _showManualEdit(s, notifier),
              icon: const Icon(Icons.edit_note),
              label: const Text('Sesuaikan Manual'),
            ),
            if (s.targetManualMl != null)
              TextButton(
                onPressed: () => notifier.updateManualTarget(null),
                child: const Text('Reset Rekomendasi'),
              ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(kHydrationDisclaimer, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.5))),
            ],
          ),
        ),
      ],
    );
  }

  void _showManualEdit(ProfileFormState s, ProfileNotifier notifier) {
    final controller = TextEditingController(text: (s.targetManualMl ?? s.calculatedTargetMl).toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Target Manual', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sesuaikan jika Anda memiliki saran khusus dari dokter.'),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: _inputDecoration('Volume (ml)', Icons.water_drop_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 1500 && val <= 4000) {
                notifier.updateManualTarget(val);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0), foregroundColor: Colors.white),
            child: const Text('SIMPAN'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF1565C0)) : null,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );
  }

  Future<void> _handleSubmit() async {
    try {
      await ref.read(profileProvider.notifier).submitProfile();
      if (mounted) {
        if (widget.isEditing) {
          context.pop();
        } else {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _AnimatedWaterBackground extends StatefulWidget {
  const _AnimatedWaterBackground();

  @override
  State<_AnimatedWaterBackground> createState() => _AnimatedWaterBackgroundState();
}

class _AnimatedWaterBackgroundState extends State<_AnimatedWaterBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(top: -100 + (50 * _controller.value), left: -50 + (100 * _controller.value), child: _buildBlob(300, const Color(0xFFBDDDFD).withValues(alpha: 0.2))),
            Positioned(bottom: 100 - (50 * _controller.value), right: -100 + (150 * _controller.value), child: _buildBlob(400, const Color(0xFFC4E8C2).withValues(alpha: 0.15))),
            Positioned(top: 300 + (100 * (1 - _controller.value)), right: 50 + (50 * _controller.value), child: _buildBlob(250, const Color(0xFFFFE194).withValues(alpha: 0.1))),
          ],
        );
      },
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)])),
    );
  }
}
