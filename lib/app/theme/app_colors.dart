import 'package:flutter/material.dart';

/// Centralized color definitions for the Hydration Tracker app.
///
/// Primary: deep blue #1A73E8
/// Background: white
/// Accent: #E8F0FE
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryLight = Color(0xFF4A93F0);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color accent = Color(0xFFE8F0FE);

  // ── Surfaces ───────────────────────────────────────────────────────────
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color card = Colors.white;

  // ── Text ───────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textHint = Color(0xFF9AA0A6);
  static const Color textOnPrimary = Colors.white;

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF34A853);
  static const Color error = Color(0xFFEA4335);
  static const Color warning = Color(0xFFFBBC04);

  // ── Dividers & Borders ─────────────────────────────────────────────────
  static const Color divider = Color(0xFFDADCE0);
  static const Color border = Color(0xFFDADCE0);

  // ── Water-themed gradients ─────────────────────────────────────────────
  static const Color waterLight = Color(0xFFBBDEFB);
  static const Color waterDark = Color(0xFF1565C0);
}
