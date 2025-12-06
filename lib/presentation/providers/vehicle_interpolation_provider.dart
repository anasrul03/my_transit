import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/vehicle_interpolation_service.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/entities/shape_entity.dart';
import 'gtfs_realtime_provider.dart';
import 'gtfs_static_provider.dart';

/// State class for vehicle interpolation tracking
/// 
/// Stores the interpolation state for a single vehicle, including
/// the last known position along the shape and when it was updated.
class VehicleInterpolationState {
  /// The vehicle entity with current position
  final VehicleEntity vehicle;
  
  /// The shape entity for the vehicle's route
  final ShapeEntity shape;
  
  /// Distance along shape in meters where the vehicle is located
  final double positionOnShape;
  
  /// Timestamp of the last GTFS realtime update for this vehicle
  final DateTime lastRealtimeUpdate;

  const VehicleInterpolationState({
    required this.vehicle,
    required this.shape,
    required this.positionOnShape,
    required this.lastRealtimeUpdate,
  });

  /// Creates a copy of this state with updated fields
  VehicleInterpolationState copyWith({
    VehicleEntity? vehicle,
    ShapeEntity? shape,
    double? positionOnShape,
    DateTime? lastRealtimeUpdate,
  }) {
    return VehicleInterpolationState(
      vehicle: vehicle ?? this.vehicle,
      shape: shape ?? this.shape,
      positionOnShape: positionOnShape ?? this.positionOnShape,
      lastRealtimeUpdate: lastRealtimeUpdate ?? this.lastRealtimeUpdate,
    );
  }
}

/// Global state for all vehicle interpolations
/// 
/// Contains the map of vehicle IDs to their interpolation states,
/// as well as viewport bounds for filtering visible vehicles.
class InterpolationGlobalState {
  /// Map of vehicle ID to interpolation state
  final Map<String, VehicleInterpolationState> vehicleStates;
  
  /// Current viewport bounds (nullable until map is initialized)
  final ({double minLat, double maxLat, double minLon, double maxLon})? viewportBounds;
  
  /// Whether interpolation is currently active
  final bool isActive;

  const InterpolationGlobalState({
    this.vehicleStates = const <String, VehicleInterpolationState>{},
    this.viewportBounds,
    this.isActive = false,
  });

  /// Creates a copy of this state with updated fields
  InterpolationGlobalState copyWith({
    Map<String, VehicleInterpolationState>? vehicleStates,
    ({double minLat, double maxLat, double minLon, double maxLon})? viewportBounds,
    bool? isActive,
  }) {
    return InterpolationGlobalState(
      vehicleStates: vehicleStates ?? this.vehicleStates,
      viewportBounds: viewportBounds ?? this.viewportBounds,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Provider for the vehicle interpolation service
final vehicleInterpolationServiceProvider = Provider<VehicleInterpolationService>((ref) {
  return VehicleInterpolationService();
});

/// Provider for managing vehicle interpolation state
final vehicleInterpolationProvider = StateNotifierProvider<VehicleInterpolationNotifier, InterpolationGlobalState>(
  (ref) {
    return VehicleInterpolationNotifier(
      interpolationService: ref.read(vehicleInterpolationServiceProvider),
      ref: ref,
    );
  },
);

/// Notifier for managing vehicle interpolation
/// 
/// This notifier handles the interpolation timer, tracks per-vehicle state,
/// manages shape caching, and handles lifecycle events.
class VehicleInterpolationNotifier extends StateNotifier<InterpolationGlobalState> with WidgetsBindingObserver {
  final VehicleInterpolationService _interpolationService;
  final Ref _ref;
  Timer? _interpolationTimer;
  bool _isAppInForeground = true;

  /// Creates a VehicleInterpolationNotifier instance
  /// 
  /// [interpolationService] - Service for interpolation calculations
  /// [ref] - Riverpod ref for accessing other providers
  VehicleInterpolationNotifier({
    required VehicleInterpolationService interpolationService,
    required Ref ref,
  })  : _interpolationService = interpolationService,
        _ref = ref,
        super(const InterpolationGlobalState()) {
    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    // Listen to realtime updates to initialize/reset vehicle states
    _ref.listen<GtfsRealtimeState>(
      gtfsRealtimeProvider,
      (GtfsRealtimeState? previous, GtfsRealtimeState current) {
        _onRealtimeUpdate(current);
      },
    );
  }

  /// Handle app lifecycle changes
  /// 
  /// Pauses interpolation when app goes to background to save battery.
  /// Resumes interpolation when app returns to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    super.didChangeAppLifecycleState(lifecycleState);
    
    final bool wasInForeground = _isAppInForeground;
    _isAppInForeground = lifecycleState == AppLifecycleState.resumed;
    
    // If app returned to foreground, resume interpolation
    if (!wasInForeground && _isAppInForeground) {
      debugPrint('📱 App resumed - restarting vehicle interpolation');
      if (state.isActive) {
        _startInterpolationTimer();
      }
    }
    // If app went to background, pause interpolation
    else if (wasInForeground && !_isAppInForeground) {
      debugPrint('📱 App backgrounded - pausing vehicle interpolation');
      _stopInterpolationTimer();
    }
  }

  /// Handles realtime update events
  /// 
  /// When new vehicle positions arrive from GTFS realtime, this method
  /// updates the interpolation state for each vehicle, fetching shapes
  /// as needed and resetting the last update timestamp.
  void _onRealtimeUpdate(GtfsRealtimeState realtimeState) async {
    if (!state.isActive) {
      return; // Interpolation not started yet
    }

    final DateTime updateTime = realtimeState.lastUpdate ?? DateTime.now();
    final Map<String, VehicleInterpolationState> updatedStates = <String, VehicleInterpolationState>{...state.vehicleStates};

    // Get GTFS static provider for shape lookups
    final GtfsStaticState staticState = _ref.read(gtfsStaticProvider);

    // Update state for each vehicle in the realtime feed
    for (final VehicleEntity vehicle in realtimeState.vehicles) {
      // Skip if vehicle doesn't have a trip ID
      if (vehicle.tripId.isEmpty) {
        continue;
      }

      // Get trip to find shape ID
      final gtfsStaticNotifier = _ref.read(gtfsStaticProvider.notifier);
      final trip = await gtfsStaticNotifier.getTripById(vehicle.tripId);
      
      if (trip?.shapeId == null) {
        continue; // No shape for this trip
      }

      // Get shape from static data
      final ShapeEntity? shape = staticState.shapes[trip!.shapeId];
      if (shape == null || shape.points.isEmpty) {
        continue; // Shape not available
      }

      // Check if this is a new vehicle or an update
      final VehicleInterpolationState? existingState = updatedStates[vehicle.id];
      
      if (existingState != null) {
        // Update existing vehicle with new realtime position
        // Reset position on shape to match new realtime coordinates
        final double newPosition = _interpolationService.findPositionOnShape(vehicle, shape);
        updatedStates[vehicle.id] = existingState.copyWith(
          vehicle: vehicle,
          positionOnShape: newPosition,
          lastRealtimeUpdate: updateTime,
        );
      } else {
        // New vehicle - initialize interpolation state
        final double initialPosition = _interpolationService.findPositionOnShape(vehicle, shape);
        updatedStates[vehicle.id] = VehicleInterpolationState(
          vehicle: vehicle,
          shape: shape,
          positionOnShape: initialPosition,
          lastRealtimeUpdate: updateTime,
        );
      }
    }

    // Remove vehicles that are no longer in the feed
    final Set<String> currentVehicleIds = realtimeState.vehicles.map((v) => v.id).toSet();
    updatedStates.removeWhere((id, _) => !currentVehicleIds.contains(id));

    // Update state
    state = state.copyWith(vehicleStates: updatedStates);
    
    debugPrint('🔄 Updated interpolation state for ${updatedStates.length} vehicles');
  }

  /// Starts the interpolation system
  /// 
  /// This should be called when the map is ready and viewport bounds are known.
  void start() {
    if (state.isActive) {
      return; // Already active
    }

    debugPrint('▶️ Starting vehicle interpolation');
    state = state.copyWith(isActive: true);
    _startInterpolationTimer();
  }

  /// Stops the interpolation system
  void stop() {
    if (!state.isActive) {
      return; // Already stopped
    }

    debugPrint('⏸️ Stopping vehicle interpolation');
    _stopInterpolationTimer();
    state = state.copyWith(
      isActive: false,
      vehicleStates: <String, VehicleInterpolationState>{},
    );
  }

  /// Updates the viewport bounds for filtering visible vehicles
  /// 
  /// [minLat] - Minimum latitude of viewport
  /// [maxLat] - Maximum latitude of viewport
  /// [minLon] - Minimum longitude of viewport
  /// [maxLon] - Maximum longitude of viewport
  void updateViewportBounds({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
  }) {
    state = state.copyWith(
      viewportBounds: (minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon),
    );
  }

  /// Gets the list of interpolated vehicles currently visible in viewport
  /// 
  /// Returns: List of interpolated vehicle entities for visible vehicles only
  List<VehicleEntity> getVisibleInterpolatedVehicles() {
    if (state.viewportBounds == null) {
      return <VehicleEntity>[]; // No viewport bounds set
    }

    final List<VehicleEntity> visibleVehicles = <VehicleEntity>[];
    final bounds = state.viewportBounds!;

    for (final vehicleState in state.vehicleStates.values) {
      // Check if vehicle is in viewport
      if (_interpolationService.isVehicleInViewport(
        vehicle: vehicleState.vehicle,
        minLat: bounds.minLat,
        maxLat: bounds.maxLat,
        minLon: bounds.minLon,
        maxLon: bounds.maxLon,
      )) {
        visibleVehicles.add(vehicleState.vehicle);
      }
    }

    return visibleVehicles;
  }

  /// Starts the interpolation timer
  /// 
  /// Creates a periodic timer that runs at the interpolation interval
  /// (100ms by default) to update vehicle positions.
  void _startInterpolationTimer() {
    // Cancel existing timer if any
    _stopInterpolationTimer();
    
    // Only start if app is in foreground
    if (!_isAppInForeground) {
      debugPrint('📱 App in background - skipping interpolation timer start');
      return;
    }

    // Start periodic timer
    _interpolationTimer = Timer.periodic(
      ApiConstants.interpolationInterval,
      (_) {
        if (_isAppInForeground && state.isActive) {
          _performInterpolation();
        }
      },
    );
    
    debugPrint('⏱️ Interpolation timer started (${ApiConstants.interpolationInterval.inMilliseconds}ms interval)');
  }

  /// Stops the interpolation timer
  void _stopInterpolationTimer() {
    _interpolationTimer?.cancel();
    _interpolationTimer = null;
  }

  /// Performs one interpolation cycle for all tracked vehicles
  /// 
  /// This is called by the interpolation timer at regular intervals.
  /// It calculates new positions for all visible vehicles and updates the state.
  void _performInterpolation() {
    if (state.viewportBounds == null || state.vehicleStates.isEmpty) {
      return; // Nothing to interpolate
    }

    final Map<String, VehicleInterpolationState> updatedStates = <String, VehicleInterpolationState>{...state.vehicleStates};
    int interpolatedCount = 0;

    final bounds = state.viewportBounds!;

    // Interpolate each vehicle
    for (final entry in state.vehicleStates.entries) {
      final String vehicleId = entry.key;
      final VehicleInterpolationState vehicleState = entry.value;

      // Only interpolate vehicles in viewport
      if (!_interpolationService.isVehicleInViewport(
        vehicle: vehicleState.vehicle,
        minLat: bounds.minLat,
        maxLat: bounds.maxLat,
        minLon: bounds.minLon,
        maxLon: bounds.maxLon,
      )) {
        continue;
      }

      // Calculate interpolated position
      final result = _interpolationService.calculateInterpolatedPosition(
        vehicle: vehicleState.vehicle,
        shape: vehicleState.shape,
        lastUpdateTime: vehicleState.lastRealtimeUpdate,
        currentPositionOnShape: vehicleState.positionOnShape,
      );

      if (result != null) {
        // Update state with interpolated position
        updatedStates[vehicleId] = vehicleState.copyWith(
          vehicle: result.vehicle,
          positionOnShape: result.positionOnShape,
        );
        interpolatedCount++;
      }
    }

    // Update state if any vehicles were interpolated
    if (interpolatedCount > 0) {
      state = state.copyWith(vehicleStates: updatedStates);
    }
  }

  @override
  void dispose() {
    // Clean up lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Stop interpolation timer
    _stopInterpolationTimer();
    
    super.dispose();
  }
}

