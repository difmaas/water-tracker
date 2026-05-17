import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/hydration_provider.dart';

class ProgressRing extends ConsumerStatefulWidget {
  const ProgressRing({super.key});

  @override
  ConsumerState<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends ConsumerState<ProgressRing> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // Continuous 2-second loop for waves
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hydrationProvider);

    if (state.isLoading) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isReached = state.isTargetReached;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Beautiful glass outer vessel container
        Container(
          width: 250,
          height: 250,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              // Premium ambient fluid neon glow
              BoxShadow(
                color: (isReached ? const Color(0xFF66BB6A) : const Color(0xFF00B0FF))
                    .withValues(alpha: 0.12),
                blurRadius: 40,
                spreadRadius: 8,
              ),
              // Soft elegant card drop shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Liquid Waves Painter driven by AnimationController (for continuous waves)
              // and TweenAnimationBuilder (for smooth rising water levels)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: state.progressPercent),
                duration: const Duration(milliseconds: 1400),
                curve: Curves.easeOutCubic, // Silky smooth fluid rising
                builder: (context, animProgress, child) {
                  return AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        size: const Size(226, 226),
                        painter: _LiquidWavePainter(
                          progress: animProgress,
                          wavePhase: _waveController.value * 2 * math.pi,
                          isReached: isReached,
                        ),
                      );
                    },
                  );
                },
              ),

              // Central Floating Frosted Glass Card showing hydration stats
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: Container(
                    width: 136,
                    height: 136,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.68),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.water_drop_rounded,
                          size: 25,
                          color: isReached ? const Color(0xFF43A047) : const Color(0xFF00B0FF),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${state.currentMl}',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: isReached ? const Color(0xFF2E7D32) : const Color(0xFF1565C0),
                            letterSpacing: -1.2,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          'ml',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: (isReached ? const Color(0xFF2E7D32) : const Color(0xFF1565C0)).withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Target ${state.targetMl} ml',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Interactive dynamic status badge
        isReached
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '🎉',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Target Terpenuhi!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade100, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_drink_rounded,
                      size: 16,
                      color: Color(0xFF2979FF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kurang ${state.remainingMl} ml lagi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}

// ── Organic Liquid Wave & Frosted Glass Vessel Painter ───────────────────────

class _LiquidWavePainter extends CustomPainter {
  final double progress; // 0.0 to 1.0+ (water level height)
  final double wavePhase; // Driving force of continuous fluid animation
  final bool isReached;

  _LiquidWavePainter({
    required this.progress,
    required this.wavePhase,
    required this.isReached,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Create clip path to keep water completely bound inside the circle sphere
    final clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.save();
    canvas.clipPath(clipPath);

    // Very soft interior dark tint
    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.015);
    canvas.drawCircle(center, radius, bgPaint);

    // Calculate water level height
    // progress = 0.0 -> y = size.height (empty)
    // progress = 1.0 -> y = 0 (full)
    // Bound the visual wave heights slightly at extremums for natural styling
    final double waterLevel = size.height * (1.0 - progress.clamp(0.02, 0.98));

    // Dynamic wave parameters
    final double waveHeight1 = 8.0; // Front amplitude
    final double waveHeight2 = 6.0; // Back amplitude
    final double waveLength1 = size.width * 0.85;
    final double waveLength2 = size.width * 1.25;

    // ── Paint 1: Back Wave (Deeper shaded liquid layer) ──────────────────────
    final backWavePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isReached
            ? [
                const Color(0xFF81C784).withValues(alpha: 0.55),
                const Color(0xFF2E7D32).withValues(alpha: 0.75),
              ]
            : [
                const Color(0xFF00B0FF).withValues(alpha: 0.5),
                const Color(0xFF1565C0).withValues(alpha: 0.72),
              ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final backPath = Path();
    backPath.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = waterLevel +
          waveHeight2 * math.sin((2 * math.pi / waveLength2) * x + wavePhase + math.pi);
      backPath.lineTo(x, y);
    }
    backPath.lineTo(size.width, size.height);
    backPath.close();
    canvas.drawPath(backPath, backWavePaint);

    // ── Paint 2: Front Wave (Bright active fluid layer) ──────────────────────
    final frontWavePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isReached
            ? [
                const Color(0xFFA5D6A7).withValues(alpha: 0.85),
                const Color(0xFF4CAF50).withValues(alpha: 0.95),
              ]
            : [
                const Color(0xFF80DEEA).withValues(alpha: 0.82),
                const Color(0xFF00ACC1).withValues(alpha: 0.92),
              ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final frontPath = Path();
    frontPath.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      final y = waterLevel +
          waveHeight1 * math.sin((2 * math.pi / waveLength1) * x + wavePhase);
      frontPath.lineTo(x, y);
    }
    frontPath.lineTo(size.width, size.height);
    frontPath.close();
    canvas.drawPath(frontPath, frontWavePaint);

    // ── Paint 3: Micro-Bubbles (Translucent rising air beads) ────────────────
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;

    // Bubbles dynamically floating upwards based on continuous wave phase
    final bubbles = [
      Offset(size.width * 0.22, waterLevel + 35 + 25 * math.sin(wavePhase * 0.9)),
      Offset(size.width * 0.44, waterLevel + 55 + 18 * math.cos(wavePhase * 1.1)),
      Offset(size.width * 0.68, waterLevel + 20 + 15 * math.sin(wavePhase + 2.5)),
      Offset(size.width * 0.82, waterLevel + 45 + 22 * math.cos(wavePhase * 0.7)),
    ];

    for (final b in bubbles) {
      if (b.dy < size.height && b.dy > waterLevel) {
        canvas.drawCircle(b, 3.2, bubblePaint);
      }
    }

    canvas.restore(); // Stop clipping

    // ── Paint 4: Frosted Glass Edge Highlight (3D Curved Rim) ────────────────
    final glassRimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.45),
        ],
        stops: const [0.0, 0.35, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, glassRimPaint);

    // ── Paint 5: Glossy Curved Glare (Apple Glass Sphere Glare) ─────────────
    final glossPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.24),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final glossPath = Path();
    glossPath.moveTo(center.dx - radius * 0.8, center.dy - radius * 0.4);
    glossPath.quadraticBezierTo(
      center.dx,
      center.dy - radius * 0.15,
      center.dx + radius * 0.8,
      center.dy - radius * 0.4,
    );
    glossPath.arcToPoint(
      Offset(center.dx - radius * 0.8, center.dy - radius * 0.4),
      radius: Radius.circular(radius),
      clockwise: false,
    );
    glossPath.close();
    canvas.drawPath(glossPath, glossPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.isReached != isReached;
  }
}
