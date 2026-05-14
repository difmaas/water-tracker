import 'package:flutter/material.dart';

class QuickAddButtons extends StatelessWidget {
  const QuickAddButtons({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur logging akan segera hadir')),
    );
  }

  void _showCustomBottomSheet(BuildContext context) {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Volume tidak valid')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _showComingSoon(context);
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showComingSoon(context),
            child: const Text('+250ml'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showComingSoon(context),
            child: const Text('+500ml'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _showCustomBottomSheet(context),
            child: const Text('Kustom'),
          ),
        ),
      ],
    );
  }
}
