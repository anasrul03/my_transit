import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';

class MapFiltersState {
  final String? selectedOperator;
  final String? searchQuery;
  final bool locationEnabled;

  const MapFiltersState({
    this.selectedOperator = ApiConstants.defaultOperator,
    this.searchQuery,
    this.locationEnabled = false,
  });

  MapFiltersState copyWith({
    String? selectedOperator,
    String? searchQuery,
    bool? locationEnabled,
  }) {
    return MapFiltersState(
      selectedOperator: selectedOperator ?? this.selectedOperator,
      searchQuery: searchQuery,
      locationEnabled: locationEnabled ?? this.locationEnabled,
    );
  }
}

final mapFiltersProvider =
    StateNotifierProvider<MapFiltersNotifier, MapFiltersState>((ref) {
  return MapFiltersNotifier();
});

class MapFiltersNotifier extends StateNotifier<MapFiltersState> {
  MapFiltersNotifier() : super(const MapFiltersState());

  void setOperator(String? operator) {
    state = state.copyWith(selectedOperator: operator);
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void setLocationEnabled(bool enabled) {
    state = state.copyWith(locationEnabled: enabled);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: null);
  }
}

