import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State class representing the internal state of the MapboxMapWidget
/// 
/// This state manages loading indicators, error handling, retry logic,
/// and map creation tracking to provide a smooth user experience.
class MapWidgetState {
  /// Whether the map is currently loading
  final bool isLoading;
  
  /// Whether an error has occurred during map loading
  final bool hasError;
  
  /// Error message to display to the user if an error occurred
  final String? errorMessage;
  
  /// Whether a retry operation is currently in progress
  final bool isRetrying;
  
  /// Whether the map has been successfully created
  final bool mapCreated;
  
  /// Counter tracking how many times the map has been created
  /// (useful for debugging and preventing duplicate creations)
  final int mapCreationCount;

  const MapWidgetState({
    this.isLoading = true,
    this.hasError = false,
    this.errorMessage,
    this.isRetrying = false,
    this.mapCreated = false,
    this.mapCreationCount = 0,
  });

  /// Creates a copy of this state with the given fields replaced with new values
  MapWidgetState copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? isRetrying,
    bool? mapCreated,
    int? mapCreationCount,
  }) {
    return MapWidgetState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage,
      isRetrying: isRetrying ?? this.isRetrying,
      mapCreated: mapCreated ?? this.mapCreated,
      mapCreationCount: mapCreationCount ?? this.mapCreationCount,
    );
  }
}

/// Provider for managing the internal state of the MapboxMapWidget
/// 
/// This provider uses a StateNotifier to manage widget-level state that
/// doesn't need to be shared across the app, but needs to be managed
/// using Riverpod instead of setState for consistency with the codebase rules.
final mapWidgetStateProvider =
    StateNotifierProvider<MapWidgetStateNotifier, MapWidgetState>((ref) {
  return MapWidgetStateNotifier();
});

/// Notifier class for managing MapWidgetState
/// 
/// Provides methods to update the map widget's internal state,
/// including loading, error, and retry states.
class MapWidgetStateNotifier extends StateNotifier<MapWidgetState> {
  /// Initializes the notifier with default state
  MapWidgetStateNotifier() : super(const MapWidgetState());

  /// Sets the loading state
  /// 
  /// [isLoading] - Whether the map is currently loading
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Sets the error state
  /// 
  /// [hasError] - Whether an error has occurred
  /// [errorMessage] - Optional error message to display
  void setError({required bool hasError, String? errorMessage}) {
    state = state.copyWith(
      hasError: hasError,
      errorMessage: errorMessage,
      isLoading: false,
    );
  }

  /// Sets the retry state
  /// 
  /// [isRetrying] - Whether a retry operation is in progress
  void setRetrying(bool isRetrying) {
    state = state.copyWith(isRetrying: isRetrying);
  }

  /// Marks the map as created and increments the creation counter
  /// 
  /// This is called when the map is successfully created to prevent
  /// duplicate map initializations.
  void markMapCreated() {
    state = state.copyWith(
      mapCreated: true,
      mapCreationCount: state.mapCreationCount + 1,
    );
  }

  /// Resets the map creation state to allow recreation
  /// 
  /// Used when retrying map initialization after an error.
  void resetMapCreation() {
    state = state.copyWith(
      mapCreated: false,
      hasError: false,
      errorMessage: null,
    );
  }

  /// Clears all error states
  void clearError() {
    state = state.copyWith(
      hasError: false,
      errorMessage: null,
      isLoading: false,
    );
  }
}

