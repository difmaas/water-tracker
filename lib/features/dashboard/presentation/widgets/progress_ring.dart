import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/hydration_provider.dart';

// Global variable to persist the progress across widget unmounts (tab switches)
double? _persistedPreviousProgress;

class ProgressRing extends ConsumerStatefulWidget {
  const ProgressRing({super.key});

  @override
  ConsumerState<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends ConsumerState<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  String _formatVolume(int volume) {
    final value = volume.toString();
    if (value.length > 3) {
      return '${value.substring(0, value.length - 3)}.${value.substring(value.length - 3)}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydrationProvider);

    if (state.isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A73E8)),
        ),
      );
    }

    final isReached = state.isTargetReached;

    if (!_waveController.isAnimating) {
      _waveController.repeat();
    }

    final double beginProgress =
        _persistedPreviousProgress ?? state.progressPercent;
    _persistedPreviousProgress = state.progressPercent;
    final double endProgress = state.progressPercent;

    final currentMl = state.currentMl;
    final targetMl = state.targetMl;
    final remainingMl = state.remainingMl;

    String mainText = '';
    String subText = '';
    Color subTextColor = const Color(0xFF6B7280);

    if (currentMl == 0) {
      mainText = 'Belum ada catatan hari ini';
      subText = 'Mulai dengan segelas air';
    } else if (currentMl >= targetMl) {
      mainText = '${_formatVolume(currentMl)} / ${_formatVolume(targetMl)} ml';
      subText = currentMl == targetMl
          ? 'Target hari ini tercapai'
          : 'Target tercapai';
      subTextColor = const Color(0xFF34A853); // Success green
    } else if (targetMl - currentMl <= 250) {
      mainText = '${_formatVolume(currentMl)} / ${_formatVolume(targetMl)} ml';
      subText = 'Sedikit lagi, kurang ${_formatVolume(remainingMl)} ml';
      subTextColor = const Color(0xFF1A73E8); // Highlight with primary blue
    } else {
      mainText = '${_formatVolume(currentMl)} / ${_formatVolume(targetMl)} ml';
      subText = 'Kurang ${_formatVolume(remainingMl)} ml lagi';
    }

    final percentText = '${(state.progressPercent * 100).toInt()}% tercapai';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F4FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Optional Small Badge at the top right of the card
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isReached
                    ? const Color(0xFFEBF8EE) // Success green bg
                    : const Color(0xFFE8F4FF), // Soft blue bg
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                percentText,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isReached
                      ? const Color(0xFF34A853)
                      : const Color(0xFF1A73E8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 2. Large Water Glass Graphic
          SizedBox(
            height: 180,
            width: double.infinity,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: beginProgress, end: endProgress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, animProgress, child) {
                return AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _WaterGlassPainter(
                        progress: animProgress,
                        wavePhase: _waveController.value * 2 * math.pi,
                        isReached: isReached,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // 3. Main Text (Today's total intake)
          Text(
            mainText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),

          // 4. Subtext (Remaining amount status)
          Text(
            subText,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaterGlassPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double wavePhase;
  final bool isReached;

  _WaterGlassPainter({
    required this.progress,
    required this.wavePhase,
    required this.isReached,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;
    final double w = 110.0; // glass top width
    final double h = 160.0; // glass height

    // Glass path (outer outline)
    final glassPath = Path();
    glassPath.moveTo(cx - w / 2, cy - h / 2);
    glassPath.lineTo(cx - w * 0.4, cy + h / 2 - 8);
    // bottom rounded curve
    glassPath.quadraticBezierTo(
      cx,
      cy + h / 2 + 2,
      cx + w * 0.4,
      cy + h / 2 - 8,
    );
    glassPath.lineTo(cx + w / 2, cy - h / 2);

    // Water level path (clipped inside the glass)
    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress > 0.0) {
      canvas.save();
      canvas.clipPath(glassPath);

      // water height goes from bottom (cy + h / 2) to top (cy - h / 2)
      final double waterTopY = (cy + h / 2) - (clampedProgress * h * 0.9);
      final waterPath = Path();
      waterPath.moveTo(cx - w, cy + h);
      waterPath.lineTo(cx - w, waterTopY);

      // Waves on top of water surface
      for (double x = cx - w; x <= cx + w; x += 4) {
        final double waveHeight = (1.0 - clampedProgress) * 5.0 + 1.5;
        final double y =
            waterTopY + waveHeight * math.sin((x / 14) + wavePhase);
        waterPath.lineTo(x, y);
      }
      waterPath.lineTo(cx + w, cy + h);
      waterPath.close();

      // Cyan to Blue water gradient
      final waterPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isReached
              ? [
                  const Color(0xFF34A853), // Success green
                  const Color(0xFF2E7D32),
                ]
              : [
                  const Color(0xFF4FC3F7), // Cyan accent
                  const Color(0xFF1A73E8), // Primary blue
                ],
        ).createShader(Rect.fromLTWH(cx - w / 2, waterTopY, w, h));

      canvas.drawPath(waterPath, waterPaint);

      // Rising Bubbles inside the water
      final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
      for (int i = 0; i < 6; i++) {
        final double bubbleX = cx + (math.sin(wavePhase * 0.8 + i) * w * 0.22);
        double bubbleY =
            (cy + h / 2) -
            (((wavePhase * 15 + i * 30) % (h * clampedProgress * 0.9)));
        if (bubbleY < waterTopY) continue;
        final double radius = (i % 2 + 2.0);
        canvas.drawCircle(Offset(bubbleX, bubbleY), radius, bubblePaint);
      }

      canvas.restore();
    }

    // Glass outline stroke
    final glassOutlinePaint = Paint()
      ..color = const Color(0xFF1A73E8).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(glassPath, glassOutlinePaint);

    // Glass highlight reflection
    final highlightPath = Path();
    highlightPath.moveTo(cx - w / 2 + 8, cy - h / 2 + 10);
    highlightPath.lineTo(cx - w * 0.4 + 6, cy + h / 2 - 15);
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(highlightPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant _WaterGlassPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isReached != isReached;
  }
}
