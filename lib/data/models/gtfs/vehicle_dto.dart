import '../../../domain/entities/vehicle_entity.dart';

class VehicleDto {
  final String id;
  final String routeId;
  final String tripId;
  final double latitude;
  final double longitude;
  final double? bearing;
  final double? speed;
  final DateTime timestamp;
  final String? operatorId;
  final String? vehicleLabel;

  VehicleDto({
    required this.id,
    required this.routeId,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    this.bearing,
    this.speed,
    required this.timestamp,
    this.operatorId,
    this.vehicleLabel,
  });

  VehicleEntity toEntity() {
    return VehicleEntity(
      id: id,
      routeId: routeId,
      tripId: tripId,
      latitude: latitude,
      longitude: longitude,
      bearing: bearing,
      speed: speed,
      timestamp: timestamp,
      operatorId: operatorId,
      vehicleLabel: vehicleLabel,
    );
  }
}

