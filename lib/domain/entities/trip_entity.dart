import 'package:equatable/equatable.dart';

class TripEntity extends Equatable {
  final String id;
  final String routeId;
  final String? serviceId;
  final String? headsign;
  final String? directionId;
  final String? blockId;
  final String? shapeId;
  final String? wheelchairAccessible;
  final String? bikesAllowed;

  const TripEntity({
    required this.id,
    required this.routeId,
    this.serviceId,
    this.headsign,
    this.directionId,
    this.blockId,
    this.shapeId,
    this.wheelchairAccessible,
    this.bikesAllowed,
  });

  @override
  List<Object?> get props => [
        id,
        routeId,
        serviceId,
        headsign,
        directionId,
        blockId,
        shapeId,
        wheelchairAccessible,
        bikesAllowed,
      ];
}

