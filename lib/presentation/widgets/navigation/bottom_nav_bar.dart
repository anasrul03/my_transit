import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom navigation bar widget for main app navigation
/// 
/// This widget displays a horizontal row of navigation tabs at the bottom
/// of the screen. Each tab represents a different section of the app (Map,
/// Routes, Favourites, Schedules, Suggestions). The selected tab is highlighted
/// with the primary color, and tapping a tab switches to that section.
/// 
/// The widget is responsive and uses SafeArea to respect device notches and
/// system UI elements.
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch navigation state to highlight the selected tab
    final NavigationState navigationState = ref.watch(navigationProvider);
    // Read the notifier to handle tab selection
    final NavigationNotifier notifier = ref.read(navigationProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NavTab(
                label: 'Map',
                icon: Icons.map,
                isSelected: navigationState.selectedTab == TabType.map,
                onTap: () => notifier.selectTab(TabType.map),
              ),
              _NavTab(
                label: 'Routes',
                icon: Icons.route,
                isSelected: navigationState.selectedTab == TabType.routes,
                onTap: () => notifier.selectTab(TabType.routes),
              ),
              _NavTab(
                label: 'Favourites',
                icon: Icons.favorite,
                isSelected: navigationState.selectedTab == TabType.favourites,
                onTap: () => notifier.selectTab(TabType.favourites),
              ),
              _NavTab(
                label: 'Schedules',
                icon: Icons.schedule,
                isSelected: navigationState.selectedTab == TabType.schedules,
                onTap: () => notifier.selectTab(TabType.schedules),
              ),
              _NavTab(
                label: 'Suggestions',
                icon: Icons.lightbulb,
                isSelected: navigationState.selectedTab == TabType.suggestions,
                onTap: () => notifier.selectTab(TabType.suggestions),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual navigation tab widget within the bottom navigation bar
/// 
/// This widget represents a single tab in the bottom navigation bar. It displays
/// an icon and label, and changes appearance when selected. The widget is
/// responsive and handles text overflow gracefully.
class _NavTab extends StatelessWidget {
  /// The text label displayed below the icon
  final String label;
  
  /// The icon displayed above the label
  final IconData icon;
  
  /// Whether this tab is currently selected
  final bool isSelected;
  
  /// Callback function called when the tab is tapped
  final VoidCallback onTap;

  /// Creates a navigation tab with the specified properties
  const _NavTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon that changes color based on selection state
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.white70,
                size: 22,
              ),
              const SizedBox(height: 2),
              // Label text that changes color and weight based on selection
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? AppTheme.primaryColor : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

