import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';

/// Provider for the LocationService instance
/// 
/// This provider supplies a singleton LocationService instance to be used
/// throughout the app for location-related operations.
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Provider for managing device location state
/// 
/// This provider manages the device's location state, including the current
/// position, whether location services are enabled, loading states, and errors.
/// It uses the LocationService to interact with device location capabilities.
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier(
      locationService: ref.read(locationServiceProvider),
    );
  },
);

/// State class representing the current device location state
/// 
/// This state tracks the device's current position, whether location services
/// are enabled, whether a location operation is in progress, and any errors
/// that occurred during location operations.
class LocationState {
  /// The device's current position, or null if not available
  final Position? currentPosition;
  
  /// Whether location services are currently enabled
  final bool isEnabled;
  
  /// Whether a location operation is currently in progress
  final bool isLoading;
  
  /// Error message if a location operation failed, or null if no error
  final String? error;

  /// Creates a LocationState with the specified values
  /// 
  /// [currentPosition] - Optional current position
  /// [isEnabled] - Whether enabled. Defaults to false.
  /// [isLoading] - Whether loading. Defaults to false.
  /// [error] - Optional error message
  const LocationState({
    this.currentPosition,
    this.isEnabled = false,
    this.isLoading = false,
    this.error,
  });

  /// Creates a copy of this state with the given fields replaced with new values
  LocationState copyWith({
    Position? currentPosition,
    bool? isEnabled,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier class for managing LocationState
/// 
/// This notifier provides methods to enable location services, get the current
/// position, update the location, and disable location services. It handles
/// permission requests and error states automatically.
class LocationNotifier extends StateNotifier<LocationState> {
  /// The location service instance used for location operations
  final LocationService _locationService;

  /// Initializes the notifier and checks initial location status
  /// 
  /// [locationService] - The location service to use for operations
  LocationNotifier({required LocationService locationService})
      : _locationService = locationService,
        super(const LocationState()) {
    // Check if location services are enabled on initialization
    _checkLocationStatus();
  }

  /// Checks whether location services are enabled on the device
  /// 
  /// This method checks the device's location service status and updates
  /// the state accordingly. It does not request permissions or get position.
  Future<void> _checkLocationStatus() async {
    final bool enabled = await _locationService.isLocationServiceEnabled();
    state = state.copyWith(isEnabled: enabled);
  }

  /// Enables location services and gets the current position
  /// 
  /// This method requests location permissions if needed, gets the current
  /// position, and updates the state. It handles errors and updates loading
  /// state appropriately.
  Future<void> enableLocation() async {
    // Set loading state and clear any previous errors
    state = state.copyWith(isLoading: true, error: null);

    // Attempt to get current position (this will request permissions if needed)
    final result = await _locationService.getCurrentPosition();

    if (result.isSuccess && result.data != null) {
      // Successfully got position - update state
      state = state.copyWith(
        currentPosition: result.data,
        isEnabled: true,
        isLoading: false,
      );
    } else {
      // Failed to get position - update state with error
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Failed to get location',
      );
    }
  }

  /// Disables location services and clears the current position
  /// 
  /// This method resets the location state to its initial state, effectively
  /// disabling location tracking and clearing any stored position data.
  void disableLocation() {
    state = const LocationState();
  }

  /// Updates the current location position
  /// 
  /// This method fetches a new position if location services are enabled.
  /// It does not show loading state or handle errors, making it suitable
  /// for periodic updates.
  Future<void> updateLocation() async {
    // Only update if location is enabled
    if (!state.isEnabled) return;

    // Get new position and update state if successful
    final result = await _locationService.getCurrentPosition();
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(currentPosition: result.data);
    }
  }
}

