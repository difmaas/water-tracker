import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../providers/reminder_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _bubbleController;
  double _pageOffset = 0.0;
  bool _isLastPage = false;

  @override
  void initState() {
    super.initState();
    // Continuous loop for floating background bubbles
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _pageOffset = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _bubbleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    await ref.read(reminderServiceProvider).requestPermissions();
  }

  Future<void> _finishOnboarding(bool requestNotif) async {
    if (requestNotif) {
      await _requestPermission();
    }
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/profile-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Background #F8FBFF
      body: Stack(
        children: [
          // Dynamic Water background with soft gradients and bubbles
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bubbleController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _OnboardingBackgroundPainter(
                    pageOffset: _pageOffset,
                    bubblePhase: _bubbleController.value * 2 * math.pi,
                  ),
                );
              },
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: AnimatedOpacity(
                      opacity: _isLastPage ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _isLastPage
                            ? null
                            : () => _pageController.animateToPage(
                                2,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOut,
                              ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(
                            0xFF1A73E8,
                          ).withValues(alpha: 0.8),
                        ),
                        child: Text(
                          'Lewati',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Onboarding Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _isLastPage = index == 2;
                      });
                    },
                    children: [
                      // Page 1
                      _buildPage(
                        context,
                        illustration: const _WaterDropIllustration(),
                        headline: 'Bangun kebiasaan minum air',
                        body:
                            'SEHATI membantumu mengingat minum air dengan cara yang sederhana.',
                      ),
                      // Page 2
                      _buildPage(
                        context,
                        illustration: const _StepFlowIllustration(),
                        headline: 'Pantau progres harianmu',
                        body:
                            'Lihat berapa banyak air yang sudah kamu minum hari ini.',
                      ),
                      // Page 3
                      _buildPage(
                        context,
                        illustration: const _NotificationBellIllustration(),
                        headline: 'Atur pengingat sesuai rutinitas',
                        body:
                            'Pilih waktu yang nyaman agar pengingat tidak mengganggu aktivitasmu.',
                      ),
                    ],
                  ),
                ),

                // Bottom Pill controls / actions
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    bottom: 40,
                    top: 16,
                  ),
                  child: Column(
                    children: [
                      if (!_isLastPage) ...[
                        SmoothPageIndicator(
                          controller: _pageController,
                          count: 3,
                          effect: ExpandingDotsEffect(
                            dotHeight: 8,
                            dotWidth: 8,
                            spacing: 8,
                            activeDotColor: const Color(
                              0xFF1A73E8,
                            ), // Primary #1A73E8
                            dotColor: const Color(
                              0xFF1A73E8,
                            ).withValues(alpha: 0.15),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF1A73E8,
                              ), // Primary
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shadowColor: const Color(
                                0xFF1A73E8,
                              ).withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  16,
                                ), // Rounded buttons
                              ),
                            ),
                            child: Text(
                              'Lanjutkan',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Page 3 Action Buttons (Izinkan Notifikasi, Nanti Saja)
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () => _finishOnboarding(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF1A73E8,
                                  ), // Primary
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: const Color(
                                    0xFF1A73E8,
                                  ).withValues(alpha: 0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Izinkan Notifikasi',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton(
                                onPressed: () => _finishOnboarding(false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1A73E8),
                                  side: const BorderSide(
                                    color: Color(0xFFE8F4FF),
                                    width: 2,
                                  ),
                                  backgroundColor: const Color(
                                    0xFFE8F4FF,
                                  ), // Accent
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  'Nanti Saja',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required Widget illustration,
    required String headline,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Expanded(flex: 5, child: Center(child: illustration)),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(24), // Rounded cards
                border: Border.all(color: const Color(0xFFE8F4FF), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF202124),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.6,
                      color: const Color(0xFF5F6368),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for soft background waves and bubbles
class _OnboardingBackgroundPainter extends CustomPainter {
  final double pageOffset;
  final double bubblePhase;

  _OnboardingBackgroundPainter({
    required this.pageOffset,
    required this.bubblePhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient Background based on page offset
    final double progress = pageOffset.clamp(0.0, 2.0);

    final Color startColor = Color.lerp(
      const Color(0xFFF8FBFF),
      const Color(0xFFE8F4FF),
      progress / 2,
    )!;

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [startColor, const Color(0xFFF8FBFF)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw background bubble/ripple circles
    final ripplePaint = Paint()
      ..color = const Color(0xFF4FC3F7).withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    // Top right ripple
    canvas.drawCircle(
      Offset(
        size.width * 0.9,
        size.height * 0.15 + (math.sin(bubblePhase * 0.3) * 15),
      ),
      80 + (math.cos(bubblePhase * 0.5) * 10),
      ripplePaint,
    );

    // Left bottom ripple
    canvas.drawCircle(
      Offset(
        size.width * 0.1,
        size.height * 0.8 + (math.cos(bubblePhase * 0.4) * 20),
      ),
      110 + (math.sin(bubblePhase * 0.4) * 15),
      ripplePaint,
    );

    // Floating bubble particles
    final bubblePaint = Paint()
      ..color = const Color(0xFF1A73E8).withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      final double x =
          size.width * (0.15 + 0.14 * i) + math.sin(bubblePhase * 0.5 + i) * 10;
      final double y =
          size.height * 0.7 -
          ((bubblePhase * 15 + i * 80) % (size.height * 0.5));
      final double r = 6.0 + (i % 3) * 4;
      if (y > 0 && y < size.height) {
        canvas.drawCircle(Offset(x, y), r, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingBackgroundPainter oldDelegate) {
    return oldDelegate.pageOffset != pageOffset ||
        oldDelegate.bubblePhase != bubblePhase;
  }
}

// Page 1 Visual: Water Drop Illustration
class _WaterDropIllustration extends StatefulWidget {
  const _WaterDropIllustration();

  @override
  State<_WaterDropIllustration> createState() => _WaterDropIllustrationState();
}

class _WaterDropIllustrationState extends State<_WaterDropIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 180),
          painter: _WaterDropPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _WaterDropPainter extends CustomPainter {
  final double progress;

  _WaterDropPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2 + (progress * 8 - 4);
    final double baseRadius = 55.0;

    // Pulse circles behind
    final pulsePaint = Paint()
      ..color = const Color(0xFFE8F4FF)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius + (progress * 16),
      pulsePaint
        ..color = const Color(
          0xFFE8F4FF,
        ).withValues(alpha: 0.4 * (1.0 - progress * 0.5)),
    );
    canvas.drawCircle(
      Offset(cx, cy),
      baseRadius + 6,
      pulsePaint..color = const Color(0xFFE8F4FF).withValues(alpha: 0.6),
    );

    // Water Drop Path
    final dropPath = Path();
    dropPath.moveTo(cx, cy - baseRadius * 1.3);
    dropPath.cubicTo(
      cx + baseRadius * 0.9,
      cy - baseRadius * 0.2,
      cx + baseRadius,
      cy + baseRadius * 0.9,
      cx,
      cy + baseRadius,
    );
    dropPath.cubicTo(
      cx - baseRadius,
      cy + baseRadius * 0.9,
      cx - baseRadius * 0.9,
      cy - baseRadius * 0.2,
      cx,
      cy - baseRadius * 1.3,
    );
    dropPath.close();

    final dropPaint = Paint()
      ..shader =
          const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4FC3F7), Color(0xFF1A73E8)],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: baseRadius),
          );

    canvas.drawPath(dropPath, dropPaint);

    // Sparkle Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromLTWH(cx - baseRadius * 0.45, cy - baseRadius * 0.4, 20, 10),
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaterDropPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Page 2 Visual: Steps Illustration (Profil -> Target -> Pengingat -> Catat Minum -> Riwayat)
class _StepFlowIllustration extends StatelessWidget {
  const _StepFlowIllustration();

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> steps = [
      {'icon': Icons.person, 'label': 'Profil'},
      {'icon': Icons.track_changes, 'label': 'Target'},
      {'icon': Icons.notifications_active, 'label': 'Pengingat'},
      {'icon': Icons.local_drink, 'label': 'Catat'},
      {'icon': Icons.history, 'label': 'Riwayat'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8F4FF), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A73E8).withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Arrow/Connector
            return const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF4FC3F7),
              size: 20,
            );
          }

          final stepIndex = index ~/ 2;
          final step = steps[stepIndex];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F4FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  step['icon'] as IconData,
                  color: const Color(0xFF1A73E8),
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                step['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5F6368),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// Page 3 Visual: Notification Bell with Ripple Waves Illustration
class _NotificationBellIllustration extends StatefulWidget {
  const _NotificationBellIllustration();

  @override
  State<_NotificationBellIllustration> createState() =>
      _NotificationBellIllustrationState();
}

class _NotificationBellIllustrationState
    extends State<_NotificationBellIllustration>
    with SingleTickerProviderStateMixin {
  late AnimationController _bellController;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _bellController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bellController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(180, 180),
          painter: _BellRipplePainter(progress: _bellController.value),
        );
      },
    );
  }
}

class _BellRipplePainter extends CustomPainter {
  final double progress;

  _BellRipplePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Ripple circles
    final ripplePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < 3; i++) {
      final double scale = (progress + i / 3.0) % 1.0;
      final double opacity = 1.0 - scale;
      ripplePaint.color = const Color(
        0xFF4FC3F7,
      ).withValues(alpha: opacity * 0.4);
      canvas.drawCircle(Offset(cx, cy), 35 + (scale * 55), ripplePaint);
    }

    // Glowing circle behind bell
    final glowPaint = Paint()
      ..color = const Color(0xFFE8F4FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 38, glowPaint);

    // Draw Bell
    final bellPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4FC3F7), Color(0xFF1A73E8)],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: 30))
      ..style = PaintingStyle.fill;

    // Draw bell base outline path
    final bellPath = Path();
    bellPath.moveTo(cx - 6, cy - 24);
    bellPath.lineTo(cx + 6, cy - 24);
    bellPath.quadraticBezierTo(cx + 16, cy - 18, cx + 18, cy + 6);
    bellPath.lineTo(cx + 24, cy + 12);
    bellPath.lineTo(cx - 24, cy + 12);
    bellPath.lineTo(cx - 18, cy + 6);
    bellPath.quadraticBezierTo(cx - 16, cy - 18, cx - 6, cy - 24);
    bellPath.close();
    canvas.drawPath(bellPath, bellPaint);

    // Bell Clapper
    final clapperPaint = Paint()
      ..color = const Color(0xFF1A73E8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy + 16), 6, clapperPaint);
  }

  @override
  bool shouldRepaint(covariant _BellRipplePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
