import '../../../domain/entities/stop_entity.dart';

class StopDto {
  final String id;
  final String? code;
  final String? name;
  final String? description;
  final double latitude;
  final double longitude;
  final String? zoneId;
  final String? parentStation;

  StopDto({
    required this.id,
    this.code,
    this.name,
    required this.latitude,
    required this.longitude,
    this.description,
    this.zoneId,
    this.parentStation,
  });

  factory StopDto.fromCsv(Map<String, String> row) {
    return StopDto(
      id: row['stop_id'] ?? '',
      code: row['stop_code'],
      name: row['stop_name'],
      description: row['stop_desc'],
      latitude: double.tryParse(row['stop_lat'] ?? '0') ?? 0.0,
      longitude: double.tryParse(row['stop_lon'] ?? '0') ?? 0.0,
      zoneId: row['zone_id'],
      parentStation: row['parent_station'],
    );
  }

  StopEntity toEntity() {
    return StopEntity(
      id: id,
      code: code,
      name: name,
      latitude: latitude,
      longitude: longitude,
      description: description,
      zoneId: zoneId,
      parentStation: parentStation,
    );
  }
}

