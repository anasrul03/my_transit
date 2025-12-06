import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../data/repositories/gtfs_realtime_repository_impl.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/gtfs_realtime_repository.dart';
import 'map_filters_provider.dart';

final gtfsRealtimeRepositoryProvider = Provider<GtfsRealtimeRepository>((ref) {
  return GtfsRealtimeRepositoryImpl();
});

final gtfsRealtimeProvider = StateNotifierProvider<GtfsRealtimeNotifier, GtfsRealtimeState>(
  (ref) {
    return GtfsRealtimeNotifier(
      repository: ref.read(gtfsRealtimeRepositoryProvider),
      mapFiltersNotifier: ref.read(mapFiltersProvider.notifier),
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
  final MapFiltersNotifier _mapFiltersNotifier;
  Timer? _pollTimer;

  /// Creates a GtfsRealtimeNotifier instance
  /// 
  /// [repository] - The repository for fetching vehicle positions
  /// [mapFiltersNotifier] - The notifier for accessing map filter state (agency selection)
  GtfsRealtimeNotifier({
    required GtfsRealtimeRepository repository,
    required MapFiltersNotifier mapFiltersNotifier,
  })  : _repository = repository,
        _mapFiltersNotifier = mapFiltersNotifier,
        super(const GtfsRealtimeState()) {
    _startPolling();
  }

  /// Starts polling for vehicle position updates
  /// 
  /// This method immediately fetches vehicle positions, then sets up a
  /// periodic timer to fetch updates at the interval specified in API constants.
  /// The polling ensures the map always shows current vehicle positions.
  void _startPolling() {
    // Fetch immediately to get initial vehicle positions
    fetchVehiclePositions();

    // Set up periodic polling to update vehicle positions regularly
    // Uses the realtime poll interval from API constants (30 seconds)
    _pollTimer = Timer.periodic(
      ApiConstants.realtimePollInterval,
      (_) => fetchVehiclePositions(),
    );
  }

  /// Fetches the latest vehicle positions from the realtime API
  /// 
  /// This method requests vehicle positions from the repository, updates
  /// the state with the new positions using a diff-patch algorithm to
  /// efficiently update only changed vehicles, and handles errors appropriately.
  /// 
  /// The method automatically uses the selected agency from map filters
  /// to fetch vehicles from the specified transit agency.
  Future<void> fetchVehiclePositions() async {
    // Set loading state and clear any previous errors
    state = state.copyWith(isLoading: true, error: null);

    // Get the selected agency and category from map filters
    // This allows fetching vehicles from a specific transit agency and category
    final String? selectedAgency = _mapFiltersNotifier.state.selectedAgency;
    final String? selectedCategory = _mapFiltersNotifier.state.selectedCategory;

    debugPrint('🚌 Fetching vehicle positions for agency: $selectedAgency${selectedCategory != null ? " (category: $selectedCategory)" : ""}');

    // Fetch vehicle positions from the repository for the specified agency and category
    // The agency parameter is part of the URL path in the API
    // The category parameter is a query parameter for Prasarana agencies
    final Result<List<VehicleEntity>> result = await _repository.getVehiclePositions(
      agency: selectedAgency,
      category: selectedCategory,
    );

    if (result.isSuccess) {
      // Use diff-patch algorithm to efficiently update only changed vehicles
      // This prevents unnecessary UI rebuilds and improves performance
      final List<VehicleEntity> newVehicles = result.data ?? [];
      debugPrint('✅ Fetched ${newVehicles.length} vehicles from API');
      
      final List<VehicleEntity> updatedVehicles = _diffPatchVehicles(state.vehicles, newVehicles);

      // Update state with the merged vehicle list and timestamp
      state = state.copyWith(
        vehicles: updatedVehicles,
        isLoading: false,
        lastUpdate: DateTime.now(),
      );
      
      debugPrint('📊 Total vehicles in state: ${updatedVehicles.length}');
    } else {
      // Update state with error if fetch failed
      debugPrint('❌ Error fetching vehicles: ${result.failure}');
      state = state.copyWith(
        isLoading: false,
        error: result.failure,
      );
    }
  }

  /// Diff-patches vehicle lists: Updates existing, adds new, removes old
  /// 
  /// This method efficiently merges old and new vehicle lists by:
  /// 1. Starting with existing vehicles
  /// 2. Updating or adding vehicles from the new list
  /// 3. Removing vehicles that are no longer in the feed
  /// 
  /// This approach minimizes unnecessary updates and improves performance.
  /// 
  /// [oldVehicles] - The current list of vehicles
  /// [newVehicles] - The new list of vehicles from the API
  /// 
  /// Returns: A merged list of vehicles with updates applied
  List<VehicleEntity> _diffPatchVehicles(
    List<VehicleEntity> oldVehicles,
    List<VehicleEntity> newVehicles,
  ) {
    // Create a map for efficient lookups and updates
    final Map<String, VehicleEntity> vehicleMap = <String, VehicleEntity>{};

    // Step 1: Add all existing vehicles to the map
    for (final VehicleEntity vehicle in oldVehicles) {
      vehicleMap[vehicle.id] = vehicle;
    }

    // Step 2: Update or add vehicles from the new list
    // This overwrites existing vehicles with updated data
    for (final VehicleEntity vehicle in newVehicles) {
      vehicleMap[vehicle.id] = vehicle;
    }

    // Step 3: Remove vehicles that are no longer in the feed
    // Create a set of new vehicle IDs for efficient lookup
    final Set<String> newVehicleIds = newVehicles.map((VehicleEntity v) => v.id).toSet();
    // Remove any vehicles not in the new list
    vehicleMap.removeWhere((String id, VehicleEntity _) => !newVehicleIds.contains(id));

    // Return the merged list of vehicles
    return vehicleMap.values.toList();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

