import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/favorite_vehicles_service.dart';

/// Provider for SharedPreferences instance
/// 
/// This provider creates and caches a SharedPreferences instance for use
/// throughout the app. It's async because SharedPreferences.getInstance()
/// returns a Future.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for FavoriteVehiclesService
/// 
/// This provider creates a FavoriteVehiclesService instance with the
/// SharedPreferences instance from the sharedPreferencesProvider.
final favoriteVehiclesServiceProvider = Provider<FavoriteVehiclesService>((ref) {
  // Watch the SharedPreferences async provider
  final AsyncValue<SharedPreferences> prefsAsync = ref.watch(sharedPreferencesProvider);
  
  // Return a service with the prefs if available, or throw if not ready
  return prefsAsync.when(
    data: (SharedPreferences prefs) => FavoriteVehiclesService(prefs),
    loading: () => throw Exception('SharedPreferences not yet loaded'),
    error: (Object error, StackTrace stackTrace) => throw error,
  );
});

/// State class for favorite vehicles
/// 
/// This state tracks which vehicle IDs have been marked as favorites by the user.
class FavoriteVehiclesState {
  /// List of vehicle IDs that are marked as favorites
  final List<String> favoriteVehicleIds;
  
  /// Whether the favorites are currently being loaded
  final bool isLoading;
  
  /// Error message if loading favorites failed
  final String? error;
  
  /// Creates a FavoriteVehiclesState
  /// 
  /// [favoriteVehicleIds] - List of favorite vehicle IDs
  /// [isLoading] - Whether favorites are being loaded
  /// [error] - Error message if any
  const FavoriteVehiclesState({
    this.favoriteVehicleIds = const <String>[],
    this.isLoading = false,
    this.error,
  });
  
  /// Creates a copy of this state with the given fields replaced
  /// 
  /// This is useful for updating state immutably while keeping unchanged fields.
  FavoriteVehiclesState copyWith({
    List<String>? favoriteVehicleIds,
    bool? isLoading,
    String? error,
  }) {
    return FavoriteVehiclesState(
      favoriteVehicleIds: favoriteVehicleIds ?? this.favoriteVehicleIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing favorite vehicles state
/// 
/// This notifier handles loading, adding, removing, and toggling favorite vehicles.
/// It uses the FavoriteVehiclesService for persistent storage.
class FavoriteVehiclesNotifier extends StateNotifier<FavoriteVehiclesState> {
  /// The favorite vehicles service for persistent storage
  final FavoriteVehiclesService _service;
  
  /// Creates a FavoriteVehiclesNotifier
  /// 
  /// [_service] - The service to use for persistent storage
  FavoriteVehiclesNotifier(this._service) : super(const FavoriteVehiclesState()) {
    // Load favorites on initialization
    loadFavorites();
  }
  
  /// Loads favorite vehicle IDs from persistent storage
  /// 
  /// This method is called automatically on initialization and can be called
  /// manually to refresh the favorites list.
  void loadFavorites() {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final List<String> favorites = _service.getFavorites();
      state = state.copyWith(
        favoriteVehicleIds: favorites,
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
  /// [vehicleId] - The vehicle ID to add
  /// 
  /// Returns: Future that completes with true if successful, false otherwise
  Future<bool> addFavorite(String vehicleId) async {
    try {
      final bool success = await _service.addFavorite(vehicleId);
      if (success) {
        // Reload favorites to update state
        loadFavorites();
      }
      return success;
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
  Future<bool> removeFavorite(String vehicleId) async {
    try {
      final bool success = await _service.removeFavorite(vehicleId);
      if (success) {
        // Reload favorites to update state
        loadFavorites();
      }
      return success;
    } catch (e) {
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
  /// [vehicleId] - The vehicle ID to toggle
  /// 
  /// Returns: Future that completes with true if successful, false otherwise
  Future<bool> toggleFavorite(String vehicleId) async {
    if (_service.isFavorite(vehicleId)) {
      return await removeFavorite(vehicleId);
    } else {
      return await addFavorite(vehicleId);
    }
  }
  
  /// Clears all favorites
  /// 
  /// Returns: Future that completes with true if successful, false otherwise
  Future<bool> clearAllFavorites() async {
    try {
      final bool success = await _service.clearFavorites();
      if (success) {
        // Update state to empty list
        state = state.copyWith(favoriteVehicleIds: <String>[]);
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
    return state.favoriteVehicleIds.contains(vehicleId);
  }
}

/// Temporary in-memory favorite vehicles service
/// 
/// This service is used as a placeholder while SharedPreferences is loading.
/// It maintains state in memory only and doesn't persist to storage.
class _TemporaryFavoriteVehiclesService implements FavoriteVehiclesService {
  final List<String> _inMemoryFavorites = <String>[];
  
  @override
  List<String> getFavorites() => List<String>.from(_inMemoryFavorites);
  
  @override
  Future<bool> addFavorite(String vehicleId) async {
    if (!_inMemoryFavorites.contains(vehicleId)) {
      _inMemoryFavorites.add(vehicleId);
    }
    return true;
  }
  
  @override
  Future<bool> removeFavorite(String vehicleId) async {
    _inMemoryFavorites.remove(vehicleId);
    return true;
  }
  
  @override
  bool isFavorite(String vehicleId) {
    return _inMemoryFavorites.contains(vehicleId);
  }
  
  @override
  Future<bool> clearFavorites() async {
    _inMemoryFavorites.clear();
    return true;
  }
}

/// Provider for favorite vehicles state management
/// 
/// This provider manages the state of favorite vehicles, allowing components
/// to add, remove, and check favorite status of vehicles.
/// 
/// While SharedPreferences is loading, it uses a temporary in-memory service
/// that won't crash the UI but also won't persist data.
final favoriteVehiclesProvider = StateNotifierProvider<FavoriteVehiclesNotifier, FavoriteVehiclesState>((ref) {
  // Get the SharedPreferences async value
  final AsyncValue<SharedPreferences> prefsAsync = ref.watch(sharedPreferencesProvider);
  
  // Handle the async state
  return prefsAsync.maybeWhen(
    data: (SharedPreferences prefs) {
      // SharedPreferences loaded - create real notifier with persistent service
      final FavoriteVehiclesService service = FavoriteVehiclesService(prefs);
      return FavoriteVehiclesNotifier(service);
    },
    // For loading and error states, use temporary in-memory service
    // This prevents crashes while still allowing the UI to work
    orElse: () {
      final FavoriteVehiclesService tempService = _TemporaryFavoriteVehiclesService();
      return FavoriteVehiclesNotifier(tempService);
    },
  );
});

