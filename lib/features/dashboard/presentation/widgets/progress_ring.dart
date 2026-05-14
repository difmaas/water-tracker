import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../../providers/hydration_provider.dart';

class ProgressRing extends ConsumerWidget {
  const ProgressRing({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hydrationProvider);

    if (state.isLoading) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isReached = state.isTargetReached;
    final color = isReached ? Colors.green : const Color(0xFF1A73E8); // AppColors.primary

    return CircularPercentIndicator(
      radius: 120.0,
      lineWidth: 14.0,
      animation: true,
      animationDuration: 500,
      percent: state.progressPercent,
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: color,
      backgroundColor: color.withOpacity(0.1),
      center: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${state.currentMl}ml',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(state.progressPercent * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: isReached
            ? const Text(
                '🎉 Target tercapai!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              )
            : Text(
                '${state.remainingMl}ml lagi',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
