import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/presentation/main_scaffold.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../providers/reminder_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLastPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    await ref.read(reminderServiceProvider).requestPermissions();
  }

  Future<void> _finishOnboarding(bool requestNotif) async {
    if (requestNotif) {
      await _requestPermission();
    }
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/profile-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Background #F8FBFF
      body: Stack(
        children: [
          // Consistent Hydration background used across all screens
          const Positioned.fill(child: HydrationBackground()),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Top Skip button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: AnimatedOpacity(
                      opacity: _isLastPage ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: TextButton(
                        onPressed: _isLastPage
                            ? null
                            : () {
                                _pageController.animateToPage(
                                  2, // Jump to notification permission page
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(
                            0xFF1A73E8,
                          ).withValues(alpha: 0.8),
                        ),
                        child: Text(
                          'Lewati',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Onboarding Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _isLastPage = index == 2;
                      });
                    },
                    children: [
                      // Page 1
                      _buildPage(
                        context,
                        illustration: Image.asset(
                          'assets/images/onboarding1.webp',
                          height: 340,
                          fit: BoxFit.contain,
                        ),
                        headline: 'Awali Hari dengan Cukup Air',
                        body:
                            'SEHATI membantumu membangun kebiasaan minum air putih secara lebih teratur setiap hari.',
                      ),
                      // Page 2
                      _buildPage(
                        context,
                        illustration: Image.asset(
                          'assets/images/onboarding2.webp',
                          height: 340,
                          fit: BoxFit.contain,
                        ),
                        headline: 'Pantau Progress Minummu',
                        body:
                            'Lihat jumlah air yang sudah kamu minum, cek riwayat harian, dan capai target dengan lebih konsisten.',
                      ),
                      // Page 3: Notification Permission Section
                      _buildPage(
                        context,
                        illustration: Image.asset(
                          'assets/images/onboarding3.webp',
                          height: 340,
                          fit: BoxFit.contain,
                        ),
                        headline: 'Pengingat Sesuai Jadwalmu',
                        body:
                            'Atur waktu dan interval minum sesuai aktivitas harianmu.',
                      ),
                    ],
                  ),
                ),

                // Bottom Controls / Actions
                Padding(
                  padding: const EdgeInsets.only(
                    left: 32,
                    right: 32,
                    bottom: 40,
                    top: 16,
                  ),
                  child: Column(
                    children: [
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: 3,
                        effect: ExpandingDotsEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          spacing: 8,
                          activeDotColor: const Color(
                            0xFF1A73E8,
                          ), // Primary #1A73E8
                          dotColor: const Color(
                            0xFF1A73E8,
                          ).withValues(alpha: 0.15),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.main(
                          label: _currentPage < 2
                              ? 'Lanjut'
                              : 'Aktifkan Pengingat',
                          onPressed: () {
                            if (_currentPage < 2) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _finishOnboarding(true);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(
    BuildContext context, {
    required Widget illustration,
    required String headline,
    required String body,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE8F4FF).withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  illustration,
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF202124),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: const Color(0xFF5F6368),
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
}
