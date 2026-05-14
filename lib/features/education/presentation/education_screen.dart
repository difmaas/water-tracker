import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Education article list screen — stub for F-01.
/// Actual implementation in F-09.
class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Education')),
      body: const Center(child: Text('Education Screen')),
    );
  }
}
