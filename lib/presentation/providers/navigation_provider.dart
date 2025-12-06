import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Enumeration of available navigation tabs in the app
/// 
/// This enum represents the different main sections of the app that users
/// can navigate between using the bottom navigation bar.
enum TabType { 
  /// Map tab - displays the interactive map with vehicle positions
  map, 
  /// Routes tab - allows users to search for transit routes
  routes, 
  /// Favourites tab - displays user's favourite vehicles and routes
  favourites, 
  /// Schedules tab - shows transit schedules and timetables
  schedules, 
  /// Suggestions tab - allows users to submit feedback and suggestions
  suggestions 
}

/// State class representing the current navigation state
/// 
/// This state tracks which tab is currently selected in the bottom
/// navigation bar, allowing the app to display the appropriate view.
class NavigationState {
  /// The currently selected tab in the navigation bar
  final TabType selectedTab;

  /// Creates a NavigationState with the specified selected tab
  /// 
  /// [selectedTab] - The tab that is currently selected. Defaults to map.
  const NavigationState({
    this.selectedTab = TabType.map,
  });

  /// Creates a copy of this state with the given fields replaced with new values
  /// 
  /// [selectedTab] - Optional new selected tab value
  /// 
  /// Returns: A new NavigationState with updated values
  NavigationState copyWith({
    TabType? selectedTab,
  }) {
    return NavigationState(
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

/// Provider for managing navigation state
/// 
/// This provider manages which tab is currently selected in the bottom
/// navigation bar. It uses a StateNotifier to allow updating the selected tab.
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

/// Notifier class for managing NavigationState
/// 
/// Provides methods to change the selected tab in the navigation bar.
class NavigationNotifier extends StateNotifier<NavigationState> {
  /// Initializes the notifier with default state (map tab selected)
  NavigationNotifier() : super(const NavigationState());

  /// Changes the selected tab to the specified tab
  /// 
  /// [tab] - The tab type to select
  /// 
  /// This method updates the state to reflect the new selected tab,
  /// which will cause the UI to switch to the corresponding view.
  void selectTab(TabType tab) {
    state = state.copyWith(selectedTab: tab);
  }
}

