import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
    final notifier = GtfsRealtimeNotifier(
      repository: ref.read(gtfsRealtimeRepositoryProvider),
      mapFiltersNotifier: ref.read(mapFiltersProvider.notifier),
    );
    
    // Listen to filter changes and immediately fetch new data when agency or category changes
    // This ensures the map updates immediately when the user selects a different operator
    ref.listen<MapFiltersState>(
      mapFiltersProvider,
      (MapFiltersState? previous, MapFiltersState current) {
        // Only fetch if agency or category actually changed
        if (previous != null &&
            (previous.selectedAgency != current.selectedAgency ||
             previous.selectedCategory != current.selectedCategory)) {
          debugPrint('🔄 Filter changed - fetching vehicles for new agency/category');
          notifier.fetchVehiclePositions();
        }
      },
    );
    
    return notifier;
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

class GtfsRealtimeNotifier extends StateNotifier<GtfsRealtimeState> with WidgetsBindingObserver {
  final GtfsRealtimeRepository _repository;
  final MapFiltersNotifier _mapFiltersNotifier;
  Timer? _pollTimer;
  bool _isAppInForeground = true;

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
    // Register lifecycle observer to detect app background/foreground state
    WidgetsBinding.instance.addObserver(this);
    _startPolling();
  }
  
  /// Handle app lifecycle changes
  /// 
  /// Pauses polling when app goes to background to save battery and data.
  /// Resumes polling when app returns to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final bool wasInForeground = _isAppInForeground;
    _isAppInForeground = state == AppLifecycleState.resumed;
    
    // If app returned to foreground, resume polling and fetch immediately
    if (!wasInForeground && _isAppInForeground) {
      debugPrint('📱 App resumed - restarting vehicle position polling');
      _startPolling();
      fetchVehiclePositions(); // Fetch immediately to get fresh data
    }
    // If app went to background, pause polling to save resources
    else if (wasInForeground && !_isAppInForeground) {
      debugPrint('📱 App backgrounded - pausing vehicle position polling');
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  /// Starts polling for vehicle position updates
  /// 
  /// This method immediately fetches vehicle positions, then sets up a
  /// periodic timer to fetch updates at the interval specified in API constants.
  /// The polling ensures the map always shows current vehicle positions.
  /// 
  /// Only starts polling if app is in foreground to conserve resources.
  void _startPolling() {
    // Cancel existing timer if any
    _pollTimer?.cancel();
    
    // Only start polling if app is in foreground
    if (!_isAppInForeground) {
      debugPrint('📱 App in background - skipping polling start');
      return;
    }
    
    // Fetch immediately to get initial vehicle positions
    fetchVehiclePositions();

    // Set up periodic polling to update vehicle positions regularly
    // Uses the realtime poll interval from API constants (30 seconds)
    _pollTimer = Timer.periodic(
      ApiConstants.realtimePollInterval,
      (_) {
        // Only fetch if app is in foreground
        if (_isAppInForeground) {
          fetchVehiclePositions();
        }
      },
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

  /// Diff-patches vehicle lists: Updates existing, adds new, removes old and stale
  /// 
  /// This method efficiently merges old and new vehicle lists by:
  /// 1. Starting with existing vehicles that are not stale
  /// 2. Updating or adding vehicles from the new list
  /// 3. Removing vehicles that are no longer in the feed
  /// 4. Removing vehicles older than 5 minutes (stale vehicles)
  /// 
  /// This approach minimizes unnecessary updates, improves performance,
  /// and reduces memory usage by removing inactive vehicles.
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

    // Calculate cutoff time for stale vehicles (5 minutes ago)
    final DateTime staleThreshold = DateTime.now().subtract(
      const Duration(minutes: 5),
    );

    // Step 1: Add existing vehicles that are not stale to the map
    // This filters out vehicles that haven't been updated in 5+ minutes
    int staleCount = 0;
    for (final VehicleEntity vehicle in oldVehicles) {
      // Keep only vehicles with recent timestamps
      if (vehicle.timestamp.isAfter(staleThreshold)) {
      vehicleMap[vehicle.id] = vehicle;
      } else {
        staleCount++;
      }
    }
    
    // Log stale vehicle cleanup if any were removed
    if (staleCount > 0) {
      debugPrint('🧹 Removed $staleCount stale vehicles (>5 minutes old)');
    }

    // Step 2: Update or add vehicles from the new list
    // This overwrites existing vehicles with updated data
    for (final VehicleEntity vehicle in newVehicles) {
      vehicleMap[vehicle.id] = vehicle;
    }

    // Step 3: Remove vehicles that are no longer in the feed
    // Create a set of new vehicle IDs for efficient lookup
    final Set<String> newVehicleIds = newVehicles.map((VehicleEntity v) => v.id).toSet();
    
    // Count removed vehicles for logging
    final int beforeRemoval = vehicleMap.length;
    
    // Remove any vehicles not in the new list (unless they're still fresh)
    // We keep vehicles not in the feed if they're less than 5 minutes old
    // This handles temporary API glitches or missing data
    vehicleMap.removeWhere((String id, VehicleEntity vehicle) {
      // Keep if in new list
      if (newVehicleIds.contains(id)) return false;
      
      // Remove if too old (handled in step 1, but double-check)
      return vehicle.timestamp.isBefore(staleThreshold);
    });
    
    final int removedCount = beforeRemoval - vehicleMap.length;
    if (removedCount > 0) {
      debugPrint('🗑️ Removed $removedCount vehicles no longer in feed');
    }

    // Return the merged list of vehicles
    return vehicleMap.values.toList();
  }

  @override
  void dispose() {
    // Clean up lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Cancel polling timer
    _pollTimer?.cancel();
    
    super.dispose();
  }
}

