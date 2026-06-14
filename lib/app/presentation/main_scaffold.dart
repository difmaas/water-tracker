import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_settings_provider.dart';

/// Main scaffold with a persistent bottom navigation bar.
class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );
    final location = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (location.startsWith('/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/progress')) {
      currentIndex = 1;
    } else if (location.startsWith('/education')) {
      currentIndex = 2;
    } else if (location.startsWith('/settings')) {
      currentIndex = 3;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: HydrationBackground(lightweightMode: lightweightMode),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          extendBody: !lightweightMode,
          body: child,
          bottomNavigationBar: lightweightMode
              ? Container(
                  color: Colors.transparent,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
                        ),
                      ),
                      child: _BottomNavSurface(
                        currentIndex: currentIndex,
                        lightweightMode: true,
                      ),
                    ),
                  ),
                )
              : SafeArea(
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 16,
                      top: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: _BottomNavSurface(
                          currentIndex: currentIndex,
                          lightweightMode: false,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _BottomNavSurface extends StatelessWidget {
  final int currentIndex;
  final bool lightweightMode;

  const _BottomNavSurface({
    required this.currentIndex,
    required this.lightweightMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: lightweightMode
            ? Colors.transparent
            : Colors.white.withValues(alpha: 0.45),
        borderRadius: lightweightMode
            ? BorderRadius.zero
            : BorderRadius.circular(30),
        border: lightweightMode
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final tabWidth = totalWidth / 4;
          final double indicatorHeight = lightweightMode ? 3.0 : 44.0;
          final double indicatorWidth = lightweightMode
              ? 20.0
              : tabWidth - 24.0;
          final double topMargin = lightweightMode
              ? 64.0
              : (72.0 - indicatorHeight) / 2;
          final double leftOffset = lightweightMode
              ? currentIndex * tabWidth + (tabWidth - indicatorWidth) / 2
              : currentIndex * tabWidth + 12.0;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: lightweightMode
                    ? const Duration(milliseconds: 150)
                    : const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                left: leftOffset,
                top: topMargin,
                width: indicatorWidth,
                height: indicatorHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: lightweightMode
                        ? const Color(0xFF1A73E8)
                        : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(
                      lightweightMode ? 1.5 : 20,
                    ),
                    border: lightweightMode
                        ? null
                        : Border.all(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                    boxShadow: lightweightMode
                        ? const []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      index: 0,
                      currentIndex: currentIndex,
                      svgPath: 'assets/icons/dashboard.svg',
                      label: 'Beranda',
                      route: '/dashboard',
                      lightweightMode: lightweightMode,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      index: 1,
                      currentIndex: currentIndex,
                      svgPath: 'assets/icons/history.svg',
                      label: 'Riwayat',
                      route: '/progress',
                      lightweightMode: lightweightMode,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      index: 2,
                      currentIndex: currentIndex,
                      svgPath: 'assets/icons/education.svg',
                      label: 'Tips',
                      route: '/education',
                      lightweightMode: lightweightMode,
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      index: 3,
                      currentIndex: currentIndex,
                      svgPath: 'assets/icons/settings.svg',
                      label: 'Pengaturan',
                      route: '/settings',
                      lightweightMode: lightweightMode,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final String svgPath;
  final String label;
  final String route;
  final bool lightweightMode;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.svgPath,
    required this.label,
    required this.route,
    required this.lightweightMode,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => context.go(route),
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Tooltip(
          message: label,
          preferBelow: false,
          child: AnimatedScale(
            scale: lightweightMode ? 1.0 : (isSelected ? 1.08 : 1.0),
            duration: lightweightMode
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: SvgPicture.asset(
              svgPath,
              colorFilter: ColorFilter.mode(
                isSelected
                    ? const Color(0xFF1A73E8)
                    : (lightweightMode
                          ? const Color(0xFF64748B)
                          : const Color(0xFF4A5568)),
                BlendMode.srcIn,
              ),
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class HydrationBackground extends StatelessWidget {
  final bool lightweightMode;

  const HydrationBackground({super.key, this.lightweightMode = false});

  @override
  Widget build(BuildContext context) {
    const decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFBBE5FF), Color(0xFFF2F8FD), Color(0xFFE5F1FA)],
        stops: [0.0, 0.5, 1.0],
      ),
    );

    if (lightweightMode) {
      return const DecoratedBox(
        decoration: BoxDecoration(color: Color(0xFFFAF9F5)),
      );
    }

    return const DecoratedBox(
      decoration: decoration,
      child: CustomPaint(painter: _HydrationBackgroundPainter()),
    );
  }
}

class _HydrationBackgroundPainter extends CustomPainter {
  const _HydrationBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final topLeftShapePath = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.24)
      ..cubicTo(
        size.width * 0.15,
        size.height * 0.28,
        size.width * 0.22,
        size.height * 0.14,
        size.width * 0.35,
        size.height * 0.16,
      )
      ..cubicTo(
        size.width * 0.42,
        size.height * 0.18,
        size.width * 0.48,
        size.height * 0.06,
        size.width * 0.52,
        0,
      )
      ..close();

    final topLeftShapePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFC8EEFF).withValues(alpha: 0.60),
          const Color(0xFFADDFFF).withValues(alpha: 0.10),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.52, size.height * 0.28))
      ..style = PaintingStyle.fill;
    canvas.drawPath(topLeftShapePath, topLeftShapePaint);

    final cornerPaint = Paint()
      ..shader =
          RadialGradient(
            center: Alignment.topRight,
            radius: 1.0,
            colors: [
              const Color(0xFFADDFFF).withValues(alpha: 0.8),
              const Color(0xFFC8EEFF).withValues(alpha: 0.3),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(
            Rect.fromLTRB(size.width * 0.60, 0, size.width, size.height * 0.20),
          )
      ..style = PaintingStyle.fill;

    final cornerPath = Path()
      ..moveTo(size.width * 0.72, 0)
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.08,
        size.width * 0.92,
        size.height * 0.12,
        size.width,
        size.height * 0.14,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(cornerPath, cornerPaint);

    final bubblePaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.25),
              const Color(0xFF90CAF9).withValues(alpha: 0.10),
              Colors.transparent,
            ],
            stops: const [0.0, 0.7, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.15, size.height * 0.22),
              radius: size.width * 0.08,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.22),
      size.width * 0.08,
      bubblePaint,
    );

    final blobPaint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFF7EC8E3).withValues(alpha: 0.35),
              const Color(0xFF90CAF9).withValues(alpha: 0.15),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.20, size.height * 0.35),
              radius: size.width * 0.28,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.20, size.height * 0.35),
      size.width * 0.28,
      blobPaint,
    );

    _drawWave(
      canvas,
      size,
      top: 0.76,
      control1: const Offset(0.28, 0.72),
      control2: const Offset(0.65, 0.84),
      end: const Offset(1.0, 0.78),
      colors: [
        const Color(0xFFADDFFF).withValues(alpha: 0.18),
        const Color(0xFF90CAF9).withValues(alpha: 0.35),
      ],
    );
    _drawWave(
      canvas,
      size,
      top: 0.83,
      control1: const Offset(0.32, 0.85),
      control2: const Offset(0.68, 0.76),
      end: const Offset(1.0, 0.83),
      colors: [
        const Color(0xFF95CBFF).withValues(alpha: 0.28),
        const Color(0xFF64B5F6).withValues(alpha: 0.50),
      ],
    );
    _drawWave(
      canvas,
      size,
      top: 0.90,
      control1: const Offset(0.35, 0.88),
      control2: const Offset(0.65, 0.96),
      end: const Offset(1.0, 0.91),
      colors: [
        const Color(0xFF1E88E5).withValues(alpha: 0.78),
        const Color(0xFF0D47A1).withValues(alpha: 0.90),
      ],
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size, {
    required double top,
    required Offset control1,
    required Offset control2,
    required Offset end,
    required List<Color> colors,
  }) {
    final path = Path()
      ..moveTo(0, size.height * top)
      ..cubicTo(
        size.width * control1.dx,
        size.height * control1.dy,
        size.width * control2.dx,
        size.height * control2.dy,
        size.width * end.dx,
        size.height * end.dy,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ).createShader(
            Rect.fromLTWH(
              0,
              size.height * (top - 0.06),
              size.width,
              size.height,
            ),
          )
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HydrationBackgroundPainter oldDelegate) {
    return false;
  }
}
