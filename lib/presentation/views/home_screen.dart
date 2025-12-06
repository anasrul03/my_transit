import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/navigation/bottom_nav_bar.dart';
import '../widgets/map/mapbox_map_widget.dart';
import '../providers/navigation_provider.dart';
import '../views/routes/routes_tab_view.dart';
import '../views/favourites/favourites_tab_view.dart';
import '../views/schedules/schedules_tab_view.dart';
import '../views/suggestions/suggestions_tab_view.dart';

/// Main home screen that displays the selected tab view
/// 
/// This screen uses an IndexedStack to keep all tab views alive, which
/// prevents the map from being recreated when switching tabs. This improves
/// performance and maintains map state across tab switches.
/// 
/// The screen displays the bottom navigation bar and the currently selected
/// tab view based on the navigation state.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch navigation state to determine which tab to display
    final NavigationState navigationState = ref.watch(navigationProvider);

    // Use IndexedStack to keep all views alive (prevents map from recreating)
    // This ensures smooth tab switching and maintains state across tabs
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: navigationState.selectedTab.index,
          children: const [
            MapboxMapWidget(),       // TabType.map (index 0)
            RoutesTabView(),         // TabType.routes (index 1)
            FavouritesTabView(),     // TabType.favourites (index 2)
            SchedulesTabView(),      // TabType.schedules (index 3)
            SuggestionsTabView(),    // TabType.suggestions (index 4)
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

