import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/gtfs_route_types.dart';
import '../../../domain/entities/schedule_entry_entity.dart';

/// Screen displaying detailed information about a single schedule entry
/// 
/// This screen shows comprehensive details about a transit schedule entry,
/// including stop information, route details, trip information, and timing.
/// It provides a better UX by avoiding repetitive text and organizing
/// information in a clear, hierarchical manner.
class ScheduleDetailScreen extends StatelessWidget {
  /// The schedule entry to display details for
  final ScheduleEntryEntity entry;

  const ScheduleDetailScreen({
    super.key,
    required this.entry,
  });

  /// Extracts schedule entry from route extra parameter
  /// 
  /// This is a convenience method to get the entry from GoRouter's extra parameter.
  /// Returns null if the entry is not found in the route state.
  /// 
  /// [state] - The GoRouter state containing route parameters
  /// 
  /// Returns: ScheduleEntryEntity if found, null otherwise
  static ScheduleEntryEntity? fromRoute(GoRouterState state) {
    return state.extra as ScheduleEntryEntity?;
  }

  @override
  Widget build(BuildContext context) {
    // Pre-compute display values to avoid repeated calls
    final String routeName = entry.getRouteDisplayName();
    final String? headsign = entry.getTripHeadsign();
    final String? arrivalTime = entry.stopTime.arrivalTime;
    final String? departureTime = entry.stopTime.departureTime;
    
    // Format times to HH:MM format
    final String? formattedArrival = arrivalTime != null 
        ? _formatTime(arrivalTime) 
        : null;
    final String? formattedDeparture = departureTime != null 
        ? _formatTime(departureTime) 
        : null;
    
    // Determine if arrival and departure times are the same
    final bool timesAreSame = formattedArrival != null && 
        formattedDeparture != null && 
        formattedArrival == formattedDeparture;
    
    // Get route color if available
    final String? routeColor = entry.route.color;
    Color? routeColorParsed;
    if (routeColor != null && routeColor.isNotEmpty) {
      try {
        // Parse hex color (with or without #)
        final String hex = routeColor.startsWith('#') ? routeColor : '#$routeColor';
        routeColorParsed = Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        // If parsing fails, use default primary color
        routeColorParsed = null;
      }
    }
    
    // Get route type display name
    final String routeTypeName = GtfsRouteType.getDisplayName(entry.route.type);
    final String routeTypeEmoji = GtfsRouteType.getEmoji(entry.route.type);
    
    // Smart text comparison to avoid repeating similar route names and headsigns
    final String? displayHeadsign = _getSmartHeadsignDisplay(routeName, headsign);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Details'),
      ),
      // Use PopScope to detect back navigation
      // Note: We don't reset the schedule entries here because we want
      // the user to see the schedule list when they navigate back
      body: PopScope(
        canPop: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stop Information Card
                _buildStopInfoCard(),
                const SizedBox(height: AppSpacing.md),
                
                // Route Information Card
                _buildRouteInfoCard(
                  context,
                  routeName: routeName,
                  routeTypeName: routeTypeName,
                  routeTypeEmoji: routeTypeEmoji,
                  routeColor: routeColorParsed,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Trip Information Card
                if (displayHeadsign != null) ...[
                  _buildTripInfoCard(context, displayHeadsign: displayHeadsign),
                  const SizedBox(height: AppSpacing.md),
                ],
                
                // Time Information Card
                _buildTimeInfoCard(
                  formattedArrival: formattedArrival,
                  formattedDeparture: formattedDeparture,
                  timesAreSame: timesAreSame,
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Additional Details Card
                _buildAdditionalDetailsCard(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the stop information card
  /// 
  /// Displays stop name, code, and location information.
  /// 
  /// Returns: Widget displaying stop information
  Widget _buildStopInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Stop Information',
                  style: AppTypography.heading3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              entry.stop.name ?? 'Unknown Stop',
              style: AppTypography.heading2,
            ),
            if (entry.stop.code != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Code: ${entry.stop.code}',
                style: AppTypography.bodySmall,
              ),
            ],
            if (entry.stop.description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.stop.description!,
                style: AppTypography.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the route information card
  /// 
  /// Displays route name, type, and color badge.
  /// 
  /// [routeName] - Display name for the route
  /// [routeTypeName] - Human-readable route type name
  /// [routeTypeEmoji] - Emoji representing the route type
  /// [routeColor] - Parsed route color, if available
  /// 
  /// Returns: Widget displaying route information
  Widget _buildRouteInfoCard(
    BuildContext context, {
    required String routeName,
    required String routeTypeName,
    required String routeTypeEmoji,
    required Color? routeColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.route,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Route Information',
                  style: AppTypography.heading3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                // Route color badge if available
                if (routeColor != null) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: routeColor,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    routeName,
                    style: AppTypography.heading2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  routeTypeEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  routeTypeName,
                  style: AppTypography.body,
                ),
              ],
            ),
            if (entry.route.longName != null && 
                entry.route.longName != routeName) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                entry.route.longName!,
                style: AppTypography.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the trip information card
  /// 
  /// Displays trip destination/headsign information.
  /// 
  /// [displayHeadsign] - The smart-formatted headsign to display
  /// 
  /// Returns: Widget displaying trip information
  Widget _buildTripInfoCard(BuildContext context, {required String displayHeadsign}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.directions_transit,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Destination',
                  style: AppTypography.heading3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              displayHeadsign,
              style: AppTypography.body,
            ),
            if (entry.trip.directionId != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Direction: ${entry.trip.directionId == "0" ? "Outbound" : "Inbound"}',
                style: AppTypography.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the time information card
  /// 
  /// Displays arrival and departure times, avoiding repetition when they're the same.
  /// 
  /// [formattedArrival] - Formatted arrival time string
  /// [formattedDeparture] - Formatted departure time string
  /// [timesAreSame] - Whether arrival and departure times are identical
  /// 
  /// Returns: Widget displaying time information
  Widget _buildTimeInfoCard({
    required String? formattedArrival,
    required String? formattedDeparture,
    required bool timesAreSame,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.schedule,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Schedule Time',
                  style: AppTypography.heading3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (timesAreSame) ...[
              // Show single time if arrival and departure are the same
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      formattedDeparture ?? '--:--',
                      style: AppTypography.heading2.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Arrival and departure at same time',
                style: AppTypography.bodySmall,
              ),
            ] else ...[
              // Show both times if they differ
              if (formattedArrival != null) ...[
                Row(
                  children: [
                    Text(
                      'Arrival: ',
                      style: AppTypography.bodySmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formattedArrival,
                        style: AppTypography.heading3.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (formattedDeparture != null) ...[
                Row(
                  children: [
                    Text(
                      'Departure: ',
                      style: AppTypography.bodySmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formattedDeparture,
                        style: AppTypography.heading3.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the additional details card
  /// 
  /// Displays accessibility and other additional information.
  /// 
  /// Returns: Widget displaying additional details
  Widget _buildAdditionalDetailsCard(BuildContext context) {
    final List<Widget> detailItems = [];
    
    // Wheelchair accessibility
    if (entry.trip.wheelchairAccessible != null) {
      final bool isAccessible = entry.trip.wheelchairAccessible == '1';
      detailItems.add(
        _buildDetailRow(
          context,
          icon: Icons.accessible,
          label: 'Wheelchair Accessible',
          value: isAccessible ? 'Yes' : 'No',
          valueColor: isAccessible ? Colors.green : Colors.grey,
        ),
      );
    }
    
    // Bikes allowed
    if (entry.trip.bikesAllowed != null) {
      final bool bikesAllowed = entry.trip.bikesAllowed == '1';
      detailItems.add(
        _buildDetailRow(
          context,
          icon: Icons.pedal_bike,
          label: 'Bikes Allowed',
          value: bikesAllowed ? 'Yes' : 'No',
          valueColor: bikesAllowed ? Colors.green : Colors.grey,
        ),
      );
    }
    
    // Stop sequence
    detailItems.add(
      _buildDetailRow(
        context,
        icon: Icons.list,
        label: 'Stop Sequence',
        value: '${entry.stopTime.stopSequence}',
      ),
    );
    
    if (detailItems.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Additional Details',
                  style: AppTypography.heading3,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ...detailItems,
          ],
        ),
      ),
    );
  }

  /// Builds a detail row with icon, label, and value
  /// 
  /// [icon] - Icon to display
  /// [label] - Label text
  /// [value] - Value text
  /// [valueColor] - Optional color for the value text
  /// 
  /// Returns: Widget displaying a detail row
  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Formats a GTFS time string to HH:MM format
  /// 
  /// GTFS times are in HH:MM:SS format and can exceed 24:00:00.
  /// This method extracts just the hour and minute portions.
  /// 
  /// [timeString] - Time string in HH:MM:SS format
  /// 
  /// Returns: Formatted time string in HH:MM format
  String _formatTime(String timeString) {
    final List<String> parts = timeString.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeString;
  }

  /// Gets smart headsign display to avoid repeating route name
  /// 
  /// If the headsign is similar to or contains the route name,
  /// it returns a simplified version to avoid redundancy.
  /// 
  /// [routeName] - The route display name
  /// [headsign] - The trip headsign
  /// 
  /// Returns: Smart-formatted headsign string, or null if not applicable
  String? _getSmartHeadsignDisplay(String routeName, String? headsign) {
    if (headsign == null || headsign.isEmpty) {
      return null;
    }
    
    // Normalize strings for comparison (lowercase, trim)
    final String normalizedRoute = routeName.toLowerCase().trim();
    final String normalizedHeadsign = headsign.toLowerCase().trim();
    
    // If headsign is exactly the same as route name, return null to avoid display
    if (normalizedHeadsign == normalizedRoute) {
      return null;
    }
    
    // If headsign starts with route name, remove the route name part
    if (normalizedHeadsign.startsWith(normalizedRoute)) {
      final String remaining = headsign.substring(routeName.length).trim();
      if (remaining.isNotEmpty && !remaining.startsWith('-')) {
        return remaining;
      }
      // If only route name remains, return null
      if (remaining.isEmpty || remaining == '-') {
        return null;
      }
    }
    
    // If route name is contained in headsign, try to extract meaningful part
    if (normalizedHeadsign.contains(normalizedRoute)) {
      // Try to find a meaningful suffix after the route name
      final int index = normalizedHeadsign.indexOf(normalizedRoute);
      if (index >= 0) {
        final String afterRoute = headsign.substring(index + routeName.length).trim();
        if (afterRoute.isNotEmpty && afterRoute.length > 2) {
          return afterRoute;
        }
      }
    }
    
    // Default: return headsign as-is
    return headsign;
  }
}

