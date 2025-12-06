import 'package:flutter/material.dart';
import '../../../domain/entities/vehicle_entity.dart';
import '../../widgets/gtfs_error_banner.dart';

/// Bottom sheet widget for displaying detailed vehicle information
/// 
/// Shows comprehensive vehicle details including ID, position, speed, bearing,
/// timestamp, trip info, and data quality warnings when a vehicle marker is clicked.
class VehicleInfoSheet extends StatelessWidget {
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

  /// Formats timestamp as relative time (e.g., "5 seconds ago")
  /// 
  /// [timestamp] - The timestamp to format
  /// 
  /// Returns: Formatted string like "5 seconds ago" or "2 minutes ago"
  String _formatRelativeTime(DateTime timestamp) {
    final Duration difference = DateTime.now().difference(timestamp);
    final int seconds = difference.inSeconds;
    
    if (seconds < 60) {
      return '$seconds ${seconds == 1 ? 'second' : 'seconds'} ago';
    } else if (seconds < 3600) {
      final int minutes = seconds ~/ 60;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      final int hours = seconds ~/ 3600;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }
  }

  /// Formats speed in m/s to km/h
  /// 
  /// [speed] - Speed in meters per second
  /// 
  /// Returns: Formatted string like "45 km/h"
  String _formatSpeed(double? speed) {
    if (speed == null) {
      return 'N/A';
    }
    final double kmh = speed * 3.6; // Convert m/s to km/h
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  /// Formats bearing as compass direction
  /// 
  /// [bearing] - Bearing in degrees (0-359)
  /// 
  /// Returns: Formatted string like "45° (NE)" or "N"
  String _formatBearing(double? bearing) {
    if (bearing == null) {
      return 'N/A';
    }
    
    // Normalize bearing to 0-360
    double normalizedBearing = bearing % 360;
    if (normalizedBearing < 0) {
      normalizedBearing += 360;
    }
    
    // Convert to compass direction
    final List<String> directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final int index = ((normalizedBearing + 22.5) / 45).floor() % 8;
    
    return '${normalizedBearing.toStringAsFixed(0)}° (${directions[index]})';
  }

  /// Formats timestamp as time string
  /// 
  /// [timestamp] - The timestamp to format
  /// 
  /// Returns: Formatted string like "14:30:25"
  String _formatTimestamp(DateTime timestamp) {
    final int hour = timestamp.hour;
    final int minute = timestamp.minute;
    final int second = timestamp.second;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_bus,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vehicle Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onDismissed?.call();
                      },
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Vehicle ID
                    _InfoRow(
                      icon: Icons.confirmation_number,
                      label: 'Vehicle ID',
                      value: vehicle.id,
                    ),
                    const SizedBox(height: 8),
                    // Vehicle Label
                    if (vehicle.vehicleLabel != null)
                      _InfoRow(
                        icon: Icons.label,
                        label: 'Vehicle Label',
                        value: vehicle.vehicleLabel!,
                      ),
                    if (vehicle.vehicleLabel != null) const SizedBox(height: 8),
                    // Route ID
                    _InfoRow(
                      icon: Icons.route,
                      label: 'Route ID',
                      value: vehicle.routeId.isNotEmpty ? vehicle.routeId : 'N/A',
                    ),
                    const SizedBox(height: 8),
                    // Trip ID
                    _InfoRow(
                      icon: Icons.trip_origin,
                      label: 'Trip ID',
                      value: vehicle.tripId.isNotEmpty ? vehicle.tripId : 'N/A',
                    ),
                    const SizedBox(height: 16),
                    // Position
                    _InfoRow(
                      icon: Icons.location_on,
                      label: 'Position',
                      value: '${vehicle.latitude.toStringAsFixed(6)}, ${vehicle.longitude.toStringAsFixed(6)}',
                    ),
                    const SizedBox(height: 8),
                    // Speed
                    _InfoRow(
                      icon: Icons.speed,
                      label: 'Speed',
                      value: _formatSpeed(vehicle.speed),
                    ),
                    const SizedBox(height: 8),
                    // Bearing
                    _InfoRow(
                      icon: Icons.explore,
                      label: 'Bearing',
                      value: _formatBearing(vehicle.bearing),
                    ),
                    const SizedBox(height: 16),
                    // Timestamp
                    _InfoRow(
                      icon: Icons.access_time,
                      label: 'Last Update',
                      value: _formatRelativeTime(vehicle.timestamp),
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.schedule,
                      label: 'Time',
                      value: _formatTimestamp(vehicle.timestamp),
                    ),
                    const SizedBox(height: 16),
                    // Data quality warnings
                    if (vehicle.dataQualityWarnings != null &&
                        vehicle.dataQualityWarnings!.isNotEmpty)
                      GtfsErrorBanner(
                        errorCodes: vehicle.dataQualityWarnings!,
                        compact: false,
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Individual info row widget
/// 
/// Displays a single piece of vehicle information with an icon, label, and value.
class _InfoRow extends StatelessWidget {
  /// Icon to display
  final IconData icon;
  
  /// Label text
  final String label;
  
  /// Value text
  final String value;

  /// Creates an _InfoRow
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

