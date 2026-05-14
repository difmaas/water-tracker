import 'package:flutter/material.dart';

/// Reusable app card — stub for F-01.
/// Promoted to core/widgets/ because it will be used in 3+ features.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: child));
  }
}
