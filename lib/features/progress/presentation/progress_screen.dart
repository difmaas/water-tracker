import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Progress screen with weekly charts — stub for F-01.
/// Actual implementation in F-12 (Phase 2).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: const Center(child: Text('Progress Screen')),
    );
  }
}
