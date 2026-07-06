import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/hydration_provider.dart';

// Global variable to persist the progress across widget unmounts (tab switches)
double? _persistedPreviousProgress;

class ProgressRing extends ConsumerStatefulWidget {
  final bool lightweightMode;

  const ProgressRing({super.key, this.lightweightMode = false});

  @override
  ConsumerState<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends ConsumerState<ProgressRing> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydrationProvider);

    if (state.isLoading) {
      return const SizedBox(
        height: 320,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
        ),
      );
    }

    final double beginProgress =
        _persistedPreviousProgress ?? state.progressPercent;
    _persistedPreviousProgress = state.progressPercent;
    final double endProgress = state.progressPercent;

    String formatVolume(int volume) {
      final value = volume.toString();
      if (value.length > 3) {
        return '${value.substring(0, value.length - 3)}.${value.substring(value.length - 3)}';
      }
      return value;
    }

    String progressStatus() {
      if (state.todayLogs.isEmpty && state.currentMl == 0) {
        return 'Belum ada catatan';
      }
      if (state.isTargetReached) {
        return 'Target tercapai';
      }
      if (state.progressPercent >= 0.8) {
        return 'Sedikit lagi';
      }
      return 'Masih perlu ditambah';
    }

    final cardWidget = LayoutBuilder(
      builder: (context, constraints) {
        final double ringSize = math.min(270.0, constraints.maxWidth - 40);
        final double mainFontSize = ringSize < 240 ? 44 : 54;
        final double subFontSize = ringSize < 240 ? 13 : 15;
        final double statusFontSize = ringSize < 240 ? 11 : 12;

        return Container(
          width: double.infinity,
          height: ringSize + 70,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: widget.lightweightMode
                ? const Color(0xFFFFFFFF)
                : Colors.white.withValues(alpha: 0.78),
            gradient: widget.lightweightMode
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.82),
                      Colors.white.withValues(alpha: 0.58),
                    ],
                  ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: widget.lightweightMode
                  ? const Color(0xFFE2E8F0)
                  : Colors.white.withValues(alpha: 0.72),
              width: widget.lightweightMode ? 1.0 : 1.2,
            ),
            boxShadow: widget.lightweightMode
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(6, 10),
                    ),
                  ],
          ),
          child: Center(
            child: SizedBox(
              width: ringSize,
              height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: beginProgress,
                      end: endProgress,
                    ),
                    duration: widget.lightweightMode
                        ? Duration.zero
                        : const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, animProgress, child) {
                      return CustomPaint(
                        size: Size(ringSize, ringSize),
                        painter: _RingPainter(
                          progress: animProgress,
                          strokeWidth: ringSize < 240 ? 18 : 22,
                          lightweightMode: widget.lightweightMode,
                        ),
                      );
                    },
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: beginProgress,
                      end: endProgress,
                    ),
                    duration: widget.lightweightMode
                        ? Duration.zero
                        : const Duration(milliseconds: 1200),
                    curve: Curves.easeOutCubic,
                    builder: (context, animProgress, child) {
                      final percent = (animProgress * 100).toInt();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percent%',
                            style: GoogleFonts.manrope(
                              fontSize: mainFontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatVolume(state.currentMl)} ml',
                            style: GoogleFonts.manrope(
                              fontSize: subFontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.black.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            progressStatus(),
                            style: GoogleFonts.manrope(
                              fontSize: statusFontSize,
                              fontWeight: FontWeight.normal,
                              color: Colors.black.withValues(alpha: 0.55),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.lightweightMode) {
      return cardWidget;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: cardWidget,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double strokeWidth;
  final bool lightweightMode;

  _RingPainter({
    required this.progress,
    this.strokeWidth = 20.0,
    this.lightweightMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Draw track background
    final trackPaint = Paint()
      ..color = lightweightMode
          ? const Color(0xFFE2E8F0)
          : Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw 3D Glass Pipe Frames (Thin concentric white outlines) - skip in lightweightMode
    if (!lightweightMode) {
      final glassOutlinePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawCircle(center, radius + (strokeWidth / 2), glassOutlinePaint);
      canvas.drawCircle(center, radius - (strokeWidth / 2), glassOutlinePaint);
    }

    // 3. Draw active progress arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = lightweightMode
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A73E8).withValues(alpha: 0.70),
                  const Color(0xFF1A73E8).withValues(alpha: 0.20),
                ],
              ).createShader(rect);

      if (lightweightMode) {
        activePaint.color = const Color(0xFF1A73E8);
      }

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        activePaint,
      );

      // 4. Draw Glowing Orbiting Indicator Dot at the end of the progress arc
      final double angle =
          -math.pi / 2 + 2 * math.pi * progress.clamp(0.0, 1.0);
      final double dotX = center.dx + radius * math.cos(angle);
      final double dotY = center.dy + radius * math.sin(angle);
      final Offset dotCenter = Offset(dotX, dotY);

      if (!lightweightMode) {
        final dotGlow = Paint()
          ..color = const Color(0xFF1A73E8).withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawCircle(dotCenter, 8.0, dotGlow);
      }

      // Inner White Core
      final dotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dotCenter, 4.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.lightweightMode != lightweightMode;
  }
}
