import 'package:equatable/equatable.dart';

/// Entity representing a favorite vehicle or route
/// 
/// This entity represents a user's favorite transit item stored in Supabase.
/// It can represent either a vehicle (with vehicle_id) or a route (with route_id),
/// and includes metadata like display name and vehicle type for UI presentation.
class FavoriteEntity extends Equatable {
  /// Unique identifier for the favorite (UUID from Supabase)
  final String id;
  
  /// ID of the user who created this favorite (UUID from auth.users)
  final String userId;
  
  /// Vehicle ID (required - identifies the specific vehicle)
  final String vehicleId;
  
  /// Route ID (optional - identifies the route this vehicle belongs to)
  final String? routeId;
  
  /// Vehicle type (optional - GTFS route type, e.g., "bus", "train")
  final String? vehicleType;
  
  /// Display name for the favorite (required - shown in UI)
  /// 
  /// This is auto-generated when creating a favorite but can be edited by the user.
  final String displayName;
  
  /// Timestamp when this favorite was created
  final DateTime createdAt;

  /// Creates a FavoriteEntity
  /// 
  /// [id] - Unique identifier (UUID)
  /// [userId] - User ID who owns this favorite
  /// [vehicleId] - Vehicle ID (required)
  /// [routeId] - Route ID (optional)
  /// [vehicleType] - Vehicle type (optional)
  /// [displayName] - Display name shown in UI (required)
  /// [createdAt] - Creation timestamp
  const FavoriteEntity({
    required this.id,
    required this.userId,
    required this.vehicleId,
    this.routeId,
    this.vehicleType,
    required this.displayName,
    required this.createdAt,
  });

  /// Creates a copy of this favorite entity with the given fields replaced
  /// 
  /// All fields are optional. If a field is not provided, the original value is kept.
  /// This is useful for updating favorite entities, especially for editing display names.
  FavoriteEntity copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    String? routeId,
    String? vehicleType,
    String? displayName,
    DateTime? createdAt,
  }) {
    return FavoriteEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      routeId: routeId ?? this.routeId,
      vehicleType: vehicleType ?? this.vehicleType,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        vehicleId,
        routeId,
        vehicleType,
        displayName,
        createdAt,
      ];
}

