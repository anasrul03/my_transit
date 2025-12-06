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
  final List<String>? dataQualityWarnings;
  final String? routeShortName;
  final String? routeLongName;
  final int? routeType;

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
    this.dataQualityWarnings,
    this.routeShortName,
    this.routeLongName,
    this.routeType,
  });

  /// Creates a copy of this vehicle entity with the given fields replaced with new values
  /// 
  /// All fields are optional. If a field is not provided, the original value is kept.
  /// This is useful for creating updated vehicle entities with new positions during interpolation.
  VehicleEntity copyWith({
    String? id,
    String? routeId,
    String? tripId,
    double? latitude,
    double? longitude,
    double? bearing,
    double? speed,
    DateTime? timestamp,
    String? operatorId,
    String? vehicleLabel,
    List<String>? dataQualityWarnings,
    String? routeShortName,
    String? routeLongName,
    int? routeType,
  }) {
    return VehicleEntity(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      tripId: tripId ?? this.tripId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bearing: bearing ?? this.bearing,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
      operatorId: operatorId ?? this.operatorId,
      vehicleLabel: vehicleLabel ?? this.vehicleLabel,
      dataQualityWarnings: dataQualityWarnings ?? this.dataQualityWarnings,
      routeShortName: routeShortName ?? this.routeShortName,
      routeLongName: routeLongName ?? this.routeLongName,
      routeType: routeType ?? this.routeType,
    );
  }

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
        dataQualityWarnings,
        routeShortName,
        routeLongName,
        routeType,
      ];
}

