import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Main scaffold with a persistent bottom navigation bar.
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Get the current location to determine the active tab index.
    final location = GoRouterState.of(context).uri.path;

    int currentIndex = 0;
    if (location.startsWith('/dashboard')) {
      currentIndex = 0;
    } else if (location.startsWith('/progress')) {
      currentIndex = 1;
    } else if (location.startsWith('/education')) {
      currentIndex = 2;
    } else if (location.startsWith('/settings')) {
      currentIndex = 3;
    }

    return Scaffold(
      extendBody:
          false, // Prevents body content from going behind bottom nav bar
      body: child,
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: Container(
            height: 68,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEFEFEF), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  context,
                  index: 0,
                  currentIndex: currentIndex,
                  selectedIcon: Icons.home_rounded,
                  unselectedIcon: Icons.home_outlined,
                  label: 'Beranda',
                  route: '/dashboard',
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  currentIndex: currentIndex,
                  selectedIcon: Icons.bar_chart_rounded,
                  unselectedIcon: Icons.bar_chart_outlined,
                  label: 'Riwayat',
                  route: '/progress',
                ),
                _buildNavItem(
                  context,
                  index: 2,
                  currentIndex: currentIndex,
                  selectedIcon: Icons.auto_stories_rounded,
                  unselectedIcon: Icons.auto_stories_outlined,
                  label: 'Tips',
                  route: '/education',
                ),
                _buildNavItem(
                  context,
                  index: 3,
                  currentIndex: currentIndex,
                  selectedIcon: Icons.settings_rounded,
                  unselectedIcon: Icons.settings_outlined,
                  label: 'Pengaturan',
                  route: '/settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required String route,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => context.go(route),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF2F3F5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Tooltip(
          message: label,
          preferBelow: false,
          child: AnimatedScale(
            scale: isSelected ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutBack,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Icon(
                isSelected ? selectedIcon : unselectedIcon,
                key: ValueKey<bool>(isSelected),
                color: isSelected
                    ? const Color(0xFF1A1A2E)
                    : Colors.grey.shade500,
                size: 25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
