import '../../../domain/entities/trip_entity.dart';

class TripDto {
  final String id;
  final String routeId;
  final String? serviceId;
  final String? headsign;
  final String? directionId;
  final String? blockId;
  final String? shapeId;
  final String? wheelchairAccessible;
  final String? bikesAllowed;

  TripDto({
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

  factory TripDto.fromCsv(Map<String, String> row) {
    return TripDto(
      id: row['trip_id'] ?? '',
      routeId: row['route_id'] ?? '',
      serviceId: row['service_id'],
      headsign: row['trip_headsign'],
      directionId: row['direction_id'],
      blockId: row['block_id'],
      shapeId: row['shape_id'],
      wheelchairAccessible: row['wheelchair_accessible'],
      bikesAllowed: row['bikes_allowed'],
    );
  }

  TripEntity toEntity() {
    return TripEntity(
      id: id,
      routeId: routeId,
      serviceId: serviceId,
      headsign: headsign,
      directionId: directionId,
      blockId: blockId,
      shapeId: shapeId,
      wheelchairAccessible: wheelchairAccessible,
      bikesAllowed: bikesAllowed,
    );
  }
}

