import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/vehicle_entity.dart';

class MapState {
  final VehicleEntity? selectedVehicle;
  final bool isInitialized;

  const MapState({
    this.selectedVehicle,
    this.isInitialized = false,
  });

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

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(const MapState());

  void selectVehicle(VehicleEntity vehicle) {
    state = state.copyWith(selectedVehicle: vehicle);
  }

  void clearSelection() {
    state = state.copyWith(selectedVehicle: null);
  }

  void setInitialized() {
    state = state.copyWith(isInitialized: true);
  }
}

