import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../features/logging/data/hydration_log_model.dart';
import '../../../../providers/hydration_provider.dart';

class HydrationLogTile extends ConsumerWidget {
  final HydrationLog log;

  const HydrationLogTile({super.key, required this.log});

  static const Color kObsidian = Color(0xFF040415);
  static const Color kPastelBlue = Color(0xFFE0F2FE);
  static const Color kPastelAmber = Color(0xFFFEF3C7);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeString =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}';
    final isNotification = log.loggedVia != 'app';
    final sourceIcon = isNotification
        ? Icons.notifications_active_rounded
        : Icons.smartphone_rounded;
    final sourceLabel = isNotification ? 'Notifikasi' : 'Aplikasi';

    // Choose beautiful colors based on log source
    final Color iconBg = isNotification ? kPastelAmber : kPastelBlue;
    final Color iconColor = isNotification
        ? const Color(0xFFB45309)
        : const Color(0xFF0369A1);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.02),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(Icons.water_drop_rounded, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Air Minum',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kObsidian,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      timeString,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Colors.black12,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      sourceIcon,
                      size: 13,
                      color: iconColor.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      sourceLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '+${log.volume} ml',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: iconColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.black45,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(context, ref);
              } else if (value == 'delete') {
                _showDeleteDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    const Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_rounded,
                      size: 18,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red.shade700)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Catatan?'),
          content: Text(
            'Apakah Anda yakin ingin menghapus catatan minum air sebesar ${log.volume} ml ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ref
                    .read(hydrationProvider.notifier)
                    .deleteLog(log.id, log.timestamp);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Catatan ${log.volume} ml berhasil dihapus'),
                  ),
                );
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: log.volume.toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Catatan Minum'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Volume Air (ml)',
                suffixText: 'ml',
                hintText: 'Masukkan volume air',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Volume tidak boleh kosong';
                }
                final volume = int.tryParse(value);
                if (volume == null || volume <= 0) {
                  return 'Masukkan angka positif';
                }
                if (volume > 3000) {
                  return 'Maksimum volume adalah 3000 ml';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final newVolume = int.parse(controller.text);
                  Navigator.of(context).pop();
                  ref
                      .read(hydrationProvider.notifier)
                      .updateLog(log.id, newVolume, log.timestamp);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Volume berhasil diubah menjadi $newVolume ml',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
