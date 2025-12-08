import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vehicle_entity.dart';

/// State class representing the map's current state
/// 
/// This state tracks which vehicle (if any) is currently selected on the map
/// and whether the map has been initialized. This allows the UI to show
/// vehicle details when a vehicle is selected.
class MapState {
  /// The vehicle currently selected on the map, or null if no vehicle is selected
  final VehicleEntity? selectedVehicle;
  
  /// Whether the map has been initialized and is ready for use
  final bool isInitialized;

  /// Creates a MapState with the specified values
  /// 
  /// [selectedVehicle] - Optional vehicle that is currently selected
  /// [isInitialized] - Whether the map has been initialized. Defaults to false.
  const MapState({
    this.selectedVehicle,
    this.isInitialized = false,
  });

  /// Creates a copy of this state with the given fields replaced with new values
  /// 
  /// [selectedVehicle] - Optional new selected vehicle value
  /// [isInitialized] - Optional new initialization status
  /// 
  /// Returns: A new MapState with updated values
  MapState copyWith({
    VehicleEntity? selectedVehicle,
    bool? isInitialized,
  }) {
    return MapState(
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Provider for managing map state
/// 
/// This provider manages the map's state, including which vehicle is selected
/// and whether the map has been initialized. It uses a StateNotifier to allow
/// updating the map state.
final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});

/// Notifier class for managing MapState
/// 
/// Provides methods to select vehicles, clear selections, and mark the map
/// as initialized.
class MapNotifier extends StateNotifier<MapState> {
  /// Initializes the notifier with default state (no vehicle selected, not initialized)
  MapNotifier() : super(const MapState());

  /// Selects a vehicle on the map
  /// 
  /// [vehicle] - The vehicle entity to select
  /// 
  /// This method updates the state to reflect the selected vehicle,
  /// which will cause the UI to display vehicle details.
  void selectVehicle(VehicleEntity vehicle) {
    state = state.copyWith(selectedVehicle: vehicle);
  }

  /// Clears the current vehicle selection
  /// 
  /// This method sets the selected vehicle to null, which will cause
  /// the UI to hide any vehicle details that were being displayed.
  void clearSelection() {
    state = state.copyWith(selectedVehicle: null);
  }

  /// Marks the map as initialized
  /// 
  /// This method should be called when the map has finished initializing
  /// and is ready for use. This allows other parts of the app to know
  /// when it's safe to interact with the map.
  void setInitialized() {
    state = state.copyWith(isInitialized: true);
  }
}

