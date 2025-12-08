import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../domain/entities/vehicle_entity.dart';
import '../../providers/gtfs_realtime_provider.dart';
import '../../providers/map_camera_provider.dart';

/// Enum for sorting options
enum VehicleSortOption {
  routeAsc,
  routeDesc,
  timeNewest,
  timeOldest,
  speedFastest,
  speedSlowest,
}

/// Enum for vehicle status filter
enum VehicleStatusFilter {
  all,
  moving,
  stopped,
}

/// Collapsible sidebar panel showing all active vehicles
/// 
/// Displays a list of all active vehicles with their details and allows
/// clicking on a vehicle to center the map on it and show vehicle information.
/// Features include filtering, sorting, status badges, and animations.
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
  VehicleSortOption _sortOption = VehicleSortOption.timeNewest;
  String? _filterRoute;
  String? _filterAgency;
  VehicleStatusFilter _statusFilter = VehicleStatusFilter.all;

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
      return '${seconds}s ago';
    } else if (seconds < 3600) {
      final int minutes = seconds ~/ 60;
      return '${minutes}m ago';
    } else if (seconds < 86400) {
      final int hours = seconds ~/ 3600;
      return '${hours}h ago';
    } else {
      final int days = seconds ~/ 86400;
      return '${days}d ago';
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

  /// Gets the appropriate icon for a vehicle based on its operator
  /// 
  /// [operatorId] - The operator/agency identifier
  /// 
  /// Returns: IconData for the vehicle type
  IconData _getVehicleIcon(String? operatorId) {
    if (operatorId == null) return Icons.directions_bus;
    
    // Rail services get train icon
    if (operatorId == ApiConstants.agencyKtmb || 
        operatorId == ApiConstants.agencyRapidRailKl) {
      return Icons.train;
    }
    
    // All others get bus icon
    return Icons.directions_bus;
  }

  /// Gets data freshness status based on timestamp
  /// 
  /// [timestamp] - The vehicle's last update timestamp
  /// 
  /// Returns: Status string (realtime, recent, stale)
  String _getDataFreshness(DateTime timestamp) {
    final Duration difference = DateTime.now().difference(timestamp);
    final int seconds = difference.inSeconds;
    
    if (seconds < 60) {
      return 'realtime';
    } else if (seconds < 300) {
      return 'recent';
    } else {
      return 'stale';
    }
  }

  /// Gets color for data freshness status
  /// 
  /// [freshness] - The freshness status string
  /// 
  /// Returns: Color for the status
  Color _getFreshnessColor(String freshness, BuildContext context) {
    switch (freshness) {
      case 'realtime':
        return Colors.green;
      case 'recent':
        return Colors.orange;
      case 'stale':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }
  }

  /// Gets speed status based on vehicle speed
  /// 
  /// [speed] - Vehicle speed in m/s
  /// 
  /// Returns: Status string (stopped, slow, normal, fast)
  String _getSpeedStatus(double? speed) {
    if (speed == null) return 'unknown';
    final double kmh = speed * 3.6;
    
    if (kmh < 1) {
      return 'stopped';
    } else if (kmh < 20) {
      return 'slow';
    } else if (kmh < 60) {
      return 'normal';
    } else {
      return 'fast';
    }
  }

  /// Gets color for speed status
  /// 
  /// [status] - The speed status string
  /// 
  /// Returns: Color for the status
  Color _getSpeedColor(String status, BuildContext context) {
    switch (status) {
      case 'stopped':
        return Colors.red;
      case 'slow':
        return Colors.orange;
      case 'normal':
        return Colors.green;
      case 'fast':
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }
  }

  /// Filters vehicles based on current filter settings
  /// 
  /// [vehicles] - List of all vehicles
  /// 
  /// Returns: Filtered list of vehicles
  List<VehicleEntity> _filterVehicles(List<VehicleEntity> vehicles) {
    List<VehicleEntity> filtered = vehicles;

    // Filter by route
    if (_filterRoute != null && _filterRoute!.isNotEmpty) {
      filtered = filtered
          .where((VehicleEntity v) => v.routeId == _filterRoute)
          .toList();
    }

    // Filter by agency
    if (_filterAgency != null && _filterAgency!.isNotEmpty) {
      filtered = filtered
          .where((VehicleEntity v) => v.operatorId == _filterAgency)
          .toList();
    }

    // Filter by status
    if (_statusFilter != VehicleStatusFilter.all) {
      filtered = filtered.where((VehicleEntity v) {
        final double? speed = v.speed;
        if (speed == null) return false;
        
        final double kmh = speed * 3.6;
        if (_statusFilter == VehicleStatusFilter.moving) {
          return kmh >= 1;
        } else {
          return kmh < 1;
        }
      }).toList();
    }

    return filtered;
  }

  /// Sorts vehicles based on current sort option
  /// 
  /// [vehicles] - List of vehicles to sort
  /// 
  /// Returns: Sorted list of vehicles
  List<VehicleEntity> _sortVehicles(List<VehicleEntity> vehicles) {
    final List<VehicleEntity> sorted = List.from(vehicles);

    switch (_sortOption) {
      case VehicleSortOption.routeAsc:
        sorted.sort((VehicleEntity a, VehicleEntity b) => 
            a.routeId.compareTo(b.routeId));
        break;
      case VehicleSortOption.routeDesc:
        sorted.sort((VehicleEntity a, VehicleEntity b) => 
            b.routeId.compareTo(a.routeId));
        break;
      case VehicleSortOption.timeNewest:
        sorted.sort((VehicleEntity a, VehicleEntity b) => 
            b.timestamp.compareTo(a.timestamp));
        break;
      case VehicleSortOption.timeOldest:
        sorted.sort((VehicleEntity a, VehicleEntity b) => 
            a.timestamp.compareTo(b.timestamp));
        break;
      case VehicleSortOption.speedFastest:
        sorted.sort((VehicleEntity a, VehicleEntity b) {
          final double speedA = a.speed ?? 0;
          final double speedB = b.speed ?? 0;
          return speedB.compareTo(speedA);
        });
        break;
      case VehicleSortOption.speedSlowest:
        sorted.sort((VehicleEntity a, VehicleEntity b) {
          final double speedA = a.speed ?? 0;
          final double speedB = b.speed ?? 0;
          return speedA.compareTo(speedB);
        });
        break;
    }

    return sorted;
  }

  /// Gets display name for sort option
  /// 
  /// [option] - The sort option
  /// 
  /// Returns: Human-readable sort option name
  String _getSortOptionName(VehicleSortOption option) {
    switch (option) {
      case VehicleSortOption.routeAsc:
        return 'Route A-Z';
      case VehicleSortOption.routeDesc:
        return 'Route Z-A';
      case VehicleSortOption.timeNewest:
        return 'Newest First';
      case VehicleSortOption.timeOldest:
        return 'Oldest First';
      case VehicleSortOption.speedFastest:
        return 'Fastest';
      case VehicleSortOption.speedSlowest:
        return 'Slowest';
    }
  }

  /// Gets the count of active filters
  /// 
  /// Returns: Number of active filters
  int _getActiveFilterCount() {
    int count = 0;
    if (_filterRoute != null && _filterRoute!.isNotEmpty) count++;
    if (_filterAgency != null && _filterAgency!.isNotEmpty) count++;
    if (_statusFilter != VehicleStatusFilter.all) count++;
    return count;
  }

  /// Shows the filter bottom sheet
  /// 
  /// [context] - Build context
  /// [vehicles] - List of all vehicles for building filter options
  void _showFilterSheet(BuildContext context, List<VehicleEntity> vehicles) {
    // Get unique routes and agencies (for future expansion)
    // Currently only showing status filter
    // final Set<String> routes = vehicles.map((VehicleEntity v) => v.routeId).toSet();
    // final Set<String> agencies = vehicles.map((VehicleEntity v) => v.operatorId ?? '').toSet();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Filter Vehicles',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              style: IconButton.styleFrom(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Scrollable content
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(24),
                          children: [
                            // Vehicle Status Filter
                            Text(
                              'Vehicle Status',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: _statusFilter == VehicleStatusFilter.all,
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      setState(() => _statusFilter = VehicleStatusFilter.all);
                                      setModalState(() {});
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Moving'),
                                  selected: _statusFilter == VehicleStatusFilter.moving,
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      setState(() => _statusFilter = VehicleStatusFilter.moving);
                                      setModalState(() {});
                                    }
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Stopped'),
                                  selected: _statusFilter == VehicleStatusFilter.stopped,
                                  onSelected: (bool selected) {
                                    if (selected) {
                                      setState(() => _statusFilter = VehicleStatusFilter.stopped);
                                      setModalState(() {});
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),

                            // Clear Filters Button
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _filterRoute = null;
                                  _filterAgency = null;
                                  _statusFilter = VehicleStatusFilter.all;
                                });
                                setModalState(() {});
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Clear All Filters'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Shows the sort bottom sheet
  /// 
  /// [context] - Build context
  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sort By',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Sort options
              ...VehicleSortOption.values.map((VehicleSortOption option) {
                final bool isSelected = option == _sortOption;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  title: Text(
                    _getSortOptionName(option),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    setState(() => _sortOption = option);
                    Navigator.of(context).pop();
                  },
                  selected: isSelected,
                  selectedTileColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.1),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final GtfsRealtimeState realtimeState = ref.watch(gtfsRealtimeProvider);
    final List<VehicleEntity> allVehicles = realtimeState.vehicles;
    
    // Apply filters and sorting
    final List<VehicleEntity> filteredVehicles = _filterVehicles(allVehicles);
    final List<VehicleEntity> sortedVehicles = _sortVehicles(filteredVehicles);
    
    final int activeFilterCount = _getActiveFilterCount();

    return Positioned(
      top: 16,
      right: 16,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        width: _isExpanded ? 360 : 56,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: _isExpanded
                        ? BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withOpacity(0.5),
                            width: 1,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: _isExpanded
                    ? Row(
                        children: [
                          // Vehicle icon with badge
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.directions_bus,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                  size: 20,
                                ),
                              ),
                              if (sortedVehicles.isNotEmpty)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 20,
                                      minHeight: 20,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${sortedVehicles.length}',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active Vehicles',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (activeFilterCount > 0)
                                  Text(
                                    '$activeFilterCount ${activeFilterCount == 1 ? 'filter' : 'filters'} active',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Filter button
                          IconButton(
                            onPressed: () => _showFilterSheet(context, allVehicles),
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.filter_list, size: 20),
                                if (activeFilterCount > 0)
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.error,
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$activeFilterCount',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onError,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: activeFilterCount > 0
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.12)
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                            ),
                            tooltip: 'Filter vehicles',
                          ),
                          const SizedBox(width: 4),
                          // Sort button
                          IconButton(
                            onPressed: () => _showSortSheet(context),
                            icon: const Icon(Icons.sort, size: 20),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                            ),
                            tooltip: 'Sort vehicles',
                          ),
                          const SizedBox(width: 4),
                          // Collapse button
                          Icon(
                            Icons.expand_less,
                            color: Theme.of(context).colorScheme.onSurface,
                            size: 24,
                          ),
                        ],
                      )
                    : Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              Icons.directions_bus,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 24,
                            ),
                            if (sortedVehicles.isNotEmpty)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.surface,
                                      width: 2,
                                    ),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${sortedVehicles.length}',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onPrimary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ),
            // Vehicle list (only shown when expanded)
            if (_isExpanded)
              Flexible(
                child: sortedVehicles.isEmpty
                    ? _buildEmptyState(context, allVehicles.isEmpty)
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sortedVehicles.length,
                        itemBuilder: (BuildContext context, int index) {
                          final VehicleEntity vehicle = sortedVehicles[index];
                          return _VehicleListItem(
                            vehicle: vehicle,
                            index: index,
                            onTap: () {
                              // Collapse the list panel to show the map
                              setState(() {
                                _isExpanded = false;
                              });
                              
                              // Trigger camera movement via provider
                              // This will center the map on the vehicle, show route shape, and display info sheet
                              ref.read(mapCameraProvider.notifier).moveCameraToVehicle(vehicle);
                              
                              // Optional callback still called for compatibility
                              widget.onVehicleSelected?.call(vehicle);
                            },
                            getVehicleIcon: _getVehicleIcon,
                            getDataFreshness: _getDataFreshness,
                            getFreshnessColor: _getFreshnessColor,
                            getSpeedStatus: _getSpeedStatus,
                            getSpeedColor: _getSpeedColor,
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

  /// Builds the empty state widget
  /// 
  /// [context] - Build context
  /// [noVehicles] - Whether there are no vehicles at all or just filtered out
  /// 
  /// Returns: Widget for empty state
  Widget _buildEmptyState(BuildContext context, bool noVehicles) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              noVehicles ? Icons.directions_bus_outlined : Icons.filter_list_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          // Title
          Text(
            noVehicles ? 'No Vehicles Available' : 'No Matching Vehicles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            noVehicles
                ? 'No active vehicles are currently being tracked. Please check back later.'
                : 'Try adjusting your filters to see more vehicles.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
            textAlign: TextAlign.center,
          ),
          if (!noVehicles) ...[
            const SizedBox(height: 24),
            // Clear filters button
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _filterRoute = null;
                  _filterAgency = null;
                  _statusFilter = VehicleStatusFilter.all;
                });
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Individual vehicle list item with animations and status badges
class _VehicleListItem extends StatelessWidget {
  /// The vehicle entity to display
  final VehicleEntity vehicle;
  
  /// Index for staggered animation
  final int index;
  
  /// Callback when item is tapped
  final VoidCallback onTap;
  
  /// Function to get vehicle icon
  final IconData Function(String?) getVehicleIcon;
  
  /// Function to get data freshness status
  final String Function(DateTime) getDataFreshness;
  
  /// Function to get freshness color
  final Color Function(String, BuildContext) getFreshnessColor;
  
  /// Function to get speed status
  final String Function(double?) getSpeedStatus;
  
  /// Function to get speed color
  final Color Function(String, BuildContext) getSpeedColor;
  
  /// Function to format relative time
  final String Function(DateTime) formatRelativeTime;
  
  /// Function to format speed
  final String Function(double?) formatSpeed;

  /// Creates a _VehicleListItem
  const _VehicleListItem({
    required this.vehicle,
    required this.index,
    required this.onTap,
    required this.getVehicleIcon,
    required this.getDataFreshness,
    required this.getFreshnessColor,
    required this.getSpeedStatus,
    required this.getSpeedColor,
    required this.formatRelativeTime,
    required this.formatSpeed,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasWarnings = vehicle.dataQualityWarnings != null &&
        vehicle.dataQualityWarnings!.isNotEmpty;
    final String freshness = getDataFreshness(vehicle.timestamp);
    final String speedStatus = getSpeedStatus(vehicle.speed);

    return TweenAnimationBuilder<double>(
      // Staggered fade-in animation
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 250 + (index * 30)),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Vehicle icon with colored background
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getVehicleIcon(vehicle.operatorId),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Vehicle info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Vehicle label with warning icon
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                vehicle.vehicleLabel ?? vehicle.id,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (hasWarnings) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Route badge
                        if (vehicle.routeId.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Route ${vehicle.routeId}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        const SizedBox(height: 6),
                        // Status badges row
                        Row(
                          children: [
                            // Speed status badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: getSpeedColor(speedStatus, context)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    speedStatus == 'stopped'
                                        ? Icons.stop_circle
                                        : Icons.speed,
                                    size: 10,
                                    color: getSpeedColor(speedStatus, context),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    formatSpeed(vehicle.speed),
                                    style: TextStyle(
                                      color: getSpeedColor(speedStatus, context),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Freshness badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: getFreshnessColor(freshness, context)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 10,
                                    color: getFreshnessColor(freshness, context),
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    formatRelativeTime(vehicle.timestamp),
                                    style: TextStyle(
                                      color: getFreshnessColor(freshness, context),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Arrow icon
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

