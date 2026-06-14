import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

/// Reusable app button following the SEHATI design system.
///
/// Features:
/// 1. Main style (Filled, Primary Color)
/// 2. Secondary style (Outlined, Primary Color Border & Text)
/// 3. Normal font style (not all caps)
/// 4. Integrated loading spinner
/// 5. Optional Icon prefix support
/// 6. Custom color support (for destructive/warning states)
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSecondary;
  final bool isLoading;
  final Color? color;
  final bool isTransparent;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
    this.isLoading = false,
    this.color,
    this.isTransparent = false,
  });

  const AppButton.main({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
  }) : isSecondary = false,
       isTransparent = false;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.color,
    this.isTransparent = false,
  }) : isSecondary = true;

  @override
  Widget build(BuildContext context) {
    final primaryColor = color ?? AppColors.primary;

    if (isSecondary) {
      final Color secondaryBgColor;
      final Color secondaryFgColor;

      if (color != null) {
        secondaryBgColor = isTransparent
            ? Colors.transparent
            : color!.withValues(alpha: 0.08);
        secondaryFgColor = color!;
      } else {
        secondaryBgColor = isTransparent
            ? Colors.transparent
            : const Color(0xFFF1F3F4);
        secondaryFgColor = AppColors.primary;
      }

      return OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: secondaryBgColor,
          foregroundColor: secondaryFgColor,
          side: BorderSide(
            color: isTransparent ? secondaryFgColor : secondaryBgColor,
            width: 1.2,
          ),
          elevation: isTransparent ? 0 : 2,
          shadowColor: isTransparent
              ? Colors.transparent
              : secondaryFgColor.withValues(alpha: 0.12),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: secondaryFgColor,
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      );
    } else {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade200,
          disabledForegroundColor: Colors.grey.shade400,
          elevation: 6,
          shadowColor: primaryColor.withValues(alpha: 0.35),
          side: BorderSide(color: primaryColor, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(label),
      );
    }
  }
}
