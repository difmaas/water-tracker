import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../providers/hydration_provider.dart';

class TargetAchievedSheet extends StatelessWidget {
  final HydrationState state;
  final bool lightweightMode;

  const TargetAchievedSheet({
    super.key,
    required this.state,
    this.lightweightMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final illustrationAsset = state.jenisKelamin == 'laki_laki'
        ? 'assets/images/target_achieve_man.webp'
        : 'assets/images/target_achieve_woman.webp';

    return SafeArea(
      top: false,
      bottom: false,
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.48,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: lightweightMode
              ? _SheetContent(
                  illustrationAsset: illustrationAsset,
                  lightweightMode: true,
                )
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: _SheetContent(
                    illustrationAsset: illustrationAsset,
                    lightweightMode: false,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SheetContent extends StatelessWidget {
  final String illustrationAsset;
  final bool lightweightMode;

  const _SheetContent({
    required this.illustrationAsset,
    required this.lightweightMode,
  });

  @override
  Widget build(BuildContext context) {
    if (lightweightMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
        decoration: const BoxDecoration(
          color: Color(0xFFD7E5FF),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: 124,
                height: 124,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/bullseye.svg',
                    width: 90,
                    height: 90,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Target hari ini tercapai',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Text(
                  'Kebutuhan cairan hari ini sudah terpenuhi.\nPertahankan kebiasaan baik ini, ya.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF111827),
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 6),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.94),
            Colors.white.withValues(alpha: 0.86),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: 230,
                height: 230,
                child: Image.asset(illustrationAsset, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'Target hari ini tercapai',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kamu sudah mencapai kebutuhan hidrasi hari ini. Pertahankan kebiasaan baik ini ya!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
