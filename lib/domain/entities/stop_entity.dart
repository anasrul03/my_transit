import 'package:equatable/equatable.dart';

class StopEntity extends Equatable {
  final String id;
  final String? code;
  final String? name;
  final String? description;
  final double latitude;
  final double longitude;
  final String? zoneId;
  final String? parentStation;

  const StopEntity({
    required this.id,
    this.code,
    this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    this.zoneId,
    this.parentStation,
  });

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        description,
        latitude,
        longitude,
        zoneId,
        parentStation,
      ];
}

