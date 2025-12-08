import 'package:equatable/equatable.dart';

class ShapePoint extends Equatable {
  final double latitude;
  final double longitude;
  final double? distanceTraveled;
  final int sequence;

  const ShapePoint({
    required this.latitude,
    required this.longitude,
    this.distanceTraveled,
    required this.sequence,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        distanceTraveled,
        sequence,
      ];
}

class ShapeEntity extends Equatable {
  final String id;
  final List<ShapePoint> points;

  const ShapeEntity({
    required this.id,
    required this.points,
  });

  @override
  List<Object?> get props => [id, points];
}

