import 'package:equatable/equatable.dart';

class RouteEntity extends Equatable {
  final String id;
  final String? shortName;
  final String? longName;
  final String? description;
  final int? type;
  final String? color;
  final String? textColor;
  final String? agencyId;

  const RouteEntity({
    required this.id,
    this.shortName,
    this.longName,
    this.description,
    this.type,
    this.color,
    this.textColor,
    this.agencyId,
  });

  @override
  List<Object?> get props => [
        id,
        shortName,
        longName,
        description,
        type,
        color,
        textColor,
        agencyId,
      ];
}

