import '../../../domain/entities/stop_time_entity.dart';

class StopTimeDto {
  final String tripId;
  final String stopId;
  final String? arrivalTime;
  final String? departureTime;
  final int stopSequence;
  final String? stopHeadsign;
  final int? pickupType;
  final int? dropOffType;
  final double? shapeDistTraveled;

  StopTimeDto({
    required this.tripId,
    required this.stopId,
    this.arrivalTime,
    this.departureTime,
    required this.stopSequence,
    this.stopHeadsign,
    this.pickupType,
    this.dropOffType,
    this.shapeDistTraveled,
  });

  factory StopTimeDto.fromCsv(Map<String, String> row) {
    return StopTimeDto(
      tripId: row['trip_id'] ?? '',
      stopId: row['stop_id'] ?? '',
      arrivalTime: row['arrival_time'],
      departureTime: row['departure_time'],
      stopSequence: int.tryParse(row['stop_sequence'] ?? '0') ?? 0,
      stopHeadsign: row['stop_headsign'],
      pickupType: row['pickup_type'] != null
          ? int.tryParse(row['pickup_type']!)
          : null,
      dropOffType: row['drop_off_type'] != null
          ? int.tryParse(row['drop_off_type']!)
          : null,
      shapeDistTraveled: row['shape_dist_traveled'] != null
          ? double.tryParse(row['shape_dist_traveled']!)
          : null,
    );
  }

  StopTimeEntity toEntity() {
    return StopTimeEntity(
      tripId: tripId,
      stopId: stopId,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
      stopSequence: stopSequence,
      stopHeadsign: stopHeadsign,
      pickupType: pickupType,
      dropOffType: dropOffType,
      shapeDistTraveled: shapeDistTraveled,
    );
  }
}

