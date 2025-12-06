import 'package:equatable/equatable.dart';
import 'stop_time_entity.dart';
import 'trip_entity.dart';
import 'route_entity.dart';
import 'stop_entity.dart';

/// Domain entity representing a schedule entry combining stop_time, trip, route, and stop data
/// 
/// This entity combines information from multiple GTFS static files to provide
/// a complete schedule entry for display. It includes the stop time information,
/// associated trip details, route information, and stop details.
class ScheduleEntryEntity extends Equatable {
  /// The stop time entity containing arrival/departure times and sequence
  final StopTimeEntity stopTime;
  
  /// The trip entity containing trip details like headsign and direction
  final TripEntity trip;
  
  /// The route entity containing route information like name and color
  final RouteEntity route;
  
  /// The stop entity containing stop details like name and location
  final StopEntity stop;

  const ScheduleEntryEntity({
    required this.stopTime,
    required this.trip,
    required this.route,
    required this.stop,
  });

  /// Gets the display time for this schedule entry
  /// 
  /// Returns the departure time if available, otherwise returns the arrival time.
  /// If neither is available, returns null. Times are in HH:MM:SS format from GTFS.
  /// 
  /// Returns: Formatted time string (HH:MM) or null if no time available
  String? getDisplayTime() {
    // Prefer departure time, fall back to arrival time
    final String? timeString = stopTime.departureTime ?? stopTime.arrivalTime;
    if (timeString == null) return null;
    
    // Extract HH:MM from HH:MM:SS format
    // GTFS times can be >24:00:00 for trips that span midnight
    final List<String> parts = timeString.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeString;
  }

  /// Gets the route display name for this schedule entry
  /// 
  /// Returns the route short name if available, otherwise returns the long name.
  /// If neither is available, returns the route ID as fallback.
  /// 
  /// Returns: Route display name string
  String getRouteDisplayName() {
    return route.shortName ?? route.longName ?? route.id;
  }

  /// Gets the trip headsign for display
  /// 
  /// Returns the trip headsign if available, otherwise returns the stop headsign
  /// from the stop_time, or null if neither is available.
  /// 
  /// Returns: Trip destination/headsign string or null
  String? getTripHeadsign() {
    return trip.headsign ?? stopTime.stopHeadsign;
  }

  @override
  List<Object?> get props => [
        stopTime,
        trip,
        route,
        stop,
      ];
}

