import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    return LocationNotifier(
      locationService: ref.read(locationServiceProvider),
    );
  },
);

class LocationState {
  final Position? currentPosition;
  final bool isEnabled;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.currentPosition,
    this.isEnabled = false,
    this.isLoading = false,
    this.error,
  });

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

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier({required LocationService locationService})
      : _locationService = locationService,
        super(const LocationState()) {
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    final enabled = await _locationService.isLocationServiceEnabled();
    state = state.copyWith(isEnabled: enabled);
  }

  Future<void> enableLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _locationService.getCurrentPosition();

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        currentPosition: result.data,
        isEnabled: true,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failure?.message ?? 'Failed to get location',
      );
    }
  }

  void disableLocation() {
    state = const LocationState();
  }

  Future<void> updateLocation() async {
    if (!state.isEnabled) return;

    final result = await _locationService.getCurrentPosition();
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(currentPosition: result.data);
    }
  }
}

