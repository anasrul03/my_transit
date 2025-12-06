import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../data/repositories/gtfs_realtime_repository_impl.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/gtfs_realtime_repository.dart';

final gtfsRealtimeRepositoryProvider = Provider<GtfsRealtimeRepository>((ref) {
  return GtfsRealtimeRepositoryImpl();
});

final gtfsRealtimeProvider = StateNotifierProvider<GtfsRealtimeNotifier, GtfsRealtimeState>(
  (ref) {
    return GtfsRealtimeNotifier(
      repository: ref.read(gtfsRealtimeRepositoryProvider),
    );
  },
);

class GtfsRealtimeState {
  final List<VehicleEntity> vehicles;
  final bool isLoading;
  final Failure? error;
  final DateTime? lastUpdate;

  const GtfsRealtimeState({
    this.vehicles = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdate,
  });

  GtfsRealtimeState copyWith({
    List<VehicleEntity>? vehicles,
    bool? isLoading,
    Failure? error,
    DateTime? lastUpdate,
  }) {
    return GtfsRealtimeState(
      vehicles: vehicles ?? this.vehicles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}

class GtfsRealtimeNotifier extends StateNotifier<GtfsRealtimeState> {
  final GtfsRealtimeRepository _repository;
  Timer? _pollTimer;

  GtfsRealtimeNotifier({required GtfsRealtimeRepository repository})
      : _repository = repository,
        super(const GtfsRealtimeState()) {
    _startPolling();
  }

  void _startPolling() {
    // Fetch immediately
    fetchVehiclePositions();

    // Then poll every 30 seconds
    _pollTimer = Timer.periodic(
      ApiConstants.realtimePollInterval,
      (_) => fetchVehiclePositions(),
    );
  }

  Future<void> fetchVehiclePositions() async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _repository.getVehiclePositions();

    if (result.isSuccess) {
      // Diff-patch: Only update vehicles that changed
      final newVehicles = result.data ?? [];
      final updatedVehicles = _diffPatchVehicles(state.vehicles, newVehicles);

      state = state.copyWith(
        vehicles: updatedVehicles,
        isLoading: false,
        lastUpdate: DateTime.now(),
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.failure,
      );
    }
  }

  /// Diff-patch vehicles: Update existing, add new, remove old
  List<VehicleEntity> _diffPatchVehicles(
    List<VehicleEntity> oldVehicles,
    List<VehicleEntity> newVehicles,
  ) {
    final vehicleMap = <String, VehicleEntity>{};

    // Add existing vehicles
    for (final vehicle in oldVehicles) {
      vehicleMap[vehicle.id] = vehicle;
    }

    // Update or add new vehicles
    for (final vehicle in newVehicles) {
      vehicleMap[vehicle.id] = vehicle;
    }

    // Remove vehicles that are no longer in the feed
    final newVehicleIds = newVehicles.map((v) => v.id).toSet();
    vehicleMap.removeWhere((id, _) => !newVehicleIds.contains(id));

    return vehicleMap.values.toList();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

