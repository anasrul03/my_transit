import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/navigation_provider.dart';
import '../../../core/theme/app_theme.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigationState = ref.watch(navigationProvider);
    final notifier = ref.read(navigationProvider.notifier);

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

class _NavTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

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
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryColor : Colors.white70,
                size: 22,
              ),
              const SizedBox(height: 2),
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

