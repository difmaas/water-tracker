// features/education/presentation/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';

/// Displays the full body content of a single [HydrationArticle].
///
/// Read-only — no share, no bookmark per FEATURES_V2.md F-09.
/// Receives article `id` via GoRouter path parameter `/education/:id`.
class ArticleDetailScreen extends StatelessWidget {
  final String articleId;

  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context) {
    // Look up article from const list — no async needed
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
          title: const Text('Artikel'),
        ),
        body: const Center(
          child: Text('Artikel tidak ditemukan.'),
        ),
      );
    }

    final colors = _categoryColors(article.category);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: CustomScrollView(
        slivers: [
          // ── Hero header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: colors.bg,
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
                    const SizedBox(height: 48), // account for status bar
                    Text(
                      article.emoji,
                      style: const TextStyle(fontSize: 56),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.bg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _categoryLabel(article.category),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.fg,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Summary (lead paragraph)
                  Text(
                    article.summary,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Divider
                  Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 20),
                  // Full body content
                  Text(
                    article.body,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF333333),
                      height: 1.7,
                    ),
                  ),
                ],
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
        return (bg: const Color(0xFFE3E8FF), fg: const Color(0xFF153B8A));
      case 'fakta_unik':
        return (bg: const Color(0xFFFFEAB3), fg: const Color(0xFF6B4B00));
      case 'kesehatan':
        return (bg: const Color(0xFFE0F7E6), fg: const Color(0xFF0F5124));
      default:
        return (bg: const Color(0xFFF5F5F5), fg: const Color(0xFF424242));
    }
  }

  String _categoryLabel(String category) {
    switch (category.toLowerCase()) {
      case 'sains':      return 'Sains';
      case 'fakta_unik': return 'Fakta Unik';
      case 'kesehatan':  return 'Kesehatan';
      default:           return category;
    }
  }
}
