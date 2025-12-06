import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/favorite_vehicles_service.dart';
import '../../data/repositories/favorite_repository_impl.dart';
import '../../domain/entities/favorite_entity.dart';
import '../../domain/entities/vehicle_entity.dart';
import '../../domain/repositories/favorite_repository.dart';
import 'auth_provider.dart';
import 'gtfs_realtime_provider.dart';

/// Provider for SharedPreferences instance
/// 
/// This provider creates and caches a SharedPreferences instance for use
/// throughout the app. It's async because SharedPreferences.getInstance()
/// returns a Future.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for FavoriteRepository
/// 
/// This provider creates a FavoriteRepositoryImpl instance for Supabase operations.
final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl();
});

/// Provider for FavoriteVehiclesService
/// 
/// This provider creates a FavoriteVehiclesService instance with the
/// FavoriteRepository and optional SharedPreferences for migration.
final favoriteVehiclesServiceProvider = Provider<FavoriteVehiclesService>((ref) {
  // Get the repository
  final repository = ref.read(favoriteRepositoryProvider);
  
  // Get SharedPreferences if available (for migration)
  final AsyncValue<SharedPreferences> prefsAsync = ref.watch(sharedPreferencesProvider);
  
  // Return service with repository and optional prefs
  return prefsAsync.maybeWhen(
    data: (SharedPreferences prefs) => FavoriteVehiclesService(repository, prefs),
    orElse: () => FavoriteVehiclesService(repository),
  );
});

/// State class for favorite vehicles
/// 
/// This state tracks favorite vehicles with full metadata (display names, types, etc.)
class FavoriteVehiclesState {
  /// List of favorite entities with full metadata
  final List<FavoriteEntity> favorites;
  
  /// Whether the favorites are currently being loaded
  final bool isLoading;
  
  /// Error message if loading favorites failed
  final String? error;
  
  /// Whether migration is in progress
  final bool isMigrating;
  
  /// Creates a FavoriteVehiclesState
  /// 
  /// [favorites] - List of favorite entities
  /// [isLoading] - Whether favorites are being loaded
  /// [error] - Error message if any
  /// [isMigrating] - Whether migration is in progress
  const FavoriteVehiclesState({
    this.favorites = const <FavoriteEntity>[],
    this.isLoading = false,
    this.error,
    this.isMigrating = false,
  });
  
  /// Creates a copy of this state with the given fields replaced
  /// 
  /// This is useful for updating state immutably while keeping unchanged fields.
  FavoriteVehiclesState copyWith({
    List<FavoriteEntity>? favorites,
    bool? isLoading,
    String? error,
    bool? isMigrating,
  }) {
    return FavoriteVehiclesState(
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isMigrating: isMigrating ?? this.isMigrating,
    );
  }
  
  /// Gets list of favorite vehicle IDs (for backward compatibility)
  /// 
  /// Returns: List of vehicle IDs from favorites
  List<String> get favoriteVehicleIds {
    return favorites.map((favorite) => favorite.vehicleId).toList();
  }
}

/// Notifier for managing favorite vehicles state
/// 
/// This notifier handles loading, adding, removing, and updating favorite vehicles.
/// It uses the FavoriteVehiclesService for Supabase operations and handles migration
/// from SharedPreferences when users sign in.
class FavoriteVehiclesNotifier extends StateNotifier<FavoriteVehiclesState> {
  /// The favorite vehicles service for Supabase operations
  final FavoriteVehiclesService _service;
  
  /// Reference to access other providers (for auth checks and vehicle lookups)
  final Ref _ref;
  
  /// Provider subscription for auth state changes
  /// Used to trigger migration when user signs in
  ProviderSubscription<AuthState>? _authStateSubscription;
  
  /// Whether migration has been attempted for the current session
  bool _migrationAttempted = false;
  
  /// Creates a FavoriteVehiclesNotifier
  /// 
  /// [_service] - The service to use for Supabase operations
  /// [_ref] - Reference to access other providers for authentication checks and vehicle lookups
  FavoriteVehiclesNotifier(this._service, this._ref) : super(const FavoriteVehiclesState()) {
    // Load favorites on initialization
    loadFavorites();
    
    // Listen to auth state changes to trigger migration on sign-in
    _authStateSubscription = _ref.listen<AuthState>(
      authStateProvider,
      (previous, current) {
        // Trigger migration when user signs in (transitions from not authenticated to authenticated)
        if (previous != null &&
            !previous.isAuthenticated &&
            current.isAuthenticated &&
            !_migrationAttempted) {
          _migrationAttempted = true;
          _migrateFavoritesIfNeeded();
        }
      },
    );
  }
  
  @override
  void dispose() {
    _authStateSubscription?.close();
    super.dispose();
  }
  
  /// Checks if the current user is authenticated (not a guest)
  /// 
  /// Returns: true if user is authenticated, false if guest or not logged in
  bool _isAuthenticated() {
    try {
      final authState = _ref.read(authStateProvider);
      return authState.isAuthenticated;
    } catch (e) {
      // If auth provider is not available, assume not authenticated
      return false;
    }
  }
  
  /// Gets vehicle entity by ID from realtime provider (for migration)
  /// 
  /// [vehicleId] - The vehicle ID to look up
  /// 
  /// Returns: VehicleEntity if found, null otherwise
  VehicleEntity? _getVehicleById(String vehicleId) {
    try {
      final realtimeState = _ref.read(gtfsRealtimeProvider);
      return realtimeState.vehicles.firstWhere(
        (vehicle) => vehicle.id == vehicleId,
        orElse: () => throw Exception('Vehicle not found'),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Migrates favorites from SharedPreferences to Supabase if needed
  /// 
  /// This method checks if there are local favorites and migrates them to Supabase
  /// when the user signs in. It only runs once per session.
  Future<void> _migrateFavoritesIfNeeded() async {
    // Check if user is authenticated
    if (!_isAuthenticated()) {
      return;
    }
    
    // Check if there are local favorites to migrate
    final localFavorites = _service.getSharedPreferencesFavorites();
    if (localFavorites.isEmpty) {
      return;
    }
    
    state = state.copyWith(isMigrating: true, error: null);
    
    try {
      // Migrate favorites, providing vehicle lookup function
      final migratedCount = await _service.migrateFromSharedPreferences(
        getVehicleById: _getVehicleById,
      );
      
      if (migratedCount > 0) {
        // Reload favorites after migration
        await loadFavorites();
      }
    } catch (e) {
      // Migration failed, but don't show error to user
      // Favorites remain in SharedPreferences and can be migrated later
    } finally {
      state = state.copyWith(isMigrating: false);
    }
  }
  
  /// Loads favorite vehicles from Supabase
  /// 
  /// This method is called automatically on initialization and can be called
  /// manually to refresh the favorites list.
  Future<void> loadFavorites() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final List<FavoriteEntity> favorites = await _service.getFavorites();
      state = state.copyWith(
        favorites: favorites,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load favorites: ${e.toString()}',
      );
    }
  }
  
  /// Adds a vehicle to favorites
  /// 
  /// [vehicle] - The vehicle entity to add (used to generate display name and metadata)
  /// [displayName] - Optional custom display name. If not provided, will be auto-generated
  /// 
  /// Returns: Future that completes with true if successful, false otherwise
  /// 
  /// Note: Only authenticated users (not guests) can add favorites
  Future<bool> addFavorite({
    required VehicleEntity vehicle,
    String? displayName,
  }) async {
    // Check if user is authenticated (not guest)
    if (!_isAuthenticated()) {
      state = state.copyWith(
        error: 'Please sign in to add favorites',
      );
      return false;
    }
    
    try {
      final FavoriteEntity? favorite = await _service.addFavorite(
        vehicle: vehicle,
        displayName: displayName,
      );
      
      if (favorite != null) {
        // Reload favorites to update state
        await loadFavorites();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to add favorite: ${e.toString()}',
      );
      return false;
    }
  }
  
  /// Removes a vehicle from favorites
  /// 
  /// [vehicleId] - The vehicle ID to remove
  /// 
  /// Returns: Future that completes with true if successful, false otherwise
  /// 
  /// Note: Only authenticated users (not guests) can remove favorites
  Future<bool> removeFavorite(String vehicleId) async {
    // Check if user is authenticated (not guest)
    if (!_isAuthenticated()) {
      state = state.copyWith(
        error: 'Please sign in to remove favorites',
      );
      return false;
    }
    
    // Optimistically remove the favorite from the list immediately for instant UI feedback
    final List<FavoriteEntity> updatedFavorites = state.favorites
        .where((favorite) => favorite.vehicleId != vehicleId)
        .toList();
    state = state.copyWith(favorites: updatedFavorites);
    
    try {
      final bool success = await _service.removeFavoriteByVehicleId(vehicleId);
      if (success) {
        // Reload favorites to ensure consistency with server state
        await loadFavorites();
      } else {
        // If removal failed, reload to restore the item
        await loadFavorites();
      }
      return success;
    } catch (e) {
      // If error occurred, reload favorites to restore the item
      await loadFavorites();
      state = state.copyWith(
        error: 'Failed to remove favorite: ${e.toString()}',
      );
      return false;
    }
  }
  
  /// Removes a favorite by its ID
  /// 
  /// [favoriteId] - The favorite ID to remove
  /// 
  /// Returns: Future that completes with true if successful, false otherwise
  Future<bool> removeFavoriteById(String favoriteId) async {
    // Check if user is authenticated (not guest)
    if (!_isAuthenticated()) {
      state = state.copyWith(
        error: 'Please sign in to remove favorites',
      );
      return false;
    }
    
    // Optimistically remove the favorite from the list immediately for instant UI feedback
    final List<FavoriteEntity> updatedFavorites = state.favorites
        .where((favorite) => favorite.id != favoriteId)
        .toList();
    state = state.copyWith(favorites: updatedFavorites);
    
    try {
      final bool success = await _service.removeFavorite(favoriteId);
      if (success) {
        // Reload favorites to ensure consistency with server state
        await loadFavorites();
      } else {
        // If removal failed, reload to restore the item
        await loadFavorites();
      }
      return success;
    } catch (e) {
      // If error occurred, reload favorites to restore the item
      await loadFavorites();
      state = state.copyWith(
        error: 'Failed to remove favorite: ${e.toString()}',
      );
      return false;
    }
  }
  
  /// Toggles a vehicle's favorite status
  /// 
  /// If the vehicle is currently a favorite, it will be removed.
  /// If it's not a favorite, it will be added.
  /// 
  /// [vehicle] - The vehicle entity to toggle
  /// 
  /// Returns: Future that completes with true if successful, false otherwise
  /// 
  /// Note: Only authenticated users (not guests) can toggle favorites
  Future<bool> toggleFavorite(VehicleEntity vehicle) async {
    // Check if user is authenticated (not guest)
    if (!_isAuthenticated()) {
      state = state.copyWith(
        error: 'Please sign in to add favorites',
      );
      return false;
    }
    
    final bool isFav = await _service.isFavorite(vehicle.id);
    if (isFav) {
      return await removeFavorite(vehicle.id);
    } else {
      return await addFavorite(vehicle: vehicle);
    }
  }
  
  /// Updates a favorite's display name
  /// 
  /// [favoriteId] - The ID of the favorite to update
  /// [displayName] - New display name
  /// 
  /// Returns: Future that completes with true if successful, false otherwise
  Future<bool> updateDisplayName({
    required String favoriteId,
    required String displayName,
  }) async {
    // Check if user is authenticated (not guest)
    if (!_isAuthenticated()) {
      state = state.copyWith(
        error: 'Please sign in to update favorites',
      );
      return false;
    }
    
    try {
      final FavoriteEntity? updated = await _service.updateDisplayName(
        favoriteId: favoriteId,
        displayName: displayName,
      );
      
      if (updated != null) {
        // Reload favorites to update state
        await loadFavorites();
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update favorite: ${e.toString()}',
      );
      return false;
    }
  }
  
  /// Clears all favorites
  /// 
  /// Returns: Future that completes with true if successful, false otherwise
  /// 
  /// Note: Only authenticated users (not guests) can clear favorites
  Future<bool> clearAllFavorites() async {
    // Check if user is authenticated (not guest)
    if (!_isAuthenticated()) {
      state = state.copyWith(
        error: 'Please sign in to clear favorites',
      );
      return false;
    }
    
    try {
      final bool success = await _service.clearFavorites();
      if (success) {
        // Update state to empty list
        state = state.copyWith(favorites: <FavoriteEntity>[]);
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to clear favorites: ${e.toString()}',
      );
      return false;
    }
  }
  
  /// Checks if a vehicle is a favorite
  /// 
  /// [vehicleId] - The vehicle ID to check
  /// 
  /// Returns: true if the vehicle is a favorite, false otherwise
  bool isFavorite(String vehicleId) {
    return state.favorites.any((favorite) => favorite.vehicleId == vehicleId);
  }
  
  /// Gets a favorite entity by vehicle ID
  /// 
  /// [vehicleId] - The vehicle ID to look up
  /// 
  /// Returns: FavoriteEntity if found, null otherwise
  FavoriteEntity? getFavoriteByVehicleId(String vehicleId) {
    try {
      return state.favorites.firstWhere(
        (favorite) => favorite.vehicleId == vehicleId,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Provider for favorite vehicles state management
/// 
/// This provider manages the state of favorite vehicles, allowing components
/// to add, remove, and check favorite status of vehicles.
final favoriteVehiclesProvider = StateNotifierProvider<FavoriteVehiclesNotifier, FavoriteVehiclesState>((ref) {
  // Get the service
  final FavoriteVehiclesService service = ref.read(favoriteVehiclesServiceProvider);
  
  // Create notifier with service and ref
  return FavoriteVehiclesNotifier(service, ref);
});
