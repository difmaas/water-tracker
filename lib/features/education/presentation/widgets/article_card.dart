import 'dart:ui';

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
    color: Color(0xFFA5F3FC),
    chipBg: Colors.white,
    fg: Color(0xFF0E7490),
  ),
  'kesehatan': (
    color: Color(0xFFC7D2FE),
    chipBg: Colors.white,
    fg: Color(0xFF4338CA),
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
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: style.fg.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      style.color.withValues(alpha: 0.45),
                      style.color.withValues(alpha: 0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.55),
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
                              color: Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _categoryLabel(widget.article.category),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.normal,
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
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
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
                              fontWeight: FontWeight.normal,
                              color: style.fg.withValues(alpha: 0.5),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.55),
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
              ),
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
