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
    }

    return Scaffold(
      extendBody: true, // Allows the body to go behind the floating nav bar
      body: child,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 20),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F1F5), // Light grey base
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(
                context,
                index: 0,
                currentIndex: currentIndex,
                icon: Icons.grid_view_rounded,
                route: '/dashboard',
              ),
              _buildNavItem(
                context,
                index: 1,
                currentIndex: currentIndex,
                icon: Icons.analytics_rounded,
                route: '/progress',
              ),
              _buildNavItem(
                context,
                index: 2,
                currentIndex: currentIndex,
                icon: Icons.auto_stories_rounded,
                route: '/education',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required int currentIndex,
    required IconData icon,
    required String route,
  }) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => context.go(route),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF007AFF) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF1A1A2E).withValues(alpha: 0.6),
          size: 22,
        ),
      ),
    );
  }
}
