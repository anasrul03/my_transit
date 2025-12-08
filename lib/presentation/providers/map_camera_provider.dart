import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vehicle_entity.dart';

/// State class for managing map camera control requests
/// 
/// This state tracks camera movement requests to specific vehicles.
/// The timestamp ensures each request is processed even if the same
/// vehicle is selected multiple times in succession.
class MapCameraState {
  /// The vehicle to move the camera to, or null if no movement requested
  final VehicleEntity? targetVehicle;
  
  /// Timestamp of the camera movement request
  /// 
  /// This is used to distinguish between successive requests to the same vehicle.
  /// Each new request gets a new timestamp, ensuring the camera movement is triggered.
  final DateTime? requestTime;

  /// Creates a MapCameraState with the specified values
  /// 
  /// [targetVehicle] - Optional vehicle to move the camera to
  /// [requestTime] - Optional timestamp of the request
  const MapCameraState({
    this.targetVehicle,
    this.requestTime,
  });

  /// Creates a copy of this state with the given fields replaced with new values
  /// 
  /// [targetVehicle] - Optional new target vehicle value
  /// [requestTime] - Optional new request time
  /// 
  /// Returns: A new MapCameraState with updated values
  MapCameraState copyWith({
    VehicleEntity? targetVehicle,
    DateTime? requestTime,
  }) {
    return MapCameraState(
      targetVehicle: targetVehicle ?? this.targetVehicle,
      requestTime: requestTime ?? this.requestTime,
    );
  }
}

/// Provider for managing map camera control
/// 
/// This provider manages camera movement requests to specific vehicles.
/// It uses a StateNotifier to allow other widgets (like the vehicle list)
/// to trigger camera movements on the map.
final mapCameraProvider = StateNotifierProvider<MapCameraNotifier, MapCameraState>((ref) {
  return MapCameraNotifier();
});

/// Notifier class for managing MapCameraState
/// 
/// Provides methods to request camera movements to specific vehicles
/// and to clear camera targets after movements complete.
class MapCameraNotifier extends StateNotifier<MapCameraState> {
  /// Initializes the notifier with default state (no camera movement requested)
  MapCameraNotifier() : super(const MapCameraState());

  /// Requests the camera to move to a specific vehicle
  /// 
  /// [vehicle] - The vehicle entity to move the camera to
  /// 
  /// This method updates the state to reflect the camera movement request.
  /// The map widget listens to this state and moves the camera when it changes.
  /// Each request gets a new timestamp to ensure it's processed even if
  /// the same vehicle is selected multiple times.
  void moveCameraToVehicle(VehicleEntity vehicle) {
    state = MapCameraState(
      targetVehicle: vehicle,
      requestTime: DateTime.now(),
    );
  }

  /// Clears the current camera target
  /// 
  /// This method should be called after the camera movement completes
  /// to reset the state and prepare for the next camera movement request.
  void clearTarget() {
    state = const MapCameraState(
      targetVehicle: null,
      requestTime: null,
    );
  }
}



