import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/hydration_provider.dart';

class QuickAddButtons extends ConsumerWidget {
  const QuickAddButtons({super.key});

  /// Logs water and shows an undo Snackbar.
  Future<void> _addWater(BuildContext context, WidgetRef ref, int volumeMl) async {
    final log = await ref.read(hydrationProvider.notifier).addLog(volumeMl);

    if (log == null || !context.mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.clearSnackBars();

    final snackBarController = scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              'Berhasil ditambah +${volumeMl}ml',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blueGrey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        action: SnackBarAction(
          label: 'BATAL',
          textColor: Colors.orangeAccent,
          onPressed: () {
            ref.read(hydrationProvider.notifier).undoLog(log.id);
          },
        ),
      ),
    );

    // Force close after 5 seconds to bypass Android accessibility overrides
    Future.delayed(const Duration(seconds: 5), () {
      try {
        snackBarController.close();
      } catch (_) {}
    });
  }

  void _showCustomBottomSheet(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Kustom',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Volume (ml)',
                  hintText: 'Contoh: 300',
                  suffixText: 'ml',
                  border: OutlineInputBorder(),
                  helperText: 'Minimal 50ml, Maksimal 2000ml',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final val = int.tryParse(controller.text);
                    if (val == null || val < 50 || val > 2000) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(
                        const SnackBar(
                          content: Text('Volume harus antara 50ml — 2000ml'),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(sheetContext);
                    _addWater(context, ref, val);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Tambah'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickButton({
    required BuildContext context,
    required String label,
    required String subLabel,
    required IconData icon,
    required VoidCallback onTap,
    bool isCustom = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCustom
                  ? [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.5)]
                  : [const Color(0xFFE3F2FD), const Color(0xFFBBDEFB)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              const BoxShadow(
                color: Colors.white,
                blurRadius: 10,
                spreadRadius: -2,
                offset: Offset(-2, -2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isCustom ? Colors.blueGrey : const Color(0xFF1565C0),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isCustom ? Colors.blueGrey.shade800 : const Color(0xFF1565C0),
                ),
              ),
              if (subLabel.isNotEmpty)
                Text(
                  subLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCustom ? Colors.blueGrey.shade500 : const Color(0xFF1976D2).withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _buildQuickButton(
          context: context,
          label: '250',
          subLabel: 'ml',
          icon: Icons.local_drink_rounded,
          onTap: () => _addWater(context, ref, 250),
        ),
        const SizedBox(width: 12),
        _buildQuickButton(
          context: context,
          label: '500',
          subLabel: 'ml',
          icon: Icons.water_drop_rounded,
          onTap: () => _addWater(context, ref, 500),
        ),
        const SizedBox(width: 12),
        _buildQuickButton(
          context: context,
          label: 'Kustom',
          subLabel: '',
          icon: Icons.add_rounded,
          onTap: () => _showCustomBottomSheet(context, ref),
          isCustom: true,
        ),
      ],
    );
  }
}
