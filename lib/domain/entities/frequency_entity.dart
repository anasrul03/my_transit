import 'package:equatable/equatable.dart';

/// Domain entity representing frequency-based service from GTFS frequencies.txt
/// 
/// Represents trips that operate on regular headways (time between trips).
/// This can represent frequency-based service or compressed schedule-based service.
class FrequencyEntity extends Equatable {
  /// Identifies a trip to which the specified headway of service applies (required).
  /// Foreign key referencing trips.trip_id.
  final String tripId;
  
  /// Time at which the first vehicle departs from the first stop of the trip (required).
  /// Format: HH:MM:SS in the timezone specified by agency.agency_timezone.
  final String startTime;
  
  /// Time at which service changes to a different headway or ceases (required).
  /// Format: HH:MM:SS in the timezone specified by agency.agency_timezone.
  final String endTime;
  
  /// Time, in seconds, between departures from the same stop (headway) for the trip (required).
  /// Must be a positive integer.
  final int headwaySecs;
  
  /// Indicates the type of service for a trip (optional).
  /// Valid values: 0 or empty (frequency-based trips), 1 (schedule-based trips).
  final int? exactTimes;

  const FrequencyEntity({
    required this.tripId,
    required this.startTime,
    required this.endTime,
    required this.headwaySecs,
    this.exactTimes,
  });

  @override
  List<Object?> get props => [
        tripId,
        startTime,
        endTime,
        headwaySecs,
        exactTimes,
      ];
}

