import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing favorite vehicles storage
/// 
/// This service handles storing and retrieving favorite vehicle IDs using
/// SharedPreferences for persistent storage across app sessions.
class FavoriteVehiclesService {
  /// SharedPreferences key for storing favorite vehicle IDs
  static const String _favoritesKey = 'favorite_vehicle_ids';
  
  /// The SharedPreferences instance
  final SharedPreferences _prefs;
  
  /// Creates a FavoriteVehiclesService with the given SharedPreferences instance
  /// 
  /// [_prefs] - SharedPreferences instance for persistent storage
  FavoriteVehiclesService(this._prefs);
  
  /// Gets the list of favorite vehicle IDs
  /// 
  /// Returns: List of vehicle IDs that have been marked as favorites
  /// Returns an empty list if no favorites have been saved.
  List<String> getFavorites() {
    try {
      final String? favoritesJson = _prefs.getString(_favoritesKey);
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return <String>[];
      }
      
      // Parse JSON array of favorite IDs
      final List<dynamic> favoritesList = json.decode(favoritesJson) as List<dynamic>;
      return favoritesList.map((dynamic id) => id.toString()).toList();
    } catch (e) {
      // If there's any error parsing, return empty list
      return <String>[];
    }
  }
  
  /// Adds a vehicle ID to the favorites list
  /// 
  /// [vehicleId] - The vehicle ID to add to favorites
  /// 
  /// Returns: true if successfully added, false otherwise
  Future<bool> addFavorite(String vehicleId) async {
    try {
      final List<String> favorites = getFavorites();
      
      // Don't add if already in favorites
      if (favorites.contains(vehicleId)) {
        return true;
      }
      
      favorites.add(vehicleId);
      
      // Save updated list
      final String favoritesJson = json.encode(favorites);
      return await _prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      return false;
    }
  }
  
  /// Removes a vehicle ID from the favorites list
  /// 
  /// [vehicleId] - The vehicle ID to remove from favorites
  /// 
  /// Returns: true if successfully removed, false otherwise
  Future<bool> removeFavorite(String vehicleId) async {
    try {
      final List<String> favorites = getFavorites();
      
      // Remove the vehicle ID from the list
      favorites.remove(vehicleId);
      
      // Save updated list
      final String favoritesJson = json.encode(favorites);
      return await _prefs.setString(_favoritesKey, favoritesJson);
    } catch (e) {
      return false;
    }
  }
  
  /// Checks if a vehicle ID is in the favorites list
  /// 
  /// [vehicleId] - The vehicle ID to check
  /// 
  /// Returns: true if the vehicle is in favorites, false otherwise
  bool isFavorite(String vehicleId) {
    final List<String> favorites = getFavorites();
    return favorites.contains(vehicleId);
  }
  
  /// Clears all favorites
  /// 
  /// Returns: true if successfully cleared, false otherwise
  Future<bool> clearFavorites() async {
    try {
      return await _prefs.remove(_favoritesKey);
    } catch (e) {
      return false;
    }
  }
}

