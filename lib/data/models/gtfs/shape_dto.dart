import '../../../domain/entities/shape_entity.dart';

class ShapePointDto {
  final double latitude;
  final double longitude;
  final double? distanceTraveled;
  final int sequence;

  ShapePointDto({
    required this.latitude,
    required this.longitude,
    this.distanceTraveled,
    required this.sequence,
  });

  factory ShapePointDto.fromCsv(Map<String, String> row) {
    return ShapePointDto(
      latitude: double.tryParse(row['shape_pt_lat'] ?? '0') ?? 0.0,
      longitude: double.tryParse(row['shape_pt_lon'] ?? '0') ?? 0.0,
      distanceTraveled: row['shape_dist_traveled'] != null
          ? double.tryParse(row['shape_dist_traveled']!)
          : null,
      sequence: int.tryParse(row['shape_pt_sequence'] ?? '0') ?? 0,
    );
  }

  ShapePoint toEntity() {
    return ShapePoint(
      latitude: latitude,
      longitude: longitude,
      distanceTraveled: distanceTraveled,
      sequence: sequence,
    );
  }
}

class ShapeDto {
  final String id;
  final List<ShapePointDto> points;

  ShapeDto({
    required this.id,
    required this.points,
  });

  ShapeEntity toEntity() {
    return ShapeEntity(
      id: id,
      points: points.map((p) => p.toEntity()).toList(),
    );
  }
}

