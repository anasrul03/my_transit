import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/vehicle_entity.dart';
import '../../../domain/entities/stop_entity.dart';
import '../../../domain/entities/stop_time_entity.dart';
import '../../providers/gtfs_static_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/favorite_vehicles_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../../core/services/location_service.dart';
import 'operator_selection_button.dart';

/// Bottom sheet widget for displaying detailed vehicle information
/// 
/// Shows comprehensive vehicle details including ID, route, operator, speed,
/// next station, distance to user, and action buttons for schedule and favorites.
/// Designed to match the reference UI with mobile-first responsiveness.
class VehicleInfoSheet extends ConsumerStatefulWidget {
  /// The vehicle entity to display information for
  final VehicleEntity vehicle;
  
  /// Callback when sheet is dismissed
  final VoidCallback? onDismissed;

  /// Creates a VehicleInfoSheet
  /// 
  /// [vehicle] - The vehicle entity to display
  /// [onDismissed] - Optional callback when sheet is dismissed
  const VehicleInfoSheet({
    super.key,
    required this.vehicle,
    this.onDismissed,
  });

  @override
  ConsumerState<VehicleInfoSheet> createState() => _VehicleInfoSheetState();
}

class _VehicleInfoSheetState extends ConsumerState<VehicleInfoSheet> {
  /// The next stop for this vehicle, if available
  StopEntity? _nextStop;
  
  /// Whether we're currently loading the next stop
  bool _loadingNextStop = true;
  
  /// Distance to the vehicle in meters
  double? _distanceToVehicle;
  
  /// Estimated driving time to the vehicle
  Duration? _drivingTime;

  @override
  void initState() {
    super.initState();
    // Load next stop and calculate distance asynchronously
    // Wrapped in post-frame callback to avoid modifying providers during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadNextStop();
        _calculateDistance();
      }
    });
  }

  /// Loads the next stop for this vehicle
  /// 
  /// Fetches stop times for the vehicle's trip and determines which stop
  /// is next based on the current time and stop sequence.
  Future<void> _loadNextStop() async {
    setState(() {
      _loadingNextStop = true;
    });

    try {
      // Get stop times for this vehicle's trip
      final List<StopTimeEntity> stopTimes = 
          await ref.read(gtfsStaticProvider.notifier).getStopTimesByTripId(widget.vehicle.tripId);
      
      if (stopTimes.isEmpty) {
        setState(() {
          _loadingNextStop = false;
        });
        return;
      }
      
      // Sort stop times by sequence
      stopTimes.sort((StopTimeEntity a, StopTimeEntity b) => a.stopSequence.compareTo(b.stopSequence));
      
      // For now, get the next stop in sequence (simplified logic)
      // In a real implementation, you would compare with current time
      // and vehicle position to determine the actual next stop
      if (stopTimes.isNotEmpty) {
        final StopTimeEntity nextStopTime = stopTimes.first;
        
        // Get stop details
        final GtfsStaticState staticState = ref.read(gtfsStaticProvider);
        final StopEntity? stop = staticState.stops.firstWhere(
          (StopEntity s) => s.id == nextStopTime.stopId,
          orElse: () => throw Exception('Stop not found'),
        );
        
        if (stop != null) {
          setState(() {
            _nextStop = stop;
            _loadingNextStop = false;
          });
        } else {
          setState(() {
            _loadingNextStop = false;
          });
        }
      } else {
        setState(() {
          _loadingNextStop = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading next stop: $e');
      setState(() {
        _loadingNextStop = false;
      });
    }
  }

  /// Calculates distance and driving time to the vehicle
  /// 
  /// Uses the user's current location and the vehicle's position to calculate
  /// distance in kilometers and estimated driving time.
  Future<void> _calculateDistance() async {
    try {
      // Get user's current location
      final LocationState locationState = ref.read(locationProvider);
      
      if (locationState.currentPosition == null) {
        // Try to enable location if not already enabled
        await ref.read(locationProvider.notifier).enableLocation();
        
        // Re-read the location state
        final LocationState updatedLocationState = ref.read(locationProvider);
        if (updatedLocationState.currentPosition == null) {
          return; // Can't calculate distance without user location
        }
      }
      
      final LocationState finalLocationState = ref.read(locationProvider);
      if (finalLocationState.currentPosition == null) return;
      
      // Calculate distance using LocationService
      final LocationService locationService = LocationService();
      final double distanceMeters = locationService.calculateDistance(
        finalLocationState.currentPosition!.latitude,
        finalLocationState.currentPosition!.longitude,
        widget.vehicle.latitude,
        widget.vehicle.longitude,
      );
      
      // Calculate estimated driving time
      // Using average urban driving speed of 40 km/h as estimate
      const double averageSpeedKmh = 40.0;
      final double distanceKm = distanceMeters / 1000.0;
      final double hours = distanceKm / averageSpeedKmh;
      final int minutes = (hours * 60).round();
      
      setState(() {
        _distanceToVehicle = distanceMeters;
        _drivingTime = Duration(minutes: minutes);
      });
    } catch (e) {
      debugPrint('❌ Error calculating distance: $e');
    }
  }

  /// Formats speed in m/s to km/h
  /// 
  /// [speed] - Speed in meters per second
  /// 
  /// Returns: Formatted string like "87 km/h"
  String _formatSpeed(double? speed) {
    if (speed == null) {
      return 'N/A';
    }
    final double kmh = speed * 3.6; // Convert m/s to km/h
    return '${kmh.round()} km/h';
  }

  /// Formats distance to vehicle
  /// 
  /// [distanceMeters] - Distance in meters
  /// 
  /// Returns: Formatted string like "30.1 km"
  String _formatDistance(double? distanceMeters) {
    if (distanceMeters == null) return 'N/A';
    
    final double km = distanceMeters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  /// Formats driving time
  /// 
  /// [duration] - Driving time duration
  /// 
  /// Returns: Formatted string like "45 min"
  String _formatDrivingTime(Duration? duration) {
    if (duration == null) return 'N/A';
    
    final int minutes = duration.inMinutes;
    return '$minutes min';
  }

  /// Gets the appropriate icon for the vehicle's route type
  /// 
  /// Returns bus or train icon based on route type
  IconData _getRouteTypeIcon() {
    if (widget.vehicle.routeType == null) {
      return Icons.directions_bus; // Default to bus
    }
    
    // Rail types: 0 (tram), 1 (subway), 2 (rail), 12 (monorail)
    if (widget.vehicle.routeType == 0 ||
        widget.vehicle.routeType == 1 ||
        widget.vehicle.routeType == 2 ||
        widget.vehicle.routeType == 12) {
      return Icons.train;
    }
    
    return Icons.directions_bus;
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    
    // Calculate responsive padding based on screen width
    // Compact padding to maximize content visibility without scrolling
    final double horizontalPadding = screenSize.width < 360 ? 12.0 : 16.0;
    final double verticalPadding = 12.0; // Reduced for compact layout
    
    // Watch favorite state for this vehicle
    final bool isFavorite = ref.watch(
      favoriteVehiclesProvider.select(
        (FavoriteVehiclesState state) => state.favoriteVehicleIds.contains(widget.vehicle.id),
      ),
    );
    
    return DraggableScrollableSheet(
      initialChildSize: 0.55, // Show at 55% initially to ensure buttons are visible
      minChildSize: 0.25, // Collapsed state at 25%
      maxChildSize: 0.90, // Fully expanded at 90%
      snap: true,
      snapSizes: const [0.25, 0.55, 0.90], // Only 3 snap points for better UX
      expand: false, // Don't expand to fill parent
      shouldCloseOnMinExtent: false, // Don't auto-close when minimized
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Content with scroll
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    8, // Reduced bottom padding as SafeArea will be applied below
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Header row with Vehicle ID and close button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Vehicle ID (Title 2 per Apple HIG - 22pt)
                        Expanded(
                          child: Text(
                            widget.vehicle.vehicleLabel ?? widget.vehicle.id,
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22, // Title 2 per Apple HIG
                                  height: 1.3,
                                ),
                          ),
                        ),
                        // Close button inline with title
                        IconButton(
                          icon: const Icon(Icons.close, size: 24),
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onDismissed?.call();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Route name - Subhead per Apple HIG (15pt)
                    Text(
                      widget.vehicle.routeShortName != null && widget.vehicle.routeLongName != null
                          ? '${widget.vehicle.routeShortName} ~ ${widget.vehicle.routeLongName}'
                          : widget.vehicle.routeShortName ?? widget.vehicle.routeLongName ?? 'Unknown Route',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            fontSize: 15, // Subhead per Apple HIG
                            height: 1.3,
                          ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Info grid (2 columns) - responsive layout
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Speed column
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label: Caption 1 per Apple HIG (12pt)
                              Text(
                                'SPEED',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 12, // Caption 1 per Apple HIG
                                      letterSpacing: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              // Value: Title 3 per Apple HIG (20pt)
                              Text(
                                _formatSpeed(widget.vehicle.speed),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20, // Title 3 per Apple HIG
                                    ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Operator column
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label: Caption 1 per Apple HIG (12pt)
                              Text(
                                'OPERATOR',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 12, // Caption 1 per Apple HIG
                                      letterSpacing: 1.2,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              // Value: Headline per Apple HIG (17pt) - smaller but readable
                              Text(
                                OperatorSelectionButton.getAgencyDisplayName(widget.vehicle.operatorId),
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17, // Headline per Apple HIG
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Next station section - compact container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label: Caption 1 per Apple HIG (12pt)
                          Text(
                            'NEXT STATION',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 12, // Caption 1 per Apple HIG
                                  letterSpacing: 1.2,
                                ),
                          ),
                          const SizedBox(height: 6),
                          _loadingNextStop
                              ? Row(
                                  children: const [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 12),
                                    // Callout per Apple HIG (16pt)
                                    Text('Loading...', style: TextStyle(fontSize: 16)),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(
                                      _getRouteTypeIcon(),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      // Value: Callout per Apple HIG (16pt)
                                      child: Text(
                                        _nextStop != null
                                            ? '${_nextStop!.name ?? _nextStop!.id}'
                                            : 'No upcoming stops',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16, // Callout per Apple HIG
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // Distance and driving time section - compact layout
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.pink.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: screenSize.width < 360
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Distance to you
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Label: Caption 1 per Apple HIG (12pt)
                                    Text(
                                      'DISTANCE TO YOU',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Colors.pink.shade300,
                                            fontSize: 12, // Caption 1 per Apple HIG
                                            letterSpacing: 1.2,
                                          ),
                                    ),
                                    const SizedBox(height: 2),
                                    // Value: Headline per Apple HIG (17pt)
                                    Text(
                                      _formatDistance(_distanceToVehicle),
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.pink.shade400,
                                            fontSize: 17, // Headline per Apple HIG
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Driving time
                                Row(
                                  children: [
                                    Icon(
                                      Icons.directions_car,
                                      size: 18,
                                      color: Colors.pink.shade300,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Label: Caption 1 per Apple HIG (12pt)
                                        Text(
                                          'DRIVING TIME',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: Colors.pink.shade300,
                                                fontSize: 12, // Caption 1 per Apple HIG
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        // Value: Headline per Apple HIG (17pt)
                                        Text(
                                          _formatDrivingTime(_drivingTime),
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.pink.shade400,
                                                fontSize: 17, // Headline per Apple HIG
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                // Distance to you
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Label: Caption 1 per Apple HIG (12pt)
                                      Text(
                                        'DISTANCE TO YOU',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Colors.pink.shade300,
                                              fontSize: 12, // Caption 1 per Apple HIG
                                              letterSpacing: 1.2,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      // Value: Headline per Apple HIG (17pt)
                                      Text(
                                        _formatDistance(_distanceToVehicle),
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.pink.shade400,
                                              fontSize: 17, // Headline per Apple HIG
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Driving time
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.directions_car,
                                        size: 18,
                                        color: Colors.pink.shade300,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Label: Caption 1 per Apple HIG (12pt)
                                            Text(
                                              'DRIVING TIME',
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: Colors.pink.shade300,
                                                    fontSize: 12, // Caption 1 per Apple HIG
                                                    letterSpacing: 1.2,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            // Value: Headline per Apple HIG (17pt)
                                            Text(
                                              _formatDrivingTime(_drivingTime),
                                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.pink.shade400,
                                                    fontSize: 17, // Headline per Apple HIG
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Disclaimer text - Caption 2 per Apple HIG (11pt)
                    Text(
                      '* Time based on current driving conditions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 11, // Caption 2 per Apple HIG
                          ),
                    ),
                    
                    ],
                  ),
                ),
              ),
              
              // Action buttons - always visible at bottom with SafeArea
              SafeArea(
                top: false, // Don't apply SafeArea to top, only bottom
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Show Schedule button - touch-friendly size
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Close the bottom sheet first
                            Navigator.of(context).pop();
                            widget.onDismissed?.call();
                            
                            // Navigate to schedules tab
                            ref.read(navigationProvider.notifier).selectTab(TabType.schedules);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            minimumSize: const Size(0, 44), // Compact but touch-friendly
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          // Button text: Body per Apple HIG (17pt)
                          child: const Text(
                            'Show Schedule',
                            style: TextStyle(
                              fontSize: 17, // Body per Apple HIG
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Favorite button - touch-friendly size
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Toggle favorite status
                            ref.read(favoriteVehiclesProvider.notifier).toggleFavorite(widget.vehicle.id);
                          },
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                            size: 24,
                          ),
                          color: isFavorite
                              ? Colors.amber
                              : Theme.of(context).colorScheme.onSurface,
                          padding: const EdgeInsets.all(10),
                          constraints: const BoxConstraints(
                            minWidth: 44, // Compact but touch-friendly
                            minHeight: 44,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
