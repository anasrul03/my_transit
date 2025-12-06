import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/favorite_entity.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../../core/constants/gtfs_route_types.dart';

/// Service for managing favorite vehicles storage using Supabase
/// 
/// This service handles storing and retrieving favorite vehicles using
/// the Supabase database through the FavoriteRepository. It also provides
/// migration functionality to move existing favorites from SharedPreferences
/// to Supabase when a user signs in.
class FavoriteVehiclesService {
  /// SharedPreferences key for storing favorite vehicle IDs (used for migration)
  static const String _favoritesKey = 'favorite_vehicle_ids';
  
  /// The favorite repository for Supabase operations
  final FavoriteRepository _repository;
  
  /// Optional SharedPreferences instance for migration
  final SharedPreferences? _prefs;
  
  /// Creates a FavoriteVehiclesService with the given repository
  /// 
  /// [_repository] - FavoriteRepository instance for Supabase operations
  /// [_prefs] - Optional SharedPreferences instance for migration
  FavoriteVehiclesService(this._repository, [this._prefs]);

  /// Gets all favorites for the current user
  /// 
  /// Returns: List of FavoriteEntity objects
  /// Returns empty list if no favorites or if user is not authenticated
  Future<List<FavoriteEntity>> getFavorites() async {
    final result = await _repository.getFavorites();
    if (result.isSuccess) {
      return result.data ?? <FavoriteEntity>[];
    }
    // Return empty list on error (user not authenticated, network error, etc.)
    return <FavoriteEntity>[];
  }

  /// Adds a vehicle to favorites
  /// 
  /// [vehicle] - The vehicle entity to add (used to generate display name and metadata)
  /// [displayName] - Optional custom display name. If not provided, will be auto-generated
  /// 
  /// Returns: FavoriteEntity if successfully added, null otherwise
  Future<FavoriteEntity?> addFavorite({
    required VehicleEntity vehicle,
    String? displayName,
  }) async {
    // Generate display name if not provided
    final String finalDisplayName = displayName ?? _generateDisplayName(vehicle);
    
    // Convert route type to string if available
    final String? vehicleType = vehicle.routeType != null
        ? GtfsRouteType.getDisplayName(vehicle.routeType).toLowerCase()
        : null;

    final result = await _repository.addFavorite(
      vehicleId: vehicle.id,
      routeId: vehicle.routeId.isNotEmpty ? vehicle.routeId : null,
      vehicleType: vehicleType,
      displayName: finalDisplayName,
    );

    if (result.isSuccess) {
      return result.data;
    }
    return null;
  }

  /// Removes a favorite by its ID
  /// 
  /// [favoriteId] - The ID of the favorite to remove
  /// 
  /// Returns: true if successfully removed, false otherwise
  Future<bool> removeFavorite(String favoriteId) async {
    final result = await _repository.removeFavorite(favoriteId);
    return result.isSuccess;
  }

  /// Removes a favorite by vehicle ID
  /// 
  /// [vehicleId] - The vehicle ID to remove from favorites
  /// 
  /// Returns: true if successfully removed, false otherwise
  Future<bool> removeFavoriteByVehicleId(String vehicleId) async {
    // First, get the favorite by vehicle ID
    final getResult = await _repository.getFavoriteByVehicleId(vehicleId);
    if (!getResult.isSuccess || getResult.data == null) {
      return false;
    }

    // Remove the favorite by its ID
    return await removeFavorite(getResult.data!.id);
  }

  /// Checks if a vehicle is favorited
  /// 
  /// [vehicleId] - The vehicle ID to check
  /// 
  /// Returns: true if the vehicle is favorited, false otherwise
  Future<bool> isFavorite(String vehicleId) async {
    final result = await _repository.isFavorite(vehicleId);
    if (result.isSuccess) {
      return result.data ?? false;
    }
    return false;
  }

  /// Updates a favorite's display name
  /// 
  /// [favoriteId] - The ID of the favorite to update
  /// [displayName] - New display name
  /// 
  /// Returns: Updated FavoriteEntity if successful, null otherwise
  Future<FavoriteEntity?> updateDisplayName({
    required String favoriteId,
    required String displayName,
  }) async {
    final result = await _repository.updateFavorite(
      favoriteId: favoriteId,
      displayName: displayName,
    );

    if (result.isSuccess) {
      return result.data;
    }
    return null;
  }

  /// Clears all favorites for the current user
  /// 
  /// Returns: true if successfully cleared, false otherwise
  /// 
  /// Note: This removes all favorites from Supabase, not just local storage
  Future<bool> clearFavorites() async {
    // Get all favorites first
    final favorites = await getFavorites();
    
    // Remove each favorite
    bool allSuccess = true;
    for (final favorite in favorites) {
      final result = await _repository.removeFavorite(favorite.id);
      if (!result.isSuccess) {
        allSuccess = false;
      }
    }
    
    return allSuccess;
  }

  /// Generates a display name for a vehicle
  /// 
  /// Uses vehicle label, route short name, or route long name to create
  /// a user-friendly display name like "Bus 101" or "Route 5 - Bus"
  /// 
  /// [vehicle] - The vehicle entity to generate a display name for
  /// 
  /// Returns: Generated display name string
  String _generateDisplayName(VehicleEntity vehicle) {
    // Prefer vehicle label if available
    if (vehicle.vehicleLabel != null && vehicle.vehicleLabel!.isNotEmpty) {
      final vehicleType = vehicle.routeType != null
          ? GtfsRouteType.getDisplayName(vehicle.routeType)
          : 'Vehicle';
      return '${vehicle.vehicleLabel} - $vehicleType';
    }

    // Use route short name if available
    if (vehicle.routeShortName != null && vehicle.routeShortName!.isNotEmpty) {
      final vehicleType = vehicle.routeType != null
          ? GtfsRouteType.getDisplayName(vehicle.routeType)
          : 'Route';
      return '${vehicle.routeShortName} - $vehicleType';
    }

    // Use route long name if available
    if (vehicle.routeLongName != null && vehicle.routeLongName!.isNotEmpty) {
      final vehicleType = vehicle.routeType != null
          ? GtfsRouteType.getDisplayName(vehicle.routeType)
          : 'Route';
      // Truncate long names to reasonable length
      final truncatedName = vehicle.routeLongName!.length > 30
          ? '${vehicle.routeLongName!.substring(0, 30)}...'
          : vehicle.routeLongName!;
      return '$truncatedName - $vehicleType';
    }

    // Fallback to vehicle ID with vehicle type
    final vehicleType = vehicle.routeType != null
        ? GtfsRouteType.getDisplayName(vehicle.routeType)
        : 'Vehicle';
    return '${vehicle.id} - $vehicleType';
  }

  /// Migrates favorites from SharedPreferences to Supabase
  /// 
  /// This method reads existing favorites from SharedPreferences and creates
  /// them in Supabase. It attempts to generate display names from available
  /// vehicle information, but may use fallback names if vehicle data is not available.
  /// 
  /// [getVehicleById] - Optional function to get vehicle entity by ID for generating display names
  /// 
  /// Returns: Number of favorites successfully migrated
  /// 
  /// Note: Only migrates if SharedPreferences is available and user is authenticated
  /// Does not clear SharedPreferences until migration is confirmed successful
  Future<int> migrateFromSharedPreferences({
    VehicleEntity? Function(String vehicleId)? getVehicleById,
  }) async {
    // Check if SharedPreferences is available
    if (_prefs == null) {
      return 0;
    }

      // Check if user is authenticated (repository will handle this, but we check early)
      final isFavResult = await _repository.isFavorite('dummy_check');
      if (!isFavResult.isSuccess && isFavResult.error != null) {
        // User not authenticated, cannot migrate
        return 0;
      }

    try {
      // Read existing favorites from SharedPreferences
      final String? favoritesJson = _prefs!.getString(_favoritesKey);
      if (favoritesJson == null || favoritesJson.isEmpty) {
        // No favorites to migrate
        return 0;
      }

      // Parse JSON array of favorite IDs
      final List<dynamic> favoritesList = json.decode(favoritesJson);
      final List<String> vehicleIds = favoritesList
          .map((dynamic id) => id.toString())
          .toList();

      if (vehicleIds.isEmpty) {
        return 0;
      }

      // Migrate each favorite
      int successCount = 0;
      for (final String vehicleId in vehicleIds) {
        try {
          // Check if already exists in Supabase
          final existingResult = await _repository.getFavoriteByVehicleId(vehicleId);
          if (existingResult.isSuccess && existingResult.data != null) {
            // Already exists, skip
            successCount++;
            continue;
          }

          // Try to get vehicle info for better display name
          VehicleEntity? vehicle;
          if (getVehicleById != null) {
            vehicle = getVehicleById(vehicleId);
          }

          // Generate display name
          String displayName;
          String? routeId;
          String? vehicleType;

          if (vehicle != null) {
            displayName = _generateDisplayName(vehicle);
            routeId = vehicle.routeId.isNotEmpty ? vehicle.routeId : null;
            vehicleType = vehicle.routeType != null
                ? GtfsRouteType.getDisplayName(vehicle.routeType).toLowerCase()
                : null;
          } else {
            // Fallback display name if vehicle info not available
            displayName = 'Vehicle $vehicleId';
          }

          // Create favorite in Supabase
          final addResult = await _repository.addFavorite(
            vehicleId: vehicleId,
            routeId: routeId,
            vehicleType: vehicleType,
            displayName: displayName,
          );

          if (addResult.isSuccess) {
            successCount++;
          }
        } catch (e) {
          // Log error but continue with other favorites
          // Don't fail entire migration if one favorite fails
          continue;
        }
      }

      // Only clear SharedPreferences if all favorites were successfully migrated
      // or if they already existed in Supabase
      if (successCount == vehicleIds.length) {
        await _prefs!.remove(_favoritesKey);
      }

      return successCount;
    } catch (e) {
      // If migration fails, don't clear SharedPreferences
      // User can try again later
      return 0;
    }
  }

  /// Gets favorite IDs from SharedPreferences (for migration check)
  /// 
  /// Returns: List of vehicle IDs stored in SharedPreferences, or empty list
  List<String> getSharedPreferencesFavorites() {
    if (_prefs == null) {
      return <String>[];
    }

    try {
      final String? favoritesJson = _prefs!.getString(_favoritesKey);
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return <String>[];
      }

      final List<dynamic> favoritesList = json.decode(favoritesJson) as List<dynamic>;
      return favoritesList.map((dynamic id) => id.toString()).toList();
    } catch (e) {
      return <String>[];
    }
  }
}
