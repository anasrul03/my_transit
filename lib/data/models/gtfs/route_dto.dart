import '../../../domain/entities/route_entity.dart';

class RouteDto {
  final String id;
  final String? shortName;
  final String? longName;
  final String? description;
  final int? type;
  final String? color;
  final String? textColor;
  final String? agencyId;

  RouteDto({
    required this.id,
    this.shortName,
    this.longName,
    this.description,
    this.type,
    this.color,
    this.textColor,
    this.agencyId,
  });

  factory RouteDto.fromCsv(Map<String, String> row) {
    return RouteDto(
      id: row['route_id'] ?? '',
      shortName: row['route_short_name'],
      longName: row['route_long_name'],
      description: row['route_desc'],
      type: row['route_type'] != null ? int.tryParse(row['route_type']!) : null,
      color: row['route_color'],
      textColor: row['route_text_color'],
      agencyId: row['agency_id'],
    );
  }

  RouteEntity toEntity() {
    return RouteEntity(
      id: id,
      shortName: shortName,
      longName: longName,
      description: description,
      type: type,
      color: color,
      textColor: textColor,
      agencyId: agencyId,
    );
  }
}

