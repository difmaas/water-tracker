import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/profile_provider.dart';
import '../domain/hydration_calculator.dart';
import '../data/user_profile_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _currentStep = 0;
  static const int _kTotalSteps = 7; // 0–6, step 6 = konfirmasi

  final _namaController = TextEditingController();
  final _beratController = TextEditingController();

  @override
  void dispose() {
    _namaController.dispose();
    _beratController.dispose();
    super.dispose();
  }

  bool _canProceedFromStep(int step, ProfileFormState s) {
    switch (step) {
      case 0: // Nama
        return _validateNama(s.nama) == null;
      case 1: // Tanggal lahir
        return _validateTanggalLahir(s.tanggalLahir) == null;
      case 2: // Jenis kelamin
        return s.jenisKelamin.isNotEmpty;
      case 3: // Berat badan
        return _validateBerat(s.beratBadan) == null;
      case 4: // Level aktivitas
        return s.levelAktivitas.isNotEmpty;
      case 5: // Letak geografis + riwayat penyakit
        return s.letakGeografis.isNotEmpty;
      case 6: // Konfirmasi
        return true;
      default:
        return false;
    }
  }

  String? _validateNama(String value) {
    if (value.isEmpty) return 'Nama harus 3–10 karakter dan hanya boleh huruf.';
    if (value.length < 3 || value.length > 10) {
      return 'Nama harus 3–10 karakter dan hanya boleh huruf.';
    }
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(value)) {
      return 'Nama harus 3–10 karakter dan hanya boleh huruf.';
    }
    return null;
  }

  String? _validateTanggalLahir(DateTime? value) {
    if (value == null) return 'Usia harus antara 10 hingga 80 tahun.';
    if (!AppDateUtils.isValidAge(value)) return 'Usia harus antara 10 hingga 80 tahun.';
    return null;
  }

  String? _validateBerat(double value) {
    if (value < 20 || value > 200) return 'Berat badan harus antara 20–200 kg.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      appBar: AppBar(
        title: const Text('Buat Profil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1565C0),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (!_canProceedFromStep(_currentStep, s)) return;
          if (_currentStep < _kTotalSteps - 1) {
            setState(() => _currentStep++);
          } else {
            _handleSubmit();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep--);
        },
        controlsBuilder: (context, details) {
          final canProceed = _canProceedFromStep(_currentStep, s);
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: canProceed ? details.onStepContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: s.isLoading && _currentStep == _kTotalSteps - 1
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_currentStep == _kTotalSteps - 1 ? 'Konfirmasi' : 'Lanjut'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Kembali'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          _buildStep(0, 'Nama', _buildNamaStep(s, notifier)),
          _buildStep(1, 'Tanggal Lahir', _buildTanggalLahirStep(s, notifier)),
          _buildStep(2, 'Jenis Kelamin', _buildJenisKelaminStep(s, notifier)),
          _buildStep(3, 'Berat Badan', _buildBeratBadanStep(s, notifier)),
          _buildStep(4, 'Level Aktivitas', _buildLevelAktivitasStep(s, notifier)),
          _buildStep(5, 'Letak Geografis & Riwayat Penyakit', _buildGeografisStep(s, notifier)),
          _buildStep(6, 'Rekomendasi Target', _buildKonfirmasiStep(s, notifier)),
        ],
      ),
    );
  }

  Step _buildStep(int index, String title, Widget content) {
    return Step(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      content: content,
      isActive: _currentStep >= index,
      state: _currentStep > index ? StepState.complete : StepState.indexed,
    );
  }

  // ── Step 0: Nama ─────────────────────────────────────────────────────────────

  Widget _buildNamaStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nama Anda', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: _namaController,
          maxLength: 10,
          decoration: InputDecoration(
            hintText: 'Contoh: Dimas',
            errorText: s.nama.isNotEmpty ? _validateNama(s.nama) : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: notifier.updateNama,
        ),
      ],
    );
  }

  // ── Step 1: Tanggal Lahir ────────────────────────────────────────────────────

  Widget _buildTanggalLahirStep(ProfileFormState s, ProfileNotifier notifier) {
    final label = s.tanggalLahir != null
        ? '${s.tanggalLahir!.day.toString().padLeft(2, '0')}/'
            '${s.tanggalLahir!.month.toString().padLeft(2, '0')}/'
            '${s.tanggalLahir!.year}'
        : 'Pilih tanggal lahir';

    final ageError = s.tanggalLahir != null ? _validateTanggalLahir(s.tanggalLahir) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tanggal Lahir', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text(label),
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(now.year - 25),
              firstDate: DateTime(now.year - 80),
              lastDate: DateTime(now.year - 10),
              helpText: 'Pilih Tanggal Lahir',
            );
            if (picked != null) notifier.updateTanggalLahir(picked);
          },
        ),
        if (ageError != null) ...[
          const SizedBox(height: 4),
          Text(ageError, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        if (s.tanggalLahir != null && ageError == null) ...[
          const SizedBox(height: 4),
          Text(
            'Usia: ${AppDateUtils.ageFromBirthdate(s.tanggalLahir!)} tahun',
            style: const TextStyle(color: Colors.green, fontSize: 12),
          ),
        ],
      ],
    );
  }

  // ── Step 2: Jenis Kelamin ────────────────────────────────────────────────────

  Widget _buildJenisKelaminStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.jenisKelamin.isEmpty)
          const Text('Pilih jenis kelamin.',
              style: TextStyle(color: Colors.red, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            _kelaminChip('Laki-laki', 'laki_laki', s.jenisKelamin, notifier.updateJenisKelamin),
            const SizedBox(width: 12),
            _kelaminChip('Perempuan', 'perempuan', s.jenisKelamin, notifier.updateJenisKelamin),
          ],
        ),
      ],
    );
  }

  Widget _kelaminChip(String label, String value, String current, Function(String) onTap) {
    final selected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(value),
      selectedColor: const Color(0xFF1565C0).withOpacity(0.15),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF1565C0) : Colors.black87,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  // ── Step 3: Berat Badan ──────────────────────────────────────────────────────

  Widget _buildBeratBadanStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Berat badan (kg)', style: TextStyle(color: Colors.black54)),
        const SizedBox(height: 8),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _beratController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: 'kg',
              border: const OutlineInputBorder(),
              errorText: s.beratBadan > 0 ? _validateBerat(s.beratBadan) : null,
            ),
            onChanged: (v) => notifier.updateBeratBadan(double.tryParse(v) ?? 0.0),
          ),
        ),
      ],
    );
  }

  // ── Step 4: Level Aktivitas ──────────────────────────────────────────────────

  Widget _buildLevelAktivitasStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (s.levelAktivitas.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('Pilih level aktivitas.',
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        ...kActivityLevels.map((item) => RadioListTile<String>(
              title: Text(item['label']!),
              subtitle: Text(item['description']!,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              value: item['value']!,
              groupValue: s.levelAktivitas,
              onChanged: (v) => notifier.updateLevelAktivitas(v!),
              contentPadding: EdgeInsets.zero,
            )),
      ],
    );
  }

  // ── Step 5: Letak Geografis + Riwayat Penyakit ──────────────────────────────

  Widget _buildGeografisStep(ProfileFormState s, ProfileNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Letak Geografis', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        if (s.letakGeografis.isEmpty)
          const Text('Pilih letak geografis.',
              style: TextStyle(color: Colors.red, fontSize: 12)),
        DropdownButtonFormField<String>(
          value: s.letakGeografis.isEmpty ? null : s.letakGeografis,
          hint: const Text('Pilih lokasi'),
          items: kGeographicOptions.map((opt) {
            return DropdownMenuItem(value: opt['value'], child: Text(opt['label']!));
          }).toList(),
          onChanged: (v) => notifier.updateLetakGeografis(v!),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        const Text('Riwayat Penyakit', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        const Text(
          'Opsional — tidak berpengaruh pada perhitungan saat ini.',
          style: TextStyle(fontSize: 12, color: Colors.black45),
        ),
        const SizedBox(height: 8),
        ...kMedicalConditions.map((condition) => CheckboxListTile(
              title: Text(kMedicalConditionLabels[condition] ?? condition),
              value: s.riwayatPenyakit.contains(condition),
              onChanged: (_) => notifier.toggleRiwayatPenyakit(condition),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            )),
      ],
    );
  }

  // ── Step 6: Konfirmasi ───────────────────────────────────────────────────────

  Widget _buildKonfirmasiStep(ProfileFormState s, ProfileNotifier notifier) {
    // Build temp profile for breakdown
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
        // Recommendation headline
        Text(
          'Rekomendasi kebutuhan cairan harian',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          '$displayTarget ml',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 12),
        // Modifier breakdown
        if (breakdowns.isNotEmpty) ...[
          Text('Rincian modifier:', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          const SizedBox(height: 4),
          ...breakdowns.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(
                      b.delta >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: b.delta >= 0 ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text('${b.label}: ${b.deltaLabel}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
        ],
        // Manual adjust
        TextButton.icon(
          onPressed: () => _showManualEdit(s, notifier),
          icon: const Icon(Icons.edit, size: 16),
          label: const Text('Ubah Manual'),
        ),
        if (s.targetManualMl != null) ...[
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => notifier.updateManualTarget(null),
            child: const Text('Gunakan rekomendasi'),
          ),
        ],
        const SizedBox(height: 16),
        // Disclaimer — required on all recommendation screens
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            border: Border.all(color: Colors.amber.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            kHydrationDisclaimer,
            style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
          ),
        ),
      ],
    );
  }

  void _showManualEdit(ProfileFormState s, ProfileNotifier notifier) {
    final controller = TextEditingController(
        text: (s.targetManualMl ?? s.calculatedTargetMl).toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Target Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                suffixText: 'ml',
                helperText: 'Rentang: 1500–4000 ml',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 1500 && val <= 4000) {
                notifier.updateManualTarget(val);
              }
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    try {
      await ref.read(profileProvider.notifier).submitProfile();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }
}
