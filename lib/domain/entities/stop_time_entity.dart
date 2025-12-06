import 'package:equatable/equatable.dart';

class StopTimeEntity extends Equatable {
  final String tripId;
  final String stopId;
  final String? arrivalTime;
  final String? departureTime;
  final int stopSequence;
  final String? stopHeadsign;
  final int? pickupType;
  final int? dropOffType;
  final double? shapeDistTraveled;

  const StopTimeEntity({
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

  @override
  List<Object?> get props => [
        tripId,
        stopId,
        arrivalTime,
        departureTime,
        stopSequence,
        stopHeadsign,
        pickupType,
        dropOffType,
        shapeDistTraveled,
      ];
}

