import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_settings_provider.dart';
import 'widgets/article_card.dart';

const _kCategories = ['all', 'sains', 'fakta_unik', 'kesehatan'];

const _kCategoryLabels = {
  'all': 'Semua',
  'sains': 'Sains',
  'fakta_unik': 'Fakta Unik',
  'kesehatan': 'Kesehatan',
};

class EducationScreen extends ConsumerStatefulWidget {
  const EducationScreen({super.key});

  @override
  ConsumerState<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends ConsumerState<EducationScreen> {
  String _selectedCategory = 'all';

  List<HydrationArticle> get _filteredArticles {
    if (_selectedCategory == 'all') return kHydrationArticles;
    return kHydrationArticles
        .where((a) => a.category.toLowerCase() == _selectedCategory)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredArticles;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 24,
        toolbarHeight: 100,
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Edukasi',
                style: GoogleFonts.manrope(
                  fontSize: 26,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Info dan tips hidrasi sehat untuk tubuhmu',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: _buildCategoryFilter(context),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 12, bottom: 12),
            sliver: kHydrationArticles.isEmpty
                ? SliverFillRemaining(child: _buildContentComingSoon())
                : filtered.isEmpty
                ? SliverFillRemaining(child: _buildEmptyFilter())
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final article = filtered[index];

                      return TweenAnimationBuilder<double>(
                        duration: Duration(milliseconds: 400 + (index * 100)),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: ArticleCard(
                            article: article,
                            isFeatured: false,
                            onTap: () =>
                                context.push('/education/${article.id}'),
                          ),
                        ),
                      );
                    }, childCount: filtered.length),
                  ),
          ),
          if (kHydrationArticles.isNotEmpty && filtered.isNotEmpty)
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    final lightweightMode = ref.watch(
      appSettingsProvider.select((state) => state.lightweightMode),
    );

    final filterContent = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: lightweightMode ? Colors.white : null,
        gradient: lightweightMode
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.60),
                  Colors.white.withValues(alpha: 0.30),
                ],
              ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: lightweightMode
              ? const Color(0xFFE2E8F0)
              : Colors.white.withValues(alpha: 0.6),
          width: 1.2,
        ),
        boxShadow: lightweightMode
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < _kCategories.length; i++) ...[
              _buildCategoryChip(_kCategories[i], lightweightMode),
              if (i != _kCategories.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: lightweightMode
            ? filterContent
            : BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: filterContent,
              ),
      ),
    );
  }

  Widget _buildCategoryChip(String cat, bool lightweightMode) {
    final isSelected = _selectedCategory == cat;

    return InkWell(
      onTap: () => setState(() => _selectedCategory = cat),
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: lightweightMode
              ? (isSelected ? const Color(0xFFEAF5FF) : Colors.white)
              : (isSelected
                    ? Colors.white.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.20)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: lightweightMode
                ? (isSelected
                      ? const Color(0xFFD7EAFB)
                      : const Color(0xFFE2E8F0))
                : (isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.55)),
            width: 1,
          ),
          boxShadow: lightweightMode
              ? const []
              : [
                  BoxShadow(
                    color: isSelected
                        ? Colors.black.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: isSelected ? 12 : 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Text(
          _kCategoryLabels[cat] ?? cat,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (lightweightMode
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF0D47A1))
                : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _buildContentComingSoon() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('📚', style: GoogleFonts.manrope(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text(
              'Konten Segera Hadir',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0D47A1),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tips dan artikel menarik seputar hidrasi sedang disiapkan untukmu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.black54,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          'Tidak ada artikel untuk kategori ini.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            color: Colors.black45,
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
