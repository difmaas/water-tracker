import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../providers/reminder_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    await ref.read(reminderServiceProvider).requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full Background Image (Campfire scene)
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Dark Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),

          // 3. PageView Content
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _isLastPage = index == 3;
              });
              if (index == 2) {
                _requestPermission();
              }
            },
            children: [
              _buildPage(
                context,
                title: 'SEHATI',
                subtitle: 'Selamat datang di aplikasi pemantau hidrasi cerdas Anda.',
                isTitlePage: true,
              ),
              _buildPage(
                context,
                title: 'Penelitian OPSI',
                subtitle: 'Aplikasi ini bertujuan sebagai penelitian efektivitas aplikasi reminder untuk genz nomofobia.',
                icon: Icons.science_outlined,
              ),
              _buildPage(
                context,
                title: 'Izin Notifikasi',
                subtitle: 'Kami memerlukan izin notifikasi untuk memberikan pengingat minum air yang tepat waktu.',
                icon: Icons.notifications_active_outlined,
              ),
              _buildPage(
                context,
                title: 'Siap Memulai?',
                subtitle: 'Mari bangun kebiasaan sehat bersama. Selamat memakai!',
                icon: Icons.check_circle_outline,
              ),
            ],
          ),

          // 4. Navigation Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  TextButton(
                    onPressed: () => _pageController.jumpToPage(3),
                    child: Text(
                      'LEWATI',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),

                  // Page Indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: 4,
                    effect: WormEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      spacing: 12,
                      dotColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                      activeDotColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),

                  // Next / Done Button
                  _isLastPage
                      ? ElevatedButton(
                          onPressed: () async {
                            await ref.read(onboardingProvider.notifier).completeOnboarding();
                            if (context.mounted) {
                              context.go('/profile-setup');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.onPrimary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            'MULAI',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      : TextButton(
                          onPressed: () => _pageController.nextPage(
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          ),
                          child: Text(
                            'LANJUT',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
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

  Widget _buildPage(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData? icon,
    bool isTitlePage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 80),
            SizedBox(height: 40),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: isTitlePage
                ? Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 12,
                    )
                : Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
          ),
          SizedBox(height: 24),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
