import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/presentation/main_scaffold.dart';
import '../../../core/constants/app_constants.dart';

class ArticleDetailScreen extends StatelessWidget {
  final String articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    final article = kHydrationArticles.cast<HydrationArticle?>().firstWhere(
      (a) => a?.id == articleId,
      orElse: () => null,
    );

    if (article == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: false,
          titleSpacing: 24,
          toolbarHeight: 100,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Artikel',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Artikel tidak ditemukan',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        body: Center(
          child: Text(
            'Artikel tidak ditemukan.',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
          ),
        ),
      );
    }

    final colors = _categoryColors(article.category);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: HydrationBackground()),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.70),
                              Colors.white.withValues(alpha: 0.40),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.75),
                            width: 1.0,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: colors.fg,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 84, 20, 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                colors.bg.withValues(alpha: 0.60),
                                Colors.white.withValues(alpha: 0.30),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.65),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              article.emoji,
                              style: GoogleFonts.inter(fontSize: 56),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.62),
                              Colors.white.withValues(alpha: 0.34),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.70),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colors.bg.withValues(alpha: 0.55),
                                    Colors.white.withValues(alpha: 0.30),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                _categoryLabel(article.category),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: colors.fg,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              article.title,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
                                height: 1.3,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              article.summary,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.black54,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              height: 1,
                              color: Colors.black.withValues(alpha: 0.05),
                            ),
                            const SizedBox(height: 20),
                            ..._buildContentParagraphs(article.body, colors.fg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContentParagraphs(String body, Color accentColor) {
    final paragraphs = body.split('\n\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < paragraphs.length; i++) {
      final p = paragraphs[i].trim();
      if (p.isEmpty) continue;

      // Check if it's a bullet point block or a paragraph starting with a bullet
      if (p.contains('\n') &&
          (p.startsWith('·') ||
              p.split('\n').every((line) => line.trim().startsWith('·')))) {
        final lines = p.split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          widgets.add(_buildBulletPoint(trimmed, accentColor));
        }
      } else if (p.startsWith('·')) {
        widgets.add(_buildBulletPoint(p, accentColor));
      } else {
        // Normal paragraph
        widgets.add(
          Text(
            p,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.black87,
              height: 1.7,
              fontWeight: FontWeight.normal,
            ),
          ),
        );
      }

      // Add paragraph spacing after each element except the last one
      if (i < paragraphs.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    return widgets;
  }

  Widget _buildBulletPoint(String text, Color accentColor) {
    // Strip the bullet marker
    final cleanText = text.replaceFirst(RegExp(r'^[·•\-]\s*'), '').trim();

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanText,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({Color bg, Color fg}) _categoryColors(String category) {
    switch (category.toLowerCase()) {
      case 'sains':
        return (bg: const Color(0xFFBDDDFD), fg: const Color(0xFF1565C0));
      case 'fakta_unik':
        return (bg: const Color(0xFFA5F3FC), fg: const Color(0xFF0E7490));
      case 'kesehatan':
        return (bg: const Color(0xFFC7D2FE), fg: const Color(0xFF4338CA));
      default:
        return (bg: const Color(0xFFF5F5F5), fg: const Color(0xFF424242));
    }
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
