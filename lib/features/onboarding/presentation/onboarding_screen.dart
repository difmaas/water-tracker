import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../providers/onboarding_provider.dart';

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
    final status = await Permission.notification.request();
    // Research requirement: Capture if permission was granted
    // This will be stored in UserProfile during F-03, 
    // but for now, we just proceed.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(bottom: 80),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _isLastPage = index == 2;
            });
            if (index == 2) {
              _requestPermission();
            }
          },
          children: [
            _buildPage(
              color: Colors.white,
              image: 'assets/images/onboarding_welcome.png',
              title: 'Stay Hydrated',
              subtitle: 'Keep track of your daily water intake and stay healthy.',
            ),
            _buildPage(
              color: Colors.white,
              image: 'assets/images/onboarding_research.png',
              title: 'OPSI Research',
              subtitle: 'This app is a research instrument for the OPSI study on hydration habits.',
            ),
            _buildPage(
              color: Colors.white,
              image: 'assets/images/onboarding_reminders.png',
              title: 'Smart Reminders',
              subtitle: 'Get timely notifications to remind you to drink water throughout the day.',
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => _pageController.jumpToPage(2),
              child: const Text('SKIP'),
            ),
            Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 3,
                effect: const WormEffect(
                  spacing: 16,
                  dotColor: Colors.black12,
                  activeDotColor: Colors.blue,
                ),
                onDotClicked: (index) => _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeIn,
                ),
              ),
            ),
            _isLastPage
                ? TextButton(
                    onPressed: () async {
                      await ref.read(onboardingProvider.notifier).completeOnboarding();
                      if (context.mounted) {
                        context.go('/profile-setup');
                      }
                    },
                    child: const Text('DONE'),
                  )
                : TextButton(
                    onPressed: () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    ),
                    child: const Text('NEXT'),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required Color color,
    required String image,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: color,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
          ),
          const SizedBox(height: 64),
          Text(
            title,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
