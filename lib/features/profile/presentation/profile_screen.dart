import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/presentation/main_scaffold.dart';
import '../../../core/utils/date_utils.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/app_settings_provider.dart';
import '../../../core/widgets/app_button.dart';

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
  bool _submitted = false;

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

    final initialAge = s.tanggalLahir != null
        ? AppDateUtils.ageFromBirthdate(s.tanggalLahir!).toString()
        : '';
    final initialWeight = s.beratBadan > 0
        ? s.beratBadan.toStringAsFixed(0)
        : '';

    _namaController = TextEditingController(text: s.nama);
    _usiaController = TextEditingController(text: initialAge);
    _beratController = TextEditingController(text: initialWeight);
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
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final age = int.tryParse(value.trim());
    if (age == null || age < 10 || age > 80) return 'Harus antara 10–80 tahun';
    return null;
  }

  String? _validateBerat(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final weight = double.tryParse(value.trim());
    if (weight == null || weight < 20 || weight > 200) {
      return 'Harus antara 20–200 kg';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _submitted = true;
    });

    final formValid = _formKey.currentState!.validate();
    final s = ref.read(profileProvider);
    final isWindowValid = AppDateUtils.isValidReminderWindow(
      s.reminderWindowStart,
      s.reminderWindowEnd,
    );

    if (formValid &&
        s.jenisKelamin.isNotEmpty &&
        s.levelAktivitas.isNotEmpty &&
        isWindowValid) {
      try {
        if (!widget.isEditing) {
          final selectedLightweightMode = ref
              .read(appSettingsProvider)
              .lightweightMode;
          await ref
              .read(appSettingsProvider.notifier)
              .setLightweightMode(selectedLightweightMode);
        }
        await ref.read(profileProvider.notifier).submitProfile();
        if (mounted) {
          if (widget.isEditing) {
            context.pop(true);
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
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;

    showDialog(
      context: context,
      builder: (context) {
        final dialogContent = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: lightweightMode
                ? const Color(0xFFEAF5FF)
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
                  ? const Color(0xFFD7EAFB)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: lightweightMode
                ? const []
                : [
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
                'Target Hidrasi Manual',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Masukkan target minum harian sendiri, terutama jika kamu memiliki anjuran khusus dari tenaga kesehatan.',
                style: GoogleFonts.manrope(
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
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF1F2937),
                ),
                decoration: InputDecoration(
                  hintText: 'Volume target (ml)',
                  filled: true,
                  fillColor: lightweightMode
                      ? const Color(0xFFF8FAFC)
                      : Colors.white.withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: lightweightMode
                          ? const Color(0xFFE2E8F0)
                          : Colors.white.withValues(alpha: 0.5),
                      width: 1.2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: lightweightMode
                          ? const Color(0xFFE2E8F0)
                          : Colors.white.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF1A73E8),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  AppButton.secondary(
                    label: 'Batal',
                    isTransparent: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (s.targetManualMl != null) ...[
                    AppButton.secondary(
                      label: 'Reset Rekomendasi',
                      color: const Color(0xFFEF4444),
                      isTransparent: true,
                      onPressed: () {
                        notifier.updateManualTarget(null);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                  AppButton.main(
                    label: 'Simpan',
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      if (val != null && val >= 1500 && val <= 4000) {
                        notifier.updateManualTarget(val);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Target manual harus antara 1500–4000 ml',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
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

  void _showHourPicker({
    required BuildContext context,
    required String title,
    required int initialValue,
    required ValueChanged<int> onSelected,
  }) {
    final lightweightMode = ref.read(appSettingsProvider).lightweightMode;

    showDialog(
      context: context,
      builder: (context) {
        final dialogContent = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: lightweightMode
                ? const Color(0xFFEAF5FF)
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
                  ? const Color(0xFFD7EAFB)
                  : Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: lightweightMode
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemCount: 17, // 6 to 22
                itemBuilder: (context, index) {
                  final hour = index + 6;
                  final isSelected = hour == initialValue;
                  final displayHour = '${hour.toString().padLeft(2, '0')}.00';
                  return GestureDetector(
                    onTap: () {
                      onSelected(hour);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1A73E8)
                            : (lightweightMode
                                  ? const Color(0xFFF8FAFC)
                                  : Colors.white.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1A73E8)
                              : (lightweightMode
                                    ? const Color(0xFFE2E8F0)
                                    : Colors.white.withValues(alpha: 0.8)),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        displayHour,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton.secondary(
                  label: 'Batal',
                  isTransparent: true,
                  onPressed: () => Navigator.pop(context),
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

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(profileProvider);
    final notifier = ref.read(profileProvider.notifier);
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    final displayTarget = s.targetManualMl ?? s.calculatedTargetMl;
    final recommendationTarget = s.calculatedTargetMl;
    final formattedRecommendation = recommendationTarget > 0
        ? (recommendationTarget >= 1000
              ? '${(recommendationTarget ~/ 1000)}.${(recommendationTarget % 1000).toString().padLeft(3, '0')}'
              : '$recommendationTarget')
        : '---';
    final isWindowValid = AppDateUtils.isValidReminderWindow(
      s.reminderWindowStart,
      s.reminderWindowEnd,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: HydrationBackground(lightweightMode: lightweightMode),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: true,
          appBar: AppBar(
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
                  widget.isEditing ? 'Ubah Profil' : 'Lengkapi Profil',
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: lightweightMode
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isEditing
                      ? 'Sesuaikan data diri untuk target hidrasi baru'
                      : 'Yuk, hitung kebutuhan cairan harianmu',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          body: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                        if (!widget.isEditing) ...[
                          _buildVisualThemeSelectionCard(lightweightMode),
                          const SizedBox(height: 20),
                        ],

                        // 2. Main Form Card
                        _ConditionalBackdropFilter(
                          enabled: !lightweightMode,
                          borderRadius: 24,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: lightweightMode
                                  ? Colors.white
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
                                    ? const Color(0xFFE2E8F0)
                                    : Colors.white.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              boxShadow: lightweightMode
                                  ? const []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nama Panggilan
                                Text(
                                  'Nama Panggilan',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _namaController,
                                  maxLength: 10,
                                  validator: _validateNama,
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF1F2937),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Nama Panggilan',
                                    counterText: '',
                                    filled: true,
                                    fillColor: Colors.white.withValues(
                                      alpha: 0.4,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF1A73E8),
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFEF4444),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFEF4444),
                                        width: 1.5,
                                      ),
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

                                // Usia input field
                                Text(
                                  'Usia (Tahun)',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _usiaController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: _validateUsia,
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF1F2937),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Usia (Tahun)',
                                    filled: true,
                                    fillColor: Colors.white.withValues(
                                      alpha: 0.4,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF1A73E8),
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFEF4444),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFEF4444),
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final age = int.tryParse(val.trim());
                                    if (age != null && age >= 10 && age <= 80) {
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
                                const SizedBox(height: 18),

                                // Berat Badan input field
                                Text(
                                  'Berat Badan (kg)',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _beratController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: _validateBerat,
                                  style: GoogleFonts.manrope(
                                    fontSize: 15,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF1F2937),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Berat Badan (kg)',
                                    filled: true,
                                    fillColor: Colors.white.withValues(
                                      alpha: 0.4,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF1A73E8),
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFEF4444),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFEF4444),
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                  onChanged: (val) {
                                    final weight = double.tryParse(val.trim());
                                    if (weight != null &&
                                        weight >= 20 &&
                                        weight <= 200) {
                                      notifier.updateBeratBadan(weight);
                                    } else {
                                      notifier.updateBeratBadan(0.0);
                                    }
                                  },
                                ),
                                const SizedBox(height: 18),

                                // Jenis Kelamin Selector
                                Text(
                                  'Jenis Kelamin',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
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
                                        (val) =>
                                            notifier.updateJenisKelamin(val),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildGenderOption(
                                        'Perempuan',
                                        'perempuan',
                                        s.jenisKelamin,
                                        (val) =>
                                            notifier.updateJenisKelamin(val),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_submitted && s.jenisKelamin.isEmpty) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      'Wajib memilih jenis kelamin',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),

                                // Aktivitas Harian
                                Text(
                                  'Aktivitas Harian',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildActivityOption(
                                  title: 'Ringan',
                                  desc: 'Lebih banyak duduk atau belajar.',
                                  value: 'ringan',
                                  current: s.levelAktivitas,
                                  onTap: (val) =>
                                      notifier.updateLevelAktivitas(val),
                                ),
                                const SizedBox(height: 8),
                                _buildActivityOption(
                                  title: 'Sedang',
                                  desc:
                                      'Aktivitas sekolah normal dan cukup sering bergerak.',
                                  value: 'sedang',
                                  current: s.levelAktivitas,
                                  onTap: (val) =>
                                      notifier.updateLevelAktivitas(val),
                                ),
                                const SizedBox(height: 8),
                                _buildActivityOption(
                                  title: 'Tinggi',
                                  desc:
                                      'Sering olahraga atau aktivitas fisik cukup berat.',
                                  value: 'aktif', // Maps to 'aktif' in database
                                  current: s.levelAktivitas,
                                  onTap: (val) =>
                                      notifier.updateLevelAktivitas(val),
                                ),
                                if (_submitted && s.levelAktivitas.isEmpty) ...[
                                  const SizedBox(height: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: Text(
                                      'Wajib memilih tingkat aktivitas harian',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 3. Target Preview Card
                        _ConditionalBackdropFilter(
                          enabled: !lightweightMode,
                          borderRadius: 24,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: lightweightMode
                                  ? Colors.white
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
                                    ? const Color(0xFFE2E8F0)
                                    : Colors.white.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              boxShadow: lightweightMode
                                  ? const []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Estimasi kebutuhan cairan harian kamu',
                                            style: GoogleFonts.manrope(
                                              fontSize: 11,
                                              fontWeight: FontWeight.normal,
                                              color: const Color(0xFF64748B),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.baseline,
                                            textBaseline:
                                                TextBaseline.alphabetic,
                                            children: [
                                              Text(
                                                displayTarget > 0
                                                    ? '$displayTarget'
                                                    : '---',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.normal,
                                                  color: const Color(
                                                    0xFF0F172A,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'ml / hari',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.normal,
                                                  color: const Color(
                                                    0xFF64748B,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (s.jenisKelamin.isNotEmpty &&
                                        s.beratBadan > 0 &&
                                        s.levelAktivitas.isNotEmpty)
                                      AppButton.secondary(
                                        label: s.targetManualMl != null
                                            ? 'Atur Ulang'
                                            : 'Sesuaikan',
                                        isTransparent: true,
                                        onPressed: () =>
                                            _showManualEdit(s, notifier),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Berdasarkan profil kamu, SEHATI menyarankan target minum air putih sekitar $formattedRecommendation ml per hari. dan bukan pengganti saran medis profesional',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          color: const Color(0xFF6B7280),
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    if (s.targetManualMl != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF1A73E8,
                                          ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Target Manual',
                                          style: GoogleFonts.manrope(
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal,
                                            color: const Color(0xFF1A73E8),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. Reminder Settings Card
                        _ConditionalBackdropFilter(
                          enabled: !lightweightMode,
                          borderRadius: 24,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: lightweightMode
                                  ? Colors.white
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
                                    ? const Color(0xFFE2E8F0)
                                    : Colors.white.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                              boxShadow: lightweightMode
                                  ? const []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Aktifkan Pengingat Minum',
                                      style: GoogleFonts.manrope(
                                        fontSize: 14,
                                        fontWeight: FontWeight.normal,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: s.reminderSystemActive,
                                      activeTrackColor: const Color(
                                        0xFF1A73E8,
                                      ).withValues(alpha: 0.5),
                                      activeThumbColor: const Color(0xFF1A73E8),
                                      onChanged: (val) {
                                        notifier.updateReminderSystemActive(
                                          val,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                if (s.reminderSystemActive) ...[
                                  const SizedBox(height: 18),
                                  Text(
                                    'Interval Pengingat',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildIntervalOption(
                                          '1 Jam',
                                          1,
                                          s.reminderInterval,
                                          (val) => notifier
                                              .updateReminderInterval(val),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildIntervalOption(
                                          '2 Jam',
                                          2,
                                          s.reminderInterval,
                                          (val) => notifier
                                              .updateReminderInterval(val),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildIntervalOption(
                                          '3 Jam',
                                          3,
                                          s.reminderInterval,
                                          (val) => notifier
                                              .updateReminderInterval(val),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      // Jam Mulai
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Jam Mulai',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                color: const Color(0xFF6B7280),
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            GestureDetector(
                                              onTap: () => _showHourPicker(
                                                context: context,
                                                title: 'Pilih Jam Mulai',
                                                initialValue:
                                                    s.reminderWindowStart,
                                                onSelected: (val) {
                                                  notifier
                                                      .updateFormReminderWindow(
                                                        val,
                                                        s.reminderWindowEnd,
                                                      );
                                                },
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.4),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${s.reminderWindowStart.toString().padLeft(2, '0')}.00',
                                                      style:
                                                          GoogleFonts.manrope(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color: const Color(
                                                              0xFF1F2937,
                                                            ),
                                                          ),
                                                    ),
                                                    const Icon(
                                                      Icons.access_time_rounded,
                                                      color: Color(0xFF6B7280),
                                                      size: 18,
                                                    ),
                                                  ],
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Jam Selesai',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                color: const Color(0xFF6B7280),
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            GestureDetector(
                                              onTap: () => _showHourPicker(
                                                context: context,
                                                title: 'Pilih Jam Selesai',
                                                initialValue:
                                                    s.reminderWindowEnd,
                                                onSelected: (val) {
                                                  notifier
                                                      .updateFormReminderWindow(
                                                        s.reminderWindowStart,
                                                        val,
                                                      );
                                                },
                                              ),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 14,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.4),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withValues(alpha: 0.5),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      '${s.reminderWindowEnd.toString().padLeft(2, '0')}.00',
                                                      style:
                                                          GoogleFonts.manrope(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                FontWeight
                                                                    .normal,
                                                            color: const Color(
                                                              0xFF1F2937,
                                                            ),
                                                          ),
                                                    ),
                                                    const Icon(
                                                      Icons.access_time_rounded,
                                                      color: Color(0xFF6B7280),
                                                      size: 18,
                                                    ),
                                                  ],
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
                                    'Pengingat akan dikirim setiap ${s.reminderInterval} jam selama jam aktif.',
                                    style: GoogleFonts.manrope(
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
                                                  ? 'Waktu mulai harus lebih awal dari waktu selesai.'
                                                  : 'Rentang pengingat minimal 8 jam.',
                                              style: GoogleFonts.manrope(
                                                fontSize: 11,
                                                fontWeight: FontWeight.normal,
                                                color: const Color(0xFFB91C1C),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: 16,
                top: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: lightweightMode
                    ? const []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: _ConditionalBackdropFilter(
                enabled: !lightweightMode,
                borderRadius: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: lightweightMode
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: lightweightMode
                          ? const Color(0xFFE2E8F0)
                          : Colors.white.withValues(alpha: 0.5),
                      width: lightweightMode ? 1.2 : 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      widget.isEditing
                          ? Row(
                              children: [
                                Expanded(
                                  child: AppButton.secondary(
                                    label: 'Kembali',
                                    isTransparent: true,
                                    onPressed: () => context.pop(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton.main(
                                    label: 'Simpan',
                                    isLoading: s.isLoading,
                                    onPressed: !s.isLoading
                                        ? _handleSubmit
                                        : null,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: AppButton.secondary(
                                    label: 'Reset',
                                    isTransparent: true,
                                    onPressed: () {
                                      ref
                                          .read(profileProvider.notifier)
                                          .reset();
                                      _namaController.clear();
                                      _usiaController.clear();
                                      _beratController.clear();
                                      setState(() {
                                        _submitted = false;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: AppButton.main(
                                    label: 'Simpan',
                                    isLoading: s.isLoading,
                                    onPressed: !s.isLoading
                                        ? _handleSubmit
                                        : null,
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
        ),
      ],
    );
  }

  Widget _buildVisualThemeSelectionCard(bool lightweightMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pilih Tampilan Aplikasi',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kamu bisa memilih tampilan yang paling nyaman untuk perangkatmu. Pilihan ini bisa diubah lagi di Pengaturan.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          _buildVisualThemeOption(
            title: 'Tampilan Utama',
            description: 'Visual lebih modern dengan efek dan tampilan penuh.',
            badge: 'Direkomendasikan untuk HP baru',
            selected: !lightweightMode,
            onTap: () {
              ref.read(appSettingsProvider.notifier).setLightweightMode(false);
            },
          ),
          const SizedBox(height: 10),
          _buildVisualThemeOption(
            title: 'Tampilan Ringan',
            description:
                'Tampilan lebih sederhana agar aplikasi lebih lancar di HP lama.',
            badge: 'Lebih lancar',
            selected: lightweightMode,
            onTap: () {
              ref.read(appSettingsProvider.notifier).setLightweightMode(true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisualThemeOption({
    required String title,
    required String description,
    required String badge,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF5FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF1A73E8) : const Color(0xFFE2E8F0),
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1A73E8) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFFCBD5E1),
                  width: 1.4,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFF1A73E8).withValues(alpha: 0.10)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                          color: selected
                              ? const Color(0xFF1A73E8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalOption(
    String label,
    int value,
    int current,
    Function(int) onTap,
  ) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A73E8).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1A73E8)
                : Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.normal,
            fontSize: 14,
            color: isSelected
                ? const Color(0xFF1A73E8)
                : const Color(0xFF4A5568),
          ),
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
    final isMale = value == 'laki_laki';

    final Color activeColor = isMale
        ? const Color(0xFF1A73E8)
        : const Color(0xFFE91E63);
    final Color inactiveIconColor = const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : Colors.white.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isMale ? Icons.man_rounded : Icons.woman_rounded,
              size: 24,
              color: isSelected ? activeColor : inactiveIconColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.normal,
                fontSize: 14,
                color: isSelected ? activeColor : const Color(0xFF4B5563),
              ),
            ),
          ],
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A73E8).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1A73E8)
                : Colors.white.withValues(alpha: 0.4),
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
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                      color: isSelected
                          ? const Color(0xFF1A73E8)
                          : const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: const Color(0xFF4A5568),
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

class RulerPainter extends CustomPainter {
  final double min;
  final double max;
  final double value;

  RulerPainter({required this.min, required this.max, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingX = 12.0;
    final double width = size.width - (paddingX * 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const int intervals = 36; // 180 / 5 = 36 intervals
    final double tickSpacing = width / intervals;

    for (int i = 0; i <= intervals; i++) {
      final double currentValue = min + (i * 5);
      final double x = paddingX + (i * tickSpacing);

      double tickHeight = 4.0;
      bool isMajor = currentValue % 20 == 0;
      bool isMedium = currentValue % 10 == 0 && !isMajor;

      if (isMajor) {
        tickHeight = 10.0;
        paint.strokeWidth = 1.2;
        paint.color = const Color(0xFF94A3B8); // Subtle slate gray
      } else if (isMedium) {
        tickHeight = 7.0;
        paint.strokeWidth = 1.0;
        paint.color = const Color(0xFFCBD5E1); // Lighter slate
      } else {
        tickHeight = 4.0;
        paint.strokeWidth = 0.8;
        paint.color = const Color(0xFFE2E8F0); // Extremely light gray
      }

      canvas.drawLine(Offset(x, 0), Offset(x, tickHeight), paint);

      if (isMajor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${currentValue.toInt()}',
            style: GoogleFonts.manrope(
              fontSize: 9,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, tickHeight + 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant RulerPainter oldDelegate) {
    return oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.value != value;
  }
}

class AgeRulerPainter extends CustomPainter {
  final double min;
  final double max;
  final double value;

  AgeRulerPainter({required this.min, required this.max, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final double paddingX = 12.0;
    final double width = size.width - (paddingX * 2);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // We want ticks every 2 units from 10 to 80.
    // (80 - 10) / 2 = 35 intervals
    const int intervals = 35;
    final double tickSpacing = width / intervals;

    for (int i = 0; i <= intervals; i++) {
      final double currentValue = min + (i * 2);
      final double x = paddingX + (i * tickSpacing);

      double tickHeight = 4.0;
      bool isMajor = currentValue % 10 == 0;
      bool isMedium = currentValue % 5 == 0 && !isMajor;

      if (isMajor) {
        tickHeight = 10.0;
        paint.strokeWidth = 1.2;
        paint.color = const Color(0xFF94A3B8); // Subtle slate gray
      } else if (isMedium) {
        tickHeight = 7.0;
        paint.strokeWidth = 1.0;
        paint.color = const Color(0xFFCBD5E1); // Lighter slate
      } else {
        tickHeight = 4.0;
        paint.strokeWidth = 0.8;
        paint.color = const Color(0xFFE2E8F0); // Extremely light gray
      }

      canvas.drawLine(Offset(x, 0), Offset(x, tickHeight), paint);

      if (isMajor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${currentValue.toInt()}',
            style: GoogleFonts.manrope(
              fontSize: 9,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, tickHeight + 3),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant AgeRulerPainter oldDelegate) {
    return oldDelegate.min != min ||
        oldDelegate.max != max ||
        oldDelegate.value != value;
  }
}

class _ConditionalBackdropFilter extends StatelessWidget {
  final bool enabled;
  final double borderRadius;
  final Widget child;

  const _ConditionalBackdropFilter({
    required this.enabled,
    required this.borderRadius,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: child,
      ),
    );
  }
}
