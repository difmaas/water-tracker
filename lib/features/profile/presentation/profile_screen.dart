import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final bool isEditing;
  const ProfileScreen({super.key, this.isEditing = false});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _namaController;
  late TextEditingController _usiaController;
  late TextEditingController _beratController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final s = ref.read(profileProvider);

    // Pre-fill hidden required fields with safe defaults if not editing
    if (!widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(profileProvider.notifier).updateTinggiBadan(160.0);
        ref
            .read(profileProvider.notifier)
            .updateLetakGeografis('dataran_rendah');
      });
    }

    _namaController = TextEditingController(text: s.nama);
    final age = s.tanggalLahir != null
        ? AppDateUtils.ageFromBirthdate(s.tanggalLahir!).toString()
        : '';
    _usiaController = TextEditingController(text: age);
    _beratController = TextEditingController(
      text: s.beratBadan > 0 ? s.beratBadan.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usiaController.dispose();
    _beratController.dispose();
    super.dispose();
  }

  String? _validateNama(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final name = value.trim();
    if (name.length < 3 || name.length > 10) return 'Harus 3–10 karakter';
    if (!RegExp(r'^[A-Za-z ]+$').hasMatch(name)) return 'Hanya huruf saja';
    return null;
  }

  String? _validateUsia(String? value) {
    if (value == null || value.isEmpty) return 'Wajib diisi';
    final val = int.tryParse(value);
    if (val == null || val < 10 || val > 80) return 'Usia valid: 10–80 tahun';
    return null;
  }

  String? _validateBerat(String? value) {
    if (value == null || value.isEmpty) return 'Wajib diisi';
    final val = double.tryParse(value);
    if (val == null || val < 20 || val > 200) return 'Range valid: 20–200 kg';
    return null;
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e')));
        }
      }
    }
  }

  void _showManualEdit(ProfileFormState s, ProfileNotifier notifier) {
    final controller = TextEditingController(
      text: (s.targetManualMl ?? s.calculatedTargetMl).toString(),
    );
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Target Hidrasi Manual',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sesuaikan target volume air minum harian jika diperlukan (1500–4000 ml).',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: 'Volume target (ml)',
                prefixIcon: const Icon(
                  Icons.water_drop_outlined,
                  color: Color(0xFF1A73E8),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'BATAL',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          if (s.targetManualMl != null)
            TextButton(
              onPressed: () {
                notifier.updateManualTarget(null);
                Navigator.pop(context);
              },
              child: Text(
                'RESET REKOMENDASI',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 1500 && val <= 4000) {
                notifier.updateManualTarget(val);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Target manual harus antara 1500–4000 ml'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'SIMPAN',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);

    final displayTarget = s.targetManualMl ?? s.calculatedTargetMl;
    final isWindowValid = AppDateUtils.isValidReminderWindow(
      s.reminderWindowStart,
      s.reminderWindowEnd,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Background #F8FBFF
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF8FBFF),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: widget.isEditing
            ? IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
              )
            : null,
        title: Text(
          widget.isEditing ? 'Ubah Profil' : 'Lengkapi Profil',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: const Color(0xFF1F2937),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header & Explanation Section
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE8F4FF,
                              ), // Soft Blue Accent
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                  0xFF1A73E8,
                                ).withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.water_drop_rounded,
                              color: Color(0xFF1A73E8), // Primary #1A73E8
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Lengkapi Profilmu',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Data ini digunakan untuk menghitung target minum harian dan mengatur pengingat yang sesuai.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 2. Main Form Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE8F4FF),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF1A73E8,
                            ).withValues(alpha: 0.02),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nama Panggilan
                          Text(
                            'Nama Panggilan',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _namaController,
                            maxLength: 10,
                            validator: _validateNama,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Nama panggilan',
                              counterText: '',
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (val) {
                              notifier.updateNama(val.trim());
                            },
                          ),
                          const SizedBox(height: 18),

                          // Row for Usia and Berat Badan
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Usia
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Usia (Tahun)',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _usiaController,
                                      keyboardType: TextInputType.number,
                                      validator: _validateUsia,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1F2937),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Thn',
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                      ),
                                      onChanged: (val) {
                                        final age = int.tryParse(val);
                                        if (age != null &&
                                            age >= 10 &&
                                            age <= 80) {
                                          notifier.updateTanggalLahir(
                                            DateTime(
                                              DateTime.now().year - age,
                                              1,
                                              1,
                                            ),
                                          );
                                        } else {
                                          notifier.updateTanggalLahir(null);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Berat Badan
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Berat Badan',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _beratController,
                                      keyboardType: TextInputType.number,
                                      validator: _validateBerat,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1F2937),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'kg',
                                        suffixText: 'kg',
                                        filled: true,
                                        fillColor: const Color(0xFFF9FAFB),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                      ),
                                      onChanged: (val) {
                                        final dVal = double.tryParse(val);
                                        if (dVal != null &&
                                            dVal >= 20 &&
                                            dVal <= 200) {
                                          notifier.updateBeratBadan(dVal);
                                        } else {
                                          notifier.updateBeratBadan(0.0);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Jenis Kelamin Selector
                          Text(
                            'Jenis Kelamin',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildGenderOption(
                                  'Laki-laki',
                                  'laki_laki',
                                  s.jenisKelamin,
                                  (val) => notifier.updateJenisKelamin(val),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildGenderOption(
                                  'Perempuan',
                                  'perempuan',
                                  s.jenisKelamin,
                                  (val) => notifier.updateJenisKelamin(val),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Aktivitas Harian
                          Text(
                            'Aktivitas Harian',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildActivityOption(
                            title: 'Ringan',
                            desc: 'Lebih banyak duduk atau belajar.',
                            value: 'ringan',
                            current: s.levelAktivitas,
                            onTap: (val) => notifier.updateLevelAktivitas(val),
                          ),
                          const SizedBox(height: 8),
                          _buildActivityOption(
                            title: 'Sedang',
                            desc:
                                'Aktivitas sekolah normal dan cukup sering bergerak.',
                            value: 'sedang',
                            current: s.levelAktivitas,
                            onTap: (val) => notifier.updateLevelAktivitas(val),
                          ),
                          const SizedBox(height: 8),
                          _buildActivityOption(
                            title: 'Tinggi',
                            desc:
                                'Sering olahraga atau aktivitas fisik cukup berat.',
                            value: 'aktif', // Maps to 'aktif' in database
                            current: s.levelAktivitas,
                            onTap: (val) => notifier.updateLevelAktivitas(val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Target Preview Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FF), // Soft Blue Background
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(
                            0xFF1A73E8,
                          ).withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TARGET HIDRASI HARIAN',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A73E8),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        displayTarget > 0
                                            ? '$displayTarget'
                                            : '---',
                                        style: GoogleFonts.inter(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: const Color(0xFF1A73E8),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'ml / hari',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(
                                            0xFF1A73E8,
                                          ).withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (s.jenisKelamin.isNotEmpty &&
                                  s.beratBadan > 0 &&
                                  s.levelAktivitas.isNotEmpty)
                                ElevatedButton(
                                  onPressed: () => _showManualEdit(s, notifier),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1A73E8),
                                    elevation: 0,
                                    side: const BorderSide(
                                      color: Color(0xFF1A73E8),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    s.targetManualMl != null
                                        ? 'Atur Ulang'
                                        : 'Sesuaikan',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '“Estimasi ini bukan pengganti saran medis profesional.”',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. Reminder Settings Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE8F4FF),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atur Pengingat Minum',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                        color: const Color(0xFF6B7280),
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
                                          initialValue: s.reminderWindowStart,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1F2937),
                                          ),
                                          items: List.generate(17, (i) => i + 6)
                                              .map((h) {
                                                return DropdownMenuItem<int>(
                                                  value: h,
                                                  child: Text(
                                                    '${h.toString().padLeft(2, '0')}.00',
                                                  ),
                                                );
                                              })
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              notifier.updateFormReminderWindow(
                                                val,
                                                s.reminderWindowEnd,
                                              );
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
                                        color: const Color(0xFF6B7280),
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
                                          initialValue: s.reminderWindowEnd,
                                          isExpanded: true,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1F2937),
                                          ),
                                          items: List.generate(17, (i) => i + 6)
                                              .map((h) {
                                                return DropdownMenuItem<int>(
                                                  value: h,
                                                  child: Text(
                                                    '${h.toString().padLeft(2, '0')}.00',
                                                  ),
                                                );
                                              })
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              notifier.updateFormReminderWindow(
                                                s.reminderWindowStart,
                                                val,
                                              );
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
                            'Pengingat akan dikirim setiap 2 jam selama jam aktif.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          if (!isWindowValid) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFEE2E2),
                                ),
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
                                      s.reminderWindowStart < 6 ||
                                              s.reminderWindowEnd > 22
                                          ? 'Jam pengingat hanya dapat diatur antara 06.00 sampai 22.00.'
                                          : s.reminderWindowEnd <=
                                                s.reminderWindowStart
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // 5. Sticky Bottom Action CTA
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  border: Border(
                    top: BorderSide(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!s.isValid)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          s.nama.trim().length < 3
                              ? '⚠️ Masukkan nama panggilan (3-10 huruf).'
                              : s.tanggalLahir == null
                              ? '⚠️ Masukkan usia valid (10-80 tahun).'
                              : s.jenisKelamin.isEmpty
                              ? '⚠️ Pilih jenis kelamin Anda.'
                              : s.beratBadan <= 0
                              ? '⚠️ Masukkan berat badan valid (20-200 kg).'
                              : s.levelAktivitas.isEmpty
                              ? '⚠️ Pilih tingkat aktivitas harian.'
                              : !isWindowValid
                              ? '⚠️ Jendela waktu pengingat harus minimal 8 jam.'
                              : '⚠️ Harap lengkapi seluruh formulir profil.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFB45309),
                            height: 1.4,
                          ),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: s.isValid && !s.isLoading
                            ? _handleSubmit
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF1A73E8,
                          ), // Primary #1A73E8
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade200,
                          disabledForegroundColor: Colors.grey.shade400,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // Rounded pill button
                          ),
                        ),
                        child: s.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                widget.isEditing
                                    ? 'SIMPAN PERUBAHAN'
                                    : 'SIMPAN PROFIL',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(
    String label,
    String value,
    String current,
    Function(String) onTap,
  ) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F4FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isSelected
                ? const Color(0xFF1A73E8)
                : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityOption({
    required String title,
    required String desc,
    required String value,
    required String current,
    required Function(String) onTap,
  }) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F4FF) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A73E8) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1A73E8),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
