import 'package:equatable/equatable.dart';

class MapMarkerEntity extends Equatable {
  final String id;
  final double latitude;
  final double longitude;
  final String? title;
  final String? type; // vehicle, stop, etc.
  final String? operatorId;
  final double? bearing;

  const MapMarkerEntity({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.title,
    this.type,
    this.operatorId,
    this.bearing,
  });

  @override
  List<Object?> get props => [
        id,
        latitude,
        longitude,
        title,
        type,
        operatorId,
        bearing,
      ];
}

