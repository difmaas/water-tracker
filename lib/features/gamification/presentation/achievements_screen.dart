import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Achievements / badges screen — stub for F-01.
/// Actual implementation in F-11 (Phase 2).
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: const Center(child: Text('Achievements Screen')),
    );
  }
}
