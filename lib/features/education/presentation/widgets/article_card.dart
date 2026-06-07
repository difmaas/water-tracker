import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';

const _kCategoryStyles = {
  'sains': (
    color: Color(0xFFBDDDFD),
    chipBg: Colors.white,
    fg: Color(0xFF1565C0),
  ),
  'fakta_unik': (
    color: Color(0xFFFFE194),
    chipBg: Colors.white,
    fg: Color(0xFF795548),
  ),
  'kesehatan': (
    color: Color(0xFFC4E8C2),
    chipBg: Colors.white,
    fg: Color(0xFF2E7D32),
  ),
};

class ArticleCard extends StatefulWidget {
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
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final style =
        _kCategoryStyles[widget.article.category.toLowerCase()] ??
        _kCategoryStyles['sains']!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          margin: EdgeInsets.only(bottom: widget.isFeatured ? 24 : 16),
          decoration: BoxDecoration(
            color: style.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: style.fg.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
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
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _categoryLabel(widget.article.category),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: style.fg,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Text(
                      widget.article.emoji,
                      style: GoogleFonts.inter(
                        fontSize: widget.isFeatured ? 32 : 24,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: widget.isFeatured ? 32 : 20),
                Text(
                  widget.article.title,
                  style: GoogleFonts.inter(
                    fontSize: widget.isFeatured ? 24 : 20,
                    fontWeight: FontWeight.w900,
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
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: style.fg.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: style.fg.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '2 menit baca',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: style.fg.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
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
        ),
      ),
    );
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'sains':
        return 'Sains';
      case 'fakta_unik':
        return 'Fakta Unik';
      case 'kesehatan':
        return 'Kesehatan';
      default:
        return category;
    }
  }
}
