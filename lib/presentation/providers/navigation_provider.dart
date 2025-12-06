import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TabType { map, routes, favourites, schedules, suggestions }

class NavigationState {
  final TabType selectedTab;

  const NavigationState({
    this.selectedTab = TabType.map,
  });

  NavigationState copyWith({
    TabType? selectedTab,
  }) {
    return NavigationState(
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});

class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(const NavigationState());

  void selectTab(TabType tab) {
    state = state.copyWith(selectedTab: tab);
  }
}

