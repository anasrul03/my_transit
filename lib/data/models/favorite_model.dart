import '../../domain/entities/favorite_entity.dart';

/// Data model for favorite items from Supabase
/// 
/// This model handles JSON serialization/deserialization for favorites
/// stored in the Supabase database and converts between database format
/// and domain entities.
class FavoriteModel extends FavoriteEntity {
  /// Creates a FavoriteModel
  /// 
  /// All parameters match FavoriteEntity
  const FavoriteModel({
    required super.id,
    required super.userId,
    required super.vehicleId,
    super.routeId,
    super.vehicleType,
    required super.displayName,
    required super.createdAt,
  });

  /// Creates a FavoriteModel from JSON data (Supabase format)
  /// 
  /// [json] - Map containing favorite data from Supabase
  /// 
  /// Returns: FavoriteModel instance
  /// 
  /// Note: Handles timestamp conversion from ISO string to DateTime
  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String,
      routeId: json['route_id'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      displayName: json['display_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Converts this model to JSON format for Supabase
  /// 
  /// Returns: Map containing favorite data in Supabase format
  /// 
  /// Note: Converts DateTime to ISO string format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_id': vehicleId,
      'route_id': routeId,
      'vehicle_type': vehicleType,
      'display_name': displayName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Creates a FavoriteModel from a FavoriteEntity
  /// 
  /// [entity] - The FavoriteEntity to convert
  /// 
  /// Returns: FavoriteModel instance
  factory FavoriteModel.fromEntity(FavoriteEntity entity) {
    return FavoriteModel(
      id: entity.id,
      userId: entity.userId,
      vehicleId: entity.vehicleId,
      routeId: entity.routeId,
      vehicleType: entity.vehicleType,
      displayName: entity.displayName,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this model to a FavoriteEntity
  /// 
  /// Returns: FavoriteEntity instance
  FavoriteEntity toEntity() {
    return FavoriteEntity(
      id: id,
      userId: userId,
      vehicleId: vehicleId,
      routeId: routeId,
      vehicleType: vehicleType,
      displayName: displayName,
      createdAt: createdAt,
    );
  }
}

