import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';

/// State class representing the current map filter settings
/// 
/// This state tracks the filters applied to the map view, including
/// the selected transit agency, search query, and whether location
/// filtering is enabled. These filters control which vehicles are
/// displayed on the map.
class MapFiltersState {
  /// The transit agency currently selected for filtering
  /// 
  /// Only vehicles from this agency will be displayed. Defaults to
  /// the default agency from API constants.
  final String? selectedAgency;
  
  /// The current search query for filtering vehicles or routes
  /// 
  /// This can be used to search for specific vehicles, routes, or stops.
  final String? searchQuery;
  
  /// Whether location-based filtering is enabled
  /// 
  /// When enabled, the map may filter vehicles based on proximity to
  /// the user's current location.
  final bool locationEnabled;
  
  /// The selected category for Prasarana agencies
  /// 
  /// This is only relevant for Prasarana bus agencies and determines
  /// which service category to fetch (e.g., 'rapid-bus-kl', 'rapid-bus-mrtfeeder').
  /// If null, the category defaults to the agency code.
  final String? selectedCategory;

  /// Creates a MapFiltersState with the specified filter values
  /// 
  /// [selectedAgency] - The agency to filter by. Defaults to defaultAgency.
  /// [searchQuery] - Optional search query string
  /// [locationEnabled] - Whether location filtering is enabled. Defaults to false.
  /// [selectedCategory] - Optional category for Prasarana agencies
  const MapFiltersState({
    this.selectedAgency = ApiConstants.defaultAgency,
    this.searchQuery,
    this.locationEnabled = false,
    this.selectedCategory,
  });

  /// Creates a copy of this state with the given fields replaced with new values
  /// 
  /// [selectedAgency] - Optional new agency value
  /// [searchQuery] - Optional new search query (use null to clear)
  /// [locationEnabled] - Optional new location enabled status
  /// [selectedCategory] - Optional new category value (use null to clear)
  /// 
  /// Returns: A new MapFiltersState with updated values
  MapFiltersState copyWith({
    String? selectedAgency,
    String? searchQuery,
    bool? locationEnabled,
    String? selectedCategory,
  }) {
    return MapFiltersState(
      selectedAgency: selectedAgency ?? this.selectedAgency,
      searchQuery: searchQuery,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      selectedCategory: selectedCategory,
    );
  }
}

/// Provider for managing map filter state
/// 
/// This provider manages the filters applied to the map view, allowing
/// users to filter vehicles by agency, search for specific items, and
/// enable location-based filtering. It uses a StateNotifier to allow
/// updating the filter state.
final mapFiltersProvider =
    StateNotifierProvider<MapFiltersNotifier, MapFiltersState>((ref) {
  return MapFiltersNotifier();
});

/// Notifier class for managing MapFiltersState
/// 
/// Provides methods to update the various map filters, including agency
/// selection, search queries, and location filtering.
class MapFiltersNotifier extends StateNotifier<MapFiltersState> {
  /// Initializes the notifier with default filter state
  MapFiltersNotifier() : super(const MapFiltersState());

  /// Sets the selected transit agency filter
  /// 
  /// [agency] - The agency code to filter by (e.g., 'rapid-bus-kl', 'rapid-rail-kl'), or null to show all agencies
  /// 
  /// This updates the filter to show only vehicles from the specified agency.
  void setAgency(String? agency) {
    state = state.copyWith(selectedAgency: agency);
  }
  
  /// Sets the selected transit agency filter (legacy method for backward compatibility)
  /// 
  /// [operator] - The agency code to filter by, or null to show all agencies
  /// 
  /// This is a legacy method that maps to setAgency for backward compatibility.
  /// New code should use setAgency instead.
  @Deprecated('Use setAgency instead')
  void setOperator(String? operator) {
    setAgency(operator);
  }

  /// Sets the search query filter
  /// 
  /// [query] - The search query string, or null to clear the search
  /// 
  /// This updates the filter to show only items matching the search query.
  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Sets whether location-based filtering is enabled
  /// 
  /// [enabled] - Whether location filtering should be enabled
  /// 
  /// When enabled, the map may filter vehicles based on proximity to
  /// the user's current location.
  void setLocationEnabled(bool enabled) {
    state = state.copyWith(locationEnabled: enabled);
  }

  /// Clears the current search query
  /// 
  /// This is a convenience method that sets the search query to null,
  /// effectively removing the search filter.
  void clearSearch() {
    state = state.copyWith(searchQuery: null);
  }
  
  /// Sets the selected category for Prasarana agencies
  /// 
  /// [category] - The category code to use (e.g., 'rapid-bus-kl', 'rapid-bus-mrtfeeder'),
  ///              or null to use the default (agency code)
  /// 
  /// This is only relevant for Prasarana bus agencies. When a Prasarana agency
  /// is selected, this category determines which service to fetch data for.
  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }
  
  /// Clears the selected category
  /// 
  /// This resets the category to null, which will cause the API to use
  /// the default category (agency code) for Prasarana agencies.
  void clearCategory() {
    state = state.copyWith(selectedCategory: null);
  }
}

