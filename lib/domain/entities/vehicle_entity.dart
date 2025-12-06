import 'package:equatable/equatable.dart';

class VehicleEntity extends Equatable {
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

  const VehicleEntity({
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

  @override
  List<Object?> get props => [
        id,
        routeId,
        tripId,
        latitude,
        longitude,
        bearing,
        speed,
        timestamp,
        operatorId,
        vehicleLabel,
      ];
}

