import '../entities/favorite_entity.dart';
import 'auth_repository.dart'; // For Result type

/// Repository interface for managing user favorites
/// 
/// This repository handles CRUD operations for user favorites stored in Supabase.
/// All operations require an authenticated user and filter results by the current user's ID.
abstract class FavoriteRepository {
  /// Gets all favorites for the current authenticated user
  /// 
  /// Returns: Result containing list of FavoriteEntity objects, or failure if error occurs
  /// 
  /// Note: Returns empty list if user has no favorites
  /// Returns failure if user is not authenticated
  Future<Result<List<FavoriteEntity>>> getFavorites();

  /// Adds a new favorite for the current authenticated user
  /// 
  /// [vehicleId] - Vehicle ID (required)
  /// [routeId] - Route ID (optional)
  /// [vehicleType] - Vehicle type (optional)
  /// [displayName] - Display name for the favorite (required)
  /// 
  /// Returns: Result containing the created FavoriteEntity, or failure if error occurs
  /// 
  /// Note: Returns failure if user is not authenticated
  /// Returns failure if favorite already exists for this vehicle
  Future<Result<FavoriteEntity>> addFavorite({
    required String vehicleId,
    String? routeId,
    String? vehicleType,
    required String displayName,
  });

  /// Removes a favorite by its ID
  /// 
  /// [favoriteId] - The ID of the favorite to remove
  /// 
  /// Returns: Result containing void on success, or failure if error occurs
  /// 
  /// Note: Returns failure if user is not authenticated
  /// Returns failure if favorite doesn't exist or doesn't belong to current user
  Future<Result<void>> removeFavorite(String favoriteId);

  /// Updates a favorite's display name
  /// 
  /// [favoriteId] - The ID of the favorite to update
  /// [displayName] - New display name
  /// 
  /// Returns: Result containing the updated FavoriteEntity, or failure if error occurs
  /// 
  /// Note: Returns failure if user is not authenticated
  /// Returns failure if favorite doesn't exist or doesn't belong to current user
  Future<Result<FavoriteEntity>> updateFavorite({
    required String favoriteId,
    required String displayName,
  });

  /// Checks if a vehicle is already favorited by the current user
  /// 
  /// [vehicleId] - The vehicle ID to check
  /// 
  /// Returns: Result containing true if favorited, false otherwise, or failure if error occurs
  /// 
  /// Note: Returns failure if user is not authenticated
  Future<Result<bool>> isFavorite(String vehicleId);

  /// Gets a favorite by vehicle ID for the current user
  /// 
  /// [vehicleId] - The vehicle ID to look up
  /// 
  /// Returns: Result containing FavoriteEntity if found, null if not found, or failure if error occurs
  /// 
  /// Note: Returns failure if user is not authenticated
  Future<Result<FavoriteEntity?>> getFavoriteByVehicleId(String vehicleId);
}

