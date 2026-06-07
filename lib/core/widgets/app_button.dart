import 'package:flutter/material.dart';

/// Reusable app button — stub for F-01.
/// Promoted to core/widgets/ because it will be used in 3+ features.
class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: onPressed, child: Text(label));
  }
}
