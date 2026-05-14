import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Profile setup screen — stub for F-01.
/// Actual implementation in F-03.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: const Center(child: Text('Profile Setup Screen')),
    );
  }
}
