import '../../../domain/entities/frequency_entity.dart';

/// Data Transfer Object for GTFS frequencies.txt file
/// 
/// Represents trips that operate on regular headways (time between trips).
/// This can represent frequency-based service or compressed schedule-based service.
class FrequencyDto {
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

  FrequencyDto({
    required this.tripId,
    required this.startTime,
    required this.endTime,
    required this.headwaySecs,
    this.exactTimes,
  });

  /// Creates a FrequencyDto from a CSV row map
  /// 
  /// Parses the CSV fields according to GTFS specification.
  factory FrequencyDto.fromCsv(Map<String, String> row) {
    return FrequencyDto(
      tripId: row['trip_id'] ?? '',
      startTime: row['start_time'] ?? '',
      endTime: row['end_time'] ?? '',
      headwaySecs: int.tryParse(row['headway_secs'] ?? '0') ?? 0,
      exactTimes: row['exact_times'] != null
          ? int.tryParse(row['exact_times']!)
          : null,
    );
  }

  /// Converts this DTO to a FrequencyEntity
  /// 
  /// Transforms the data transfer object into a domain entity.
  FrequencyEntity toEntity() {
    return FrequencyEntity(
      tripId: tripId,
      startTime: startTime,
      endTime: endTime,
      headwaySecs: headwaySecs,
      exactTimes: exactTimes,
    );
  }
}

