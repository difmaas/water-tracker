import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../providers/app_settings_provider.dart';

const _kLightweightCategoryStyles = {
  'sains': (
    topColor: Color(0xFFD4E7FF),
    bottomColor: Color(0xFFD4E7FF),
    textColor: Color(0xFF0F172A),
  ),
  'fakta_unik': (
    topColor: Color(0xFF83BBF4),
    bottomColor: Color(0xFF83BBF4),
    textColor: Color(0xFF0F172A),
  ),
  'kesehatan': (
    topColor: Color(0xFF4776E8),
    bottomColor: Color(0xFF4776E8),
    textColor: Colors.white,
  ),
};

const _kCategoryStyles = {
  'sains': (
    color: Color(0xFFEAF5FF),
    chipBg: Colors.white,
    fg: Color(0xFF1565C0),
  ),
  'fakta_unik': (
    color: Color(0xFFFEFCE8),
    chipBg: Colors.white,
    fg: Color(0xFF854D0E),
  ),
  'kesehatan': (
    color: Color(0xFFECFDF5),
    chipBg: Colors.white,
    fg: Color(0xFF047857),
  ),
};

class ArticleCard extends ConsumerStatefulWidget {
  final HydrationArticle article;
  final VoidCallback onTap;
  final bool isFeatured;

  const ArticleCard({
    super.key,
    required this.article,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  ConsumerState<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends ConsumerState<ArticleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    if (lightweightMode) {
      final lwStyle =
          _kLightweightCategoryStyles[widget.article.category.toLowerCase()] ??
          _kLightweightCategoryStyles['sains']!;

      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 165,
            height: 240,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: lwStyle.bottomColor,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Emoji Bubble
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: lwStyle.textColor.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      widget.article.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const Spacer(),
                // Title Text
                Text(
                  widget.article.title,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: lwStyle.textColor,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),
                // Bottom Row: Clean Read Time Label
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: lwStyle.textColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '1 menit baca',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: lwStyle.textColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final style =
        _kCategoryStyles[widget.article.category.toLowerCase()] ??
        _kCategoryStyles['sains']!;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: lightweightMode
            ? style.color
            : Colors.white.withValues(alpha: 0.78),
        gradient: lightweightMode
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.82),
                  Colors.white.withValues(alpha: 0.58),
                ],
              ),
        borderRadius: BorderRadius.circular(16),
        border: lightweightMode
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: 1.2,
              ),
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.isFeatured ? 32 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: lightweightMode
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: lightweightMode
                          ? style.color.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _categoryLabel(widget.article.category),
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: style.fg,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  widget.article.emoji,
                  style: GoogleFonts.manrope(
                    fontSize: widget.isFeatured ? 32 : 24,
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.isFeatured ? 32 : 20),
            Text(
              widget.article.title,
              style: GoogleFonts.manrope(
                fontSize: widget.isFeatured ? 24 : 20,
                fontWeight: FontWeight.normal,
                color: style.fg,
                height: 1.25,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.article.summary,
              maxLines: widget.isFeatured ? 4 : 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.normal,
                color: lightweightMode
                    ? style.fg.withValues(alpha: 0.8)
                    : style.fg.withValues(alpha: 0.7),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: lightweightMode
                      ? style.fg.withValues(alpha: 0.7)
                      : style.fg.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 6),
                Text(
                  '1 menit baca',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: lightweightMode
                        ? style.fg.withValues(alpha: 0.7)
                        : style.fg.withValues(alpha: 0.5),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: lightweightMode
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: lightweightMode
                          ? style.fg.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.55),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: style.fg,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: lightweightMode
                ? style.color
                : Colors.white.withValues(alpha: 0.78),
            border: lightweightMode
                ? Border.all(
                    color: style.fg.withValues(alpha: 0.15),
                    width: 1.0,
                  )
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.72),
                    width: 1.2,
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: lightweightMode
                ? const []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(6, 10),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: lightweightMode
                ? cardContent
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: cardContent,
                  ),
          ),
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'sains':
        return 'Sains';
      case 'fakta_unik':
        return 'Fakta unik';
      case 'kesehatan':
        return 'Kesehatan';
      default:
        return category;
    }
  }
}
