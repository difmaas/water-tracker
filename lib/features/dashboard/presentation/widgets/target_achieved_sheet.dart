import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../providers/hydration_provider.dart';

class TargetAchievedSheet extends StatelessWidget {
  final HydrationState state;

  const TargetAchievedSheet({super.key, required this.state});

  String _formatVolume(int volume) {
    final value = volume.toString();
    if (value.length > 3) {
      return '${value.substring(0, value.length - 3)}.${value.substring(value.length - 3)}';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final isExceeded = state.currentMl > state.targetMl;
    final currentFormatted = _formatVolume(state.currentMl);
    final targetFormatted = _formatVolume(state.targetMl);
    final progressText = '$currentFormatted / $targetFormatted ml';

    final subtitleText = isExceeded
        ? 'Kamu sudah melewati target minum hari ini.'
        : 'Kamu sudah memenuhi target minum air hari ini.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Top drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 28),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Concentric circles with water glass and checklist icons
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer circle (Success light green)
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEBF8EE),
                    shape: BoxShape.circle,
                  ),
                ),
                // Middle circle (Soft blue)
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F4FF),
                    shape: BoxShape.circle,
                  ),
                ),
                // Center circle (Primary blue)
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A73E8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_drink_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                // Checkmark badge overlay at bottom right
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF34A853),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Target Hari Ini Tercapai!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitleText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Progress info box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8F4FF), width: 1.5),
              ),
              child: Center(
                child: Text(
                  progressText,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A73E8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Supportive Message
            Text(
              'Pertahankan kebiasaan baik ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),

            // Primary action: Kembali ke Beranda
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A73E8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Kembali ke Beranda',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Secondary action: Lihat Riwayat
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/progress');
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Lihat Riwayat',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
