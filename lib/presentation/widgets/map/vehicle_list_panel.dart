import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/vehicle_entity.dart';
import '../../providers/gtfs_realtime_provider.dart';
import 'vehicle_info_sheet.dart';

/// Collapsible sidebar panel showing all active vehicles
/// 
/// Displays a list of all active vehicles with their details and allows
/// clicking on a vehicle to center the map on it and show vehicle information.
class VehicleListPanel extends ConsumerStatefulWidget {
  /// Whether the panel is initially expanded
  final bool initiallyExpanded;
  
  /// Callback when a vehicle is selected
  final void Function(VehicleEntity vehicle)? onVehicleSelected;

  /// Creates a VehicleListPanel
  /// 
  /// [initiallyExpanded] - Whether the panel starts expanded (default: false)
  /// [onVehicleSelected] - Optional callback when a vehicle is clicked
  const VehicleListPanel({
    super.key,
    this.initiallyExpanded = false,
    this.onVehicleSelected,
  });

  @override
  ConsumerState<VehicleListPanel> createState() => _VehicleListPanelState();
}

class _VehicleListPanelState extends ConsumerState<VehicleListPanel> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  /// Formats timestamp as relative time
  String _formatRelativeTime(DateTime timestamp) {
    final Duration difference = DateTime.now().difference(timestamp);
    final int seconds = difference.inSeconds;
    
    if (seconds < 60) {
      return '$seconds${seconds == 1 ? 's' : 's'} ago';
    } else if (seconds < 3600) {
      final int minutes = seconds ~/ 60;
      return '$minutes${minutes == 1 ? 'm' : 'm'} ago';
    } else {
      final int hours = seconds ~/ 3600;
      return '$hours${hours == 1 ? 'h' : 'h'} ago';
    }
  }

  /// Formats speed in m/s to km/h
  String _formatSpeed(double? speed) {
    if (speed == null) {
      return 'N/A';
    }
    final double kmh = speed * 3.6;
    return '${kmh.toStringAsFixed(0)} km/h';
  }

  @override
  Widget build(BuildContext context) {
    final GtfsRealtimeState realtimeState = ref.watch(gtfsRealtimeProvider);
    final List<VehicleEntity> vehicles = realtimeState.vehicles;

    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _isExpanded ? 320 : 56,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with toggle button
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: _isExpanded
                    ? Row(
                        children: [
                          Icon(
                            Icons.list,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vehicles (${vehicles.length})',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.expand_less,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.list,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                          Icon(
                            Icons.expand_more,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
            // Vehicle list (only shown when expanded)
            if (_isExpanded)
              Flexible(
                child: vehicles.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No vehicles available',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: vehicles.length,
                        itemBuilder: (BuildContext context, int index) {
                          final VehicleEntity vehicle = vehicles[index];
                          return _VehicleListItem(
                            vehicle: vehicle,
                            onTap: () {
                              widget.onVehicleSelected?.call(vehicle);
                              // Show vehicle info sheet
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (BuildContext sheetContext) {
                                  return VehicleInfoSheet(vehicle: vehicle);
                                },
                              );
                            },
                            formatRelativeTime: _formatRelativeTime,
                            formatSpeed: _formatSpeed,
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Individual vehicle list item
class _VehicleListItem extends StatelessWidget {
  /// The vehicle entity to display
  final VehicleEntity vehicle;
  
  /// Callback when item is tapped
  final VoidCallback onTap;
  
  /// Function to format relative time
  final String Function(DateTime) formatRelativeTime;
  
  /// Function to format speed
  final String Function(double?) formatSpeed;

  /// Creates a _VehicleListItem
  const _VehicleListItem({
    required this.vehicle,
    required this.onTap,
    required this.formatRelativeTime,
    required this.formatSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasWarnings = vehicle.dataQualityWarnings != null &&
        vehicle.dataQualityWarnings!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            // Vehicle icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.directions_bus,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Vehicle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          vehicle.vehicleLabel ?? vehicle.id,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasWarnings) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (vehicle.routeId.isNotEmpty)
                        Text(
                          'Route: ${vehicle.routeId}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      if (vehicle.routeId.isNotEmpty && vehicle.speed != null)
                        const Text(' • '),
                      if (vehicle.speed != null)
                        Text(
                          formatSpeed(vehicle.speed),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                    ],
                  ),
                  Text(
                    formatRelativeTime(vehicle.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

