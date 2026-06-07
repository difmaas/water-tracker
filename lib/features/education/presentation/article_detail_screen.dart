import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Artikel',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
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
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: colors.bg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: colors.fg,
                  size: 20,
                ),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: colors.bg,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 48),
                    Text(article.emoji, style: GoogleFonts.inter(fontSize: 56)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _categoryLabel(article.category),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.fg,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    article.title,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
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
                      fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.w500,
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
              fontWeight: FontWeight.bold,
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
                fontWeight: FontWeight.w500,
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
        return (bg: const Color(0xFFFFE194), fg: const Color(0xFF795548));
      case 'kesehatan':
        return (bg: const Color(0xFFC4E8C2), fg: const Color(0xFF2E7D32));
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
