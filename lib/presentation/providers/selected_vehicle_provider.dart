import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vehicle_entity.dart';

/// Provider for managing the currently selected vehicle
/// 
/// This provider uses a simple StateProvider to track which vehicle is
/// currently selected. It's a lightweight alternative to the mapProvider
/// for cases where you only need to track vehicle selection without
/// additional map state.
/// 
/// The provider returns null when no vehicle is selected, or the
/// VehicleEntity when a vehicle is selected.
final selectedVehicleProvider =
    StateProvider<VehicleEntity?>((ref) => null);

