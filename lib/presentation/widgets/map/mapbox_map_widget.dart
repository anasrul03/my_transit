import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../../core/services/mapbox_service.dart';
import '../../../core/services/vehicle_marker_service.dart';
import '../../../core/services/route_shape_service.dart';
import '../../../domain/entities/vehicle_entity.dart';
import '../../../domain/entities/shape_entity.dart';
import '../../../domain/entities/trip_entity.dart';
import '../../../domain/entities/route_entity.dart';
import '../../../domain/usecases/interpolate_vehicle_position.dart';
import '../../providers/connectivity_provider.dart';
import '../../providers/gtfs_realtime_provider.dart';
import '../../providers/gtfs_static_provider.dart';
import '../../providers/map_filters_provider.dart';
import '../../providers/map_widget_provider.dart';
import '../../providers/route_highlight_provider.dart';
import 'operator_selection_button.dart';
import 'vehicle_info_sheet.dart';
import 'vehicle_list_panel.dart';
import '../../widgets/data_freshness_indicator.dart';
import '../../widgets/gtfs_error_banner.dart';

/// Internal class to track vehicle animation state
/// 
/// Stores the last known position and timestamp for interpolation calculations.
class _VehicleAnimationState {
  final VehicleEntity lastVehicle;
  final DateTime lastUpdateTime;
  final double? lastInterpolationFactor;

  _VehicleAnimationState({
    required this.lastVehicle,
    required this.lastUpdateTime,
    this.lastInterpolationFactor,
  });
}

/// Widget that displays a Mapbox map with connectivity and error handling
/// 
/// This widget manages the Mapbox map initialization, loading states,
/// error handling, and connectivity checks. It uses Riverpod for state
/// management instead of setState to comply with project coding standards.
class MapboxMapWidget extends ConsumerStatefulWidget {
  const MapboxMapWidget({super.key});

  @override
  ConsumerState<MapboxMapWidget> createState() => _MapboxMapWidgetState();
}

class _MapboxMapWidgetState extends ConsumerState<MapboxMapWidget> {
  /// Reference to the MapboxMap instance once created
  MapboxMap? mapboxMap;
  
  /// Reference to the CircleAnnotationManager for vehicle markers
  /// 
  /// This manager handles all vehicle markers on the map, allowing
  /// efficient addition, update, and removal of markers.
  /// Using CircleAnnotation instead of PointAnnotation because it doesn't
  /// require images and is simpler to use.
  CircleAnnotationManager? _circleAnnotationManager;
  
  /// Reference to the PolylineAnnotationManager for route shape drawing
  /// 
  /// This manager handles drawing route shapes as polylines when vehicles are clicked.
  PolylineAnnotationManager? _polylineAnnotationManager;
  
  /// Map of vehicle IDs to their CircleAnnotation objects
  /// 
  /// This is used to efficiently track which vehicles are currently
  /// displayed and their annotation objects for updates and deletion.
  final Map<String, CircleAnnotation> _currentAnnotations = <String, CircleAnnotation>{};
  
  /// Currently highlighted route polyline annotation, if any
  /// 
  /// This is used to remove the previous highlight when a new one is set.
  PolylineAnnotation? _currentRouteHighlight;
  
  /// Cache for trip lookups to avoid repeated repository calls
  /// 
  /// Maps tripId to TripEntity for efficient lookups.
  final Map<String, TripEntity?> _tripCache = <String, TripEntity?>{};
  
  /// Cache for route lookups to avoid repeated repository calls
  /// 
  /// Maps routeId to RouteEntity for efficient lookups.
  final Map<String, RouteEntity?> _routeCache = <String, RouteEntity?>{};
  
  /// Timer for smooth vehicle animation along route shapes
  /// 
  /// Runs at 0.1 second intervals (10 Hz) to animate vehicles smoothly.
  Timer? _animationTimer;
  
  /// Timer for debouncing marker updates
  /// 
  /// Prevents excessive marker updates when vehicle data changes rapidly.
  /// Debounce delay: 250ms to balance responsiveness and performance.
  Timer? _markerUpdateTimer;
  
  /// Last processed vehicle count to prevent redundant updates
  /// 
  /// Tracks the number of vehicles that were last processed to avoid
  /// unnecessary marker updates when the vehicle list hasn't actually changed.
  int _lastProcessedVehicleCount = -1;
  
  /// Map of vehicle IDs to their last known position and timestamp
  /// 
  /// Used for calculating interpolation progress for smooth animation.
  final Map<String, _VehicleAnimationState> _vehicleAnimationStates = <String, _VehicleAnimationState>{};
  
  /// Use case for interpolating vehicle positions along shapes
  final InterpolateVehiclePositionUseCase _interpolationUseCase = InterpolateVehiclePositionUseCase();
  
  /// Flag to track if this widget has been disposed
  bool _isDisposed = false;

  /// Previous vehicle state to detect changes
  /// 
  /// Used to track when vehicle data actually changes to avoid
  /// unnecessary marker updates.
  GtfsRealtimeState? _previousRealtimeState;
  
  /// Previous filter state to detect changes
  /// 
  /// Used to track when filter settings change to trigger marker updates.
  MapFiltersState? _previousFiltersState;

  @override
  void initState() {
    super.initState();
    // Delay connectivity check until after the widget tree is built
    // This prevents Riverpod errors about modifying providers during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMap();
    });
  }

  /// Schedules a debounced marker update
  /// 
  /// Cancels any pending marker update timer and schedules a new one
  /// after a short delay (250ms). This prevents excessive updates when
  /// vehicle data changes rapidly.
  void _scheduleMarkerUpdate() {
    // Cancel any pending update
    _markerUpdateTimer?.cancel();
    
    // Schedule new update after debounce delay
    _markerUpdateTimer = Timer(const Duration(milliseconds: 250), () {
      if (!_isDisposed && mounted) {
        _updateVehicleMarkers();
      }
    });
  }

  /// Initializes the map by checking connectivity first
  /// 
  /// This ensures we have internet connectivity before attempting
  /// to load the map, providing better user feedback.
  Future<void> _initializeMap() async {
    // Check connectivity first to provide immediate feedback
    // This is now safe to call after the build phase completes
    await ref.read(connectivityProvider.notifier).checkConnectivity();
  }

  /// Callback invoked when the Mapbox map is successfully created
  /// 
  /// [mapboxMap] - The created MapboxMap instance
  /// 
  /// This method handles the map creation, sets the initial camera position,
  /// and updates the widget state to reflect successful initialization.
  void _onMapCreated(MapboxMap mapboxMap) {
    final MapWidgetState currentState = ref.read(mapWidgetStateProvider);
    
    // Prevent duplicate map creations
    if (_isDisposed || currentState.mapCreated) return;
    
    // Store the map reference and mark as created
    this.mapboxMap = mapboxMap;
    ref.read(mapWidgetStateProvider.notifier).markMapCreated();
    
    debugPrint('✅ Mapbox map created successfully (count: ${currentState.mapCreationCount + 1})');
    
    // Set initial camera position after a short delay to ensure map is ready
    // This delay helps prevent race conditions during map initialization
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (_isDisposed || !mounted) return;
      
      try {
        // Set camera to Kuala Lumpur coordinates (default location)
        await mapboxMap.setCamera(
          CameraOptions(
            center: Point(coordinates: Position(101.6869, 3.1390)), // KL coordinates
            zoom: 12.0,
            bearing: 0.0,
            pitch: 0.0,
          ),
        );
        debugPrint('✅ Camera position set successfully');
        
        // Clear loading state if no errors occurred
        if (mounted && !currentState.hasError) {
          ref.read(mapWidgetStateProvider.notifier).setLoading(false);
        }
      } catch (e) {
        debugPrint('❌ Error setting camera: $e');
        // Update error state if camera setup fails
        if (mounted) {
          ref.read(mapWidgetStateProvider.notifier).setError(
            hasError: true,
            errorMessage: e.toString(),
          );
        }
      }
    });
  }
  
  /// Callback invoked when the map style has finished loading
  /// 
  /// [data] - Event data containing style loading information
  /// 
  /// This clears any previous errors once the style loads successfully,
  /// indicating the map is ready for use. It also initializes the
  /// PointAnnotationManager for vehicle markers.
  void _onStyleLoadedListener(StyleLoadedEventData data) async {
    final MapWidgetState currentState = ref.read(mapWidgetStateProvider);
    
    // Ignore style loaded events if map hasn't been created yet
    if (!currentState.mapCreated || mapboxMap == null) {
      debugPrint('⚠️ Style loaded before map created - ignoring');
      return;
    }
    
    debugPrint('✅ Map style loaded successfully');
    
    // Initialize CircleAnnotationManager after style loads
    // This must be done after the style is loaded to ensure the manager
    // can properly attach to the map style
    // Using CircleAnnotation instead of PointAnnotation because it doesn't
    // require images and is simpler to use
    try {
      _circleAnnotationManager = await mapboxMap!.annotations
          .createCircleAnnotationManager();
      debugPrint('✅ CircleAnnotationManager created successfully');
      
      // Initialize PolylineAnnotationManager for route shape drawing
      _polylineAnnotationManager = await mapboxMap!.annotations
          .createPolylineAnnotationManager();
      debugPrint('✅ PolylineAnnotationManager created successfully');
      
      // Set up annotation click listener for vehicle marker clicks
      // Note: We'll implement click handling through map gesture detection
      // The click handler method is ready but needs to be wired up based on Mapbox API version
      
      // Start animation timer for smooth vehicle movement
      _startAnimationTimer();
      
      // Update markers with current vehicles if available
      // Use debounced update to prevent conflicts with listener-based updates
      if (mounted) {
        _scheduleMarkerUpdate();
      }
    } catch (e) {
      debugPrint('❌ Error creating annotation managers: $e');
    }
    
    // Clear error state if style loads successfully after an error
    if (mounted && currentState.hasError) {
      ref.read(mapWidgetStateProvider.notifier).clearError();
    }
  }
  
  /// Callback invoked when an error occurs during map loading
  /// 
  /// [data] - Event data containing error message and type
  /// 
  /// This updates the error state to display the error message to the user
  /// and allows them to retry the map loading.
  void _onMapLoadErrorListener(MapLoadingErrorEventData data) {
    debugPrint('❌ Map load error: ${data.message}, type: ${data.type}');
    
    // Update error state with the error message from Mapbox
    if (mounted) {
      ref.read(mapWidgetStateProvider.notifier).setError(
        hasError: true,
        errorMessage: data.message,
      );
    }
  }

  /// Retries the map connection after an error
  /// 
  /// This method resets the error state, checks connectivity again,
  /// and prepares the widget for a new map initialization attempt.
  Future<void> _retryConnection() async {
    final MapWidgetStateNotifier notifier = ref.read(mapWidgetStateProvider.notifier);
    
    // Set retry state and reset error/map creation flags
    notifier.setRetrying(true);
    notifier.resetMapCreation();

    // Force a connectivity check to ensure we have internet
    await ref.read(connectivityProvider.notifier).checkConnectivity();
    
    // Small delay to allow connectivity check to complete
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Reset retry state and set loading state for new attempt
    if (mounted) {
      notifier.setRetrying(false);
      notifier.setLoading(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch connectivity, map widget state, vehicle positions, and operator filter
    final ConnectivityState connectivityState = ref.watch(connectivityProvider);
    final MapWidgetState mapWidgetState = ref.watch(mapWidgetStateProvider);
    final RouteHighlightState highlightState = ref.watch(routeHighlightProvider);
    final GtfsRealtimeState realtimeState = ref.watch(gtfsRealtimeProvider); // Watch for vehicle updates
    final MapFiltersState filtersState = ref.watch(mapFiltersProvider); // Watch for filter changes
    
    // Check if vehicle data or filters changed and schedule marker update
    // This is more efficient than post-frame callbacks on every rebuild
    if (mapWidgetState.mapCreated && 
        _circleAnnotationManager != null && 
        !_isDisposed) {
      // Check if vehicle data changed
      final bool vehiclesChanged = _previousRealtimeState == null ||
          _previousRealtimeState!.vehicles.length != realtimeState.vehicles.length ||
          _previousRealtimeState!.lastUpdate != realtimeState.lastUpdate;
      
      // Check if filters changed
      final bool filtersChanged = _previousFiltersState == null ||
          _previousFiltersState!.selectedAgency != filtersState.selectedAgency ||
          _previousFiltersState!.selectedCategory != filtersState.selectedCategory;
      
      if (vehiclesChanged || filtersChanged) {
        _previousRealtimeState = realtimeState;
        _previousFiltersState = filtersState;
        _scheduleMarkerUpdate();
      }
    }
    
    // Update route highlight when highlight state changes
    if (mapWidgetState.mapCreated && 
        _polylineAnnotationManager != null && 
        !_isDisposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDisposed) {
          _updateRouteHighlight(highlightState);
        }
      });
    }

    // Check if Mapbox access token is configured
    // Without the token, the map cannot be initialized
    if (!MapboxService.isConfigured) {
      return _buildErrorState(
        icon: Icons.vpn_key_off,
        title: 'Mapbox Access Token Required',
        message: 'Mapbox access token is not configured.\n\n'
            'To fix this:\n'
            '1. Get a token from https://account.mapbox.com/access-tokens/\n'
            '2. Run: flutter run --dart-define ACCESS_TOKEN=pk.your_token_here\n\n'
            'Note: The token must start with "pk." (public token)',
        action: null,
      );
    }

    // Show no connection error only before map is created
    // Once map is created, we show a connectivity indicator instead
    if (!connectivityState.isConnected && 
        !mapWidgetState.isRetrying && 
        !mapWidgetState.mapCreated) {
      return _buildErrorState(
        icon: Icons.wifi_off,
        title: 'No Internet Connection',
        message: 'Please check your internet connection and try again',
        action: _buildRetryButton(),
      );
    }

    // Show loading state while checking connectivity or retrying
    if ((connectivityState.isChecking || mapWidgetState.isRetrying) && 
        !mapWidgetState.mapCreated) {
      return _buildLoadingState('Checking connection...');
    }

    // Build the map widget with overlays
    // Once map is created, we keep it stable to prevent unnecessary rebuilds
    return Stack(
      children: [
        // Map Widget - stable key prevents rebuilds
        MapWidget(
          key: const ValueKey("mapWidget_stable"),
          cameraOptions: CameraOptions(
            center: Point(coordinates: Position(101.6869, 3.1390)), // KL coordinates
            zoom: 12.0,
            bearing: 0.0,
            pitch: 0.0,
          ),
          styleUri: 'mapbox://styles/mapbox/streets-v12',
          textureView: true,
          onMapCreated: _onMapCreated,
          onStyleLoadedListener: _onStyleLoadedListener,
          onMapLoadErrorListener: _onMapLoadErrorListener,
        ),
        
        // Loading overlay - shown while map is loading and no errors
        if (mapWidgetState.isLoading && !mapWidgetState.hasError)
          _buildLoadingState('Loading map tiles...'),
        
        // Error overlay - shown when an error occurs
        if (mapWidgetState.hasError)
          _buildErrorOverlay(),
        
        // Connectivity indicator - shown at top when map is created but offline
        if (mapWidgetState.mapCreated)
          _buildConnectivityIndicator(connectivityState),
        
        // Operator selection floating action button
        // Positioned at bottom-right when map is created
        if (mapWidgetState.mapCreated)
          Positioned(
            bottom: 16,
            right: 16,
            child: const OperatorSelectionButton(),
          ),
        
        // Data freshness indicator - shown at top-left when map is created
        if (mapWidgetState.mapCreated)
          Positioned(
            top: 16,
            left: 16,
            child: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final GtfsRealtimeState realtimeState = ref.watch(gtfsRealtimeProvider);
                return DataFreshnessIndicator(
                  lastUpdate: realtimeState.lastUpdate,
                  compact: true,
                );
              },
            ),
          ),
        
        // Error banner - shown at top when there are data quality warnings
        if (mapWidgetState.mapCreated)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? child) {
                final GtfsRealtimeState realtimeState = ref.watch(gtfsRealtimeProvider);
                // Collect all unique error codes from vehicles
                final Set<String> allErrorCodes = <String>{};
                for (final VehicleEntity vehicle in realtimeState.vehicles) {
                  if (vehicle.dataQualityWarnings != null) {
                    allErrorCodes.addAll(vehicle.dataQualityWarnings!);
                  }
                }
                if (allErrorCodes.isEmpty) {
                  return const SizedBox.shrink();
                }
                return GtfsErrorBanner(
                  errorCodes: allErrorCodes.toList(),
                  compact: true,
                );
              },
            ),
          ),
        
        // Vehicle list panel - shown at top-right when map is created
        if (mapWidgetState.mapCreated)
          const VehicleListPanel(),
      ],
    );
  }
  


  /// Checks if coordinates are valid for Malaysia
  /// 
  /// [latitude] - The latitude to validate
  /// [longitude] - The longitude to validate
  /// 
  /// Returns: true if coordinates are within Malaysia bounds, false otherwise
  /// Malaysia bounds: approximately 0.85°N to 7.36°N, 99.64°E to 119.27°E
  /// Also rejects (0.0, 0.0) which indicates missing position data
  bool _isValidCoordinate(double latitude, double longitude) {
    // Reject (0.0, 0.0) which is the default for missing position data
    // This coordinate is in the Gulf of Guinea, far from Malaysia
    if (latitude == 0.0 && longitude == 0.0) {
      return false;
    }
    
    // Check if coordinates are within Malaysia bounds
    // Malaysia bounds: approximately 0.85°N to 7.36°N, 99.64°E to 119.27°E
    // Using slightly expanded bounds for safety: 0.0°N to 8.0°N, 99.0°E to 120.0°E
    if (latitude < 0.0 || latitude > 8.0) {
      return false;
    }
    if (longitude < 99.0 || longitude > 120.0) {
      return false;
    }
    
    return true;
  }

  /// Updates vehicle markers on the map based on current vehicle positions
  /// 
  /// This method uses a diff-patch algorithm to efficiently update markers:
  /// - Adds new markers for vehicles not currently displayed
  /// - Updates existing markers for vehicles that have moved
  /// - Removes markers for vehicles that are no longer in the feed
  /// 
  /// The method filters vehicles by the selected operator and validates
  /// coordinates before displaying them.
  Future<void> _updateVehicleMarkers() async {
    // Early return if manager is not initialized or widget is disposed
    if (_circleAnnotationManager == null || _isDisposed || !mounted) {
      debugPrint('⚠️ Cannot update markers: manager=${_circleAnnotationManager != null}, disposed=$_isDisposed, mounted=$mounted');
      return;
    }
    
    try {
      // Get current vehicle positions and operator filter
      final GtfsRealtimeState realtimeState = ref.read(gtfsRealtimeProvider);
      final MapFiltersState filtersState = ref.read(mapFiltersProvider);
      final List<VehicleEntity> vehicles = realtimeState.vehicles;
      
      // Skip update if vehicle count hasn't changed (prevents redundant updates)
      if (vehicles.length == _lastProcessedVehicleCount && 
          _lastProcessedVehicleCount > 0) {
        debugPrint('⏭️ Skipping marker update: vehicle count unchanged (${vehicles.length})');
        return;
      }
      
      _lastProcessedVehicleCount = vehicles.length;
      debugPrint('📍 Updating markers: ${vehicles.length} total vehicles, selectedAgency=${filtersState.selectedAgency}');
      
      // Filter vehicles to only include those with valid coordinates
      // This is a safety check - most invalid coordinates should already be filtered during parsing
      // This prevents markers from being placed off-screen (e.g., at 0.0, 0.0)
      final List<VehicleEntity> validVehicles = <VehicleEntity>[];
      int filteredCount = 0;
      
      for (final VehicleEntity vehicle in vehicles) {
        if (_isValidCoordinate(vehicle.latitude, vehicle.longitude)) {
          validVehicles.add(vehicle);
        } else {
          filteredCount++;
        }
      }
      
      // Only log if we filtered out vehicles (should be rare now)
      if (filteredCount > 0) {
        debugPrint('🚫 Filtered out $filteredCount vehicles with invalid coordinates (safety check)');
      }
      
      debugPrint('✅ ${validVehicles.length} vehicles with valid coordinates will be displayed');
      
      // Note: Vehicles are already filtered by agency at the API level
      // The API fetches vehicles for the selected agency, so we don't need
      // to filter client-side. However, we keep this for safety and consistency.
      // If selectedAgency is null, show all vehicles (though API will use default)
      final List<VehicleEntity> filteredVehicles = validVehicles;
      
      // Create set of new vehicle IDs for efficient lookup
      final Set<String> newVehicleIds = filteredVehicles
          .map((VehicleEntity v) => v.id)
          .toSet();
      
      // Find vehicles to remove (in current set but not in new set)
      final Set<String> vehiclesToRemove = _currentAnnotations.keys
          .toSet()
          .difference(newVehicleIds);
      
      // Remove markers for vehicles no longer in the feed
      for (final String vehicleId in vehiclesToRemove) {
        final CircleAnnotation? annotation = _currentAnnotations[vehicleId];
        if (annotation != null) {
          await _circleAnnotationManager!.delete(annotation);
          _currentAnnotations.remove(vehicleId);
        }
      }
      if (vehiclesToRemove.isNotEmpty) {
        debugPrint('🗑️ Removed ${vehiclesToRemove.length} vehicle markers');
      }
      
      // Find vehicles to add (in new set but not in current set)
      final Set<String> vehiclesToAdd = newVehicleIds
          .difference(_currentAnnotations.keys.toSet());
      
      // Find vehicles to update (in both sets, but position may have changed)
      final Set<String> vehiclesToUpdate = _currentAnnotations.keys
          .toSet()
          .intersection(newVehicleIds);
      
      // Create annotations for new vehicles
      for (final VehicleEntity vehicle in filteredVehicles) {
        if (vehiclesToAdd.contains(vehicle.id)) {
          try {
            // Double-check coordinates are valid before creating marker
            if (!_isValidCoordinate(vehicle.latitude, vehicle.longitude)) {
              debugPrint('⚠️ Skipping marker creation for vehicle ${vehicle.id}: invalid coordinates (${vehicle.latitude}, ${vehicle.longitude})');
              continue;
            }
            
            final CircleAnnotationOptions options = 
                VehicleMarkerService.createAnnotationFromVehicle(vehicle);
            final CircleAnnotation annotation = 
                await _circleAnnotationManager!.create(options);
            _currentAnnotations[vehicle.id] = annotation;
            debugPrint('✅ Created marker for vehicle ${vehicle.id} at (${vehicle.latitude}, ${vehicle.longitude})');
          } catch (e) {
            debugPrint('❌ Error creating marker for vehicle ${vehicle.id}: $e');
          }
        }
      }
      if (vehiclesToAdd.isNotEmpty) {
        debugPrint('➕ Added ${vehiclesToAdd.length} vehicle markers');
      }
      
      // Update annotations for existing vehicles (position changes)
      // For updates, we delete and recreate the annotation
      // This is simpler than trying to update individual properties
      for (final VehicleEntity vehicle in filteredVehicles) {
        if (vehiclesToUpdate.contains(vehicle.id)) {
          // Double-check coordinates are valid before updating marker
          if (!_isValidCoordinate(vehicle.latitude, vehicle.longitude)) {
            debugPrint('⚠️ Skipping marker update for vehicle ${vehicle.id}: invalid coordinates (${vehicle.latitude}, ${vehicle.longitude})');
            // Remove the marker if coordinates became invalid
            final CircleAnnotation? oldAnnotation = _currentAnnotations[vehicle.id];
            if (oldAnnotation != null) {
              await _circleAnnotationManager!.delete(oldAnnotation);
              _currentAnnotations.remove(vehicle.id);
            }
            continue;
          }
          
          final CircleAnnotation? oldAnnotation = _currentAnnotations[vehicle.id];
          if (oldAnnotation != null) {
            await _circleAnnotationManager!.delete(oldAnnotation);
          }
          
          final CircleAnnotationOptions options = 
              VehicleMarkerService.createAnnotationFromVehicle(vehicle);
          final CircleAnnotation newAnnotation = 
              await _circleAnnotationManager!.create(options);
          _currentAnnotations[vehicle.id] = newAnnotation;
        }
      }
      if (vehiclesToUpdate.isNotEmpty) {
        debugPrint('🔄 Updated ${vehiclesToUpdate.length} vehicle markers');
      }
    } catch (e) {
      debugPrint('❌ Error updating vehicle markers: $e');
    }
  }

  /// Builds a loading state widget with a progress indicator
  /// 
  /// [message] - The message to display to the user while loading
  /// 
  /// Returns a centered loading widget with a progress indicator and message
  Widget _buildLoadingState(String message) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Colors.blue,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This may take a few seconds',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a full-screen error state widget
  /// 
  /// [icon] - Icon to display for the error
  /// [title] - Title text for the error
  /// [message] - Detailed error message
  /// [action] - Optional action widget (e.g., retry button)
  /// 
  /// Returns a centered error widget with icon, title, message, and optional action
  Widget _buildErrorState({
    required IconData icon,
    required String title,
    required String message,
    required Widget? action,
  }) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 80,
                color: Colors.white30,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[
                const SizedBox(height: 32),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an error overlay that appears on top of the map
  /// 
  /// This overlay displays when the map fails to load, showing
  /// an error icon, message, and a retry button.
  Widget _buildErrorOverlay() {
    final MapWidgetState mapWidgetState = ref.read(mapWidgetStateProvider);
    
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                'Map Loading Failed',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                mapWidgetState.errorMessage ?? 'An error occurred while loading the map',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              _buildRetryButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a retry button for reattempting map connection
  /// 
  /// The button shows a loading indicator while retrying and
  /// is disabled during the retry operation.
  Widget _buildRetryButton() {
    final MapWidgetState mapWidgetState = ref.read(mapWidgetStateProvider);
    
    return ElevatedButton.icon(
      onPressed: mapWidgetState.isRetrying ? null : _retryConnection,
      icon: mapWidgetState.isRetrying
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.refresh),
      label: Text(mapWidgetState.isRetrying ? 'Retrying...' : 'Try Again'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Builds a connectivity indicator that shows at the top when offline
  /// 
  /// [state] - The current connectivity state
  /// 
  /// Returns a positioned widget showing offline status, or an empty
  /// widget if connected or if there's an error.
  Widget _buildConnectivityIndicator(ConnectivityState state) {
    final MapWidgetState mapWidgetState = ref.read(mapWidgetStateProvider);
    
    // Hide indicator if connected or if there's an error (error overlay handles that)
    if (state.isConnected || mapWidgetState.hasError) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        color: Colors.orange.withOpacity(0.9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Offline',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gets the shape entity for a vehicle by looking up its trip
  /// 
  /// [vehicle] - The vehicle entity to get the shape for
  /// 
  /// Returns: The ShapeEntity if found, or null if not found
  /// This method caches trip lookups to improve performance.
  Future<ShapeEntity?> _getShapeForVehicle(VehicleEntity vehicle) async {
    try {
      // Get trip from cache or repository
      TripEntity? trip = _tripCache[vehicle.tripId];
      if (trip == null) {
        final gtfsStaticNotifier = ref.read(gtfsStaticProvider.notifier);
        trip = await gtfsStaticNotifier.getTripById(vehicle.tripId);
        _tripCache[vehicle.tripId] = trip;
      }

      if (trip?.shapeId == null) {
        return null;
      }

      // Get shape from GTFS static provider
      final gtfsStaticState = ref.read(gtfsStaticProvider);
      return gtfsStaticState.shapes[trip!.shapeId];
    } catch (e) {
      debugPrint('❌ Error getting shape for vehicle ${vehicle.id}: $e');
      return null;
    }
  }

  /// Gets the route entity for a vehicle
  /// 
  /// [vehicle] - The vehicle entity to get the route for
  /// 
  /// Returns: The RouteEntity if found, or null if not found
  /// This method caches route lookups to improve performance.
  Future<RouteEntity?> _getRouteForVehicle(VehicleEntity vehicle) async {
    try {
      // Check cache first
      RouteEntity? route = _routeCache[vehicle.routeId];
      if (route != null) {
        return route;
      }

      // Get route from GTFS static provider
      final gtfsStaticState = ref.read(gtfsStaticProvider);
      route = gtfsStaticState.routes.firstWhere(
        (RouteEntity r) => r.id == vehicle.routeId,
        orElse: () => throw Exception('Route not found'),
      );

      // Cache the route
      _routeCache[vehicle.routeId] = route;
      return route;
    } catch (e) {
      debugPrint('❌ Error getting route for vehicle ${vehicle.id}: $e');
      return null;
    }
  }

  /// Handles click events on vehicle markers
  /// 
  /// [annotation] - The circle annotation that was clicked
  /// 
  /// When a vehicle marker is clicked, this method:
  /// 1. Finds the vehicle associated with the clicked annotation
  /// 2. Shows vehicle information in a bottom sheet
  /// 3. Gets the vehicle's trip and shape
  /// 4. Gets the route color
  /// 5. Highlights the route on the map
  /// 
  /// Note: This method is ready but needs to be wired up to the Mapbox click event handler
  /// based on the specific Mapbox Maps Flutter API version being used.
  // ignore: unused_element
  Future<void> _handleVehicleClick(CircleAnnotation annotation) async {
    if (mapboxMap == null || _isDisposed || !mounted) return;

    try {
      // Find the vehicle associated with this annotation
      final String? vehicleId = _findVehicleIdForAnnotation(annotation);
      if (vehicleId == null) {
        debugPrint('⚠️ Could not find vehicle for clicked annotation');
        return;
      }

      // Get vehicle from realtime provider
      final GtfsRealtimeState realtimeState = ref.read(gtfsRealtimeProvider);
      final VehicleEntity? vehicle = realtimeState.vehicles.firstWhere(
        (VehicleEntity v) => v.id == vehicleId,
        orElse: () => throw Exception('Vehicle not found'),
      );

      if (vehicle == null) {
        debugPrint('⚠️ Vehicle not found for ID: $vehicleId');
        return;
      }

      // Show vehicle information sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext sheetContext) {
          return VehicleInfoSheet(
            vehicle: vehicle,
            onDismissed: () {
              // Optionally handle dismissal
            },
          );
        },
      );

      // Get shape for vehicle
      final ShapeEntity? shape = await _getShapeForVehicle(vehicle);
      if (shape != null) {
        // Get route for vehicle to get route color
        final RouteEntity? route = await _getRouteForVehicle(vehicle);
        final String? routeColor = route?.color;

        // Highlight the route
        ref.read(routeHighlightProvider.notifier).highlightRoute(
          vehicle.id,
          shape.id,
          routeColor,
        );

        debugPrint('✅ Highlighted route for vehicle ${vehicle.id}');
      }

      debugPrint('✅ Showed vehicle info for ${vehicle.id}');
    } catch (e) {
      debugPrint('❌ Error handling vehicle click: $e');
    }
  }

  /// Finds the vehicle ID associated with a circle annotation
  /// 
  /// [annotation] - The circle annotation to find the vehicle for
  /// 
  /// Returns: The vehicle ID if found, or null if not found
  String? _findVehicleIdForAnnotation(CircleAnnotation annotation) {
    for (final entry in _currentAnnotations.entries) {
      if (entry.value.id == annotation.id) {
        return entry.key;
      }
    }
    return null;
  }

  /// Updates the route highlight on the map based on the highlight state
  /// 
  /// [highlightState] - The current route highlight state
  /// 
  /// This method draws or removes the route polyline based on the highlight state.
  Future<void> _updateRouteHighlight(RouteHighlightState highlightState) async {
    if (_polylineAnnotationManager == null || mapboxMap == null || _isDisposed) {
      return;
    }

    try {
      // Clear previous highlight if exists
      if (_currentRouteHighlight != null) {
        await RouteShapeService.clearRouteShape(
          _polylineAnnotationManager!,
          _currentRouteHighlight!,
        );
        _currentRouteHighlight = null;
      }

      // Draw new highlight if one is specified
      if (highlightState.isHighlighted && highlightState.highlightedShapeId != null) {
        final GtfsStaticState gtfsStaticState = ref.read(gtfsStaticProvider);
        final ShapeEntity? shape = gtfsStaticState.shapes[highlightState.highlightedShapeId!];
        
        if (shape == null) {
          debugPrint('⚠️ Shape not found for highlight: ${highlightState.highlightedShapeId}');
          return;
        }

        _currentRouteHighlight = await RouteShapeService.drawRouteShape(
          mapboxMap!,
          _polylineAnnotationManager!,
          shape,
          highlightState.highlightedRouteColor,
        );

        if (_currentRouteHighlight != null) {
          debugPrint('✅ Route highlight drawn for shape ${shape.id}');
        }
      }
    } catch (e) {
      debugPrint('❌ Error updating route highlight: $e');
    }
  }

  /// Starts the animation timer for smooth vehicle movement
  /// 
  /// The timer runs at 0.1 second intervals (10 Hz) to animate vehicles
  /// smoothly along their route shapes between position updates.
  void _startAnimationTimer() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isDisposed || !mounted || mapboxMap == null) {
        timer.cancel();
        return;
      }
      _animateVehicles();
    });
  }

  /// Animates vehicles smoothly along their route shapes
  /// 
  /// This method is called by the animation timer at 0.1 second intervals.
  /// It interpolates vehicle positions along their route shapes for smooth movement.
  Future<void> _animateVehicles() async {
    if (_circleAnnotationManager == null || _isDisposed || !mounted) {
      return;
    }

    try {
      final GtfsRealtimeState realtimeState = ref.read(gtfsRealtimeProvider);
      final List<VehicleEntity> vehicles = realtimeState.vehicles;

      for (final VehicleEntity vehicle in vehicles) {
        // Skip if vehicle doesn't have an annotation
        if (!_currentAnnotations.containsKey(vehicle.id)) {
          continue;
        }

        // Get shape for vehicle
        final ShapeEntity? shape = await _getShapeForVehicle(vehicle);
        if (shape == null || shape.points.isEmpty) {
          continue;
        }

        // Get or create animation state
        _VehicleAnimationState? animState = _vehicleAnimationStates[vehicle.id];
        final DateTime now = DateTime.now();

        // Update animation state if vehicle position changed
        if (animState == null || 
            animState.lastVehicle.latitude != vehicle.latitude ||
            animState.lastVehicle.longitude != vehicle.longitude) {
          // Calculate interpolation factor based on vehicle position relative to shape
          final double interpolationFactor = _calculateInterpolationFactor(
            vehicle,
            shape,
          );

          animState = _VehicleAnimationState(
            lastVehicle: vehicle,
            lastUpdateTime: now,
            lastInterpolationFactor: interpolationFactor,
          );
          _vehicleAnimationStates[vehicle.id] = animState;
        } else {
          // Update timestamp for existing state
          animState = _VehicleAnimationState(
            lastVehicle: animState.lastVehicle,
            lastUpdateTime: now,
            lastInterpolationFactor: animState.lastInterpolationFactor,
          );
          _vehicleAnimationStates[vehicle.id] = animState;
        }

        // Interpolate position along shape
        if (animState.lastInterpolationFactor != null) {
          final VehicleEntity interpolatedVehicle = _interpolationUseCase.interpolate(
            vehicle: vehicle,
            shape: shape,
            interpolationFactor: animState.lastInterpolationFactor!,
          );

          // Update marker position
          final CircleAnnotation? annotation = _currentAnnotations[vehicle.id];
          if (annotation != null) {
            try {
              // Delete and recreate annotation with new position
              await _circleAnnotationManager!.delete(annotation);
              final CircleAnnotationOptions options = 
                  VehicleMarkerService.createAnnotationFromVehicle(interpolatedVehicle);
              final CircleAnnotation newAnnotation = 
                  await _circleAnnotationManager!.create(options);
              _currentAnnotations[vehicle.id] = newAnnotation;
            } catch (e) {
              debugPrint('❌ Error updating vehicle ${vehicle.id} position: $e');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error animating vehicles: $e');
    }
  }

  /// Calculates the interpolation factor for a vehicle along its shape
  /// 
  /// [vehicle] - The vehicle entity
  /// [shape] - The shape entity to interpolate along
  /// 
  /// Returns: Interpolation factor (0.0 to 1.0) representing vehicle's position along shape
  /// This is a simplified calculation - in a production system, you might want to
  /// use the vehicle's actual position to find the nearest point on the shape.
  double _calculateInterpolationFactor(VehicleEntity vehicle, ShapeEntity shape) {
    if (shape.points.isEmpty) {
      return 0.0;
    }

    // Find the nearest point on the shape to the vehicle's current position
    double minDistance = double.infinity;
    int nearestIndex = 0;

    for (int i = 0; i < shape.points.length; i++) {
      final point = shape.points[i];
      final distance = _calculateDistance(
        vehicle.latitude,
        vehicle.longitude,
        point.latitude,
        point.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Calculate interpolation factor based on nearest point index
    // This is a simplified approach - you might want more sophisticated logic
    return nearestIndex / shape.points.length;
  }

  /// Calculates distance between two points using Haversine formula
  /// 
  /// [lat1] - Latitude of first point
  /// [lon1] - Longitude of first point
  /// [lat2] - Latitude of second point
  /// [lon2] - Longitude of second point
  /// 
  /// Returns: Distance in meters
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.141592653589793 / 180;

  @override
  void dispose() {
    // Mark as disposed to prevent any further state updates
    _isDisposed = true;
    
    // Cancel animation timer
    _animationTimer?.cancel();
    _animationTimer = null;
    
    // Cancel marker update timer
    _markerUpdateTimer?.cancel();
    _markerUpdateTimer = null;
    
    // Clean up annotation managers
    // The managers will be automatically disposed when the map is disposed,
    // but we clear the references here for clarity
    try {
      _circleAnnotationManager = null;
      _polylineAnnotationManager = null;
      _currentAnnotations.clear();
      _vehicleAnimationStates.clear();
      _tripCache.clear();
      _routeCache.clear();
      _currentRouteHighlight = null;
    } catch (e) {
      debugPrint('Error disposing annotation managers: $e');
    }
    
    // MapWidget handles the MapboxMap disposal automatically
    // We only clear the reference here to help with garbage collection
    try {
      if (mapboxMap != null) {
        mapboxMap = null;
      }
    } catch (e) {
      debugPrint('Error disposing mapboxMap: $e');
    }
    super.dispose();
  }
}

