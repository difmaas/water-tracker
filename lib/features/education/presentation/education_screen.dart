// features/education/presentation/education_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import 'widgets/article_card.dart';

const _kCategories = ['all', 'sains', 'fakta_unik', 'kesehatan'];

const _kCategoryLabels = {
  'all': 'Semua',
  'sains': 'Sains',
  'fakta_unik': 'Fakta Unik',
  'kesehatan': 'Kesehatan',
};

/// Article list screen with category filter tabs.
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
      backgroundColor: const Color(0xFFF8F9FE),
      body: Stack(
        children: [
          const _AnimatedWaterBackground(),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: const Color(0xFFF8F9FE),
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                toolbarHeight: 70,
                title: const Text(
                  'Edukasi',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                    letterSpacing: -1.0,
                  ),
                ),
                centerTitle: false,
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoryHeaderDelegate(
                  child: _buildCategoryFilter(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                sliver: kHydrationArticles.isEmpty
                    ? SliverFillRemaining(child: _buildContentComingSoon())
                    : filtered.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyFilter())
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
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
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: ArticleCard(
                                      article: article,
                                      isFeatured: false,
                                      onTap: () => context.push('/education/${article.id}'),
                                    ),
                                  ),
                                );
                              },
                              childCount: filtered.length,
                            ),
                          ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    const double tabWidth = 100.0;
    final int selectedIndex = _kCategories.indexOf(_selectedCategory);

    return Container(
      height: 70,
      width: double.infinity,
      color: const Color(0xFFF8F9FE),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: tabWidth * _kCategories.length + 8,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // Liquid Sliding Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                left: selectedIndex * tabWidth,
                width: tabWidth,
                height: 42, // Match the padding/height of the text container
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              // Labels
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
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? const Color(0xFF1A1A2E) : Colors.grey.shade600,
                          ),
                          child: Text(_kCategoryLabels[cat] ?? cat),
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('📚', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Konten Segera Hadir',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 8),
            Text(
              'Artikel edukasi hidrasi sedang disiapkan oleh tim peneliti.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
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
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
        ),
      ),
    );
  }
}

/// Subtle animated background with moving soft blobs
class _AnimatedWaterBackground extends StatefulWidget {
  const _AnimatedWaterBackground();

  @override
  State<_AnimatedWaterBackground> createState() => _AnimatedWaterBackgroundState();
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
              child: _buildBlob(300, const Color(0xFFBDDDFD).withValues(alpha: 0.15)),
            ),
            Positioned(
              bottom: 100 - (50 * _controller.value),
              right: -100 + (150 * _controller.value),
              child: _buildBlob(400, const Color(0xFFC4E8C2).withValues(alpha: 0.12)),
            ),
            Positioned(
              top: 300 + (100 * (1 - _controller.value)),
              right: 50 + (50 * _controller.value),
              child: _buildBlob(250, const Color(0xFFFFE194).withValues(alpha: 0.1)),
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
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0.0)],
        ),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) => true;
}
