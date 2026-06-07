import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';
import 'widgets/article_card.dart';

const _kCategories = ['all', 'sains', 'fakta_unik', 'kesehatan'];

const _kCategoryLabels = {
  'all': 'Semua',
  'sains': 'Sains',
  'fakta_unik': 'Fakta Unik',
  'kesehatan': 'Kesehatan',
};

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const _AnimatedWaterBackground(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: false,
                pinned: true,
                centerTitle: false,
                elevation: 0,
                backgroundColor: Colors.white,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                toolbarHeight: 100,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tips Minum Air',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Info dan tips hidrasi sehat untuk tubuhmu',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                titleSpacing: 24,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryHeaderDelegate(
                  child: _buildCategoryFilter(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 12, bottom: 20),
                sliver: kHydrationArticles.isEmpty
                    ? SliverFillRemaining(child: _buildContentComingSoon())
                    : filtered.isEmpty
                    ? SliverFillRemaining(child: _buildEmptyFilter())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final article = filtered[index];

                          return TweenAnimationBuilder<double>(
                            duration: Duration(
                              milliseconds: 400 + (index * 100),
                            ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    const double tabWidth = 90.0;
    final int selectedIndex = _kCategories.indexOf(_selectedCategory);

    return Container(
      height: 70,
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: tabWidth * _kCategories.length + 8,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                left: selectedIndex * tabWidth,
                width: tabWidth,
                height: 42,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: _kCategories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: tabWidth,
                      height: 42,
                      child: Center(
                        child: Text(
                          _kCategoryLabels[cat] ?? cat,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: isSelected
                                ? const Color(0xFF0D47A1)
                                : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
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
              child: Text('📚', style: GoogleFonts.inter(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text(
              'Konten Segera Hadir',
              style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
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

class _AnimatedWaterBackground extends StatefulWidget {
  const _AnimatedWaterBackground();

  @override
  State<_AnimatedWaterBackground> createState() =>
      _AnimatedWaterBackgroundState();
}

class _AnimatedWaterBackgroundState extends State<_AnimatedWaterBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100 + (50 * _controller.value),
              left: -50 + (100 * _controller.value),
              child: _buildBlob(
                300,
                const Color(0xFFBDDDFD).withValues(alpha: 0.15),
              ),
            ),
            Positioned(
              bottom: 100 - (50 * _controller.value),
              right: -100 + (150 * _controller.value),
              child: _buildBlob(
                400,
                const Color(0xFFC4E8C2).withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              top: 300 + (100 * (1 - _controller.value)),
              right: 50 + (50 * _controller.value),
              child: _buildBlob(
                250,
                const Color(0xFFFFE194).withValues(alpha: 0.1),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0.0)]),
      ),
    );
  }
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _CategoryHeaderDelegate({required this.child});

  @override
  double get minExtent => 70;
  @override
  double get maxExtent => 70;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) => true;
}
